-- ========================================
-- DEEP INVESTIGATION: Find the exact trigger error
-- ========================================

-- Step 1: Check Postgres logs for recent errors
-- (You need to do this in Supabase Dashboard → Logs → Postgres Logs)
-- Look for errors around the time of signup attempt

-- Step 2: Temporarily DISABLE the trigger to see if signup works without it
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;

-- Step 3: Verify trigger is disabled
SELECT
    'Trigger Check' as test,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers
            WHERE trigger_name = 'on_auth_user_created_profile'
        ) THEN 'STILL EXISTS ❌'
        ELSE 'DISABLED ✅ - Try signup now!'
    END as status;

-- After you test signup without the trigger and it works,
-- we'll know the trigger is the problem. Then uncomment below:

/*
-- Step 4: Check if there are OTHER triggers on auth.users that might conflict
SELECT
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
   OR event_object_schema = 'auth';

-- Step 5: Re-enable trigger with better error handling
CREATE OR REPLACE FUNCTION create_user_profile_on_signup()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    default_username TEXT;
    final_username TEXT;
    username_suffix INTEGER := 0;
    username_exists BOOLEAN;
BEGIN
    -- Log that trigger is running
    RAISE NOTICE 'Trigger started for user: %', NEW.id;

    -- Generate default username from email or use user ID
    IF NEW.email IS NOT NULL THEN
        default_username := split_part(NEW.email, '@', 1);
        RAISE NOTICE 'Generated username from email: %', default_username;
    ELSE
        default_username := 'user_' || substring(NEW.id::text from 1 for 6);
        RAISE NOTICE 'Generated username from ID: %', default_username;
    END IF;

    -- Ensure username is unique
    final_username := default_username;
    LOOP
        SELECT EXISTS(SELECT 1 FROM users WHERE username = final_username)
        INTO username_exists;

        EXIT WHEN NOT username_exists;

        username_suffix := username_suffix + 1;
        final_username := default_username || username_suffix;
        RAISE NOTICE 'Username conflict, trying: %', final_username;
    END LOOP;

    RAISE NOTICE 'Final username: %', final_username;

    -- Create user profile
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
        final_username,
        NULL,
        NULL,
        ARRAY[]::TEXT[],
        ARRAY[]::TEXT[],
        0,
        0,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'User profile created successfully for: %', final_username;

    RETURN NEW;

EXCEPTION WHEN OTHERS THEN
    -- Log the actual error
    RAISE LOG 'ERROR in create_user_profile_on_signup: % - SQLSTATE: %', SQLERRM, SQLSTATE;
    -- Re-raise so Supabase knows it failed
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created_profile
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile_on_signup();

SELECT 'Trigger recreated with logging ✅' as status;
*/
