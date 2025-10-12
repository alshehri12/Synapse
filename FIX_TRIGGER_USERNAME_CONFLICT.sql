-- ========================================
-- FIX: Update Trigger to Handle Username Conflicts
-- ========================================
-- This fixes the "Database error saving new user" by ensuring
-- the trigger creates unique usernames even if conflicts exist

CREATE OR REPLACE FUNCTION create_user_profile_on_signup()
RETURNS TRIGGER
SECURITY DEFINER -- Runs with elevated privileges, bypasses RLS
SET search_path = public
AS $$
DECLARE
    default_username TEXT;
    final_username TEXT;
    username_suffix INTEGER := 0;
    username_exists BOOLEAN;
BEGIN
    -- Generate default username from email or use user ID
    IF NEW.email IS NOT NULL THEN
        default_username := split_part(NEW.email, '@', 1);
    ELSE
        default_username := 'user_' || substring(NEW.id::text from 1 for 6);
    END IF;

    -- Ensure username is unique by appending numbers if needed
    final_username := default_username;
    LOOP
        -- Check if username already exists
        SELECT EXISTS(SELECT 1 FROM users WHERE username = final_username)
        INTO username_exists;

        -- If username is unique, exit loop
        EXIT WHEN NOT username_exists;

        -- Otherwise, append/increment suffix
        username_suffix := username_suffix + 1;
        final_username := default_username || username_suffix;
    END LOOP;

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
        final_username,  -- Use the unique username
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

-- The trigger already exists, no need to recreate it
-- It will automatically use the updated function

-- Test: Verify the function was updated
SELECT
    routine_name,
    routine_type,
    'Function updated successfully ✅' as status
FROM information_schema.routines
WHERE routine_name = 'create_user_profile_on_signup';
