-- ROOMS.io Onboarding Schema Updates
-- Migration for hotel_code, join_codes, and join_requests
-- Created: December 2024

-- ============================================================================
-- HOTEL CODE COLUMN
-- ============================================================================

-- Add hotel_code column to hotels table
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS hotel_code TEXT UNIQUE;

-- Create index for fast hotel code lookups
CREATE INDEX IF NOT EXISTS idx_hotels_code ON hotels(hotel_code);

-- ============================================================================
-- JOIN CODES TABLE
-- ============================================================================

-- Join codes for employee onboarding
CREATE TABLE IF NOT EXISTS join_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    max_uses INTEGER DEFAULT 10,
    current_uses INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES user_profiles(id),
    UNIQUE(hotel_id, code)
);

-- Indexes for join_codes
CREATE INDEX IF NOT EXISTS idx_join_codes_hotel ON join_codes(hotel_id);
CREATE INDEX IF NOT EXISTS idx_join_codes_code ON join_codes(code);
CREATE INDEX IF NOT EXISTS idx_join_codes_active ON join_codes(is_active) WHERE is_active = TRUE;

-- ============================================================================
-- JOIN REQUESTS TABLE
-- ============================================================================

-- Join requests for pending employee approvals
CREATE TABLE IF NOT EXISTS join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hotel_id UUID NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    join_code_id UUID REFERENCES join_codes(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES user_profiles(id),
    assigned_role user_role,
    notes TEXT,
    UNIQUE(hotel_id, user_id)
);

-- Indexes for join_requests
CREATE INDEX IF NOT EXISTS idx_join_requests_hotel ON join_requests(hotel_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_user ON join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON join_requests(status);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE join_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE join_requests ENABLE ROW LEVEL SECURITY;

-- Join Codes: Only hotel owners/managers can manage
CREATE POLICY "Hotel owners can manage join codes" ON join_codes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM hotels
            WHERE hotels.id = join_codes.hotel_id
            AND hotels.owner_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM hotel_staff
            WHERE hotel_staff.hotel_id = join_codes.hotel_id
            AND hotel_staff.user_id = auth.uid()
            AND hotel_staff.role IN ('owner', 'manager')
            AND hotel_staff.is_active = TRUE
        )
    );

-- Join Codes: Anyone can read active codes for validation
CREATE POLICY "Anyone can validate join codes" ON join_codes
    FOR SELECT USING (is_active = TRUE AND expires_at > NOW() AND current_uses < max_uses);

-- Join Requests: Users can create their own requests
CREATE POLICY "Users can create join requests" ON join_requests
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Join Requests: Users can view their own requests
CREATE POLICY "Users can view own requests" ON join_requests
    FOR SELECT USING (user_id = auth.uid());

-- Join Requests: Hotel owners/managers can view and manage requests
CREATE POLICY "Hotel staff can manage join requests" ON join_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM hotels
            WHERE hotels.id = join_requests.hotel_id
            AND hotels.owner_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM hotel_staff
            WHERE hotel_staff.hotel_id = join_requests.hotel_id
            AND hotel_staff.user_id = auth.uid()
            AND hotel_staff.role IN ('owner', 'manager')
            AND hotel_staff.is_active = TRUE
        )
    );

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to validate and use a join code
CREATE OR REPLACE FUNCTION validate_join_code(
    p_hotel_code TEXT,
    p_join_code TEXT
)
RETURNS TABLE (
    hotel_id UUID,
    hotel_name TEXT,
    join_code_id UUID,
    is_valid BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_hotel_id UUID;
    v_hotel_name TEXT;
    v_join_code_id UUID;
    v_expires_at TIMESTAMPTZ;
    v_max_uses INTEGER;
    v_current_uses INTEGER;
    v_is_active BOOLEAN;
BEGIN
    -- Find hotel by code
    SELECT h.id, h.name INTO v_hotel_id, v_hotel_name
    FROM hotels h
    WHERE h.hotel_code = p_hotel_code;
    
    IF v_hotel_id IS NULL THEN
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::UUID, FALSE, 'Hotel code not found'::TEXT;
        RETURN;
    END IF;
    
    -- Find join code
    SELECT jc.id, jc.expires_at, jc.max_uses, jc.current_uses, jc.is_active
    INTO v_join_code_id, v_expires_at, v_max_uses, v_current_uses, v_is_active
    FROM join_codes jc
    WHERE jc.hotel_id = v_hotel_id AND jc.code = p_join_code;
    
    IF v_join_code_id IS NULL THEN
        RETURN QUERY SELECT v_hotel_id, v_hotel_name, NULL::UUID, FALSE, 'Join code not found'::TEXT;
        RETURN;
    END IF;
    
    IF NOT v_is_active THEN
        RETURN QUERY SELECT v_hotel_id, v_hotel_name, v_join_code_id, FALSE, 'Join code is no longer active'::TEXT;
        RETURN;
    END IF;
    
    IF v_expires_at < NOW() THEN
        RETURN QUERY SELECT v_hotel_id, v_hotel_name, v_join_code_id, FALSE, 'Join code has expired'::TEXT;
        RETURN;
    END IF;
    
    IF v_current_uses >= v_max_uses THEN
        RETURN QUERY SELECT v_hotel_id, v_hotel_name, v_join_code_id, FALSE, 'Join code has reached maximum uses'::TEXT;
        RETURN;
    END IF;
    
    -- Valid code
    RETURN QUERY SELECT v_hotel_id, v_hotel_name, v_join_code_id, TRUE, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if hotel code is available
CREATE OR REPLACE FUNCTION is_hotel_code_available(p_hotel_code TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM hotels WHERE hotel_code = p_hotel_code
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get hotel by code
CREATE OR REPLACE FUNCTION get_hotel_by_code(p_hotel_code TEXT)
RETURNS TABLE (
    id UUID,
    name TEXT,
    address TEXT,
    phone TEXT,
    email TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT h.id, h.name, h.address, h.phone, h.email
    FROM hotels h
    WHERE h.hotel_code = p_hotel_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE join_codes IS 'Temporary codes for employee onboarding, generated by owners/managers';
COMMENT ON TABLE join_requests IS 'Pending employee requests awaiting approval';
COMMENT ON COLUMN hotels.hotel_code IS 'Unique human-readable code for hotel identification (e.g., taj-chennai)';
