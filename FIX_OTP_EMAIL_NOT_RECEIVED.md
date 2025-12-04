# 🚨 FIX: Users Not Receiving OTP Emails

## The Problem

Users are creating accounts but **NOT receiving OTP verification emails**, even though your SMTP server works fine when you send test emails.

---

## 🎯 Root Cause Analysis

There are **3 possible reasons** why OTP emails are not arriving:

### 1. ❌ **Wrong Email Template Variable** (Most Common)
- Supabase email template uses `{{ .OTP }}` but should use `{{ .Token }}`
- Email gets sent but shows blank code
- Users think email never arrived

### 2. ❌ **Email Confirmation Disabled in Supabase**
- "Enable email confirmations" is turned OFF
- Supabase doesn't send any email at all
- Most common with new projects

### 3. ❌ **SMTP Configuration Issue**
- Using Supabase default SMTP (limited and unreliable)
- SMTP credentials incorrect
- Sender email not verified
- Rate limits exceeded

---

## ✅ THE FIX (Step-by-Step)

### **STEP 1: Check Email Template (5 minutes)**

This is the **MOST COMMON** issue!

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your Synapse project

2. **Navigate to Email Templates**
   ```
   Left sidebar → Authentication → Email Templates
   ```

3. **Open "Confirm signup" template**
   - Click on "Confirm signup" in the list
   - You'll see the email HTML code

4. **Find the OTP variable**
   - Search for: `{{ .OTP }}`  ← THIS IS WRONG ❌
   - Or search for: `{{ .Token }}` ← THIS IS CORRECT ✅

5. **If you see `{{ .OTP }}`, REPLACE THE ENTIRE TEMPLATE**
   - Copy the content from: `CORRECTED_EMAIL_TEMPLATE.html` (in your project folder)
   - Delete everything in the Supabase template editor
   - Paste the corrected template
   - Click **Save**

6. **Test immediately**
   - Create a new test account in your app
   - Check if email arrives with visible OTP code

---

### **STEP 2: Verify Email Confirmations Are Enabled (2 minutes)**

1. **Go to Authentication Settings**
   ```
   Supabase Dashboard → Authentication → Providers → Email
   ```

2. **Check these settings are ENABLED (✅)**
   - ✅ **Enable email provider**
   - ✅ **Confirm email** (This is critical!)
   - ✅ **Secure email change** (recommended)

3. **Check OTP Settings**
   ```
   Scroll down to: "Email OTP"
   ```
   - Make sure it's not disabled

4. **Click Save** if you made any changes

---

### **STEP 3: Check SMTP Configuration (3 minutes)**

Your test emails work, but production might be different!

1. **Go to SMTP Settings**
   ```
   Supabase Dashboard → Project Settings → Auth → SMTP Settings
   ```

2. **Check Current Setup**
   - Are you using **Supabase's default SMTP**? → ⚠️ Problem!
   - Or **Custom SMTP**? → ✅ Good, verify settings below

3. **If Using Supabase Default:**
   - This is **NOT reliable** for production
   - Limited to ~30 emails/hour
   - Often blocked by Gmail/Outlook
   - **Solution**: Set up custom SMTP (see Step 4)

4. **If Using Custom SMTP, Verify:**
   - ✅ Host is correct (e.g., `smtp.gmail.com`)
   - ✅ Port is correct (usually `587` or `465`)
   - ✅ Username is correct
   - ✅ Password/API key is correct
   - ✅ Sender email matches your SMTP account
   - ✅ "Enable Custom SMTP" is checked ✅

---

### **STEP 4: Set Up Reliable SMTP (Optional but Recommended)**

If emails still don't arrive, use a professional email service:

#### **Option A: Gmail SMTP (Quick Setup)**

**Requirements**: Gmail account with 2FA enabled

1. **Enable 2-Factor Authentication** on your Gmail
   - Google Account → Security → 2-Step Verification

2. **Create App Password**
   - Google Account → Security → App passwords
   - Select "Mail" and "Other (Custom name)"
   - Name it "Synapse App"
   - Copy the 16-character password

3. **Configure in Supabase**
   ```
   SMTP Host: smtp.gmail.com
   SMTP Port: 587
   SMTP User: your-email@gmail.com
   SMTP Password: [paste 16-character app password]
   Sender Email: your-email@gmail.com
   Sender Name: Synapse
   Enable Custom SMTP: ✅
   ```

4. **Save and Test**

**Pros**: ✅ Free, ✅ Reliable, ✅ Quick setup
**Cons**: ❌ Daily limit (500 emails), ❌ Gmail sender address

---

#### **Option B: SendGrid (Professional - FREE)**

**Best for production!**

1. **Sign Up for SendGrid**
   - Go to: https://signup.sendgrid.com
   - Choose **FREE plan** (100 emails/day)

