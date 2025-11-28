# 🚨 OTP Email Troubleshooting Guide - Production Issues

## Problem
Users in production are NOT receiving OTP verification emails after signing up.

---

## ✅ Step-by-Step Diagnosis

### **Step 1: Check Supabase Email Template**

1. **Go to Supabase Dashboard**
   - URL: https://app.supabase.com
   - Select your Synapse project

2. **Check Email Template Variable**
   ```
   Navigation: Authentication → Email Templates → "Confirm signup"

   WRONG ❌: {{ .OTP }}
   CORRECT ✅: {{ .Token }}
   ```

3. **Fix if needed**
   - Copy content from `CORRECTED_EMAIL_TEMPLATE.html` in this repo
   - Paste into "Confirm signup" template
   - Click "Save"

---

### **Step 2: Check Email Confirmation Settings**

1. **Go to Authentication Settings**
   ```
   Navigation: Authentication → Settings → Email
   ```

2. **Verify these settings are ENABLED:**
   - ✅ Enable email confirmations
   - ✅ Enable email OTP (if using OTP method)
   - ✅ Secure email change

3. **Check OTP Expiry**
   - Default: 3600 seconds (60 minutes)
   - Recommended: Keep default or reduce to 600 seconds (10 minutes)

---

### **Step 3: Check SMTP Configuration**

1. **Current Status**
   ```
   Navigation: Authentication → Email Templates → SMTP Settings
   ```

2. **Check SMTP Provider**
   - Using Supabase Default? → **NOT recommended for production**
   - Using Custom SMTP? → **Good, verify credentials**

3. **Recommended Setup for Production:**

   **Option A: SendGrid (FREE 100 emails/day)**
   ```
   SMTP Host: smtp.sendgrid.net
   SMTP Port: 587
   SMTP User: apikey
   SMTP Password: [Your SendGrid API Key]
   Sender Email: noreply@usynapse.com
   Sender Name: Synapse
   ```

   **Option B: AWS SES (FREE 62,000 emails/month)**
   ```
   SMTP Host: email-smtp.us-east-1.amazonaws.com
   SMTP Port: 587
   SMTP User: [Your AWS SES Access Key]
   SMTP Password: [Your AWS SES Secret Key]
   Sender Email: noreply@usynapse.com
   Sender Name: Synapse
   ```

---

### **Step 4: Check Email Logs in Supabase**

1. **View Auth Logs**
   ```
   Navigation: Logs → Auth Logs
   Filter: Last 24 hours
   ```

2. **Look for these events:**
   - ✅ `user_signup` - User created successfully
   - ✅ `send_email` - Email sending attempt
   - ❌ `email_failed` - Email sending failed

3. **Common Error Messages:**
   ```
   "SMTP connection failed" → SMTP credentials wrong
   "Rate limit exceeded" → Too many emails sent
   "Invalid sender email" → Sender email not verified
   "Template error" → Email template has syntax errors
   ```

---

### **Step 5: Test Email Delivery**

1. **Create Test Account**
   - Use your own email address
   - Try different providers (Gmail, Outlook, iCloud)

2. **Check All Folders**
   - ✅ Inbox
   - ✅ Spam/Junk
   - ✅ Promotions (Gmail)
   - ✅ Updates (Gmail)

3. **Search for Sender**
   - Search: `from:noreply@mail.app.supabase.io`
   - Or: `from:noreply@usynapse.com` (if custom SMTP)

---

## 🔧 Quick Fixes

### **Fix 1: Update Email Template Variable**

**Current template probably has:**
```html
<div class="otp-code">{{ .OTP }}</div>
```

**Change to:**
```html
<div class="otp-code">{{ .Token }}</div>
```

**Full corrected template:**
- File: `CORRECTED_EMAIL_TEMPLATE.html` (in this repo)
- Copy entire content
- Paste into Supabase → Authentication → Email Templates → "Confirm signup"

---

### **Fix 2: Enable Custom SMTP (SendGrid - Quick Setup)**

1. **Sign up for SendGrid**
   - URL: https://signup.sendgrid.com
   - Choose FREE plan (100 emails/day)

2. **Create API Key**
   - Settings → API Keys → Create API Key
   - Name: "Synapse Production"
   - Permission: Full Access
   - Copy the API key (save it securely!)

