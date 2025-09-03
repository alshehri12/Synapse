-- Temporarily disable RLS on notifications table to fix join request functionality
-- The current RLS policy `FOR ALL USING (auth.uid() = user_id)` prevents one user from creating a notification for another user.
-- This is required for:
--   1. A requester sending a "join request" notification to a pod owner.
--   2. A pod owner sending an "approved/rejected" notification back to the requester.

-- Disable RLS on notifications
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;

-- TODO: A better long-term solution would be to use a Supabase Edge Function with a service_role key to create notifications,
-- which would allow us to keep RLS enabled and secure.
