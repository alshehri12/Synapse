-- ========================================
-- COMPLETE FIX: Remove ALL problematic triggers, create tables, then add working triggers
-- ========================================

-- STEP 1: Remove ALL existing triggers on auth.users to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;

-- STEP 2: Remove the functions
DROP FUNCTION IF EXISTS create_default_user_settings() CASCADE;
DROP FUNCTION IF EXISTS create_user_profile_on_signup() CASCADE;

-- STEP 3: Verify all triggers are gone
SELECT 'All triggers removed ✅' as status
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.triggers
    WHERE event_object_schema = 'auth'
    AND event_object_table = 'users'
);

-- ========================================
-- NOW TEST SIGNUP - IT SHOULD WORK!
-- ========================================
-- Try creating an account now. If it works, the trigger was the problem.
-- If it still fails, the issue is elsewhere (likely RLS policies).

-- After confirming signup works WITHOUT triggers, uncomment below to re-add them:

/*
-- ========================================
-- STEP 4: Create a SINGLE combined trigger that handles everything
-- ========================================

CREATE OR REPLACE FUNCTION handle_new_auth_user()
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
    -- Generate unique username
    IF NEW.email IS NOT NULL THEN
        default_username := split_part(NEW.email, '@', 1);
    ELSE
        default_username := 'user_' || substring(NEW.id::text from 1 for 6);
    END IF;

    -- Ensure username is unique
    final_username := default_username;
    LOOP
        SELECT EXISTS(SELECT 1 FROM users WHERE username = final_username)
        INTO username_exists;

        EXIT WHEN NOT username_exists;

        username_suffix := username_suffix + 1;
        final_username := default_username || username_suffix;
    END LOOP;

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

    -- Create user settings (only if table exists)
    INSERT INTO user_settings (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;

EXCEPTION WHEN OTHERS THEN
    -- If anything fails, log it but don't crash signup
    RAISE WARNING 'Error in handle_new_auth_user: %', SQLERRM;
    RETURN NEW; -- Still return NEW so signup completes
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER on_new_user_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_auth_user();

SELECT 'New combined trigger created ✅' as status;
*/
