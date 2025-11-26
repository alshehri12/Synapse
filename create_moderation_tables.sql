-- Content Moderation Tables for App Store Compliance (Guideline 1.2)
-- Run this in Supabase SQL Editor

-- Drop existing tables if they exist (for clean slate)
DROP TABLE IF EXISTS public.content_reports CASCADE;
DROP TABLE IF EXISTS public.blocked_users CASCADE;

-- Table for blocked users
CREATE TABLE public.blocked_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    blocked_user_id UUID NOT NULL,
    blocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
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
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID,
    action_taken TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_blocked_users_user_id ON public.blocked_users(user_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked_user_id ON public.blocked_users(blocked_user_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_reporter_id ON public.content_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_reported_user_id ON public.content_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_status ON public.content_reports(status);
CREATE INDEX IF NOT EXISTS idx_content_reports_reported_at ON public.content_reports(reported_at DESC);

-- RLS Policies for blocked_users
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

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
ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own reports"
    ON public.content_reports FOR SELECT
    USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports"
    ON public.content_reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Admin policy (you'll need to create an admin role)
CREATE POLICY "Admins can view all reports"
    ON public.content_reports FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.content_reports
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Add role column to user_profiles if it doesn't exist
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';
