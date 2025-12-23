-- Auto-invoke Edge Function when notifications are inserted
-- Uses pg_net extension to make HTTP calls from triggers

-- Enable pg_net extension (available in Supabase)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ============================================================================
-- 1. TRIGGER ON NOTIFICATIONS TABLE to invoke Edge Function
-- This is cleaner - invoke Edge Function after any notification insert
-- ============================================================================

CREATE OR REPLACE FUNCTION invoke_push_notification_edge_function()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Use pg_net to call the Edge Function asynchronously
    -- The Edge Function URL and anon key are hardcoded for simplicity
    PERFORM net.http_post(
        url := 'https://nqlcagdgkiekanclxumz.supabase.co/functions/v1/send-push-notification',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xbGNhZ2Rna2lla2FuY2x4dW16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjUwNDYsImV4cCI6MjA4MDk0MTA0Nn0.CzmVdBwEqg1WdjO5IAnqF67xnje8nNYuIbo4P3S4GHA'
        ),
        body := jsonb_build_object('notification_ids', ARRAY[NEW.id])
    );
    
    RETURN NEW;
END;
$$;

-- Create trigger on notifications table
DROP TRIGGER IF EXISTS trg_invoke_push_notification ON notifications;
CREATE TRIGGER trg_invoke_push_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION invoke_push_notification_edge_function();


-- ============================================================================
-- 2. UPDATE: notify_new_booking to fix the enum casting issue
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_new_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hotel_name TEXT;
    v_room_number TEXT;
    v_guest_name TEXT;
BEGIN
    -- Get hotel name
    SELECT name INTO v_hotel_name FROM hotels WHERE id = NEW.hotel_id;
    
    -- Get room number
    SELECT room_number INTO v_room_number FROM rooms WHERE id = NEW.room_id;
    
    -- Get guest name
    SELECT name INTO v_guest_name FROM guests WHERE id = NEW.guest_id;
    
    -- Insert notification record for each owner
    INSERT INTO notifications (hotel_id, user_id, type, title, body, data)
    SELECT 
        NEW.hotel_id,
        hs.user_id,
        'new_booking',
        'New Booking - ' || COALESCE(v_hotel_name, 'Hotel'),
        'Room ' || COALESCE(v_room_number, 'N/A') || ' booked by ' || COALESCE(v_guest_name, 'Guest'),
        jsonb_build_object(
            'booking_id', NEW.id,
            'room_id', NEW.room_id,
            'room_number', v_room_number,
            'guest_name', v_guest_name,
            'hotel_id', NEW.hotel_id,
            'hotel_name', v_hotel_name,
            'check_in', NEW.check_in,
            'check_out', NEW.check_out
        )
    FROM hotel_staff hs
    WHERE hs.hotel_id = NEW.hotel_id
      AND hs.role = 'owner'
      AND hs.is_active = true;
    
    RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trg_notify_new_booking ON bookings;
CREATE TRIGGER trg_notify_new_booking
    AFTER INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_booking();


-- ============================================================================
-- 3. UPDATE: notify_room_status_change with enum casting fix
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_room_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hotel_name TEXT;
BEGIN
    -- Only notify if status actually changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- Get hotel name
    SELECT name INTO v_hotel_name FROM hotels WHERE id = NEW.hotel_id;
    
    -- Insert notification record for each owner
    -- Fix: Cast status enum to TEXT to use with REPLACE function
    INSERT INTO notifications (hotel_id, user_id, type, title, body, data)
    SELECT 
        NEW.hotel_id,
        hs.user_id,
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

-- Recreate the trigger
DROP TRIGGER IF EXISTS trg_notify_room_status_change ON rooms;
CREATE TRIGGER trg_notify_room_status_change
    AFTER UPDATE OF status ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION notify_room_status_change();
