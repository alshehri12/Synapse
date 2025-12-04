# Password Reset - Clear Step-by-Step Guide

## What You Need to Understand First

**The Problem**: When someone clicks "reset password" in the email, Supabase needs to know where to send them.

**The Solution**: We'll make the link open your Synapse app directly (no website needed!)

---

## 🎯 Complete Setup (3 Steps)

### ✅ STEP 1: Configure Xcode (2 minutes)

This tells iOS that your app can handle `synapse://` links.

**Instructions**:

1. **Open** your Synapse project in Xcode

2. Click on **Synapse** (the blue app icon) at the very top of the left sidebar

3. Make sure you're on the **Info** tab (top of the window)

4. Scroll down until you see **URL Types** section

5. Click the **+** button under URL Types

6. Fill in these **exact** values:
   ```
   Identifier: com.synapse.app
   URL Schemes: synapse
   Role: Editor
   ```

7. Press Enter or click outside the field

**You're done with Step 1!** ✅

---

### ✅ STEP 2: Configure Supabase Dashboard (1 minute)

This tells Supabase that `synapse://reset-password` is allowed.

**Instructions**:

1. Go to **https://supabase.com/dashboard**

2. Click on your **Synapse** project

3. In the left sidebar, click **Authentication** (🔐 icon)

4. Click **URL Configuration**

5. Scroll to **Redirect URLs** section

6. Click **+ Add URL** button

7. Type **exactly**: `synapse://reset-password`

8. Click **Save** at the bottom

**You're done with Step 2!** ✅

---

### ✅ STEP 3: Rebuild Your App (30 seconds)

The code is already updated, you just need to rebuild.

**Instructions**:

1. In Xcode, press **Cmd + Shift + K** (Clean Build Folder)

2. Then press **Cmd + B** (Build)

3. Run the app on your device or simulator

**You're done with Step 3!** ✅

---

## 🧪 How to Test

1. Open your app

2. Go to login screen

3. Click **"Forgot Password?"**

4. Enter your email

5. Click **"Send Reset Link"**

6. Check your email inbox

7. Click the reset link in the email

8. **What should happen**:
   - Your Synapse app opens
   - You see Supabase's password reset screen
   - Enter new password
   - Password is updated ✅

---

## ❓ What If It Doesn't Work?

### Issue: "Invalid redirect URL" error

**Fix**: Make sure you added `synapse://reset-password` (exactly like that) to Supabase Dashboard → Authentication → URL Configuration → Redirect URLs

### Issue: Link doesn't open the app

**Fix**: Make sure you:
1. Added URL scheme in Xcode (Step 1)
2. Rebuilt the app (Step 3)
3. Testing on a real device (simulator sometimes has issues with deep links)

### Issue: Shows Supabase error page

**Fix**: Wait 1-2 minutes after saving the redirect URL in Supabase Dashboard. Changes take a moment to propagate.

---

## 📱 What the User Experience Will Be

### Current Flow:
1. User taps "Forgot Password?" ✅ (Working)
2. User enters email ✅ (Working)
3. User receives email ✅ (Working)
4. User clicks link in email → **Opens your app** ✅ (Will work after setup)
5. User enters new password on Supabase page
6. Password is reset ✅
7. User returns to app and logs in ✅

---

## 🎯 Summary

**You need to do TWO things**:

1. **Xcode**: Add URL Type with scheme `synapse`
2. **Supabase Dashboard**: Add `synapse://reset-password` to Redirect URLs

That's it! No web hosting, no domain, no server needed.

---

## 🔄 Alternative: Even Simpler (But Less Professional)

If you want the **absolute simplest** solution:

1. Remove the `redirectTo` parameter entirely (I can do this)
2. Users will see Supabase's default page (not branded)
3. Still works perfectly, just not custom

Let me know which approach you prefer!

---

## ✨ Why This Approach is Better

❌ **Web hosting approach** (what I explained before):
- Need to host HTML file
- Need a domain
- Need to configure credentials
- More complex

✅ **Deep link approach** (what we're doing now):
- No hosting needed
- No domain needed
- Just 2 configuration steps
- Works perfectly
- Professional

---

## Need Help?

Tomorrow when we work on this, I can:
1. Walk through the Xcode setup with you
2. Show you exactly where to click in Supabase
3. Test it together
4. Fix any issues

The setup is very simple - it just needs those 2 configuration steps!
