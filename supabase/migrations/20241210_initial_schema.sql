-- ROOMS.io Database Schema
-- Initial Migration for Multi-Hotel Support with Supabase Auth

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User roles in the system
CREATE TYPE user_role AS ENUM ('owner', 'manager', 'staff', 'kitchen_manager');

-- Room status
CREATE TYPE room_status AS ENUM ('free', 'occupied', 'cleaning', 'maintenance', 'out_of_service');

-- Booking status
CREATE TYPE booking_status AS ENUM ('confirmed', 'checked_in', 'checked_out', 'cancelled');

-- Payment mode
CREATE TYPE payment_mode AS ENUM ('cash', 'card', 'upi', 'bank_transfer', 'other');

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- User Profiles (extends Supabase auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    -- Biometric placeholder (will store encrypted template later)
    has_biometric BOOLEAN DEFAULT FALSE,
    biometric_enrolled_at TIMESTAMPTZ
);

-- Hotels
CREATE TABLE hotels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    total_rooms INTEGER NOT NULL DEFAULT 0,
    total_floors INTEGER NOT NULL DEFAULT 1,
    floor_configs JSONB, -- Stores floor configuration [{floor: 1, startRoom: 101, endRoom: 110}]
    owner_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_setup_completed BOOLEAN DEFAULT FALSE,
    CONSTRAINT hotels_name_check CHECK (char_length(name) >= 2),
    CONSTRAINT hotels_total_rooms_check CHECK (total_rooms >= 0),
    CONSTRAINT hotels_total_floors_check CHECK (total_floors >= 1)
);

-- Hotel Staff (Junction table - allows users to work in multiple hotels)
CREATE TABLE hotel_staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id),
    UNIQUE(hotel_id, user_id) -- User can only have one role per hotel
);

-- Employee Biometrics (placeholder for future biometric implementation)
CREATE TABLE employee_biometrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    -- Encrypted biometric template (placeholder - will be encrypted blob)
    biometric_template TEXT, -- Will store encrypted fingerprint template
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    enrolled_by UUID REFERENCES user_profiles(id),
    is_active BOOLEAN DEFAULT TRUE,
    last_verified_at TIMESTAMPTZ,
    UNIQUE(user_id, hotel_id) -- One biometric per user per hotel
);

-- Room Types
CREATE TABLE room_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    max_occupancy INTEGER NOT NULL DEFAULT 2,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT room_types_base_price_check CHECK (base_price >= 0),
    CONSTRAINT room_types_max_occupancy_check CHECK (max_occupancy >= 1)
);

-- Rooms
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    room_number TEXT NOT NULL,
    floor INTEGER NOT NULL,
    room_type_id UUID REFERENCES room_types(id) ON DELETE SET NULL,
    status room_status DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(hotel_id, room_number),
    CONSTRAINT rooms_floor_check CHECK (floor >= 1)
);

-- Guests
CREATE TABLE guests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    gender TEXT,
    id_type TEXT, -- 'passport', 'drivers_license', 'national_id', etc.
    id_number TEXT,
    id_photo_url TEXT, -- URL to stored ID photo
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    guest_id UUID NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
    check_in TIMESTAMPTZ NOT NULL,
    check_out TIMESTAMPTZ NOT NULL,
    number_of_guests INTEGER NOT NULL DEFAULT 1,
    booking_source TEXT, -- 'walk-in', 'online', 'phone', etc.
    status booking_status DEFAULT 'confirmed',
    total_amount DECIMAL(10, 2) DEFAULT 0,
    amount_paid DECIMAL(10, 2) DEFAULT 0,
    amount_pending DECIMAL(10, 2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id),
    -- Biometric verification tracking
    checked_in_by UUID REFERENCES user_profiles(id),
    checked_in_biometric_verified BOOLEAN DEFAULT FALSE,
    checked_out_by UUID REFERENCES user_profiles(id),
    checked_out_biometric_verified BOOLEAN DEFAULT FALSE,
    CONSTRAINT bookings_check_dates CHECK (check_out > check_in),
    CONSTRAINT bookings_number_of_guests_check CHECK (number_of_guests >= 1),
    CONSTRAINT bookings_total_amount_check CHECK (total_amount >= 0),
    CONSTRAINT bookings_amount_paid_check CHECK (amount_paid >= 0)
);

