-- Migration: Rename 'maintenance' to 'emergency' in room_status enum
-- IMPORTANT: Run Step 1 first, then run Steps 2-3 separately!

-- ============================================
-- STEP 1: Run this FIRST, then click "Run"
-- ============================================
ALTER TYPE room_status ADD VALUE IF NOT EXISTS 'emergency';

-- ============================================
-- STEP 2: Run this AFTER Step 1 completes
-- ============================================
-- UPDATE rooms SET status = 'emergency' WHERE status = 'maintenance';
-- UPDATE room_status_logs SET old_status = 'emergency' WHERE old_status = 'maintenance';
-- UPDATE room_status_logs SET new_status = 'emergency' WHERE new_status = 'maintenance';
