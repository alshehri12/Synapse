-- 🔓 CLEAR RATE LIMITS FOR TESTING
-- ⚠️ Use this only for testing/development, not in production!

-- ==================================================
-- Option 1: Check if there's a rate limit table
-- ==================================================

-- Supabase stores rate limits internally, but you can check auth logs
SELECT
    created_at,
    event_type,
    ip_address,
    user_agent
FROM auth.audit_log_entries
WHERE event_type LIKE '%rate_limit%'
ORDER BY created_at DESC
LIMIT 20;


-- ==================================================
-- Option 2: Check recent signup attempts
-- ==================================================

SELECT
    created_at,
    event_type,
    ip_address
FROM auth.audit_log_entries
WHERE event_type IN ('user_signedup', 'user_signup_error')
ORDER BY created_at DESC
LIMIT 20;


-- ==================================================
-- Option 3: Adjust rate limits via Supabase Dashboard
-- ==================================================

-- You cannot directly clear rate limits via SQL
-- Rate limits are handled by Supabase's auth service
--
-- INSTEAD, do this:
-- 1. Go to Supabase Dashboard → Authentication → Rate Limits
-- 2. Temporarily increase limits:
--    - Sign ups per hour: 50 (from default 10)
--    - OTP requests per hour: 20 (from default 5)
-- 3. Click Save
-- 4. Try signup again


-- ==================================================
-- Option 4: Wait for auto-reset (Recommended)
-- ==================================================

-- Rate limits automatically reset after:
-- - Email signup: 1 hour
-- - OTP requests: 1 hour
-- - Password reset: 1 hour
--
-- Just wait 15-60 minutes and try again


-- ==================================================
-- For Production: Best Practices
-- ==================================================

-- Recommended rate limit settings:
--
-- Development/Testing:
-- - Sign ups per hour: 50
-- - OTP requests per hour: 20
-- - Password resets per hour: 10
--
-- Production:
-- - Sign ups per hour: 10 (prevents spam)
-- - OTP requests per hour: 5 (prevents abuse)
-- - Password resets per hour: 5
--
-- Enable CAPTCHA for production:
-- Supabase Dashboard → Authentication → Settings → Enable CAPTCHA
