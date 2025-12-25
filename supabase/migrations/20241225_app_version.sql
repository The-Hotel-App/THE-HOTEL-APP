-- App Version Table for In-App Updates
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS app_version (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version TEXT NOT NULL,
  download_url TEXT NOT NULL,
  release_notes TEXT DEFAULT '',
  is_mandatory BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE app_version ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read (your 4 developers)
CREATE POLICY "Authenticated users can read app_version"
  ON app_version FOR SELECT
  TO authenticated
  USING (true);

-- Insert initial version (update this when you release!)
INSERT INTO app_version (version, download_url, release_notes)
VALUES (
  '1.1.3',
  'https://github.com/The-Hotel-App/THE-HOTEL-APP/releases',
  'Initial release with in-app updates'
);
