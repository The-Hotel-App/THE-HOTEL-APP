-- Update Room Status Notification Trigger
-- Adds staff name and role to notification body
-- Prevents self-notification when owner makes the change
-- Requirements: 5.2, 5.3, 5.4, 5.5

-- ============================================================================
-- UPDATE: notify_room_status_change function
-- - Include staff name and role in notification body
-- - Add self-notification prevention (exclude acting user from recipients)
-- - Fix user_id to be the recipient (owner), not the acting user
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_room_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hotel_name TEXT;
    v_staff_name TEXT;
    v_staff_role TEXT;
    v_acting_user UUID;
BEGIN
    -- Only notify if status actually changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- Get hotel name
    SELECT name INTO v_hotel_name FROM hotels WHERE id = NEW.hotel_id;
    
    -- Get acting user from updated_by
    v_acting_user := NEW.updated_by;
    
    -- Get staff name and role
    IF v_acting_user IS NOT NULL THEN
        SELECT up.name INTO v_staff_name 
        FROM user_profiles up 
        WHERE up.id = v_acting_user;
        
        SELECT hs.role::TEXT INTO v_staff_role 
        FROM hotel_staff hs 
        WHERE hs.user_id = v_acting_user AND hs.hotel_id = NEW.hotel_id;
    END IF;
    
    -- Insert notification record for each owner (except the acting user)
    -- Requirement 5.5: Self-notification prevention
    INSERT INTO notifications (hotel_id, user_id, type, title, body, data)
    SELECT 
        NEW.hotel_id,
        hs.user_id,  -- The owner receiving the notification
        'room_status_change',
        'Room Status - ' || COALESCE(v_hotel_name, 'Hotel'),
        -- Requirement 5.2: Format "{staff_name} ({role}) changed Room {room_number} to {new_status}"
        COALESCE(v_staff_name, 'Staff') || ' (' || COALESCE(INITCAP(v_staff_role), 'Staff') || ') changed Room ' || NEW.room_number || ' to ' || INITCAP(REPLACE(NEW.status::TEXT, '_', ' ')),
        -- Requirement 5.3: Include staff_id, staff_name, and staff_role in data payload
        jsonb_build_object(
            'room_id', NEW.id,
            'room_number', NEW.room_number,
            'old_status', OLD.status::TEXT,
            'new_status', NEW.status::TEXT,
            'hotel_id', NEW.hotel_id,
            'hotel_name', v_hotel_name,
            'staff_id', v_acting_user,
            'staff_name', v_staff_name,
            'staff_role', v_staff_role
        )
    FROM hotel_staff hs
    WHERE hs.hotel_id = NEW.hotel_id
      AND hs.role = 'owner'
      AND hs.is_active = true
      -- Requirement 5.5: Exclude the acting user from receiving notification
      AND hs.user_id != COALESCE(v_acting_user, '00000000-0000-0000-0000-000000000000'::UUID);
    
    RETURN NEW;
END;
$$;

-- Recreate the trigger to ensure it uses the updated function
DROP TRIGGER IF EXISTS trg_notify_room_status_change ON rooms;
CREATE TRIGGER trg_notify_room_status_change
    AFTER UPDATE OF status ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION notify_room_status_change();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION notify_room_status_change() IS 
'Trigger function that creates notifications for hotel owners when room status changes.
Includes staff name and role in notification body.
Prevents self-notification when the acting user is an owner.
Requirements: 5.2, 5.3, 5.4, 5.5';
