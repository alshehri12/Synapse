# 🔧 Supabase OTP Configuration Guide

## 🎯 **Goal: Configure Supabase to Send 6-Digit OTP Codes Instead of Email Links**

### **Current Issue**
- Supabase sends email verification links by default
- You want 6-digit OTP codes instead
- Your app already has OTP verification UI ready

---

## 📧 **Step 1: Configure Supabase Email Templates**

### **1.1 Access Supabase Dashboard**
1. Go to: https://app.supabase.com
2. Select your project: `https://oocegnwdfnnjgoworrwh.supabase.co`
3. Navigate to: **Authentication** → **Email Templates**

### **1.2 Update "Confirm Signup" Template**

**Replace the default template with this OTP template:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Your Email - Synapse</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8f9fa;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            color: #10b981;
            margin-bottom: 10px;
        }
        .otp-code {
            background: #f3f4f6;
            border: 2px solid #10b981;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            margin: 30px 0;
        }
        .otp-digits {
            font-size: 36px;
            font-weight: bold;
            color: #10b981;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
        }
        .instructions {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #6b7280;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🧠 Synapse</div>
            <h1>Verify Your Email Address</h1>
        </div>
        
        <p>Welcome to Synapse! To complete your account setup, please enter the verification code below in the app:</p>
        
        <div class="otp-code">
            <div class="otp-digits">{{ .Token }}</div>
        </div>
        
        <div class="instructions">
            <strong>Instructions:</strong>
            <ul>
                <li>Open the Synapse app</li>
                <li>Enter the 6-digit code above</li>
                <li>This code expires in 15 minutes</li>
            </ul>
        </div>
        
        <p>If you didn't create an account with Synapse, you can safely ignore this email.</p>
        
        <div class="footer">
            <p>This email was sent from Synapse App</p>
            <p>© 2025 Synapse. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
```

### **1.3 Update Subject Line**
Change the subject line to:
```
Verify Your Synapse Account - Code: {{ .Token }}
```

---

## ⚙️ **Step 2: Configure Supabase Auth Settings**

### **2.1 Disable Email Confirmation Redirect**
1. Go to: **Authentication** → **Settings**
2. Find **"Email confirmation"** section
3. **Uncheck** "Enable email confirmations" (temporarily)
4. Or set **"Site URL"** to your app's deep link scheme

### **2.2 Configure SMTP (Optional but Recommended)**
1. Go to: **Authentication** → **SMTP Settings**
2. Enable **"Enable custom SMTP"**
3. Configure with your email provider:
   - **Host**: `smtp.resend.com` (or your provider)
   - **Port**: `587`
   - **Username**: `resend` (or your username)
   - **Password**: Your API key
   - **Sender email**: `no-reply@mysynapses.com`
   - **Sender name**: `Synapse App`

---

## 🧪 **Step 3: Test the Configuration**

### **3.1 Test Email Template**
1. Save the template in Supabase
2. Try creating a new account
3. Check if you receive an email with 6-digit code
4. Verify the code works in your app

### **3.2 Expected Behavior**
- ✅ User creates account
- ✅ Receives email with 6-digit code (not link)
- ✅ Enters code in app
- ✅ Account gets verified
- ✅ Can sign in successfully

---

## 🔄 **Step 4: Update Your App Flow**

### **4.1 Current Flow (After This Configuration)**
1. User fills signup form
2. App calls `signUp()` method
3. Supabase sends OTP email automatically
4. User sees OTP verification screen
5. User enters 6-digit code
6. App calls `verifyOtp()` method
7. Account is verified and user can sign in

### **4.2 No Changes Needed in Your App Code**
Your existing code already handles this flow correctly!

---

## 🚨 **Important Notes**

### **Template Variables**
- `{{ .Token }}` - The 6-digit OTP code
- `{{ .Email }}` - User's email address
- `{{ .SiteURL }}` - Your site URL

### **Security**
- OTP codes expire in 15 minutes by default
- Codes are single-use
- Failed attempts are rate-limited

### **Fallback**
If OTP doesn't work, you can:
1. Re-enable email confirmations in Supabase
2. Use the link-based verification temporarily
3. Debug the SMTP configuration

---

## ✅ **Verification Checklist**

- [ ] Email template updated with OTP format
- [ ] Subject line includes the code
- [ ] SMTP configured (optional)
- [ ] Test account creation
- [ ] Verify OTP email received
- [ ] Test OTP verification in app
- [ ] Confirm user can sign in after verification

---

## 🆘 **Troubleshooting**

### **If emails don't arrive:**
1. Check spam folder
2. Verify SMTP configuration
3. Test with default Supabase email first
4. Check Supabase logs

### **If OTP doesn't work:**
1. Verify template uses `{{ .Token }}`
2. Check app's OTP verification method
3. Ensure code is 6 digits
4. Check for typos in email/OTP

### **If user can't sign in:**
1. Verify account is actually verified
2. Check Supabase user status
3. Ensure email confirmation is disabled
4. Test with fresh account

---

**This configuration will make Supabase send 6-digit OTP codes instead of verification links!** 🎉
