-- Fix RLS Policies for OTP Email Verification Flow
-- This allows users to create their profile after signing up

-- Drop existing restrictive policies if they exist
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- Allow authenticated users to insert their own profile
-- This is crucial for the signup flow
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow public read access to user profiles (for browsing/discovery)
CREATE POLICY "Public can view user profiles" ON users
    FOR SELECT
    TO public
    USING (true);

-- Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT INSERT, SELECT, UPDATE ON users TO authenticated;
GRANT SELECT ON users TO anon;
