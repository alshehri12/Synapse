-- Test if the trigger and function exist

-- Check if trigger exists
SELECT
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created_profile';

-- Check if function exists
SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_name = 'create_user_profile_on_signup';

-- Check existing RLS policies on users table
SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;
