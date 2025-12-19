# ✅ Password Reset - Final Setup Checklist

## Complete Flow Overview

**User Journey:**
1. User taps "Forgot Password?" in app
2. Enters email address
3. Receives email with "Reset My Password" button
4. Clicks button → Opens `https://usynapse.com/reset-password.html`
5. Sees form with two password fields
6. Enters new password twice
7. Clicks "Reset Password"
8. Success! Password is updated ✅

---

## 📋 Complete Setup Checklist

### ✅ **Step 1: Upload Reset Page to Your Website**

- [ ] **Login to usynapse.com hosting** (cPanel or FTP)
- [ ] **Navigate to:** `public_html/` folder
- [ ] **Upload:** `web/reset-password-page.html`
- [ ] **Rename to:** `reset-password.html`
- [ ] **Test URL:** Visit `https://usynapse.com/reset-password.html`
- [ ] **Should see:** Beautiful green Synapse password reset page

**Hosting Methods:**

**Option A - cPanel:**
```
1. Login to cPanel (usynapse.com/cpanel)
2. File Manager → public_html/
3. Upload → Select reset-password-page.html
4. Right-click → Rename → reset-password.html
5. Done!
```

**Option B - FTP:**
```
1. Open FileZilla/Cyberduck
2. Connect to ftp.usynapse.com
3. Navigate to /public_html/
4. Upload reset-password-page.html
5. Rename to reset-password.html
6. Done!
```

---

### ✅ **Step 2: Update Supabase Email Template**

