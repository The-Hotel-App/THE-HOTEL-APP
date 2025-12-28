-- Migration: Add tariff-based pricing to room_types
-- Description: Each room type has a fixed tariff duration (hours), tariff amount, and grace period

-- Add tariff-based pricing columns to room_types
ALTER TABLE room_types 
ADD COLUMN IF NOT EXISTS tariff_duration_hours integer DEFAULT 24,
ADD COLUMN IF NOT EXISTS tariff_amount numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS grace_period_hours numeric DEFAULT 2;

-- Migrate existing data: use base_price as tariff_amount, default 24h tariff
UPDATE room_types 
SET 
  tariff_amount = base_price,
  tariff_duration_hours = 24,
  grace_period_hours = 2
WHERE tariff_amount = 0 OR tariff_amount IS NULL;

-- Add comments for clarity
COMMENT ON COLUMN room_types.tariff_duration_hours IS 'Fixed billing period in hours (e.g., 24 for service apartment)';
COMMENT ON COLUMN room_types.tariff_amount IS 'Price for one tariff cycle';
COMMENT ON COLUMN room_types.grace_period_hours IS 'Extra hours allowed after tariff before next tariff applies';
