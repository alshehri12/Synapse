# 📧 Fix: Email Rate Limit with Postmark

## Your Setup:
✅ You're using **Postmark** (excellent choice!)
❌ But still getting "Email rate limit exceeded" error

---

## 🔍 Why This Happens with Postmark:

Even though you configured Postmark SMTP in Supabase, you might be hitting limits due to:

1. **Postmark account limits** (Free tier has limits)
2. **Sender signature not verified** in Postmark
3. **Supabase still using default email** (SMTP not properly configured)
4. **Postmark sandbox mode** (testing environment)
5. **Monthly send limit reached**

---

## ✅ DIAGNOSTIC STEPS

### **Step 1: Verify Postmark is Actually Being Used**

1. **Check Supabase SMTP Settings:**
   - Supabase Dashboard → Project Settings → Auth
   - Scroll to **SMTP Settings**
   - Verify:
     ```
     ✅ Enable Custom SMTP: Checked
     ✅ SMTP Host: smtp.postmarkapp.com
     ✅ SMTP Port: 587 (or 2525)
     ✅ SMTP User: [Your Postmark Server API Token]
     ✅ SMTP Password: [Your Postmark Server API Token]
     ✅ Sender Email: [Your verified sender]
     ```

2. **If ANY of these are wrong, Supabase is NOT using Postmark!**
   - It's falling back to Supabase default SMTP
   - That's why you're hitting rate limits

---

### **Step 2: Check Postmark Account Status**

1. **Login to Postmark:** https://account.postmarkapp.com

2. **Check Activity:**
   - Go to **Activity** tab
   - See if emails are showing up there
   - If YES → Postmark is working
   - If NO → Supabase is not using Postmark

3. **Check Account Limits:**
   - Go to **Account Settings**
   - Check your plan:
     ```
     Free Trial: 100 emails total (one-time)
     Developer: 10,000 emails/month for $15
     ```

4. **Check if you hit limit:**
   - Look for warning messages
   - Check "Credits remaining" or "Emails sent this month"

---

### **Step 3: Verify Sender Signature**

1. **In Postmark Dashboard:**
   - Go to **Sender Signatures**
   - Find your sender email (e.g., noreply@yourdomain.com)
   - Status should be: ✅ **VERIFIED**

2. **If NOT verified:**
   - Click "Verify" or "Resend verification"
   - Check your email inbox
   - Click verification link
   - Wait 2-3 minutes

3. **If not added yet:**
   - Click **Add Sender Signature**
   - Enter: noreply@yourdomain.com
   - Verify via email

---

## 🔧 FIX: Proper Postmark Configuration in Supabase

### **Get Your Postmark Credentials:**

1. **Login to Postmark:** https://account.postmarkapp.com

2. **Select your Server** (or create one):
   - Servers → Select "Default Transactional Server" (or your server)

