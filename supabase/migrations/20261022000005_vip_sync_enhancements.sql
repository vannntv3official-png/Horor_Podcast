-- ==============================================================================
-- Khmer Horror Podcast - VIP Membership & Bakong KHQR Sync Enhancements
-- Migration: 20261022000005_vip_sync_enhancements.sql
-- ==============================================================================

BEGIN;

-- 1. Add extra columns to payment_transactions for better tracking
ALTER TABLE public.payment_transactions
ADD COLUMN IF NOT EXISTS sender_name TEXT NULL,
ADD COLUMN IF NOT EXISTS sender_phone TEXT NULL,
ADD COLUMN IF NOT EXISTS slip_image_url TEXT NULL,
ADD COLUMN IF NOT EXISTS admin_notes TEXT NULL;

-- 2. Ensure foreign key to public.profiles exists for PostgREST joins
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_payment_transactions_profiles'
    ) THEN
        ALTER TABLE public.payment_transactions
        ADD CONSTRAINT fk_payment_transactions_profiles
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Constraint already exists or could not be added: %', SQLERRM;
END $$;

-- 3. Robust RPC: Approve VIP Transaction
CREATE OR REPLACE FUNCTION public.approve_vip_transaction(p_transaction_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_plan_id TEXT;
    v_days INTEGER;
    v_new_expiry TIMESTAMPTZ;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only admins can approve VIP transactions';
    END IF;

    SELECT user_id, plan_id INTO v_user_id, v_plan_id
    FROM public.payment_transactions
    WHERE id = p_transaction_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Transaction % not found', p_transaction_id;
    END IF;

    -- Calculate plan days
    IF v_plan_id = 'vip_1_month' THEN
        v_days := 30;
    ELSIF v_plan_id = 'vip_3_months' THEN
        v_days := 90;
    ELSIF v_plan_id = 'vip_1_year' THEN
        v_days := 365;
    ELSE
        v_days := 30;
    END IF;

    -- Compute new expiration date (extend if existing active VIP)
    SELECT COALESCE(
        CASE 
            WHEN vip_expires_at > NOW() THEN vip_expires_at + (v_days || ' days')::INTERVAL
            ELSE NOW() + (v_days || ' days')::INTERVAL
        END,
        NOW() + (v_days || ' days')::INTERVAL
    ) INTO v_new_expiry
    FROM public.profiles
    WHERE id = v_user_id;

    -- Update profile
    UPDATE public.profiles
    SET is_vip = TRUE,
        vip_expires_at = v_new_expiry,
        updated_at = NOW()
    WHERE id = v_user_id;

    -- Update transaction
    UPDATE public.payment_transactions
    SET status = 'approved',
        updated_at = NOW()
    WHERE id = p_transaction_id;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'vip_expires_at', v_new_expiry
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Robust RPC: Reject VIP Transaction
CREATE OR REPLACE FUNCTION public.reject_vip_transaction(p_transaction_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only admins can reject VIP transactions';
    END IF;

    UPDATE public.payment_transactions
    SET status = 'rejected',
        admin_notes = COALESCE(p_reason, admin_notes),
        updated_at = NOW()
    WHERE id = p_transaction_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Grant permissions to RPCs
GRANT EXECUTE ON FUNCTION public.approve_vip_transaction(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_vip_transaction(UUID, TEXT) TO authenticated;

-- 6. Add to Supabase Realtime publication if not already present
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payment_transactions;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Table payment_transactions already in realtime or publication not configured';
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Table profiles already in realtime or publication not configured';
END $$;

COMMIT;
