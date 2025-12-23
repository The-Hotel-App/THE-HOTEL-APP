-- ROOMS.io Schema Cleanup: Remove Join Hotel Workflow
-- Migration: Remove join_codes, join_requests tables and validate_join_code function
-- Created: December 2024
--
-- These features are being removed because staff will now be added directly
-- by hotel owners instead of using join codes.

-- ============================================================================
-- DROP POLICIES FIRST (required before dropping tables)
-- ============================================================================

-- Note: Using DO blocks to conditionally drop policies only if tables exist
-- This handles cases where the original migration was never applied

-- Drop policies on join_requests (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'join_requests') THEN
        DROP POLICY IF EXISTS "Users can create join requests" ON join_requests;
        DROP POLICY IF EXISTS "Users can view own requests" ON join_requests;
        DROP POLICY IF EXISTS "Hotel staff can manage join requests" ON join_requests;
    END IF;
END $$;

-- Drop policies on join_codes (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'join_codes') THEN
        DROP POLICY IF EXISTS "Hotel owners can manage join codes" ON join_codes;
        DROP POLICY IF EXISTS "Anyone can validate join codes" ON join_codes;
    END IF;
END $$;

-- ============================================================================
-- DROP FUNCTIONS
-- ============================================================================

DROP FUNCTION IF EXISTS validate_join_code(TEXT, TEXT);

-- ============================================================================
-- DROP TABLES
-- ============================================================================

-- Drop join_requests first (has foreign key to join_codes)
DROP TABLE IF EXISTS join_requests;

-- Drop join_codes
DROP TABLE IF EXISTS join_codes;

-- ============================================================================
-- NOTES
-- ============================================================================
-- The following are kept as they are used by other features:
-- - hotels.hotel_code column (used for login flow)
-- - is_hotel_code_available function (used for hotel setup)
-- - get_hotel_by_code function (used for login flow)