-- Payments
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_mode payment_mode NOT NULL,
    payment_date TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    created_by UUID REFERENCES user_profiles(id),
    -- Biometric verification for financial transactions
    biometric_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT payments_amount_check CHECK (amount > 0)
);

-- Day Books
CREATE TABLE daybooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    opening_balance DECIMAL(10, 2) DEFAULT 0,
    closing_balance DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id),
    UNIQUE(hotel_id, date)
);

-- Day Book Transactions
CREATE TABLE daybook_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    daybook_id UUID NOT NULL REFERENCES daybooks(id) ON DELETE CASCADE,
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL, -- 'income', 'expense'
    category TEXT NOT NULL, -- 'booking', 'payment', 'salary', 'maintenance', etc.
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT,
    reference_id UUID, -- Can link to booking, payment, etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id),
    CONSTRAINT daybook_transactions_amount_check CHECK (amount >= 0)
);

-- Maintenance Objects (AC, TV, Furniture, etc.)
CREATE TABLE maintenance_objects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service History (Cleaning, Maintenance logs)
CREATE TABLE service_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    service_type TEXT NOT NULL, -- 'cleaning', 'maintenance'
    maintenance_object_id UUID REFERENCES maintenance_objects(id),
    status TEXT NOT NULL, -- 'pending', 'in_progress', 'completed'
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    -- Biometric tracking
    started_by UUID REFERENCES user_profiles(id),
    started_biometric_verified BOOLEAN DEFAULT FALSE,
    completed_by UUID REFERENCES user_profiles(id),
    completed_biometric_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Room Status Logs (Audit trail)
CREATE TABLE room_status_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    old_status room_status,
    new_status room_status NOT NULL,
    changed_by UUID REFERENCES user_profiles(id),
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- Biometric Audit Logs (Track all biometric verifications)
CREATE TABLE biometric_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL, -- 'check_in', 'payment', 'cleaning_start', etc.
    reference_id UUID, -- Link to booking, payment, service_history, etc.
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    device_info JSONB, -- Store device information
    success BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

CREATE INDEX idx_user_profiles_active ON user_profiles(is_active);
CREATE INDEX idx_hotels_owner ON hotels(owner_id);
CREATE INDEX idx_hotel_staff_hotel ON hotel_staff(hotel_id);
CREATE INDEX idx_hotel_staff_user ON hotel_staff(user_id);
CREATE INDEX idx_hotel_staff_active ON hotel_staff(is_active);
CREATE INDEX idx_rooms_hotel ON rooms(hotel_id);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_bookings_hotel ON bookings(hotel_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_dates ON bookings(check_in, check_out);
CREATE INDEX idx_guests_hotel ON guests(hotel_id);
CREATE INDEX idx_payments_hotel ON payments(hotel_id);
CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_daybooks_hotel_date ON daybooks(hotel_id, date);
CREATE INDEX idx_service_history_hotel ON service_history(hotel_id);
CREATE INDEX idx_service_history_room ON service_history(room_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hotels ENABLE ROW LEVEL SECURITY;
ALTER TABLE hotel_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_biometrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE daybooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daybook_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_status_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE biometric_audit_logs ENABLE ROW LEVEL SECURITY;

-- User Profiles: Users can read their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Hotels: Users can see hotels they're associated with
CREATE POLICY "Users can view their hotels" ON hotels
    FOR SELECT USING (
        owner_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM hotel_staff
            WHERE hotel_staff.hotel_id = hotels.id
            AND hotel_staff.user_id = auth.uid()
            AND hotel_staff.is_active = TRUE
        )
    );

CREATE POLICY "Owners can create hotels" ON hotels
    FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Owners can update their hotels" ON hotels
    FOR UPDATE USING (owner_id = auth.uid());

-- Hotel Staff: Users can see staff of hotels they belong to
CREATE POLICY "View hotel staff" ON hotel_staff
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM hotels
            WHERE hotels.id = hotel_staff.hotel_id
            AND (
                hotels.owner_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM hotel_staff hs
                    WHERE hs.hotel_id = hotels.id
                    AND hs.user_id = auth.uid()
                    AND hs.is_active = TRUE
                )
            )
        )
    );

