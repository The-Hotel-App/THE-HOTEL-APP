-- Push Notifications Infrastructure
-- Creates tables and triggers for FCM push notifications to hotel Owners

-- ============================================================================
-- 1. DEVICE TOKENS TABLE
-- Stores FCM tokens for each user/hotel combination
-- ============================================================================

CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Prevent duplicate tokens for same user/hotel
    CONSTRAINT unique_device_token UNIQUE (user_id, hotel_id, fcm_token)
);

-- Index for fast lookups by hotel (used when sending notifications)
CREATE INDEX IF NOT EXISTS idx_device_tokens_hotel_id ON device_tokens(hotel_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON device_tokens(is_active) WHERE is_active = true;

-- RLS Policies for device_tokens
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
CREATE POLICY "Users can insert own device tokens"
    ON device_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own device tokens"
    ON device_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own device tokens"
    ON device_tokens FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own device tokens"
    ON device_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 2. NOTIFICATIONS TABLE
-- Stores notification history for in-app display
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('new_booking', 'room_status_change', 'checkout', 'payment', 'system')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,  -- For "clear history" (soft delete)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_notifications_user_hotel ON notifications(user_id, hotel_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- RLS Policies for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- System can insert notifications (via service role in Edge Function)
CREATE POLICY "Service role can insert notifications"
    ON notifications FOR INSERT
    WITH CHECK (true);

-- ============================================================================
-- 3. HELPER FUNCTION: Get Owner FCM Tokens for a Hotel
-- ============================================================================

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
        up.email as user_email
    FROM device_tokens dt
    JOIN hotel_staff hs ON dt.user_id = hs.user_id AND dt.hotel_id = hs.hotel_id
    JOIN user_profiles up ON dt.user_id = up.id
    WHERE dt.hotel_id = p_hotel_id
      AND dt.is_active = true
      AND hs.role = 'owner'
      AND hs.is_active = true;
END;
$$;

-- ============================================================================
-- 4. TRIGGER FUNCTION: Notify on New Booking
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
    
    -- Call Edge Function via pg_net (if available) or store for polling
    -- For now, we'll insert into a queue table that the Edge Function polls
    -- Or use Supabase Realtime to trigger the Edge Function
    
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

-- Create trigger on bookings table
DROP TRIGGER IF EXISTS trg_notify_new_booking ON bookings;
CREATE TRIGGER trg_notify_new_booking
    AFTER INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_booking();

-- ============================================================================
-- 5. TRIGGER FUNCTION: Notify on Room Status Change
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
    INSERT INTO notifications (hotel_id, user_id, type, title, body, data)
    SELECT 
        NEW.hotel_id,
        hs.user_id,
        'room_status_change',
        'Room Status - ' || COALESCE(v_hotel_name, 'Hotel'),
        'Room ' || NEW.room_number || ': ' || INITCAP(REPLACE(OLD.status, '_', ' ')) || ' → ' || INITCAP(REPLACE(NEW.status, '_', ' ')),
        jsonb_build_object(
            'room_id', NEW.id,
            'room_number', NEW.room_number,
            'old_status', OLD.status,
            'new_status', NEW.status,
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

-- Create trigger on rooms table
DROP TRIGGER IF EXISTS trg_notify_room_status_change ON rooms;
CREATE TRIGGER trg_notify_room_status_change
    AFTER UPDATE OF status ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION notify_room_status_change();

-- ============================================================================
-- 6. FUNCTION: Mark Notifications as Read
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_notifications_read(p_notification_ids UUID[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_read = true
    WHERE id = ANY(p_notification_ids)
      AND user_id = auth.uid();
END;
$$;

-- ============================================================================
-- 7. FUNCTION: Toggle Notification Visibility (Clear/Restore)
-- ============================================================================

CREATE OR REPLACE FUNCTION toggle_notifications_visibility(p_hidden BOOLEAN)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_hidden = p_hidden
    WHERE user_id = auth.uid();
END;
$$;
