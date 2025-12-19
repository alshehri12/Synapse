# 🔐 Setup Password Reset Email Template

## What You Need:

A password reset email that contains a **clickable link** (not a code) that allows users to reset their password.

---

## ✅ Solution: PASSWORD_RESET_EMAIL_TEMPLATE.html

I've created the correct template with:

✅ **"Reset My Password" button** - Big, clear, clickable
✅ **Backup text link** - In case button doesn't work
✅ **Uses `{{ .ConfirmationURL }}`** - Supabase password reset link variable
✅ **60-minute expiry notice** - Security best practice
✅ **Professional design** - Matches Synapse branding
✅ **No JavaScript** - Email-safe, no warnings
✅ **Table-based layout** - Works in all email clients

---

## 🎯 How to Install (3 minutes)

### **Step 1: Copy the Template**

1. Open: `PASSWORD_RESET_EMAIL_TEMPLATE.html`
2. Select all (Cmd+A)
3. Copy (Cmd+C)

### **Step 2: Update Supabase Email Template**

1. **Go to Supabase Dashboard** → Your Synapse project

2. **Navigate to:**
   ```
   Authentication → Email Templates
   ```

3. **Find "Reset Password" or "Change Email" template**
   - Look for the template that says "Recovery" or "Reset Password"
   - NOT "Confirm signup" (that's for OTP verification)

4. **Click on the template**

5. **Delete all existing content**

6. **Paste the new template** (Cmd+V)

7. **Update the subject line** (optional but recommended):
   ```
   Reset Your Synapse Password
   ```

8. **Click Save**

---

## 📧 Key Template Variables

The template uses these Supabase variables:

### **`{{ .ConfirmationURL }}`**
- **What it is:** The magic link for password reset
- **Where it goes:** User clicks this link → Opens password reset page
- **Example URL:** `https://yourdomain.com/reset-password?token=abc123...`

This is **automatically generated** by Supabase when user requests password reset!

---

## 🔗 How the Reset Flow Works

### **User Side:**

1. User taps "Forgot Password?" in app
2. Enters their email address
3. Taps "Send Reset Link"
4. **Receives email** with "Reset My Password" button
5. **Clicks button** → Opens password reset page
6. Enters new password
7. Password is updated ✅

### **Technical Flow:**

```
User taps "Forgot Password"
    ↓
App calls: supabaseManager.resetPassword(email: email)
    ↓
Supabase sends email with {{ .ConfirmationURL }}
    ↓
User clicks link in email
    ↓
Opens: synapse://reset-password (deep link)
    OR
Opens: https://yourdomain.com/reset-password (web page)
    ↓
User enters new password
    ↓
Password updated in Supabase ✅
```

---

## ⚙️ Configuration Needed

### **Step 1: Configure Redirect URL** (Already Done!)

You already have this in `SupabaseManager.swift`:

```swift
let redirectURL = URL(string: "synapse://reset-password")!
```

This tells Supabase where to send users after clicking the email link.

### **Step 2: Add Redirect URL to Supabase Dashboard**

1. **Go to Supabase Dashboard** → Your project

2. **Authentication** → **URL Configuration**

3. **Redirect URLs** section

4. **Add this URL:**
   ```
   synapse://reset-password
   ```

5. **Click Save**

### **Step 3: Verify Email Template is Set**

1. Authentication → Email Templates
2. Check "Reset Password" template
3. Should have the new template with button
4. Subject should be clear

---

## 🧪 How to Test

### **Test 1: Send Reset Email**

1. Open your app
2. Go to login screen
3. Tap "Forgot Password?"
4. Enter your email
5. Tap "Send Reset Link"

### **Test 2: Check Email**

1. Check your email inbox
2. You should receive email within 1-2 minutes
3. Email should have:
   - ✅ "Reset My Password" green button
   - ✅ Backup text link below
   - ✅ Clean, professional design
   - ✅ No warnings or blocked content

### **Test 3: Click the Link**

1. Click "Reset My Password" button
2. Should open:
   - **Mobile:** Your Synapse app (via deep link)
   - **Desktop:** Browser with Supabase reset page

3. Enter new password
4. Confirm password is updated

---

## 📊 Email Template Comparison

### **OTP Verification Email:**
```
Subject: Welcome to Synapse
Variable: {{ .Token }}
Shows: 6-digit code (123456)
User: Copies code → Enters in app
Template: POSTMARK_OPTIMIZED_EMAIL_TEMPLATE.html
```

### **Password Reset Email:**
```
Subject: Reset Your Synapse Password
Variable: {{ .ConfirmationURL }}
Shows: Clickable button/link
User: Clicks button → Opens reset page
Template: PASSWORD_RESET_EMAIL_TEMPLATE.html ← NEW!
```

---

## 🎨 Template Features Explained

### **1. Big Green Button**
```html
<a href="{{ .ConfirmationURL }}" ... >
    Reset My Password
</a>
```
- Clear call-to-action
- Works on all email clients
- No JavaScript needed

### **2. Backup Text Link**
```html
Or copy and paste this link:
{{ .ConfirmationURL }}
```
- In case button doesn't work
- User can copy/paste manually
- Better accessibility

### **3. Security Notice**
```html
This link will expire in 60 minutes
```
- Informs user about security
- Encourages quick action
- Standard security practice

### **4. Ignore Notice**
```html
If you did not request this, ignore this email
```
- Reduces user anxiety
- Security best practice
- Prevents unnecessary support tickets

---

## 🚨 Common Issues & Solutions

### **Issue 1: Link opens browser instead of app**

**Cause:** Deep link not configured properly

**Fix:**
1. Xcode → Synapse target → Info → URL Types
2. Add URL scheme: `synapse`
3. Rebuild app

### **Issue 2: Link shows Supabase error page**

**Cause:** Redirect URL not added to Supabase

**Fix:**
1. Supabase → Authentication → URL Configuration
2. Add: `synapse://reset-password`
3. Save

### **Issue 3: Email doesn't arrive**

**Cause:** Email rate limit or SMTP issue

**Fix:**
1. Check Postmark Activity logs
2. Verify "Enable Custom SMTP" is checked
3. Check Postmark sender verified

### **Issue 4: Button doesn't work**

**Cause:** Email client blocking links

**Fix:**
- Already handled! Backup text link is provided
- User can copy/paste URL manually

---

## 📝 Supabase Template Types

Make sure you're editing the **correct** template:

| Template Name | When Sent | Variable Used | Your Template |
|---------------|-----------|---------------|---------------|
| **Confirm signup** | User creates account | `{{ .Token }}` | POSTMARK_OPTIMIZED_EMAIL_TEMPLATE.html |
| **Reset Password** | User forgets password | `{{ .ConfirmationURL }}` | PASSWORD_RESET_EMAIL_TEMPLATE.html ← NEW! |
| **Change Email** | User changes email | `{{ .ConfirmationURL }}` | (Can use same as reset) |
| **Magic Link** | Passwordless login | `{{ .ConfirmationURL }}` | (Optional) |

---

## ✅ Complete Setup Checklist

- [ ] `PASSWORD_RESET_EMAIL_TEMPLATE.html` copied
- [ ] Supabase → Email Templates → "Reset Password" opened
- [ ] Old template deleted
- [ ] New template pasted
- [ ] Subject line updated: "Reset Your Synapse Password"
- [ ] Template saved
- [ ] Supabase → URL Configuration → Redirect URLs
- [ ] Added: `synapse://reset-password`
- [ ] Saved redirect URL
- [ ] Xcode → URL Types → `synapse` scheme added (if not already)
- [ ] Tested: Send reset email
- [ ] Tested: Email arrives with button
- [ ] Tested: Click button opens app
- [ ] Tested: Can reset password

---

## 🎯 Expected User Experience

### **Before (Without proper template):**
```
❌ Generic Supabase email
❌ Confusing link
❌ Opens browser with error
❌ User confused, contacts support
```

### **After (With new template):**
```
✅ Professional Synapse-branded email
✅ Clear "Reset My Password" button
✅ Opens app directly (or fallback to browser)
✅ User resets password easily
✅ No support tickets needed
```

---

## 🚀 Summary

**What Changed:**
- Created PASSWORD_RESET_EMAIL_TEMPLATE.html
- Has clickable button (not a code!)
- Uses `{{ .ConfirmationURL }}` variable
- Professional, email-safe design

**Where to Use:**
- Supabase → Email Templates → "Reset Password"

**What It Does:**
- User gets email with button
- Clicks button → Opens reset page
- Enters new password
- Password updated ✅

**Next Steps:**
1. Copy PASSWORD_RESET_EMAIL_TEMPLATE.html
2. Paste into Supabase "Reset Password" template
3. Save
4. Test with your email
5. Done! 🎉
