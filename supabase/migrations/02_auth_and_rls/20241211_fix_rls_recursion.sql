-- ROOMS.io RLS Policy Fix
-- Fix infinite recursion in hotel_staff policies
-- Run this in Supabase SQL Editor

-- ============================================================================
-- STEP 1: Drop all policies that depend on user_has_hotel_access function
-- ============================================================================

DROP POLICY IF EXISTS "Hotel access for rooms" ON rooms;
DROP POLICY IF EXISTS "Hotel access for room_types" ON room_types;
DROP POLICY IF EXISTS "Hotel access for guests" ON guests;
DROP POLICY IF EXISTS "Hotel access for bookings" ON bookings;
DROP POLICY IF EXISTS "Hotel access for payments" ON payments;
DROP POLICY IF EXISTS "Hotel access for daybooks" ON daybooks;
DROP POLICY IF EXISTS "Hotel access for daybook_transactions" ON daybook_transactions;
DROP POLICY IF EXISTS "Hotel access for maintenance_objects" ON maintenance_objects;
DROP POLICY IF EXISTS "Hotel access for service_history" ON service_history;
DROP POLICY IF EXISTS "Hotel access for room_status_logs" ON room_status_logs;
DROP POLICY IF EXISTS "Hotel access for biometric_audit_logs" ON biometric_audit_logs;
DROP POLICY IF EXISTS "Hotel access for employee_biometrics" ON employee_biometrics;

-- Drop problematic hotel_staff policies
DROP POLICY IF EXISTS "View hotel staff" ON hotel_staff;
DROP POLICY IF EXISTS "Owners can manage hotel staff" ON hotel_staff;

-- ============================================================================
-- STEP 2: Drop and recreate the helper functions
-- ============================================================================

-- Drop the old function now that policies are removed
DROP FUNCTION IF EXISTS user_has_hotel_access(UUID);

-- Create helper function that checks if user is staff (bypasses RLS)
CREATE OR REPLACE FUNCTION is_user_staff_of_hotel(target_hotel_id UUID, target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM hotel_staff
        WHERE hotel_id = target_hotel_id
        AND user_id = target_user_id
        AND is_active = TRUE
    ) INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create helper function that checks if user is owner
CREATE OR REPLACE FUNCTION is_user_owner_of_hotel(target_hotel_id UUID, target_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM hotels
        WHERE id = target_hotel_id
        AND owner_id = target_user_id
    ) INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the main hotel access function using the helpers
CREATE OR REPLACE FUNCTION user_has_hotel_access(target_hotel_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_user_owner_of_hotel(target_hotel_id, auth.uid()) 
        OR is_user_staff_of_hotel(target_hotel_id, auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 3: Recreate all the hotel access policies
-- ============================================================================

-- Rooms
CREATE POLICY "Hotel access for rooms" ON rooms
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Room types
CREATE POLICY "Hotel access for room_types" ON room_types
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Guests
CREATE POLICY "Hotel access for guests" ON guests
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Bookings
CREATE POLICY "Hotel access for bookings" ON bookings
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Payments
CREATE POLICY "Hotel access for payments" ON payments
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Daybooks
CREATE POLICY "Hotel access for daybooks" ON daybooks
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Daybook transactions
CREATE POLICY "Hotel access for daybook_transactions" ON daybook_transactions
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Maintenance objects
CREATE POLICY "Hotel access for maintenance_objects" ON maintenance_objects
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Service history
CREATE POLICY "Hotel access for service_history" ON service_history
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Room status logs
CREATE POLICY "Hotel access for room_status_logs" ON room_status_logs
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Biometric audit logs
CREATE POLICY "Hotel access for biometric_audit_logs" ON biometric_audit_logs
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- Employee biometrics
CREATE POLICY "Hotel access for employee_biometrics" ON employee_biometrics
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- ============================================================================
-- STEP 4: Create fixed policies for hotel_staff (non-recursive)
-- ============================================================================

-- Users can view staff of hotels where they are owner or active staff
CREATE POLICY "View hotel staff" ON hotel_staff
    FOR SELECT USING (
        is_user_owner_of_hotel(hotel_id, auth.uid()) OR
        is_user_staff_of_hotel(hotel_id, auth.uid())
    );

-- Owners can insert staff
CREATE POLICY "Owners can insert hotel staff" ON hotel_staff
    FOR INSERT WITH CHECK (
        is_user_owner_of_hotel(hotel_id, auth.uid())
    );

-- Owners can update staff
CREATE POLICY "Owners can update hotel staff" ON hotel_staff
    FOR UPDATE USING (
        is_user_owner_of_hotel(hotel_id, auth.uid())
    );

-- Owners can delete staff
CREATE POLICY "Owners can delete hotel staff" ON hotel_staff
    FOR DELETE USING (
        is_user_owner_of_hotel(hotel_id, auth.uid())
    );

-- ============================================================================
-- STEP 5: Grant execute permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION is_user_staff_of_hotel(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_user_owner_of_hotel(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_has_hotel_access(UUID) TO authenticated;
