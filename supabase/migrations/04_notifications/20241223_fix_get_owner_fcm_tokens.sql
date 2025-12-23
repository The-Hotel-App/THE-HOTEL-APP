-- Fix: get_owner_fcm_tokens function - email is in auth.users, not user_profiles

CREATE OR REPLACE FUNCTION get_owner_fcm_tokens(p_hotel_id UUID)
RETURNS TABLE (
    user_id UUID,
    fcm_token TEXT,
    user_email TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dt.user_id,
        dt.fcm_token,
        au.email::TEXT as user_email
    FROM device_tokens dt
    JOIN hotel_staff hs ON dt.user_id = hs.user_id AND dt.hotel_id = hs.hotel_id
    JOIN auth.users au ON dt.user_id = au.id
    WHERE dt.hotel_id = p_hotel_id
      AND dt.is_active = true
      AND hs.role = 'owner'
      AND hs.is_active = true;
END;
$$;

