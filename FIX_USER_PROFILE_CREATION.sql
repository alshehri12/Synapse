-- ========================================
-- FIX: User Profile Creation on Signup
-- ========================================
-- This script fixes the "Database error saving new user" issue
-- by creating user profiles automatically via database trigger

-- Solution: Create user profile automatically when auth user is created
-- This bypasses RLS issues during signup flow

-- ========================================
-- STEP 1: Create Function to Auto-Create User Profile
-- ========================================

CREATE OR REPLACE FUNCTION create_user_profile_on_signup()
RETURNS TRIGGER
SECURITY DEFINER -- Runs with elevated privileges, bypasses RLS
SET search_path = public
AS $$
DECLARE
    default_username TEXT;
BEGIN
    -- Generate default username from email or use user ID
    IF NEW.email IS NOT NULL THEN
        default_username := split_part(NEW.email, '@', 1);
    ELSE
        default_username := 'user_' || substring(NEW.id::text from 1 for 6);
    END IF;

    -- Create user profile automatically
    INSERT INTO users (
        id,
        email,
        username,
        bio,
        avatar_url,
        skills,
        interests,
        ideas_sparked,
        projects_contributed,
        date_joined,
        updated_at
    ) VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        default_username,
        NULL,
        NULL,
        ARRAY[]::TEXT[],
        ARRAY[]::TEXT[],
        0,
        0,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING; -- Prevent duplicate errors

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STEP 2: Create Trigger on auth.users
-- ========================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;

-- Create trigger that fires AFTER user signup
CREATE TRIGGER on_auth_user_created_profile
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile_on_signup();

-- ========================================
-- STEP 3: Update RLS Policies
-- ========================================

-- Keep existing policies but add fallback for service role
DROP POLICY IF EXISTS "Service role can insert profiles" ON users;
CREATE POLICY "Service role can insert profiles" ON users
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Ensure authenticated users can still insert (for manual profile creation)
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- ========================================
-- STEP 4: Grant Necessary Permissions
-- ========================================

-- Ensure the trigger function can insert into users table
GRANT INSERT ON users TO service_role;
GRANT USAGE ON SCHEMA public TO service_role;

-- ========================================
-- STEP 5: Test the Setup
-- ========================================

-- You can test this by creating a test user:
-- 1. Go to Supabase Dashboard → Authentication → Add User
-- 2. Check if profile is automatically created in users table

-- Query to verify trigger exists:
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created_profile';

-- Query to verify function exists:
SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_name = 'create_user_profile_on_signup';

-- ========================================
-- OPTIONAL: Backfill Existing Users
-- ========================================

-- If you have existing auth.users without profiles, uncomment and run this:
/*
INSERT INTO users (
    id,
    email,
    username,
    bio,
    avatar_url,
    skills,
    interests,
    ideas_sparked,
    projects_contributed,
    date_joined,
    updated_at
)
SELECT
    au.id,
    COALESCE(au.email, ''),
    COALESCE(
        au.raw_user_meta_data->>'username',
        split_part(au.email, '@', 1),
        'user_' || substring(au.id::text from 1 for 6)
    ),
    NULL,
    NULL,
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[],
    0,
    0,
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
WHERE u.id IS NULL; -- Only insert if profile doesn't exist
*/

-- ========================================
-- Done! ✅
-- ========================================

-- After running this script:
-- 1. All new signups will automatically get a user profile
-- 2. No more "Database error saving new user" errors
-- 3. The app can still manually update usernames after OTP verification
