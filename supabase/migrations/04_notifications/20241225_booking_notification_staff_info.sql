-- Update notify_new_booking function to include staff user who created the booking
-- This ensures owners know WHO created the booking, not just the guest info

CREATE OR REPLACE FUNCTION notify_new_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hotel_name TEXT;
    v_room_number TEXT;
    v_guest_name TEXT;
    v_staff_name TEXT;
BEGIN
    -- Get hotel name
    SELECT name INTO v_hotel_name FROM hotels WHERE id = NEW.hotel_id;
    
    -- Get room number
    SELECT room_number INTO v_room_number FROM rooms WHERE id = NEW.room_id;
    
    -- Get guest name
    SELECT name INTO v_guest_name FROM guests WHERE id = NEW.guest_id;
    
    -- Get staff name who created the booking
    SELECT name INTO v_staff_name FROM user_profiles WHERE id = NEW.created_by;
    
    -- Insert notification record for each owner
    INSERT INTO notifications (hotel_id, user_id, type, title, body, data)
    SELECT 
        NEW.hotel_id,
        hs.user_id,
        'new_booking',
        'New Booking - ' || COALESCE(v_hotel_name, 'Hotel'),
        'Room ' || COALESCE(v_room_number, 'N/A') || ' booked by ' || COALESCE(v_guest_name, 'Guest') || 
        CASE 
            WHEN v_staff_name IS NOT NULL THEN ' (by ' || v_staff_name || ')'
            ELSE ''
        END,
        jsonb_build_object(
            'booking_id', NEW.id,
            'room_id', NEW.room_id,
            'room_number', v_room_number,
            'guest_name', v_guest_name,
            'staff_id', NEW.created_by,
            'staff_name', v_staff_name,
            'hotel_id', NEW.hotel_id,
            'hotel_name', v_hotel_name,
            'check_in', NEW.check_in,
            'check_out', NEW.check_out,
            'total_amount', NEW.total_amount,
            'amount_paid', NEW.amount_paid
        )
    FROM hotel_staff hs
    WHERE hs.hotel_id = NEW.hotel_id
      AND hs.role = 'owner'
      AND hs.is_active = true;
    
    RETURN NEW;
END;
$$;

-- Recreate the trigger to use the updated function
DROP TRIGGER IF EXISTS trg_notify_new_booking ON bookings;
CREATE TRIGGER trg_notify_new_booking
    AFTER INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_booking();

-- Add comment for documentation
COMMENT ON FUNCTION notify_new_booking() IS 
'Creates notifications for hotel owners when a new booking is created. 
Includes guest info AND the staff member who created the booking.';
