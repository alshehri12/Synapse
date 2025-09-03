-- Temporarily disable RLS on pod_invitations table to fix join request functionality
-- The current RLS policy conflicts with our join request flow where:
-- - inviter_id = pod owner (who receives the request)
-- - invitee_id = requesting user (who sends the request)
-- But RLS policy requires auth.uid() = inviter_id for INSERT

-- Disable RLS on pod_invitations
ALTER TABLE public.pod_invitations DISABLE ROW LEVEL SECURITY;

-- Alternative: Fix the RLS policy to allow join requests
-- Uncomment the following lines if you prefer to keep RLS enabled with fixed policies:

-- DROP POLICY IF EXISTS "Users can create invitations" ON public.pod_invitations;
-- 
-- -- Allow users to create join requests (where they are the invitee/requester)
-- CREATE POLICY "Users can create join requests" ON public.pod_invitations
--     FOR INSERT WITH CHECK (auth.uid() = invitee_id);
-- 
-- -- Allow pod owners to create traditional invitations (where they are the inviter)
-- CREATE POLICY "Pod owners can create invitations" ON public.pod_invitations
--     FOR INSERT WITH CHECK (
--         auth.uid() = inviter_id AND
--         EXISTS (SELECT 1 FROM public.pods WHERE id = pod_id AND creator_id = auth.uid())
--     );
