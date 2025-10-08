# ⚡ QUICK FIX - OTP Not Showing in Email

## 🎯 **The Problem**
Your email shows "YOUR VERIFICATION CODE" but **no actual code number**.

## ✅ **The Solution** (1 Minute Fix)

### **Step 1: Open Supabase Dashboard**
1. Go to: https://app.supabase.com
2. Select your project
3. Click: **Authentication** → **Email Templates**

### **Step 2: Edit Confirm Signup Template**
1. Find and click on: **"Confirm signup"** template
2. Look for this line in the HTML:
   ```html
   <div class="otp-code">{{ .OTP }}</div>
   ```

3. **Change it to:**
   ```html
   <div class="otp-code">{{ .Token }}</div>
   ```

### **Step 3: Save**
1. Click **"Save"** button at the bottom
2. Done! ✅

---

## 🧪 **Test It**
1. Create a new account in your app
2. Check your email
3. You should now see the **4-digit code** displayed!

---

## 🎁 **Bonus Feature Added**
I've also added a **"Paste" button** in the app so users can easily copy the code from email and paste it!

**How to use:**
1. Long-press the code in email → Copy
2. Open app → Tap "Paste" button
3. Code auto-fills → Tap "Verify"
4. Done! 🎉

---

## 📋 **Why This Happened**
- Your template used `{{ .OTP }}` which doesn't exist in Supabase
- The correct variable name is `{{ .Token }}`
- This is a common mistake - Supabase doesn't document this well!

---

## ⚠️ **If Still Not Working**
1. Double-check you saved the template
2. Try sending a test email from Supabase Dashboard
3. Check spam folder
4. Wait 1-2 minutes for changes to apply

---

**That's it! The OTP code will now show in your emails! 🎉**

For detailed information, see: `OTP_EMAIL_FIX_GUIDE.md`
