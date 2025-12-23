-- Fix RLS policy for user_profiles to allow reading staff profiles within same hotel
-- Created: December 2024
--
-- Problem: Owners/managers can't see staff names because RLS only allows viewing own profile
-- Solution: Allow users to view profiles of people in the same hotel

-- Add policy for hotel staff to read colleague profiles
CREATE POLICY "Hotel members can view colleague profiles" ON user_profiles
    FOR SELECT USING (
        -- Users can always see their own profile
        auth.uid() = id
        OR
        -- Users can see profiles of people in the same hotel
        EXISTS (
            SELECT 1 FROM hotel_staff hs1
            INNER JOIN hotel_staff hs2 ON hs1.hotel_id = hs2.hotel_id
            WHERE hs1.user_id = auth.uid()
            AND hs2.user_id = user_profiles.id
            AND hs1.is_active = TRUE
        )
        OR
        -- Hotel owners can see profiles of their staff
        EXISTS (
            SELECT 1 FROM hotels h
            INNER JOIN hotel_staff hs ON h.id = hs.hotel_id
            WHERE h.owner_id = auth.uid()
            AND hs.user_id = user_profiles.id
        )
        OR
        -- Users can see profiles of hotel owners they work for
        EXISTS (
            SELECT 1 FROM hotel_staff hs
            INNER JOIN hotels h ON hs.hotel_id = h.id
            WHERE hs.user_id = auth.uid()
            AND h.owner_id = user_profiles.id
            AND hs.is_active = TRUE
        )
    );

-- Drop the old restrictive policy (if it exists and is causing issues)
-- Note: We're keeping the original policy as users still need to see their own profile
-- The new policy is additive (uses OR logic)
