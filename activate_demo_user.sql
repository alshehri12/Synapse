-- Activate Demo User for Apple Review
-- Run this in Supabase SQL Editor

-- First, find the user ID for apple@usynapse.com
-- You'll need to replace 'USER_ID_HERE' with the actual UUID from auth.users table

-- Step 1: Get the user ID (run this first to see the user_id)
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'apple@usynapse.com';

-- Step 2: Verify the email (if email_confirmed_at is NULL)
-- Replace 'USER_ID_HERE' with the actual user ID from Step 1
UPDATE auth.users
SET email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email = 'apple@usynapse.com';

-- Step 3: Create user profile (if it doesn't exist)
-- Replace 'USER_ID_HERE' with the actual user ID from Step 1
INSERT INTO public.user_profiles (id, email, username, created_at, updated_at)
VALUES (
    (SELECT id FROM auth.users WHERE email = 'apple@usynapse.com'),
    'apple@usynapse.com',
    'AppleReviewer',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE
SET username = 'AppleReviewer',
    email = 'apple@usynapse.com',
    updated_at = NOW();

-- Step 4: Verify everything is set up correctly
SELECT
    u.id,
    u.email,
    u.email_confirmed_at,
    u.confirmed_at,
    p.username,
    p.created_at as profile_created_at
FROM auth.users u
LEFT JOIN public.user_profiles p ON u.id = p.id
WHERE u.email = 'apple@usynapse.com';
