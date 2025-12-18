# 📧 Fix: "Email rate limit exceeded"

## Error Message:
```
Email rate limit exceeded
```

---

## 🚨 What This Means:

You've hit Supabase's **email sending limit**. This is different from signup rate limits - this is about how many emails Supabase can send.

---

## 📊 Supabase Email Limits

### **Free Tier (Using Supabase's Default SMTP):**
- ⚠️ **~30 emails per hour** (very limited!)
- ⚠️ **~100-200 emails per day**
- ⚠️ Shared with all free tier users
- ⚠️ Unreliable for production

### **Paid Tier:**
- ✅ Higher limits but still restricted
- ✅ Better but not unlimited

---

## ✅ SOLUTIONS (From Best to Worst)

### **Solution 1: Use Custom SMTP** (BEST - Recommended!)

Stop using Supabase's default email service. Use a professional email service instead:

#### **Option A: SendGrid (FREE - 100 emails/day)**

1. **Sign up at SendGrid:**
   - Go to https://signup.sendgrid.com
   - Choose FREE plan (100 emails/day)

2. **Create API Key:**
   - Settings → API Keys → Create API Key
   - Name: "Synapse Production"
   - Permission: Full Access
   - Copy the API key (save it!)

3. **Configure in Supabase:**
   - Supabase Dashboard → Project Settings → Auth
   - Scroll to **SMTP Settings**
   - Click "Enable Custom SMTP" ✅
   - Fill in:
     ```
     SMTP Host: smtp.sendgrid.net
     SMTP Port: 587
     SMTP User: apikey
     SMTP Password: [Your SendGrid API Key]
     Sender Email: noreply@yourdomain.com
     Sender Name: Synapse
     ```
   - Click **Save**

4. **Verify Sender Email in SendGrid:**
   - SendGrid → Settings → Sender Authentication
   - Verify a Single Sender
   - Add: noreply@yourdomain.com
   - Check email and verify

5. **Test:**
   - Try signup again
   - Email should arrive ✅

**Benefits:**
- ✅ 100 emails/day FREE (vs 30/hour with Supabase)
- ✅ Better deliverability
- ✅ No rate limit errors
- ✅ Professional sender address
- ✅ Email analytics

---

#### **Option B: Gmail SMTP (Quick & Easy)**

1. **Enable 2FA on Gmail:**
   - Google Account → Security → 2-Step Verification

2. **Create App Password:**
   - Google Account → Security → App passwords
   - Select "Mail" and "Other (Custom name)"
   - Name: "Synapse App"
   - Copy 16-character password

3. **Configure in Supabase:**
   ```
   SMTP Host: smtp.gmail.com
   SMTP Port: 587
   SMTP User: your-email@gmail.com
   SMTP Password: [16-character app password]
   Sender Email: your-email@gmail.com
   Sender Name: Synapse
   Enable Custom SMTP: ✅
   ```

**Limits:**
- ✅ 500 emails/day FREE
- ❌ Shows Gmail sender address (not professional)

---

#### **Option C: AWS SES (Most Professional)**

1. **Sign up for AWS:**
   - https://aws.amazon.com/ses/

2. **Verify sender email/domain**

3. **Get SMTP credentials:**
   - AWS Console → SES → SMTP Settings
   - Create SMTP Credentials

4. **Configure in Supabase:**
   ```
   SMTP Host: email-smtp.us-east-1.amazonaws.com
   SMTP Port: 587
   SMTP User: [Your AWS SMTP username]
   SMTP Password: [Your AWS SMTP password]
   Sender Email: noreply@yourdomain.com
   Sender Name: Synapse
   ```

**Benefits:**
- ✅ FREE 62,000 emails/month
- ✅ Most reliable
- ✅ Professional
- ❌ Slightly more complex setup

---

### **Solution 2: Wait and Retry** (TEMPORARY FIX)

If you're just testing and can't set up custom SMTP right now:

1. **Wait 1 hour** - Supabase email limit resets
2. **Use sparingly** - Only test when necessary
3. **Set up custom SMTP soon** - This will keep happening

---

### **Solution 3: Upgrade Supabase Plan** (NOT RECOMMENDED)

- Even paid Supabase plans have email limits
- Custom SMTP is still better and cheaper
- Not recommended - use SendGrid instead

---

## 🎯 Step-by-Step: Setup SendGrid (Recommended)

### **Why SendGrid?**
- ✅ Completely FREE (100 emails/day)
- ✅ Takes 10 minutes to setup
- ✅ Solves rate limit issues permanently
- ✅ Better email deliverability
- ✅ Professional

### **Complete Setup:**

#### **1. Create SendGrid Account (2 minutes)**
```
1. Go to https://signup.sendgrid.com
2. Sign up with your email
3. Verify your email address
4. Choose FREE plan (100 emails/day)
```