2. **Verify Your Email**
   - Check inbox and click verification link

3. **Create API Key**
   - Settings → API Keys → **Create API Key**
   - Name: "Synapse Production"
   - Access: **Full Access**
   - Click **Create & View**
   - **COPY THE KEY** (you won't see it again!)

4. **Configure in Supabase**
   ```
   SMTP Host: smtp.sendgrid.net
   SMTP Port: 587
   SMTP User: apikey
   SMTP Password: [paste your SendGrid API key]
   Sender Email: noreply@yourdomain.com
   Sender Name: Synapse
   Enable Custom SMTP: ✅
   ```

5. **Verify Sender Email** (Important!)
   - SendGrid → Settings → **Sender Authentication**
   - Click **Verify a Single Sender**
   - Fill in form with `noreply@yourdomain.com`
   - Check email and click verification link

6. **Save and Test**

**Pros**: ✅ Professional, ✅ Free 100/day, ✅ Better deliverability, ✅ Detailed analytics
**Cons**: Requires domain verification for production

---

### **STEP 5: Test Email Delivery**

After making changes, test thoroughly:

1. **Create Test Account**
   - Use your own email (Gmail, Outlook, etc.)
   - Try signup flow

2. **Check All Email Folders**
   - ✅ Inbox
   - ✅ Spam/Junk
   - ✅ Promotions (Gmail)
   - ✅ Updates (Gmail)

3. **Look for Sender**
   - Search: `from:noreply` in your email
   - Or: `Synapse verification`

4. **Test Multiple Providers**
   - Gmail
   - Outlook/Hotmail
   - iCloud
   - Yahoo

5. **Verify Code Is Visible**
   - Email should show 4-digit code clearly
   - Code should be the first 4 digits of the token

---

## 🔍 How to Debug

### **Check Supabase Logs**

1. **Go to Logs**
   ```
   Supabase Dashboard → Logs → Auth Logs
   ```

2. **Filter Recent**
   - Set time range: Last 1 hour
   - Look for user signup events

3. **Look for These Events**
   - ✅ `user.signup` → User created successfully
   - ✅ `email.sent` → Email sent
   - ❌ `email.failed` → Email failed to send

4. **Check Error Messages**
   - `"SMTP connection failed"` → Wrong SMTP credentials
   - `"Rate limit exceeded"` → Too many emails (use custom SMTP)
   - `"Invalid sender"` → Sender email not verified
   - `"Template error"` → Email template has syntax errors

---

## 📊 Quick Diagnosis Checklist

Work through this checklist:

- [ ] Email template uses `{{ .Token }}` not `{{ .OTP }}`
- [ ] "Confirm email" is ENABLED in Authentication → Providers → Email
- [ ] Custom SMTP is configured (not using Supabase default)
- [ ] SMTP credentials are correct
- [ ] Sender email is verified (for SendGrid/professional SMTP)
- [ ] Test email arrives in inbox (not spam)
- [ ] OTP code is visible in email
- [ ] No errors in Supabase Auth logs
- [ ] Tested with multiple email providers (Gmail, Outlook)

---

## 🎯 Most Likely Fix

**90% of the time, the issue is:**

1. ❌ Email template using `{{ .OTP }}` instead of `{{ .Token }}`
2. ❌ "Confirm email" setting is disabled

**Quick Fix (2 minutes):**

1. Supabase Dashboard → Authentication → Email Templates
2. Open "Confirm signup"
3. Replace entire content with `CORRECTED_EMAIL_TEMPLATE.html`
4. Save
5. Go to Authentication → Providers → Email
6. Enable "Confirm email" ✅
7. Save
8. Test with new account

---

## 🆘 If Still Not Working

### **Contact Me Tomorrow**

When we work on this tomorrow, I'll need:

1. **Screenshot** of your email template (the {{ .Token }} line)
2. **Screenshot** of Authentication → Providers → Email settings
3. **Screenshot** of SMTP Settings
4. **Copy** of error from Supabase Auth logs (if any)
5. **Test email address** you're using to test

I'll diagnose and fix it with you!

---

## 📝 Summary

### **What to Do Right Now:**

1. ✅ **Check email template** → Replace `{{ .OTP }}` with `{{ .Token }}`
2. ✅ **Enable email confirmation** → Authentication → Providers → Email
3. ✅ **Verify SMTP** → Make sure custom SMTP is configured
4. ✅ **Test** → Create test account and check email

### **Expected Result:**

- User signs up
- Email arrives within seconds
- Shows 4-digit OTP code clearly
- User enters code
- Account verified ✅

---

## 🎉 After Fix

Once emails are working:

1. **Test with 5 different email providers**
2. **Monitor Supabase logs for 24 hours**
3. **Check spam rates** (should be 0%)
4. **Update app documentation** if needed

Let me know the results tomorrow! 💪
