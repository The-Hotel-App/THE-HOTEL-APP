-- Find user by email function for adding existing users to hotels
-- This function is used when an owner wants to add an existing user to their hotel
-- without creating a new auth account

CREATE OR REPLACE FUNCTION find_user_by_email(
    p_email TEXT,
    p_hotel_id UUID,
    p_requester_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_user_name TEXT;
    v_is_owner BOOLEAN;
    v_is_already_staff BOOLEAN;
BEGIN
    -- Verify the requester is the owner of the hotel
    SELECT EXISTS (
        SELECT 1 FROM hotels
        WHERE id = p_hotel_id
        AND owner_id = p_requester_id
    ) INTO v_is_owner;
    
    IF NOT v_is_owner THEN
        RETURN jsonb_build_object(
            'found', FALSE,
            'error', 'Only hotel owners can search for users'
        );
    END IF;

    -- Find user by email in auth.users (email is in auth.users, not user_profiles)
    SELECT au.id INTO v_user_id
    FROM auth.users au
    WHERE LOWER(au.email) = LOWER(p_email);
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'found', FALSE,
            'error', 'No user found with this email'
        );
    END IF;

    -- Get user name from user_profiles
    SELECT name INTO v_user_name
    FROM user_profiles
    WHERE id = v_user_id;

    -- Check if user is already staff at this hotel
    SELECT EXISTS (
        SELECT 1 FROM hotel_staff
        WHERE hotel_id = p_hotel_id
        AND user_id = v_user_id
    ) INTO v_is_already_staff;

    -- Return user info
    RETURN jsonb_build_object(
        'found', TRUE,
        'user_id', v_user_id,
        'name', COALESCE(v_user_name, 'Unknown'),
        'already_staff', v_is_already_staff
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION find_user_by_email(TEXT, UUID, UUID) TO authenticated;

COMMENT ON FUNCTION find_user_by_email IS 'Find a user by email for adding them to a hotel. Returns user info if found, with a flag if they are already staff at the hotel.';