CREATE POLICY "Owners can manage hotel staff" ON hotel_staff
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM hotels
            WHERE hotels.id = hotel_staff.hotel_id
            AND hotels.owner_id = auth.uid()
        )
    );

-- Generic policy for hotel-scoped data
-- This function will be used by multiple policies
CREATE OR REPLACE FUNCTION user_has_hotel_access(target_hotel_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM hotels
        WHERE id = target_hotel_id
        AND (
            owner_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM hotel_staff
                WHERE hotel_staff.hotel_id = target_hotel_id
                AND hotel_staff.user_id = auth.uid()
                AND hotel_staff.is_active = TRUE
            )
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply hotel access policy to all hotel-scoped tables
CREATE POLICY "Hotel access for rooms" ON rooms
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for room_types" ON room_types
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for guests" ON guests
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for bookings" ON bookings
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for payments" ON payments
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for daybooks" ON daybooks
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for daybook_transactions" ON daybook_transactions
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for maintenance_objects" ON maintenance_objects
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for service_history" ON service_history
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for room_status_logs" ON room_status_logs
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for biometric_audit_logs" ON biometric_audit_logs
    FOR ALL USING (user_has_hotel_access(hotel_id));

CREATE POLICY "Hotel access for employee_biometrics" ON employee_biometrics
    FOR ALL USING (user_has_hotel_access(hotel_id));

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically create user_profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, name, phone)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'phone', NULL)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_hotels_updated_at BEFORE UPDATE ON hotels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guests_updated_at BEFORE UPDATE ON guests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_room_types_updated_at BEFORE UPDATE ON room_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daybooks_updated_at BEFORE UPDATE ON daybooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Log room status changes
CREATE OR REPLACE FUNCTION log_room_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO room_status_logs (hotel_id, room_id, old_status, new_status, changed_by)
        VALUES (NEW.hotel_id, NEW.id, OLD.status, NEW.status, auth.uid());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_room_status_change
    AFTER UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION log_room_status_change();

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Get user's hotels with their role
CREATE OR REPLACE FUNCTION get_user_hotels(user_uuid UUID)
RETURNS TABLE (
    hotel_id UUID,
    hotel_name TEXT,
    user_role user_role,
    is_owner BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.id as hotel_id,
        h.name as hotel_name,
        COALESCE(hs.role, 'owner'::user_role) as user_role,
        (h.owner_id = user_uuid) as is_owner
    FROM hotels h
    LEFT JOIN hotel_staff hs ON h.id = hs.hotel_id AND hs.user_id = user_uuid
    WHERE h.owner_id = user_uuid OR (hs.user_id = user_uuid AND hs.is_active = TRUE)
    ORDER BY is_owner DESC, h.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE user_profiles IS 'Extended user information beyond Supabase auth.users';
COMMENT ON TABLE hotels IS 'Hotel/Lodge information - one owner can have multiple hotels';
COMMENT ON TABLE hotel_staff IS 'Junction table allowing users to work in multiple hotels with different roles';
COMMENT ON TABLE employee_biometrics IS 'Stores encrypted biometric templates for fingerprint verification';
COMMENT ON COLUMN employee_biometrics.biometric_template IS 'Encrypted fingerprint template - placeholder for now';
COMMENT ON TABLE biometric_audit_logs IS 'Audit trail for all biometric verifications';
