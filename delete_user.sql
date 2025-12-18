-- ❌ DELETE USER FROM SUPABASE
-- User: xmx1000@gmail.com
-- ⚠️ WARNING: This will permanently delete the user and ALL related data!

-- ==================================================
-- STEP 1: Find the user ID first (to verify)
-- ==================================================

SELECT
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users
WHERE email = 'xmx1000@gmail.com';

-- Copy the user ID from the result above, you'll need it for verification


-- ==================================================
-- STEP 2: Check what data will be deleted
-- ==================================================

-- Check user profile
SELECT * FROM public.user_profiles
WHERE email = 'xmx1000@gmail.com';

-- Check user's ideas
SELECT * FROM public.idea_sparks
WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'xmx1000@gmail.com');

-- Check user's pods
SELECT * FROM public.pod_members
WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'xmx1000@gmail.com');


-- ==================================================
-- STEP 3: DELETE USER (⚠️ PERMANENT - Cannot be undone!)
-- ==================================================

-- Option A: Delete user and CASCADE all related data automatically
-- This removes everything in one command
DELETE FROM auth.users
WHERE email = 'xmx1000@gmail.com';


-- ==================================================
-- Option B: Delete manually step-by-step (More control)
-- ==================================================

-- First, get the user ID
DO $$
DECLARE
    target_user_id uuid;
BEGIN
    -- Get the user ID
    SELECT id INTO target_user_id
    FROM auth.users
    WHERE email = 'xmx1000@gmail.com';

    IF target_user_id IS NULL THEN
        RAISE NOTICE 'User not found: xmx1000@gmail.com';
    ELSE
        RAISE NOTICE 'Found user ID: %', target_user_id;

        -- Delete from user_profiles
        DELETE FROM public.user_profiles
        WHERE user_id = target_user_id;
        RAISE NOTICE 'Deleted user profile';

        -- Delete from pod_members
        DELETE FROM public.pod_members
        WHERE user_id = target_user_id;
        RAISE NOTICE 'Deleted pod memberships';

        -- Delete from idea_sparks (if user owns ideas)
        DELETE FROM public.idea_sparks
        WHERE user_id = target_user_id;
        RAISE NOTICE 'Deleted user ideas';

        -- Delete from idea_comments (if any)
        DELETE FROM public.idea_comments
        WHERE user_id = target_user_id;
        RAISE NOTICE 'Deleted user comments';

        -- Delete from idea_votes (if any)
        DELETE FROM public.idea_votes
        WHERE user_id = target_user_id;
        RAISE NOTICE 'Deleted user votes';

        -- Finally, delete the auth user
        DELETE FROM auth.users
        WHERE id = target_user_id;
        RAISE NOTICE 'Deleted auth user';

        RAISE NOTICE '✅ User completely deleted: xmx1000@gmail.com';
    END IF;
END $$;


-- ==================================================
-- STEP 4: Verify deletion
-- ==================================================

-- Check if user is gone
SELECT * FROM auth.users WHERE email = 'xmx1000@gmail.com';
-- Should return 0 rows

-- Check if profile is gone
SELECT * FROM public.user_profiles WHERE email = 'xmx1000@gmail.com';
-- Should return 0 rows


-- ==================================================
-- TROUBLESHOOTING
-- ==================================================

-- If you get "Permission denied" error, make sure you're using the service_role key
-- In Supabase SQL Editor, this should work automatically

-- If deletion fails due to foreign key constraints, run Option B instead
-- It deletes related data first, then the user

-- If you want to just disable the user instead of deleting:
-- UPDATE auth.users SET banned_until = '2099-12-31' WHERE email = 'xmx1000@gmail.com';
