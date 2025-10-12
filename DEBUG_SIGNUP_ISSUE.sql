-- ========================================
-- DEBUG: Check what's causing signup failure
-- ========================================

-- 1. Check if the trigger exists
SELECT
    'Trigger Status' as check_type,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers
            WHERE trigger_name = 'on_auth_user_created_profile'
        ) THEN 'EXISTS ✅'
        ELSE 'MISSING ❌'
    END as status;

-- 2. Check if the function exists
SELECT
    'Function Status' as check_type,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines
            WHERE routine_name = 'create_user_profile_on_signup'
        ) THEN 'EXISTS ✅'
        ELSE 'MISSING ❌'
    END as status;

-- 3. Check for existing user with email bbs@bbssbb.com
SELECT
    'User in auth.users' as check_type,
    CASE
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'bbs@bbssbb.com')
        THEN 'EXISTS (email taken) ❌'
        ELSE 'NOT EXISTS ✅'
    END as status;

-- 4. Check for existing profile with email bbs@bbssbb.com
SELECT
    'Profile in users table' as check_type,
    CASE
        WHEN EXISTS (SELECT 1 FROM users WHERE email = 'bbs@bbssbb.com')
        THEN 'EXISTS ❌'
        ELSE 'NOT EXISTS ✅'
    END as status;

-- 5. Check username uniqueness constraint
SELECT
    'Username Constraint' as check_type,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints
            WHERE table_name = 'users'
            AND constraint_type = 'UNIQUE'
            AND constraint_name LIKE '%username%'
        ) THEN 'EXISTS ✅'
        ELSE 'MISSING ❌'
    END as status;

-- 6. Check if there are any usernames that would conflict with email prefix
SELECT
    'Potential Username Conflict' as check_type,
    CASE
        WHEN EXISTS (SELECT 1 FROM users WHERE username = 'bbs')
        THEN 'CONFLICT FOUND (username=bbs already exists) ❌'
        ELSE 'NO CONFLICT ✅'
    END as status;

-- 7. List all RLS policies on users table
SELECT
    'RLS Policies on users' as info,
    policyname,
    cmd,
    roles::text
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- 8. Check if RLS is enabled on users table
SELECT
    'RLS Status on users' as check_type,
    CASE
        WHEN relrowsecurity THEN 'ENABLED ✅'
        ELSE 'DISABLED ❌'
    END as status
FROM pg_class
WHERE relname = 'users';

-- 9. Check the actual trigger definition
SELECT
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created_profile';

-- 10. Try to manually simulate what the trigger does
-- This will help identify the exact error
-- UNCOMMENT THIS SECTION TO TEST (replace with a test UUID):
/*
DO $$
DECLARE
    test_email TEXT := 'test@example.com';
    test_username TEXT;
    test_id UUID := gen_random_uuid();
BEGIN
    -- Generate username like the trigger does
    test_username := split_part(test_email, '@', 1);

    -- Try to insert
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
        test_id,
        test_email,
        test_username,
        NULL,
        NULL,
        ARRAY[]::TEXT[],
        ARRAY[]::TEXT[],
        0,
        0,
        NOW(),
        NOW()
    );

    RAISE NOTICE 'Test insert successful for username: %', test_username;

    -- Clean up
    DELETE FROM users WHERE id = test_id;
    RAISE NOTICE 'Test cleanup complete';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR: %', SQLERRM;
END $$;
*/
