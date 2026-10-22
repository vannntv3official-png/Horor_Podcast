-- ==============================================================================
-- Khmer Horror Podcast - Security Hardening & Privilege Escalation Protection
-- Migration: 20261022000006_security_hardening.sql
-- ==============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Anti-Tamper Trigger: Protect VIP Fields on public.profiles
-- Prevents regular users from modifying is_vip or vip_expires_at via client SDK
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profiles_vip_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If is_vip or vip_expires_at is changed
    IF (NEW.is_vip IS DISTINCT FROM OLD.is_vip OR NEW.vip_expires_at IS DISTINCT FROM OLD.vip_expires_at) THEN
        -- Only allow if caller is an admin
        IF NOT public.is_admin() THEN
            -- Revert VIP changes to original values silently to prevent unauthorized escalation
            NEW.is_vip := OLD.is_vip;
            NEW.vip_expires_at := OLD.vip_expires_at;
        END IF;
    END IF;

    -- Always update updated_at timestamp
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_profiles_vip ON public.profiles;
CREATE TRIGGER trg_protect_profiles_vip
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_profiles_vip_status();

-- -----------------------------------------------------------------------------
-- 2. Anti-Tamper Trigger: Payment Transactions Insertion Protection
-- Enforces that regular users can ONLY insert with status = 'pending'
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_payment_transactions_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Force status to pending for any non-admin caller
    IF NOT public.is_admin() THEN
        NEW.status := 'pending';
        NEW.created_at := NOW();
        NEW.updated_at := NOW();
    END IF;

    -- Basic input validation
    IF NEW.amount_usd <= 0 THEN
        RAISE EXCEPTION 'Transaction amount must be greater than zero';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_protect_payment_transactions_insert ON public.payment_transactions;
CREATE TRIGGER trg_protect_payment_transactions_insert
    BEFORE INSERT ON public.payment_transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_payment_transactions_insert();

-- Enforce strict RLS policy on payment_transactions insert
DROP POLICY IF EXISTS "transactions_insert_user" ON public.payment_transactions;
CREATE POLICY "transactions_insert_user"
    ON public.payment_transactions FOR INSERT
    WITH CHECK (
        auth.uid() = user_id 
        AND (status IS NULL OR status = 'pending')
    );

-- -----------------------------------------------------------------------------
-- 3. Hardened Role Assignment
-- -----------------------------------------------------------------------------
-- Ensure user_roles can only ever be inserted/updated/deleted by genuine admins
DROP POLICY IF EXISTS "user_roles_insert_admin" ON public.user_roles;
CREATE POLICY "user_roles_insert_admin"
    ON public.user_roles FOR INSERT
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "user_roles_update_admin" ON public.user_roles;
CREATE POLICY "user_roles_update_admin"
    ON public.user_roles FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "user_roles_delete_admin" ON public.user_roles;
CREATE POLICY "user_roles_delete_admin"
    ON public.user_roles FOR DELETE
    USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 4. Audit Log Access Hardening
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "audit_logs_select" ON public.admin_audit_logs;
CREATE POLICY "audit_logs_select"
    ON public.admin_audit_logs FOR SELECT
    USING (public.is_admin());

DROP POLICY IF EXISTS "audit_logs_insert" ON public.admin_audit_logs;
CREATE POLICY "audit_logs_insert"
    ON public.admin_audit_logs FOR INSERT
    WITH CHECK (public.is_editor());

COMMIT;
