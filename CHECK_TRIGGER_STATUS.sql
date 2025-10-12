-- Quick check: Does the trigger exist?

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers
            WHERE trigger_name = 'on_auth_user_created_profile'
        )
        THEN '✅ TRIGGER EXISTS'
        ELSE '❌ TRIGGER DOES NOT EXIST - This is your problem!'
    END as trigger_status;

SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines
            WHERE routine_name = 'create_user_profile_on_signup'
        )
        THEN '✅ FUNCTION EXISTS'
        ELSE '❌ FUNCTION DOES NOT EXIST - This is your problem!'
    END as function_status;
