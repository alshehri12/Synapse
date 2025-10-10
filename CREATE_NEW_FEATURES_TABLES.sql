-- ========================================
-- SQL Script: Create Tables for New Features
-- Run this in Supabase SQL Editor
-- ========================================

-- 1. Content Reports Table
CREATE TABLE IF NOT EXISTS content_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_content_type TEXT NOT NULL CHECK (reported_content_type IN ('idea', 'comment', 'user', 'project')),
    reported_content_id UUID NOT NULL,
    reported_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'hate_speech', 'violence', 'nudity', 'false_information', 'intellectual_property', 'other')),
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Blocked Users Table
CREATE TABLE IF NOT EXISTS blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    blocked_username TEXT NOT NULL,
    blocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_user_id)
);

-- 3. User Settings Table
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    marketing_emails BOOLEAN DEFAULT false,
    data_processing_consent BOOLEAN DEFAULT false,
    analytics_consent BOOLEAN DEFAULT false,
    age_verified BOOLEAN DEFAULT false,
    gdpr_consent_date TIMESTAMPTZ,
    coppa_parental_consent BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. User Data Export Requests (for GDPR)
CREATE TABLE IF NOT EXISTS data_export_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    export_url TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

-- 5. Account Deletion Requests
CREATE TABLE IF NOT EXISTS account_deletion_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'cancelled')),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    scheduled_deletion_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ
);

-- ========================================
-- Indexes for Performance
-- ========================================

CREATE INDEX IF NOT EXISTS idx_content_reports_reporter ON content_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_status ON content_reports(status);
CREATE INDEX IF NOT EXISTS idx_content_reports_created ON content_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users(blocked_user_id);
CREATE INDEX IF NOT EXISTS idx_data_exports_user ON data_export_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_account_deletions_user ON account_deletion_requests(user_id);

-- ========================================
-- Row Level Security (RLS) Policies
-- ========================================

-- Enable RLS
ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_export_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE account_deletion_requests ENABLE ROW LEVEL SECURITY;

-- Content Reports Policies
CREATE POLICY "Users can create reports" ON content_reports
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports" ON content_reports
    FOR SELECT TO authenticated
    USING (auth.uid() = reporter_id);

-- Blocked Users Policies
CREATE POLICY "Users can block others" ON blocked_users
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can view own blocks" ON blocked_users
    FOR SELECT TO authenticated
    USING (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock" ON blocked_users
    FOR DELETE TO authenticated
    USING (auth.uid() = blocker_id);

-- User Settings Policies
CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE TO authenticated
    USING (auth.uid() = id);

-- Data Export Policies
CREATE POLICY "Users can create own export requests" ON data_export_requests
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own export requests" ON data_export_requests
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

-- Account Deletion Policies
CREATE POLICY "Users can create own deletion requests" ON account_deletion_requests
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own deletion requests" ON account_deletion_requests
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can cancel own deletion requests" ON account_deletion_requests
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- ========================================
-- Functions and Triggers
-- ========================================

-- Function to create default user settings
CREATE OR REPLACE FUNCTION create_default_user_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_settings (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create settings when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_user_settings();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_content_reports_updated_at
    BEFORE UPDATE ON content_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- Verification Queries
-- ========================================

-- Check all tables were created
SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
    'content_reports',
    'blocked_users',
    'user_settings',
    'data_export_requests',
    'account_deletion_requests'
);

-- Done! ✅
