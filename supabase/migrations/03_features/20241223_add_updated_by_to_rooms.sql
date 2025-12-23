-- Add updated_by column to rooms table to track who made the change
-- This allows the notification trigger to know who performed the action

-- 1. Add the column
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id);

-- 2. Update the notify_room_status_change function to use updated_by
CREATE OR REPLACE FUNCTION notify_room_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hotel_name TEXT;
    v_acting_user UUID;
BEGIN
    -- Only notify if status actually changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- Get hotel name
    SELECT name INTO v_hotel_name FROM hotels WHERE id = NEW.hotel_id;
    
    -- Use updated_by if available, otherwise fall back to null
    -- The Edge Function will NOT skip notifications where user_id doesn't match the acting user
    v_acting_user := COALESCE(NEW.updated_by, NULL);
    
    -- Insert notification record for each owner
    INSERT INTO notifications (hotel_id, user_id, type, title, body, data)
    SELECT 
        NEW.hotel_id,
        v_acting_user,  -- This is now the USER WHO TRIGGERED the change, not the owner
        'room_status_change',
        'Room Status - ' || COALESCE(v_hotel_name, 'Hotel'),
        'Room ' || NEW.room_number || ': ' || INITCAP(REPLACE(OLD.status::TEXT, '_', ' ')) || ' → ' || INITCAP(REPLACE(NEW.status::TEXT, '_', ' ')),
        jsonb_build_object(
            'room_id', NEW.id,
            'room_number', NEW.room_number,
            'old_status', OLD.status::TEXT,
            'new_status', NEW.status::TEXT,
            'hotel_id', NEW.hotel_id,
            'hotel_name', v_hotel_name
        )
    FROM hotel_staff hs
    WHERE hs.hotel_id = NEW.hotel_id
      AND hs.role = 'owner'
      AND hs.is_active = true;
    
    RETURN NEW;
END;
$$;

