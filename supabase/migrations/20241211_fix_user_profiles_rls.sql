-- Fix RLS policies for user_profiles table
-- This migration adds INSERT policy so users can create their own profile if the trigger fails

-- Allow users to insert their own profile (for cases where the trigger doesn't run)
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Also ensure the upsert works by allowing the combination of INSERT and UPDATE
-- The existing UPDATE policy handles updates, this handles inserts
