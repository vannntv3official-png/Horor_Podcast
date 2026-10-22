-- ==============================================================================
-- Khmer Horror Podcast - Monetization (VIP Membership & KHQR Payments)
-- Migration: 20261022000004_monetization_vip.sql
-- ==============================================================================

BEGIN;

-- 1. Add VIP status columns to public.profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_vip BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS vip_expires_at TIMESTAMPTZ NULL;

-- 2. Create Payment Transactions Table for KHQR / VIP Orders
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL, -- 'vip_1_month', 'vip_3_months', 'vip_1_year'
    amount_usd NUMERIC(10, 2) NOT NULL,
    amount_khr NUMERIC(12, 0) NOT NULL,
    payment_method TEXT DEFAULT 'bakong_khqr' NOT NULL,
    transaction_ref TEXT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON public.payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status);

-- 3. Enable RLS on payment_transactions
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own transactions; Admins can view all
DROP POLICY IF EXISTS "transactions_select" ON public.payment_transactions;
CREATE POLICY "transactions_select"
    ON public.payment_transactions FOR SELECT
    USING (auth.uid() = user_id OR public.is_admin());

-- Allow authenticated users to create a payment transaction
DROP POLICY IF EXISTS "transactions_insert_user" ON public.payment_transactions;
CREATE POLICY "transactions_insert_user"
    ON public.payment_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Only Admins can approve or update transactions
DROP POLICY IF EXISTS "transactions_update_admin" ON public.payment_transactions;
CREATE POLICY "transactions_update_admin"
    ON public.payment_transactions FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 4. Helper Function: Approve VIP Transaction
CREATE OR REPLACE FUNCTION public.approve_vip_transaction(p_transaction_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_plan_id TEXT;
    v_days INTEGER;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only admins can approve VIP transactions';
    END IF;

    SELECT user_id, plan_id INTO v_user_id, v_plan_id
    FROM public.payment_transactions
    WHERE id = p_transaction_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Transaction not found';
    END IF;

    -- Calculate duration
    IF v_plan_id = 'vip_1_month' THEN
        v_days := 30;
    ELSIF v_plan_id = 'vip_3_months' THEN
        v_days := 90;
    ELSIF v_plan_id = 'vip_1_year' THEN
        v_days := 365;
    ELSE
        v_days := 30;
    END IF;

    -- Update profile
    UPDATE public.profiles
    SET is_vip = TRUE,
        vip_expires_at = COALESCE(
            CASE 
                WHEN vip_expires_at > NOW() THEN vip_expires_at + (v_days || ' days')::INTERVAL
                ELSE NOW() + (v_days || ' days')::INTERVAL
            END,
            NOW() + (v_days || ' days')::INTERVAL
        )
    WHERE id = v_user_id;

    -- Update transaction status
    UPDATE public.payment_transactions
    SET status = 'approved',
        updated_at = NOW()
    WHERE id = p_transaction_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

COMMIT;