- [ ] **Go to:** https://supabase.com/dashboard
- [ ] **Select:** Your Synapse project
- [ ] **Navigate to:** Authentication → Email Templates
- [ ] **Find:** "Change Email" or "Recovery" template
  - (NOT "Confirm signup" - that's for OTP!)
- [ ] **Copy content from:** `PASSWORD_RESET_EMAIL_TEMPLATE.html`
- [ ] **Paste into:** Supabase template editor
- [ ] **Update subject line:** "Reset Your Synapse Password"
- [ ] **Click:** Save
- [ ] **Verify:** Template has green "Reset My Password" button

**Important:** Make sure you're editing the **password reset** template, not the signup confirmation template!

---

### ✅ **Step 3: Configure Supabase Redirect URL**

- [ ] **Still in Supabase Dashboard**
- [ ] **Go to:** Authentication → URL Configuration
- [ ] **Scroll to:** "Redirect URLs" section
- [ ] **Click:** Add URL button
- [ ] **Enter exactly:** `https://usynapse.com/reset-password.html`
- [ ] **Click:** Save
- [ ] **Verify:** URL appears in the list

**Critical:** The URL must be **exact** - including `https://` and `.html`

---

### ✅ **Step 4: Code is Already Updated**

- [x] **SupabaseManager.swift** already points to `https://usynapse.com/reset-password.html`
- [x] **reset-password-page.html** already has your Supabase credentials
- [ ] **Rebuild app** (Cmd + Shift + K, then Cmd + B)
- [ ] **Run on device** to test

---

## 🧪 Testing the Complete Flow

### **Test 1: Email Template**

1. **Trigger reset:**
   - Open app
   - Tap "Forgot Password?"
   - Enter your email
   - Tap "Send Reset Link"

2. **Check email:**
   - Should arrive within 1-2 minutes
   - Subject: "Reset Your Synapse Password"
   - Has green "Reset My Password" button ✅
   - Has backup text link below button ✅

3. **Check Postmark:**
   - Login to Postmark dashboard
   - Go to Activity tab
   - Should see the email sent ✅

---

### **Test 2: Reset Page**

1. **Direct access:**
   - Open browser
   - Visit: `https://usynapse.com/reset-password.html`
   - Should see:
     - ✅ Green Synapse logo
     - ✅ "Reset Your Password" heading
     - ✅ Two password input fields
     - ✅ Green "Reset Password" button

---

### **Test 3: Complete Reset Flow**

1. **Click email button:**
   - Open the password reset email
   - Click "Reset My Password" button
   - Should open: `https://usynapse.com/reset-password.html?...`
   - (URL will have extra parameters - that's correct!)

2. **Enter new password:**
   - Type new password (at least 6 characters)
   - Type same password in confirm field
   - Watch password strength bar change ✅

3. **Submit:**
   - Click "Reset Password" button
   - Should show: "Password Reset Successful!" ✅
   - Should see: "Open Synapse App" button ✅

4. **Verify:**
   - Open app (or click "Open Synapse App")
   - Go to login
   - Enter email + NEW password
   - Should login successfully ✅

---

## 🚨 Troubleshooting

### **Issue: Email doesn't arrive**

**Check:**
- [ ] Postmark Activity logs - Is email sent?
- [ ] Spam/Junk folder
- [ ] Email rate limits (see FIX_EMAIL_RATE_LIMIT.md)
- [ ] "Enable Custom SMTP" checked in Supabase

**Fix:** See `FIX_POSTMARK_RATE_LIMIT.md`

---

### **Issue: Blank page when clicking email link**

**Cause:** File not uploaded to usynapse.com

**Check:**
- [ ] Visit `https://usynapse.com/reset-password.html` directly
- [ ] Should see reset page, not 404 error
- [ ] File uploaded to correct folder (public_html/)
- [ ] File named exactly: `reset-password.html`

**Fix:** Re-upload file to correct location

---

### **Issue: "Invalid link" error on reset page**

**Cause:** Redirect URL not added to Supabase

**Check:**
- [ ] Supabase → Authentication → URL Configuration
- [ ] `https://usynapse.com/reset-password.html` is in Redirect URLs list
- [ ] URL is exactly the same (including https://)

**Fix:** Add URL to Supabase and wait 2-3 minutes

---

### **Issue: Email button goes to wrong URL**

**Cause:** App not rebuilt after code change

**Check:**
- [ ] SupabaseManager.swift has correct URL
- [ ] App was rebuilt (Cmd + B)
- [ ] Testing on device with new build

**Fix:**
```
1. Xcode → Product → Clean Build Folder (Cmd + Shift + K)
2. Xcode → Product → Build (Cmd + B)
3. Run on device
4. Try password reset again
```

---

### **Issue: Password reset fails with error**

**Cause:** Supabase credentials wrong in HTML

**Check:**
- [ ] Open `reset-password-page.html`
- [ ] Line 214: `supabaseUrl` matches your project
- [ ] Line 215: `supabaseKey` matches your anon key
- [ ] Both should match values in `Info.plist`

**Fix:** Update credentials and re-upload file

---

## 📊 What Each File Does

### **1. PASSWORD_RESET_EMAIL_TEMPLATE.html**
- **Where:** Supabase → Email Templates → "Recovery"
- **Purpose:** Email user receives
- **Contains:** "Reset My Password" button
- **Variable:** `{{ .ConfirmationURL }}` (Supabase fills this)

### **2. reset-password-page.html**
- **Where:** `usynapse.com/public_html/`
- **Purpose:** Web page where user resets password
- **Contains:** Form with 2 password fields
- **Action:** Calls Supabase to update password

### **3. SupabaseManager.swift**
- **Where:** App code
- **Purpose:** Sends reset email when user requests
- **Sets:** Redirect URL to usynapse.com

---

## 🎯 Expected Results

### **Email:**
```
From: Synapse <noreply@yourdomain.com>
Subject: Reset Your Synapse Password

[Green header with Synapse logo]
Reset Your Password

We received a request to reset your password.
Click the button below to create a new password.

[Green "Reset My Password" button]

Or copy this link: https://usynapse.com/reset-password.html?token=...

This link will expire in 60 minutes.
```

### **Reset Page:**
```
[Synapse logo 🧠]
Reset Your Password

[Password field]
[Confirm password field]
[Password strength meter]

[Green "Reset Password" button]
```

### **Success:**
```
✅ Password Reset Successful!
Your password has been updated.

[Open Synapse App button]
```

---

## ✅ Final Verification

Before considering this complete, verify ALL of these:

- [ ] `reset-password.html` uploaded to usynapse.com
- [ ] Page loads at: `https://usynapse.com/reset-password.html`
- [ ] PASSWORD_RESET_EMAIL_TEMPLATE.html pasted into Supabase
- [ ] Email template saved in Supabase
- [ ] Redirect URL added to Supabase Dashboard
- [ ] SupabaseManager.swift has correct URL
- [ ] App rebuilt and running latest code
- [ ] Test email arrives with button
- [ ] Button opens usynapse.com page
- [ ] Can enter new password
- [ ] Password resets successfully
- [ ] Can login with new password

---

## 📝 Summary

**3 Components Working Together:**

1. **Email Template** (in Supabase)
   → Sends email with button

2. **Reset Page** (on usynapse.com)
   → Shows form to enter new password

3. **App Code** (SupabaseManager)
   → Tells Supabase where to redirect

**Flow:**
```
User in app
  ↓ (Taps "Forgot Password?")
SupabaseManager.resetPassword()
  ↓ (Sends email via Postmark)
Email with "Reset My Password" button
  ↓ (User clicks button)
Opens: https://usynapse.com/reset-password.html
  ↓ (User enters new password)
Supabase updates password
  ↓
Success! ✅
```

---

## 🚀 Quick Setup (If Starting Fresh)

```bash
# 1. Upload file
# Via cPanel or FTP to: public_html/reset-password.html

# 2. Update Supabase
# Dashboard → Email Templates → Recovery → Paste PASSWORD_RESET_EMAIL_TEMPLATE.html

# 3. Add Redirect URL
# Dashboard → URL Configuration → Add: https://usynapse.com/reset-password.html

# 4. Rebuild app
# Xcode → Clean + Build

# 5. Test
# App → Forgot Password → Enter email → Check email → Click button → Reset password
```

Done! 🎉

---

## 💡 Pro Tips

1. **Test with your own email first** before releasing
2. **Check spam folder** if email doesn't arrive
3. **Monitor Postmark Activity** to see emails being sent
4. **Keep backup** of reset-password.html file
5. **Update App Store URL** in HTML (line 296) when app is live

---

## 📞 Need Help?

If something isn't working:

1. **Check which step fails:**
   - Email not arriving? → See FIX_POSTMARK_RATE_LIMIT.md
   - Blank page? → File not uploaded correctly
   - Invalid link error? → Redirect URL not in Supabase
   - Reset fails? → Credentials wrong in HTML

2. **Verify each component:**
   - Email template in Supabase
   - Reset page on usynapse.com
   - Redirect URL in Supabase
   - App code up to date

3. **Test step by step:**
   - Can you access page directly?
   - Does email arrive?
   - Does button have correct URL?
   - Does page load when clicking?

Everything should work perfectly once all 3 components are set up! ✅
