# Password Reset Configuration Guide

## Current Issue
The password reset email contains a link that doesn't properly redirect users back to the mobile app.

## Best Practices for Mobile Apps

You have **three main options** for handling password reset in your iOS app:

---

## ✅ **Option 1: Web-Based Reset Page (RECOMMENDED - Easiest)**

### How it works:
1. User requests password reset from app
2. Supabase sends email with link to your website: `https://yourdomain.com/auth/reset-password?token=xxx`
3. User clicks link → opens in browser
4. Your web page shows a password reset form
5. User enters new password
6. Web page calls Supabase API to update password
7. Shows success message with "Open App" button

### Setup Required:

#### 1. Update Supabase Dashboard
Go to: **Supabase Dashboard → Authentication → URL Configuration**
- **Site URL**: `https://yourdomain.com`
- **Redirect URLs**: Add `https://yourdomain.com/auth/reset-password`

#### 2. Create Simple Reset Password Web Page
Host this HTML page at `https://yourdomain.com/auth/reset-password`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Reset Password - Synapse</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #E8F5F0 0%, #F0FFF4 100%);
            padding: 20px;
            margin: 0;
        }
        .container {
            max-width: 400px;
            margin: 50px auto;
            background: white;
            padding: 30px;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        h1 {
            color: #3D9970;
            margin-bottom: 20px;
        }
        input {
            width: 100%;
            padding: 12px;
            margin: 10px 0;
            border: 1.5px solid #E5E5E5;
            border-radius: 8px;
            font-size: 16px;
            box-sizing: border-box;
        }
        button {
            width: 100%;
            padding: 14px;
            background: #3D9970;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 10px;
        }
        button:hover {
            background: #2D7556;
        }
        .success {
            color: #3D9970;
            background: #E8F5F0;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
        }
        .error {
            color: #E84A5F;
            background: #FFE5E9;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Reset Your Password</h1>
        <div id="form-container">
            <input type="password" id="password" placeholder="Enter new password" minlength="6">
            <input type="password" id="confirm-password" placeholder="Confirm new password">
            <button onclick="resetPassword()">Reset Password</button>
        </div>
        <div id="message"></div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
    <script>
        // Replace with your actual Supabase credentials
        const supabaseUrl = 'YOUR_SUPABASE_URL'
        const supabaseKey = 'YOUR_SUPABASE_ANON_KEY'
        const supabase = window.supabase.createClient(supabaseUrl, supabaseKey)

        async function resetPassword() {
            const password = document.getElementById('password').value
            const confirmPassword = document.getElementById('confirm-password').value
            const messageDiv = document.getElementById('message')

            if (password !== confirmPassword) {
                messageDiv.innerHTML = '<div class="error">Passwords do not match!</div>'
                return
            }

            if (password.length < 6) {
                messageDiv.innerHTML = '<div class="error">Password must be at least 6 characters!</div>'
                return
            }

            try {
                const { error } = await supabase.auth.updateUser({ password })

                if (error) throw error

                messageDiv.innerHTML = `
                    <div class="success">
                        <h3>✅ Password Reset Successful!</h3>
                        <p>You can now sign in with your new password.</p>
                        <button onclick="window.location.href='synapse://'">Open Synapse App</button>
                    </div>
                `
                document.getElementById('form-container').style.display = 'none'
            } catch (error) {
                messageDiv.innerHTML = `<div class="error">Error: ${error.message}</div>`
            }
        }
    </script>
</body>
</html>
```

#### 3. Update SupabaseManager.swift
Change the redirect URL to your domain:
```swift
let redirectURL = URL(string: "https://yourdomain.com/auth/reset-password")!
```

**Pros**:
- ✅ Simple to implement
- ✅ Works on all platforms
- ✅ No app changes needed
- ✅ Easy to test and debug

**Cons**:
- ❌ Requires web hosting
- ❌ User has to type password on web (not in app)

---

## Option 2: Deep Link to App (More Native)

### How it works:
1. User requests password reset
2. Email contains: `synapse://reset-password?token=xxx`
3. User clicks link → opens app directly
4. App shows password reset screen
5. User enters new password in the app

### Setup Required:

#### 1. Configure URL Scheme in Xcode
1. Open `Synapse.xcodeproj`
2. Select target → Info tab
3. Add URL Type:
   - Identifier: `com.yourcompany.synapse`
   - URL Schemes: `synapse`

#### 2. Update Supabase Dashboard
- **Redirect URLs**: Add `synapse://reset-password`

#### 3. Handle Deep Link in App
Add to `SynapseApp.swift`:
```swift
.onOpenURL { url in
    if url.scheme == "synapse" && url.host == "reset-password" {
        // Extract token and show reset password screen
        if let token = url.queryParameters?["token"] {
            // Show reset password view
        }
    }
}
```

#### 4. Create Reset Password View
Create new view to handle password update with token.

**Pros**:
- ✅ Fully native experience
- ✅ Password reset inside app
- ✅ No web hosting needed

**Cons**:
- ❌ More complex implementation
- ❌ Requires app code changes
- ❌ iOS only (need separate Android implementation)

---

## Option 3: Universal Links (Most Professional)

Similar to deep links but uses actual HTTPS URLs that work on web AND open app.

### Setup Required:
1. Host `apple-app-site-association` file on your domain
2. Configure Associated Domains in Xcode
3. Implement Universal Link handling

**Pros**:
- ✅ Most professional solution
- ✅ Works even if app not installed
- ✅ SEO friendly

**Cons**:
- ❌ Most complex setup
- ❌ Requires domain verification
- ❌ Requires web hosting

---

## 🎯 Recommendation

For **Synapse**, I recommend **Option 1** (Web-Based Reset) because:
1. ✅ Quickest to implement
2. ✅ Works immediately
3. ✅ Easy to test and debug
4. ✅ Professional appearance
5. ✅ Can upgrade to deep links later

## Quick Start

1. **Host the HTML page** at your domain
2. **Update Supabase Dashboard** redirect URLs
3. **Replace `yourdomain.com`** in SupabaseManager.swift
4. **Test** by requesting password reset!

---

## Testing

1. Trigger password reset from app
2. Check email
3. Click link
4. Should open your web page
5. Enter new password
6. Should see success message
7. Return to app and sign in with new password

---

## Troubleshooting

**Link shows Supabase error page**:
- Check redirect URL is added in Supabase Dashboard
- Verify URL in email matches your configured URL

**Web page doesn't work**:
- Check Supabase credentials in HTML
- Open browser console for errors
- Verify token is in URL parameters

**"Open App" button doesn't work**:
- Add URL scheme to Xcode (see Option 2)
- Or link to App Store instead
