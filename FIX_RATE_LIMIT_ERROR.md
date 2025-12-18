# 🚨 Fix: "Too many attempts, please wait and try again"

## Error Message:
```
Sign Up Error
too many attempts, please wait moment and try again.
```

---

## 🎯 What This Means:

Supabase is **rate limiting** your signup attempts to prevent spam. This is a security feature.

**Default Limits:**
- ⏱️ **10 signups per hour** from same IP address
- ⏱️ **5 OTP requests per hour** per email
- ⏱️ Auto-reset after 15-60 minutes

---

## ✅ QUICK FIXES

### **Fix 1: Wait 15-30 Minutes** (Easiest)

Just wait and the rate limit will automatically reset. ☕

### **Fix 2: Increase Rate Limits in Supabase** (Recommended for Testing)

1. **Go to Supabase Dashboard** → Your Synapse project
2. **Click Authentication** (left sidebar)
3. **Click Rate Limits** tab
4. **Increase the limits:**
   ```
   Sign ups per hour: 50 (was 10)
   OTP requests per hour: 20 (was 5)
   Password resets per hour: 10 (was 5)
   ```
5. **Click Save**
6. **Try signup again** ✅

### **Fix 3: Use Different Email or Network**

**Option A:** Try a different email address
**Option B:** Switch to mobile data (different IP address)
**Option C:** Use a VPN

---

## 🔧 For Development vs Production

### **Development/Testing Settings:**
```
Sign ups per hour: 50-100
OTP requests per hour: 20-30
Password resets per hour: 10-20
```
Higher limits make testing easier.

### **Production Settings:**
```
Sign ups per hour: 10
OTP requests per hour: 5
Password resets per hour: 5
```
Lower limits prevent spam and abuse.

**+ Enable CAPTCHA for production:**
- Supabase Dashboard → Authentication → Settings
- Enable "Enable CAPTCHA protection"

---

## 📊 How to Check Rate Limit Activity

### In Supabase SQL Editor:

```sql
-- Check recent signup attempts
SELECT
    created_at,
    event_type,
    ip_address
FROM auth.audit_log_entries
WHERE event_type IN ('user_signedup', 'user_signup_error')
ORDER BY created_at DESC
LIMIT 20;
```

This shows you how many attempts were made from your IP.

---

## 🎯 Best Practice for Your App

### **During Development:**
1. Set rate limits HIGH (50-100 per hour)
2. Makes testing much easier
3. You won't hit limits constantly

### **Before Production Launch:**
1. Set rate limits LOWER (10 per hour)
2. Enable CAPTCHA
3. Monitor auth logs for abuse

### **In Your App Code:**

Add user-friendly error message:

```swift
// In SupabaseManager.swift - signUp function
do {
    try await supabaseClient.auth.signUp(...)
} catch {
    if error.localizedDescription.contains("too many attempts") ||
       error.localizedDescription.contains("rate limit") {
        throw NSError(
            domain: "SignUpError",
            code: 429,
            userInfo: [
                NSLocalizedDescriptionKey: "Too many signup attempts. Please wait a few minutes and try again."
            ]
        )
    }
}
```

---

## 🆘 If Still Having Issues

### Check These:

1. ✅ Rate limits increased in Supabase Dashboard
2. ✅ Waited at least 15 minutes since last attempt
3. ✅ Using different email address
4. ✅ Check Supabase status: https://status.supabase.com

### Common Causes:

- 🔄 Testing signup repeatedly (increases attempts counter)
- 🌐 Multiple users on same WiFi network
- 🤖 Bot detection triggered
- 📧 Same email used multiple times

---

## 💡 Recommended Solution RIGHT NOW:

**Step 1:** Go to Supabase Dashboard → Authentication → Rate Limits

**Step 2:** Change to:
```
Sign ups per hour: 50
OTP requests per hour: 20
```

**Step 3:** Save

**Step 4:** Wait 5 minutes

**Step 5:** Try signup again ✅

This should fix it immediately! 🚀

---

## 📝 Summary

- **Cause:** Too many signup attempts in short time
- **Quick Fix:** Wait 15-30 minutes OR increase rate limits
- **Best Fix:** Increase rate limits in Supabase Dashboard (for testing)
- **Production:** Keep limits low + enable CAPTCHA

See `clear_rate_limits.sql` for SQL queries to check attempts.