#### **2. Create API Key (1 minute)**
```
1. Login to SendGrid
2. Settings (left sidebar) → API Keys
3. Click "Create API Key"
4. Name: "Synapse Production"
5. Permissions: "Full Access"
6. Click "Create & View"
7. COPY THE KEY (you won't see it again!)
```

#### **3. Configure Supabase (2 minutes)**
```
1. Supabase Dashboard → Your Synapse project
2. Project Settings → Auth → SMTP Settings
3. Enable Custom SMTP: ✅
4. Fill in:
   - Host: smtp.sendgrid.net
   - Port: 587
   - User: apikey (literally the word "apikey")
   - Password: [Paste your SendGrid API key]
   - Sender: noreply@yourdomain.com
   - Name: Synapse
5. Click Save
```

#### **4. Verify Sender (2 minutes)**
```
1. Back to SendGrid
2. Settings → Sender Authentication
3. Click "Verify a Single Sender"
4. Fill in form:
   - From Email: noreply@yourdomain.com
   - From Name: Synapse
   - Reply To: (your support email)
   - Address, City, etc. (required)
5. Submit
6. Check email and click verification link
```

#### **5. Test (30 seconds)**
```
1. Try signup in your app
2. Email should arrive within seconds ✅
3. No more rate limit errors! 🎉
```

**Total Time: ~10 minutes**

---

## 📊 Comparison: Supabase vs Custom SMTP

| Feature | Supabase Default | SendGrid (Free) |
|---------|------------------|-----------------|
| **Emails/day** | ~100-200 | 100 ✅ |
| **Emails/hour** | ~30 ❌ | No hourly limit ✅ |
| **Rate limits** | Frequent ❌ | Rare ✅ |
| **Deliverability** | Poor ❌ | Excellent ✅ |
| **Sender address** | Generic ❌ | Your domain ✅ |
| **Analytics** | No ❌ | Yes ✅ |
| **Cost** | Free | Free ✅ |
| **Setup time** | 0 min | 10 min |

**Winner: SendGrid** 🏆

---

## 🆘 Quick Fix RIGHT NOW

### **If you need to test immediately:**

1. **Wait 1 hour** (Supabase email limit resets)
2. **Or use different email** (each email has separate limit)
3. **Or switch networks** (different IP might help)

### **Then set up SendGrid:**
Follow the step-by-step guide above - takes 10 minutes, solves the problem forever.

---

## 🔍 How to Check Email Usage

### **In Supabase Dashboard:**

1. Go to **Logs** → **Auth Logs**
2. Filter by last 24 hours
3. Look for `email.sent` and `email.failed` events
4. Count how many emails sent

### **In SQL Editor:**

```sql
-- Check recent email sending activity
SELECT
    created_at,
    event_type,
    event_message
FROM auth.audit_log_entries
WHERE event_type LIKE '%email%'
ORDER BY created_at DESC
LIMIT 50;
```

---

## ⚠️ Common Mistakes to Avoid

### **Mistake 1: Testing signup repeatedly**
- Each signup = 1 email sent
- Hits rate limit quickly
- Solution: Use SendGrid

### **Mistake 2: Not verifying sender email**
- SendGrid requires sender verification
- Emails won't send without it
- Solution: Check email and verify

### **Mistake 3: Using wrong SMTP credentials**
- SMTP User must be: `apikey` (not your email)
- SMTP Password must be: Your SendGrid API key
- Solution: Double-check settings

### **Mistake 4: Relying on Supabase default email**
- Only good for initial testing
- Not suitable for production
- Solution: Set up custom SMTP immediately

---

## 📝 Summary

### **Problem:**
```
Email rate limit exceeded
```

### **Root Cause:**
- Using Supabase's default SMTP
- Limited to ~30 emails/hour
- Shared with all free tier users

### **Best Solution:**
1. Sign up for SendGrid (FREE)
2. Create API key
3. Configure in Supabase SMTP settings
4. Verify sender email
5. Never hit email limits again ✅

### **Time Investment:**
- 10 minutes setup
- Saves hours of frustration
- Professional email delivery
- No more rate limit errors

---

## 🎯 Recommended Action RIGHT NOW:

**Step 1:** Sign up at https://signup.sendgrid.com

**Step 2:** Create API key

**Step 3:** Configure in Supabase → Project Settings → Auth → SMTP Settings

**Step 4:** Verify sender email in SendGrid

**Step 5:** Test signup - should work perfectly! ✅

**This is the ONLY permanent solution.** 🚀

---

## 📚 Additional Resources

- SendGrid Free Plan: https://sendgrid.com/pricing/
- SendGrid Setup Guide: https://docs.sendgrid.com/for-developers/sending-email/integrations
- Supabase SMTP Docs: https://supabase.com/docs/guides/auth/auth-smtp

For detailed spam-free email template, see: `SPAM_FREE_EMAIL_TEMPLATE.html`
