-- Migration: Add support for multiple guests and rooms per booking
-- Date: 2024-12-24

-- 1. Add age column to guests table
ALTER TABLE guests ADD COLUMN IF NOT EXISTS age integer;

-- 2. Create booking_guests junction table (links multiple guests to a booking)
CREATE TABLE IF NOT EXISTS booking_guests (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    guest_id uuid NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
    is_primary boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    UNIQUE(booking_id, guest_id)
);

-- 3. Create booking_rooms junction table (links multiple rooms to a booking)
CREATE TABLE IF NOT EXISTS booking_rooms (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    room_price numeric DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    UNIQUE(booking_id, room_id)
);

-- 4. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_booking_guests_booking_id ON booking_guests(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_guests_guest_id ON booking_guests(guest_id);
CREATE INDEX IF NOT EXISTS idx_booking_rooms_booking_id ON booking_rooms(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_rooms_room_id ON booking_rooms(room_id);

-- 5. Enable RLS on new tables
ALTER TABLE booking_guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_rooms ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for booking_guests
CREATE POLICY "Users can view booking_guests for their hotel bookings"
    ON booking_guests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bookings b
            JOIN hotel_staff hs ON hs.hotel_id = b.hotel_id
            WHERE b.id = booking_guests.booking_id
            AND hs.user_id = auth.uid()
            AND hs.is_active = true
        )
    );

CREATE POLICY "Users can insert booking_guests for their hotel bookings"
    ON booking_guests FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM bookings b
            JOIN hotel_staff hs ON hs.hotel_id = b.hotel_id
            WHERE b.id = booking_guests.booking_id
            AND hs.user_id = auth.uid()
            AND hs.is_active = true
        )
    );

CREATE POLICY "Users can delete booking_guests for their hotel bookings"
    ON booking_guests FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM bookings b
            JOIN hotel_staff hs ON hs.hotel_id = b.hotel_id
            WHERE b.id = booking_guests.booking_id
            AND hs.user_id = auth.uid()
            AND hs.is_active = true
        )
    );

-- 7. Create RLS policies for booking_rooms
CREATE POLICY "Users can view booking_rooms for their hotel bookings"
    ON booking_rooms FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bookings b
            JOIN hotel_staff hs ON hs.hotel_id = b.hotel_id
            WHERE b.id = booking_rooms.booking_id
            AND hs.user_id = auth.uid()
            AND hs.is_active = true
        )
    );

CREATE POLICY "Users can insert booking_rooms for their hotel bookings"
    ON booking_rooms FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM bookings b
            JOIN hotel_staff hs ON hs.hotel_id = b.hotel_id
            WHERE b.id = booking_rooms.booking_id
            AND hs.user_id = auth.uid()
            AND hs.is_active = true
        )
    );

CREATE POLICY "Users can delete booking_rooms for their hotel bookings"
    ON booking_rooms FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM bookings b
            JOIN hotel_staff hs ON hs.hotel_id = b.hotel_id
            WHERE b.id = booking_rooms.booking_id
            AND hs.user_id = auth.uid()
            AND hs.is_active = true
        )
    );

-- 8. Add comment for documentation
COMMENT ON TABLE booking_guests IS 'Junction table linking multiple guests to a single booking';
COMMENT ON TABLE booking_rooms IS 'Junction table linking multiple rooms to a single booking';
COMMENT ON COLUMN guests.age IS 'Guest age in years';
