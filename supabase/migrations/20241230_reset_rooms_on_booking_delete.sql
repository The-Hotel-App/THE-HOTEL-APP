-- Migration: Reset room status to 'free' when bookings are deleted
-- This ensures rooms don't stay in 'occupied' status when their bookings are removed

-- Function to reset room status when a booking is deleted
CREATE OR REPLACE FUNCTION reset_room_status_on_booking_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Reset the main room from the booking
    UPDATE rooms 
    SET status = 'free', 
        current_booking_id = NULL,
        updated_at = NOW()
    WHERE id = OLD.room_id 
      AND status = 'occupied';
    
    -- Also reset any rooms linked via booking_rooms junction table
    UPDATE rooms 
    SET status = 'free', 
        current_booking_id = NULL,
        updated_at = NOW()
    WHERE id IN (
        SELECT room_id FROM booking_rooms WHERE booking_id = OLD.id
    ) AND status = 'occupied';
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to fire BEFORE delete on bookings
DROP TRIGGER IF EXISTS trigger_reset_room_on_booking_delete ON bookings;
CREATE TRIGGER trigger_reset_room_on_booking_delete
    BEFORE DELETE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION reset_room_status_on_booking_delete();

-- Also create a function to reset ALL rooms to free (useful for manual cleanup)
CREATE OR REPLACE FUNCTION reset_all_rooms_to_free(p_hotel_id UUID DEFAULT NULL)
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    IF p_hotel_id IS NOT NULL THEN
        UPDATE rooms 
        SET status = 'free', 
            current_booking_id = NULL,
            updated_at = NOW()
        WHERE hotel_id = p_hotel_id 
          AND status != 'free';
    ELSE
        UPDATE rooms 
        SET status = 'free', 
            current_booking_id = NULL,
            updated_at = NOW()
        WHERE status != 'free';
    END IF;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION reset_all_rooms_to_free(UUID) TO authenticated;

COMMENT ON FUNCTION reset_room_status_on_booking_delete() IS 'Automatically resets room status to free when a booking is deleted';
COMMENT ON FUNCTION reset_all_rooms_to_free(UUID) IS 'Manually reset all rooms to free status. Pass hotel_id to reset only that hotel''s rooms, or NULL for all rooms';
