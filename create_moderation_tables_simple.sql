-- Content Moderation Tables - Simplified Version
-- Run this in Supabase SQL Editor

-- Drop existing tables if they exist
DROP TABLE IF EXISTS public.content_reports CASCADE;
DROP TABLE IF EXISTS public.blocked_users CASCADE;

-- Table for blocked users
CREATE TABLE public.blocked_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    blocked_user_id UUID NOT NULL,
    blocked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, blocked_user_id)
);

-- Table for content reports
CREATE TABLE public.content_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID NOT NULL,
    reported_user_id UUID NOT NULL,
    content_id TEXT NOT NULL,
    content_type TEXT NOT NULL,
    reason TEXT NOT NULL,
    description TEXT,
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID,
    action_taken TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_blocked_users_user_id ON public.blocked_users(user_id);
CREATE INDEX idx_blocked_users_blocked_user_id ON public.blocked_users(blocked_user_id);
CREATE INDEX idx_content_reports_reporter_id ON public.content_reports(reporter_id);
CREATE INDEX idx_content_reports_reported_user_id ON public.content_reports(reported_user_id);
CREATE INDEX idx_content_reports_status ON public.content_reports(status);
CREATE INDEX idx_content_reports_reported_at ON public.content_reports(reported_at DESC);

-- Enable RLS
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies for blocked_users
CREATE POLICY "Users can view their own blocked users"
    ON public.blocked_users FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can block other users"
    ON public.blocked_users FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unblock users"
    ON public.blocked_users FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policies for content_reports
CREATE POLICY "Users can view their own reports"
    ON public.content_reports FOR SELECT
    USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports"
    ON public.content_reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Add role column to user_profiles if table exists
DO $$
BEGIN
    -- Check if user_profiles table exists first
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'user_profiles'
    ) THEN
        -- Check if role column doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'user_profiles'
            AND column_name = 'role'
        ) THEN
            ALTER TABLE public.user_profiles ADD COLUMN role TEXT DEFAULT 'user';
        END IF;
    END IF;
END $$;

-- Success message
SELECT 'Content moderation tables created successfully!' as message;
