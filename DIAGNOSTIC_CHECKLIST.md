# 🔍 OTP Email Diagnostic Checklist

## Question: "Why is my OTP code not showing in the email?"

Run through this checklist to find the problem:

---

## ✅ **Checklist:**

### **1. Did you update the Supabase email template?**

**Action:** Go to Supabase Dashboard → Authentication → Email Templates → Confirm signup

**Check:** Does the template have `{{ .Token }}` or `{{ .OTP }}`?

- [ ] ✅ I see `{{ .Token }}` - CORRECT
- [ ] ❌ I see `{{ .OTP }}` - **THIS IS THE PROBLEM!** Change to `{{ .Token }}`
- [ ] ❓ I don't know / Haven't checked - **GO CHECK NOW!**

**If you checked the ❌ box:** This is 100% your problem. Change it now!

---

### **2. Did you save the template after changing?**

- [ ] ✅ Yes, I clicked Save and saw confirmation
- [ ] ❌ No, I forgot to save
- [ ] ❓ I don't remember

**If ❌ or ❓:** Go back and save it!

---

### **3. Are you testing with the same email too quickly?**

**Last signup attempt was:**
- [ ] ✅ More than 60 seconds ago
- [ ] ❌ Less than 60 seconds ago - **Wait and try again!**
- [ ] ✅ I'm using a different email address

---

### **4. Did you check the spam folder?**

- [ ] ✅ Yes, checked spam - email is there
- [ ] ✅ Yes, checked spam - email NOT there
- [ ] ❌ Haven't checked spam yet - **Check it now!**

---

### **5. Is the email actually being sent?**

**Check Xcode console logs for:**
```
📧 Sending OTP email to: your-email@test.com
✅ OTP email sent successfully
```

- [ ] ✅ I see "OTP email sent successfully"
- [ ] ❌ I see "Error sending OTP email"
- [ ] ❓ I don't know how to check

**If ❌:** The email isn't being sent. Check rate limit or Supabase settings.

---

### **6. What does the email actually show?**

**In the email, I see:**
- [ ] Header with "Synapse" logo ✅
- [ ] Text "YOUR VERIFICATION CODE" ✅
- [ ] **A NUMBER (like 1234 or 123456)** ← **THE IMPORTANT PART!**
- [ ] Footer with "Thank you for choosing Synapse" ✅

**If you DON'T see a number:**
- The template still has `{{ .OTP }}` instead of `{{ .Token }}`
- Go back to Supabase and fix it!

---

## 🎯 **Most Common Issue (99% of cases):**

**You updated the template FILE in your project, but NOT in Supabase Dashboard!**

The files I created (`CORRECTED_EMAIL_TEMPLATE.html`) are just REFERENCE files.
You need to actually UPDATE the template in Supabase!

```
❌ WRONG:
   "I have CORRECTED_EMAIL_TEMPLATE.html in my project"
   → This doesn't do anything!

✅ CORRECT:
   "I logged into Supabase Dashboard and changed the template there"
   → This is what actually works!
```

---

## 🚀 **Quick Fix Right Now:**

1. **Open two windows:**
   - Window 1: Supabase Dashboard (https://app.supabase.com)
   - Window 2: Your project folder with `CORRECTED_EMAIL_TEMPLATE.html`

2. **In Supabase:**
   - Go to Authentication → Email Templates → Confirm signup
   - Click in the HTML editor

3. **Copy from your file:**
   - Open `CORRECTED_EMAIL_TEMPLATE.html`
   - Select ALL (Cmd+A)
   - Copy (Cmd+C)

4. **Paste into Supabase:**
   - Select ALL in Supabase editor (Cmd+A)
   - Paste (Cmd+V)
   - Scroll down and click **SAVE**

5. **Test:**
   - Wait 60 seconds
   - Sign up with NEW email
   - Check inbox
   - Should see OTP code!

---

## 📊 **Verification:**

**After you update and save, test with these steps:**

1. Open Supabase Dashboard
2. Go to Authentication → Email Templates → Confirm signup
3. Look for this line: `<div class="otp-code">`
4. What comes next?

**✅ Correct:**
```html
<div class="otp-code">{{ .Token }}</div>
```

**❌ Wrong:**
```html
<div class="otp-code">{{ .OTP }}</div>
```

---

## 💡 **Understanding:**

```
Your App (Swift code)
  ↓
  Calls: supabase.auth.signUp()
  ↓
Supabase Server
  ↓
  Generates: Random OTP code (e.g., "1234")
  ↓
  Loads: Email template from YOUR Supabase Dashboard
  ↓
  Replaces: {{ .Token }} with "1234"
  ↓
  Sends: Email to user
```

**The template in Supabase Dashboard is what gets used!**
**NOT the files in your Xcode project!**

---

## ✅ **Final Answer:**

**Question:** "Is the app generating OTP?"
**Answer:** YES! Supabase generates it automatically.

**Question:** "Is the app sending email?"
**Answer:** YES! Supabase sends it automatically.

**Question:** "Why is OTP blank in email?"
**Answer:** The **Supabase email template** still has wrong variable.

**Solution:** Update template in **Supabase Dashboard** to use `{{ .Token }}`

---

**The app is perfect. The Supabase template needs fixing! 🎯**
