# 📧 **Email Verification Testing Guide**

## 🎯 **Goal: Get `no-reply@mysynapses.com` working with Supabase**

### **Current Supabase Configuration**
- **URL**: `https://oocegnwdfnnjgoworrwh.supabase.co`
- **Email sender should be**: `no-reply@mysynapses.com`

---

## **Step 1: Check Current Email Settings**

1. **Go to Supabase Dashboard**: https://app.supabase.com
2. **Navigate to**: Project Settings → Auth → Email Templates
3. **Check current "Sender email"** - what does it show?

---

## **Step 2: Quick Email Test (Using Default Supabase)**

### **Temporarily use Supabase default email**
1. **Set sender email to**: `noreply@mail.app.supabase.io` (temporary)
2. **Save settings**
3. **Test app immediately**:
   - Create account
   - Check you receive verification email
   - Verify the email flow works

### **Expected Behavior**
- ✅ You receive email from `noreply@mail.app.supabase.io`
- ✅ Verification link works
- ✅ You can sign in after verification

---

## **Step 3: Configure Custom Domain Email**

### **Option A: Quick Setup with Resend**

1. **Sign up**: https://resend.com
2. **Add domain**: `mysynapses.com`
3. **Follow their verification steps**
4. **Get SMTP details**:
   ```
   Host: smtp.resend.com
   Port: 587
   Username: resend
   Password: [Your Resend API key]
   ```

5. **Configure in Supabase**:
   - Project Settings → Auth → SMTP Settings
   - Enable "Enable custom SMTP"
   - Fill in the details above
   - Sender email: `no-reply@mysynapses.com`

### **Option B: Use Existing Email Provider**

If you already have email hosting for `mysynapses.com`:

1. **Get SMTP settings** from your email provider
2. **Create email account**: `no-reply@mysynapses.com`
3. **Configure in Supabase** with your provider's SMTP details

---

## **Step 4: Test Custom Email**

1. **Change Supabase sender email** to `no-reply@mysynapses.com`
2. **Test the app again**:
   - Try creating a new account
   - Check verification email comes from your domain
   - Verify the link works

---

## **Step 5: Verification Checklist**

### **Email Delivery Test**
- [ ] Account creation sends verification email
- [ ] Email comes from `no-reply@mysynapses.com`
- [ ] Email doesn't go to spam folder
- [ ] Verification link works correctly
- [ ] Can sign in after verification

### **App Functionality Test**
- [ ] Authentication screen appears
- [ ] Can create account successfully
- [ ] Can sign in with verified account
- [ ] Main app interface loads
- [ ] Can create ideas
- [ ] Basic navigation works

---

## 🚀 **Quick Start Option**

### **Just want to test the app NOW?**

1. **Deploy database schema** (REQUIRED - copy `supabase_schema.sql` to Supabase SQL Editor)
2. **Keep default Supabase email** for now
3. **Test app functionality**
4. **Set up custom email later**

This gets you testing in 5 minutes while you work on email configuration.

---

## 📞 **Current Status Check**

Right now, we need to:

1. ✅ **Deploy database schema** - Critical first step
2. ✅ **Test basic email verification** - Even with default Supabase email
3. ✅ **Verify app compiles and runs** - Core functionality
4. ⚙️ **Set up custom email domain** - Production-ready feature

**Which step would you like to start with?**

The fastest path to a working app is:
**Deploy Schema → Test with Default Email → Upgrade to Custom Email**

Let me know if you want to start with the database schema deployment!
