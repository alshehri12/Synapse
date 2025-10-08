# 🚨 URGENT: Update Supabase Email Template NOW

## ⚠️ **The Problem**
Your email is being sent, but the OTP code is **BLANK** because you haven't updated the Supabase template yet!

---

## ✅ **The Fix (Do This NOW):**

### **Step 1: Open Supabase Dashboard**
1. Go to: https://app.supabase.com
2. Login to your account
3. Select your Synapse project

### **Step 2: Navigate to Email Templates**
1. Click on **"Authentication"** in the left sidebar
2. Click on **"Email Templates"**
3. You'll see a list of email templates

### **Step 3: Edit the Confirm Signup Template**
1. Find and click on: **"Confirm signup"**
2. You'll see the HTML editor

### **Step 4: Find and Replace**

**Find this line (around line 96):**
```html
<div class="otp-code">{{ .OTP }}</div>
```

**Replace with:**
```html
<div class="otp-code">{{ .Token }}</div>
```

**IMPORTANT:** Change **ONLY** `{{ .OTP }}` to `{{ .Token }}`
Don't change anything else!

### **Step 5: Save**
1. Scroll to the bottom
2. Click the **"Save"** button
3. Wait for confirmation message

### **Step 6: Test**
1. Wait 60 seconds (for rate limit)
2. Create a new test account
3. Check email - OTP should now show!

---

## 🔍 **How to Verify You Did It Right:**

After saving, the template should have:
```html
<div class="otp-container">
    <div class="otp-label">Your Verification Code</div>
    <div class="otp-code">{{ .Token }}</div>  <!-- ✅ CORRECT -->
    <div class="otp-instructions">Enter this code to verify your account</div>
</div>
```

**NOT:**
```html
<div class="otp-code">{{ .OTP }}</div>  <!-- ❌ WRONG -->
```

---

## 📝 **Alternative: Copy Full Template**

If you want to replace the entire template, use this:

1. Open: `CORRECTED_EMAIL_TEMPLATE.html` (in your project folder)
2. Copy **everything** from that file
3. In Supabase Dashboard → Email Templates → Confirm signup
4. **Replace all content** with the copied template
5. Click Save

---

## 🧪 **After Updating:**

**Test Email:**
1. Wait 60 seconds from your last signup attempt
2. Use a NEW email address (e.g., test123@gmail.com)
3. Sign up in the app
4. Check email inbox
5. You should see: **Large 4 or 6-digit code displayed**

**Example of what you'll see:**
```
YOUR VERIFICATION CODE

    1 2 3 4

Enter this code to verify your account
```

---

## ❓ **Still Not Working?**

### **Check 1: Did you save?**
- Make sure you clicked "Save" button
- Look for confirmation message

### **Check 2: Right template?**
- Make sure you edited "Confirm signup"
- NOT "Invite user" or "Magic Link"

### **Check 3: Right variable?**
- Should be: `{{ .Token }}`
- NOT: `{{ .OTP }}` or `{{ .Code }}`

### **Check 4: Wait for rate limit**
- Wait 60+ seconds between tests
- Or use different email address

---

## 🎯 **Why This Happens:**

**Supabase Template Variables:**

| Variable | Works? | Purpose |
|----------|--------|---------|
| `{{ .Token }}` | ✅ YES | OTP code (use this!) |
| `{{ .TokenHash }}` | ✅ YES | Hashed token |
| `{{ .Email }}` | ✅ YES | User email |
| `{{ .SiteURL }}` | ✅ YES | Your site URL |
| `{{ .OTP }}` | ❌ NO | Doesn't exist! |
| `{{ .Code }}` | ❌ NO | Doesn't exist! |

**Your HTML had:**
```html
<div class="otp-code">{{ .OTP }}</div>
```

**{{ .OTP }} doesn't exist in Supabase!**

So it renders as:
```html
<div class="otp-code"></div>  <!-- Empty! -->
```

---

## 🎥 **Visual Guide:**

```
Supabase Dashboard
  ↓
[Authentication] (sidebar)
  ↓
[Email Templates]
  ↓
[Confirm signup] ← Click this
  ↓
HTML Editor opens
  ↓
Find: {{ .OTP }}
Replace: {{ .Token }}
  ↓
[Save] ← Click this
  ↓
Done! ✅
```

---

## ⏰ **Do This Right Now:**

1. Open Supabase Dashboard
2. Authentication → Email Templates → Confirm signup
3. Change `{{ .OTP }}` to `{{ .Token }}`
4. Save
5. Wait 60 seconds
6. Test with new signup

**This is the ONLY thing preventing OTP from showing!**

---

**The app code is perfect. The email template needs updating in Supabase! 🎯**