3. **Add to Supabase**
   ```
   Supabase Dashboard:
   Authentication → Email Templates → SMTP Settings

   Enable Custom SMTP: ✅
   SMTP Host: smtp.sendgrid.net
   SMTP Port: 587
   SMTP User: apikey
   SMTP Password: [Paste your SendGrid API Key]
   Sender Email: noreply@usynapse.com
   Sender Name: Synapse
   ```

4. **Verify Sender Email in SendGrid**
   - SendGrid → Settings → Sender Authentication
   - Add "noreply@usynapse.com"
   - Click verification link in email

5. **Test**
   - Create new test account in your app
   - Check if email arrives

---

### **Fix 3: Check Rate Limits**

**Supabase Free Tier Limits:**
- Email rate limit: ~30 emails/hour
- May be throttled during high usage

**Solution:**
- Upgrade Supabase plan OR
- Use custom SMTP (SendGrid/AWS SES) - no Supabase email limits

---

## 📊 Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Wrong template variable** | Email sent but no code shown | Change `{{ .OTP }}` to `{{ .Token }}` |
| **SMTP not configured** | No emails received at all | Setup SendGrid or AWS SES |
| **Emails in spam** | Users say no email | Check spam folder, setup SPF/DKIM |
| **Rate limited** | Works sometimes, not others | Enable custom SMTP |
| **Template error** | Emails fail to send | Check Supabase logs for syntax errors |
| **Unverified sender** | Gmail blocks emails | Verify sender email in SendGrid |

---

## 🎯 Recommended Production Setup

### **Best Practice Configuration:**

1. ✅ **Use custom SMTP (SendGrid or AWS SES)**
   - Don't rely on Supabase default email
   - Better deliverability
   - No rate limits
   - Professional sender address

2. ✅ **Verify sender domain**
   - Add SPF record to DNS
   - Add DKIM record to DNS
   - Improves email deliverability

3. ✅ **Monitor email logs**
   - Regularly check Supabase Auth logs
   - Setup alerts for email failures

4. ✅ **Test email delivery**
   - Test with multiple email providers
   - Check spam scores
   - Monitor delivery rates

---

## 🆘 If Still Not Working

### **Debug Checklist:**

- [ ] Email template uses `{{ .Token }}` not `{{ .OTP }}`
- [ ] Email confirmations are ENABLED in Supabase
- [ ] Custom SMTP is configured (SendGrid/AWS SES)
- [ ] Sender email is verified
- [ ] No errors in Supabase Auth logs
- [ ] Tested with multiple email providers
- [ ] Checked spam folders
- [ ] OTP expiry time is reasonable (not too short)

### **Get Help:**

1. **Check Supabase Status**
   - https://status.supabase.com
   - May be temporary outage

2. **Supabase Support**
   - Community: https://github.com/supabase/supabase/discussions
   - Discord: https://discord.supabase.com

3. **SendGrid Support**
   - Check email logs in SendGrid dashboard
   - Verify API key permissions

---

## 📝 Next Steps After Fix

1. **Test thoroughly**
   - Create 5 test accounts
   - Use different email providers
   - Verify all receive OTP emails

2. **Monitor for 24 hours**
   - Check Supabase logs
   - Watch for user complaints
   - Verify delivery rate

3. **Update documentation**
   - Document your SMTP setup
   - Save API keys securely
   - Note any custom configuration

---

## 🚀 Long-term Improvements

1. **Add email delivery monitoring**
   - Track email sent vs delivered
   - Alert on high failure rates

2. **Implement fallback OTP method**
   - SMS OTP as backup
   - Magic link option

3. **Add user feedback**
   - "Didn't receive email?" button
   - Resend OTP option
   - Check spam folder reminder

---

## Summary

**Most Likely Issue:** Email template using wrong variable (`{{ .OTP }}` instead of `{{ .Token }}`)

**Quick Fix:**
1. Go to Supabase → Authentication → Email Templates
2. Open "Confirm signup" template
3. Replace `{{ .OTP }}` with `{{ .Token }}`
4. Save

**Production Fix:**
1. Setup SendGrid account (free)
2. Create API key
3. Configure SMTP in Supabase
4. Verify sender email
5. Test

**Test:**
- Create new account
- Check email arrives
- Verify OTP code is visible
- Test on multiple email providers
