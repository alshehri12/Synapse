-- Synapse App - Supabase Database Schema
-- Created for migration from Firebase
-- Date: 2025-01-16

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    skills TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',
    ideas_sparked INTEGER DEFAULT 0,
    projects_contributed INTEGER DEFAULT 0,
    date_joined TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ideas table
CREATE TABLE public.idea_sparks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    author_username TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    is_public BOOLEAN DEFAULT true,
    status TEXT DEFAULT 'sparking' CHECK (status IN ('planning', 'sparking', 'incubating', 'launched', 'completed', 'on_hold', 'cancelled')),
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pods (incubation projects) table
CREATE TABLE public.pods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idea_id UUID REFERENCES public.idea_sparks(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    creator_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT true,
    status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'active', 'completed', 'on_hold')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pod members table (for detailed member info)
CREATE TABLE public.pod_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pod_id UUID REFERENCES public.pods(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    role TEXT DEFAULT 'Member',
    permissions TEXT[] DEFAULT '{"view", "comment"}',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pod_id, user_id)
);

-- Tasks table
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pod_id UUID REFERENCES public.pods(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
    assigned_to_username TEXT,
    status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'completed')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat messages table
CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pod_id UUID REFERENCES public.pods(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    sender_username TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity feed table
CREATE TABLE public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pod invitations table
CREATE TABLE public.pod_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pod_id UUID REFERENCES public.pods(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(pod_id, invitee_id)
);

-- Create indexes for performance
CREATE INDEX idx_idea_sparks_author_id ON public.idea_sparks(author_id);
CREATE INDEX idx_idea_sparks_is_public ON public.idea_sparks(is_public);
CREATE INDEX idx_idea_sparks_created_at ON public.idea_sparks(created_at DESC);

CREATE INDEX idx_pods_creator_id ON public.pods(creator_id);
CREATE INDEX idx_pods_idea_id ON public.pods(idea_id);
CREATE INDEX idx_pods_is_public ON public.pods(is_public);

CREATE INDEX idx_pod_members_pod_id ON public.pod_members(pod_id);
CREATE INDEX idx_pod_members_user_id ON public.pod_members(user_id);

CREATE INDEX idx_tasks_pod_id ON public.tasks(pod_id);
CREATE INDEX idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX idx_tasks_status ON public.tasks(status);

CREATE INDEX idx_chat_messages_pod_id ON public.chat_messages(pod_id);
CREATE INDEX idx_chat_messages_timestamp ON public.chat_messages(timestamp DESC);

CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);

CREATE INDEX idx_activities_user_id ON public.activities(user_id);
CREATE INDEX idx_activities_created_at ON public.activities(created_at DESC);

CREATE INDEX idx_pod_invitations_invitee_id ON public.pod_invitations(invitee_id);
CREATE INDEX idx_pod_invitations_status ON public.pod_invitations(status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idea_sparks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pod_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pod_invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users: Users can view all profiles but only update their own
CREATE POLICY "Users can view all profiles" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Ideas: Public ideas visible to all, private ideas only to author
CREATE POLICY "Public ideas visible to all" ON public.idea_sparks
    FOR SELECT USING (is_public = true OR auth.uid() = author_id);

CREATE POLICY "Users can create ideas" ON public.idea_sparks
    FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own ideas" ON public.idea_sparks
    FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own ideas" ON public.idea_sparks
    FOR DELETE USING (auth.uid() = author_id);

-- Pods: Public pods visible to all, private pods only to members
CREATE POLICY "Public pods visible to all" ON public.pods
    FOR SELECT USING (
        is_public = true OR 
        auth.uid() = creator_id OR 
        EXISTS (SELECT 1 FROM public.pod_members WHERE pod_id = pods.id AND user_id = auth.uid())
    );

CREATE POLICY "Users can create pods" ON public.pods
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update pods" ON public.pods
    FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Creators can delete pods" ON public.pods
    FOR DELETE USING (auth.uid() = creator_id);

-- Pod members: Only pod members can view membership
CREATE POLICY "Pod members can view membership" ON public.pod_members
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.pod_members pm WHERE pm.pod_id = pod_members.pod_id AND pm.user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.pods p WHERE p.id = pod_members.pod_id AND p.creator_id = auth.uid())
    );

CREATE POLICY "Pod creators can manage members" ON public.pod_members
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.pods WHERE id = pod_id AND creator_id = auth.uid())
    );

CREATE POLICY "Users can join pods" ON public.pod_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Tasks: Only pod members can view/manage tasks
CREATE POLICY "Pod members can view tasks" ON public.tasks
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.pod_members WHERE pod_id = tasks.pod_id AND user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.pods WHERE id = tasks.pod_id AND creator_id = auth.uid())
    );

CREATE POLICY "Pod members can create tasks" ON public.tasks
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.pod_members WHERE pod_id = tasks.pod_id AND user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.pods WHERE id = tasks.pod_id AND creator_id = auth.uid())
    );

CREATE POLICY "Pod members can update tasks" ON public.tasks
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.pod_members WHERE pod_id = tasks.pod_id AND user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.pods WHERE id = tasks.pod_id AND creator_id = auth.uid())
    );

-- Chat messages: Only pod members can view/send messages
CREATE POLICY "Pod members can view chat" ON public.chat_messages
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.pod_members WHERE pod_id = chat_messages.pod_id AND user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.pods WHERE id = chat_messages.pod_id AND creator_id = auth.uid())
    );

CREATE POLICY "Pod members can send messages" ON public.chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND (
            EXISTS (SELECT 1 FROM public.pod_members WHERE pod_id = chat_messages.pod_id AND user_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.pods WHERE id = chat_messages.pod_id AND creator_id = auth.uid())
        )
    );

-- Notifications: Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR ALL USING (auth.uid() = user_id);

-- Activities: Users can view public activities or their own
CREATE POLICY "Users can view activities" ON public.activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create activities" ON public.activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Pod invitations: Users can view invitations sent to them or sent by them
CREATE POLICY "Users can view relevant invitations" ON public.pod_invitations
    FOR SELECT USING (auth.uid() = invitee_id OR auth.uid() = inviter_id);

CREATE POLICY "Users can create invitations" ON public.pod_invitations
    FOR INSERT WITH CHECK (auth.uid() = inviter_id);

CREATE POLICY "Users can respond to invitations" ON public.pod_invitations
    FOR UPDATE USING (auth.uid() = invitee_id);

-- Functions for automatic timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER handle_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_idea_sparks_updated_at
    BEFORE UPDATE ON public.idea_sparks
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_pods_updated_at
    BEFORE UPDATE ON public.pods
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Real-time subscriptions for live updates
-- Enable realtime for specific tables
ALTER publication supabase_realtime ADD TABLE public.chat_messages;
ALTER publication supabase_realtime ADD TABLE public.notifications;
ALTER publication supabase_realtime ADD TABLE public.tasks;
ALTER publication supabase_realtime ADD TABLE public.pod_members;