3. **Get Server API Token:**
   - Click on your server name
   - Go to **API Tokens** tab
   - Copy the **Server API Token** (looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
   - This is used for BOTH username AND password in Supabase

4. **Verify Sender Signature:**
   - Go to **Sender Signatures** tab
   - Add: `noreply@yourdomain.com` (or your domain)
   - Verify via email
   - Wait until status shows ✅ VERIFIED

---

### **Configure Supabase with Postmark:**

1. **Go to Supabase Dashboard** → Your Synapse project

2. **Navigate to:**
   ```
   Project Settings → Auth → SMTP Settings
   ```

3. **Enable Custom SMTP** ✅

4. **Fill in EXACTLY like this:**
   ```
   Enable Custom SMTP: ✅ (checked)

   SMTP Host: smtp.postmarkapp.com

   SMTP Port: 587
   (Alternative: 2525 if 587 is blocked)

   SMTP User: [Your Postmark Server API Token]
   (Example: 12345678-1234-1234-1234-123456789abc)

   SMTP Password: [Same Postmark Server API Token]
   (Yes, same as username!)

   Sender Email: noreply@yourdomain.com
   (MUST be verified in Postmark!)

   Sender Name: Synapse
   ```

5. **Click Save**

6. **Wait 2-3 minutes** for changes to take effect

---

## 🎯 Common Postmark Issues & Fixes

### **Issue 1: "SMTP authentication failed"**

**Cause:** Wrong API token or not using Server API Token

**Fix:**
1. Go to Postmark → Servers → Your Server
2. Go to **API Tokens** tab (not Account API Tokens!)
3. Copy **Server API Token**
4. Use this for BOTH username AND password in Supabase

---

### **Issue 2: "Sender signature not verified"**

**Cause:** Sender email not verified in Postmark

**Fix:**
1. Postmark → Sender Signatures
2. Add your sender email
3. Check email inbox
4. Click verification link
5. Wait 2-3 minutes
6. Try sending again

---

### **Issue 3: "Email rate limit exceeded" (still!)

**Cause:** Supabase is NOT using Postmark - falling back to default

**Fix:**
1. Double-check SMTP settings in Supabase
2. Make sure "Enable Custom SMTP" is ✅ checked
3. Verify SMTP Host is: `smtp.postmarkapp.com`
4. Save settings
5. Wait 5 minutes
6. Try again

---

### **Issue 4: "Monthly limit reached"**

**Cause:** Postmark free trial (100 emails) used up

**Fix:**
1. Check Postmark dashboard for usage
2. Upgrade to paid plan:
   - Developer: $15/month for 10,000 emails
   - Or use SendGrid free tier (100/day)

---

## 📊 Postmark vs Supabase Default

| Feature | Supabase Default | Postmark |
|---------|------------------|----------|
| **Emails/month** | ~3,000 | 10,000+ ✅ |
| **Emails/hour** | ~30 ❌ | No limit ✅ |
| **Deliverability** | Poor ❌ | Excellent ✅ |
| **Spam rate** | High ❌ | Very low ✅ |
| **Cost** | Free | $15/month |
| **Setup** | None | 10 minutes |

**Postmark is MUCH better!** 🏆

---

## 🧪 How to Test if Postmark is Working

### **Test 1: Check Supabase Logs**

1. Supabase Dashboard → Logs → Auth Logs
2. Filter: Last 1 hour
3. Look for email sending events
4. Check for SMTP errors

### **Test 2: Check Postmark Activity**

1. Login to Postmark
2. Go to **Activity** tab
3. Try signup in your app
4. **If email appears in Postmark Activity** → ✅ Working!
5. **If NOT** → ❌ Supabase not using Postmark

### **Test 3: Send Test Email**

1. Try signup with your email
2. Wait 1-2 minutes
3. Check:
   - ✅ Email inbox (should arrive)
   - ✅ Postmark Activity (should show in logs)
   - ✅ No rate limit error

---

## 🆘 Quick Troubleshooting Checklist

Run through this checklist:

- [ ] Postmark account is active and not suspended
- [ ] Server API Token copied correctly (not Account API Token!)
- [ ] Sender email verified in Postmark (✅ green checkmark)
- [ ] "Enable Custom SMTP" is ✅ CHECKED in Supabase
- [ ] SMTP Host is exactly: `smtp.postmarkapp.com`
- [ ] SMTP Port is: `587` or `2525`
- [ ] SMTP User = Server API Token
- [ ] SMTP Password = Same Server API Token
- [ ] Sender Email matches verified signature in Postmark
- [ ] Saved SMTP settings in Supabase
- [ ] Waited 2-3 minutes after saving
- [ ] Email appears in Postmark Activity when testing
- [ ] No monthly limit reached in Postmark

---

## 💡 Most Likely Issues

### **95% of the time it's one of these:**

1. ❌ **"Enable Custom SMTP" not checked** in Supabase
   - Supabase ignores SMTP settings if not enabled
   - Falls back to default email

2. ❌ **Sender email not verified** in Postmark
   - Postmark blocks emails from unverified senders
   - Check Sender Signatures tab

3. ❌ **Using Account API Token instead of Server API Token**
   - Account token doesn't work for SMTP
   - Must use Server API Token

4. ❌ **Postmark free trial used up**
   - Check usage in dashboard
   - Upgrade to paid plan if needed

---

## 🎯 Step-by-Step Fix RIGHT NOW

### **Do this in order:**

1. **Login to Postmark** → https://account.postmarkapp.com

2. **Go to Servers** → Select your server

3. **API Tokens tab** → Copy "Server API Token"

4. **Sender Signatures tab** → Verify status is ✅ VERIFIED
   - If not, verify it now

5. **Login to Supabase** → Your Synapse project

6. **Project Settings → Auth → SMTP Settings**

7. **Enable Custom SMTP: ✅ CHECK THIS BOX!**

8. **Fill in:**
   ```
   Host: smtp.postmarkapp.com
   Port: 587
   User: [Postmark Server API Token]
   Password: [Same Token]
   Sender: [Your verified email]
   Name: Synapse
   ```

9. **Click Save**

10. **Wait 5 minutes**

11. **Test signup** → Should work! ✅

---

## 📝 Summary

**Problem:** Email rate limit exceeded

**Cause:** Either:
- Supabase not actually using Postmark (check "Enable Custom SMTP")
- Postmark sender not verified
- Postmark free trial used up

**Solution:**
1. Verify Postmark sender signature ✅
2. Get Server API Token from Postmark
3. Enable Custom SMTP in Supabase ✅
4. Configure SMTP settings correctly
5. Save and test

**Expected Result:**
- ✅ Emails appear in Postmark Activity
- ✅ No rate limit errors
- ✅ Better deliverability
- ✅ Professional sender address

---

## 🚀 After Fix

Once working properly:
- Emails sent through Postmark (not Supabase)
- Can send up to 10,000/month (paid plan)
- Excellent deliverability to inbox
- Detailed analytics in Postmark dashboard
- No more rate limit errors!

If you're still having issues, let me know which step is failing! 💪
