-- Add staff to hotel function
-- This function is needed because when creating a staff account:
-- 1. Owner is logged in
-- 2. signUp() is called for new staff -> this auto-logs in as the new user
-- 3. Then we try to insert into hotel_staff -> auth.uid() is now the NEW user, not owner
-- 4. RLS INSERT policy fails because new user is not owner
--
-- This function bypasses RLS using SECURITY DEFINER

CREATE OR REPLACE FUNCTION add_staff_to_hotel(
    p_hotel_id UUID,
    p_user_id UUID,
    p_role user_role,
    p_created_by UUID
)
RETURNS void AS $$
DECLARE
    v_is_owner BOOLEAN;
BEGIN
    -- Verify that the creator is the owner of the hotel
    SELECT EXISTS (
        SELECT 1 FROM hotels
        WHERE id = p_hotel_id
        AND owner_id = p_created_by
    ) INTO v_is_owner;
    
    IF NOT v_is_owner THEN
        RAISE EXCEPTION 'Only hotel owners can add staff';
    END IF;
    
    -- Insert the staff record
    INSERT INTO hotel_staff (hotel_id, user_id, role, is_active, created_by)
    VALUES (p_hotel_id, p_user_id, p_role, TRUE, p_created_by);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION add_staff_to_hotel(UUID, UUID, user_role, UUID) TO authenticated;
