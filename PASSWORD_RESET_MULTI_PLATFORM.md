# Password Reset: Multi-Platform Solution

## The Problem

When users click password reset links:
- **Mobile users**: Should open the app (deep link works)
- **Desktop users**: Can't open the app (deep link fails)

PKCE flow makes desktop web reset impossible because the web page doesn't have the `code_verifier`.

## Solutions

### **Option 1: Universal Link (Recommended) ⭐**

Use a **smart web page** that detects the platform and handles both cases:

#### Flow:
1. User clicks reset link → Opens `https://usynapse.com/reset-password?code=xxx`
2. Web page detects platform:
   - **Mobile** → Automatically redirects to `synapse://reset-password?code=xxx`
   - **Desktop** → Shows message: "Please open this link on your mobile device"

#### Setup:
```swift
// In SupabaseManager.swift
let redirectURL = URL(string: "https://usynapse.com/reset-password")!
```

#### Supabase Configuration:
- Add to Redirect URLs: `https://usynapse.com/reset-password`
- Upload `reset-password-smart.html` to your web server

#### Benefits:
- ✅ Works on all platforms
- ✅ Single redirect URL
- ✅ Better UX (auto-detects platform)
- ✅ Can show QR code for desktop users

---

### **Option 2: Disable PKCE for Password Reset**

Configure Supabase to use **implicit flow** (hash-based tokens) instead of PKCE for password reset emails.

#### How:
1. Go to Supabase Dashboard → Authentication → Settings
2. Look for PKCE or Flow settings
3. Disable PKCE for password reset emails (keep it for app sign-in)
4. Email will send: `https://usynapse.com/reset-password#access_token=xxx&refresh_token=xxx`

#### Benefits:
- ✅ Works on desktop browsers
- ✅ No platform detection needed
- ❌ Less secure than PKCE
- ❌ Tokens visible in URL

---

### **Option 3: Magic Link Alternative**

Instead of traditional password reset, use **magic link authentication**:

#### Flow:
1. User requests password reset
2. Receives email with magic link
3. Click link → Auto-signs in
4. App shows "Reset Your Password" screen
5. User enters new password while authenticated

#### Benefits:
- ✅ Works on all platforms
- ✅ More secure (no password in transit)
- ✅ Better UX (auto-login)
- ❌ Different flow than traditional reset

---

### **Option 4: Desktop-Specific Flow**

Provide a **different method** for desktop users:

#### Desktop Flow:
1. User opens reset link on desktop
2. Page shows: "Open the Synapse app on your mobile device"
3. In app: Settings → Reset Password
4. Enter email → Receive OTP code
5. Enter OTP + new password

#### Benefits:
- ✅ Secure (no web form needed)
- ✅ Works with PKCE
- ❌ More steps for user
- ❌ Requires app access

---

## Recommended Implementation

### **Use Option 1: Universal Link with Smart Detection**

Here's the complete setup:

#### 1. Update SupabaseManager.swift

```swift
@MainActor
func resetPassword(email: String) async throws {
    // Universal link that works on both mobile and desktop
    let redirectURL = URL(string: "https://usynapse.com/reset-password")!

    try await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectURL
    )
}
```

#### 2. Upload Smart Web Page

Upload `reset-password-smart.html` to `https://usynapse.com/reset-password.html`

The page will:
- **Mobile**: Auto-redirect to `synapse://reset-password?code=xxx`
- **Desktop**: Show friendly message with options

#### 3. Configure Supabase

Add these redirect URLs:
```
https://usynapse.com/reset-password
https://usynapse.com/reset-password.html
synapse://reset-password
```

#### 4. Update Info.plist (iOS Universal Links)

Add associated domains for seamless deep linking:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:usynapse.com</string>
</array>
```

Then create `apple-app-site-association` file on your server.

---

## Smart Web Page Features

The `reset-password-smart.html` includes:

### Mobile Detection:
```javascript
function isMobile() {
    return /iPhone|iPad|iPod|Android/i.test(navigator.userAgent)
}
```

### Auto-redirect on Mobile:
```javascript
if (isMobile()) {
    const deepLink = `synapse://reset-password?code=${code}`
    window.location.href = deepLink

    // Fallback if app not installed
    setTimeout(() => {
        showAppStoreLink()
    }, 3000)
}
```

### Desktop Message:
```javascript
else {
    showMessage("Please open this link on your mobile device where Synapse is installed")
}
```

---

## Platform-Specific UX

### Mobile (iOS/Android)
1. User clicks reset link in email
2. Browser opens briefly
3. **Automatic redirect** to Synapse app
4. App shows native ResetPasswordView
5. User enters new password
6. Success! ✅

### Desktop (Mac/Windows)
1. User clicks reset link in email
2. Web page opens
3. Shows friendly message:
   ```
   ⚠️ Please Open on Mobile

   To reset your password securely, please:
   1. Open this link on your mobile device
   2. Or forward this email to your phone
   3. Or scan the QR code below (if shown)
   ```
4. Optional: Show QR code for easy mobile access

---

## Advanced: QR Code for Desktop

Add QR code generation for desktop users:

```javascript
// On desktop, generate QR code with the reset URL
if (!isMobile()) {
    const qrCodeURL = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(window.location.href)}`

    showMessage(`
        <img src="${qrCodeURL}" alt="QR Code">
        <p>Scan with your phone to reset password</p>
    `)
}
```

---

## Testing

### Mobile Testing:
1. Request password reset in app
2. Open email on mobile device
3. Click "Reset My Password"
4. Should auto-open app
5. Reset password in app

### Desktop Testing:
1. Request password reset in app
2. Open email on desktop
3. Click "Reset My Password"
4. Should see "Open on Mobile" message
5. Forward email to phone or scan QR code

---

## Security Considerations

### Why PKCE Desktop Doesn't Work:
```
App                        Supabase
 |                             |
 |-- resetPasswordForEmail --->|
 |    (generates code_verifier)|
 |                             |
 |<---- Email with code --------|
 |                             |
User clicks link on DESKTOP    |
 |                             |
Desktop Browser               |
 |                             |
 |-- exchangeCodeForSession -->|
 |    ❌ NO code_verifier!    |
 |                             |
 |<---- ERROR -----------------|
```

### Why Mobile Works:
```
App                        Supabase
 |                             |
 |-- resetPasswordForEmail --->|
 |    (stores code_verifier)  |
 |                             |
 |<---- Email with code --------|
 |                             |
User clicks link → App opens   |
 |                             |
 |-- exchangeCodeForSession -->|
 |    ✅ Has code_verifier!   |
 |                             |
 |<---- Success! --------------|
```

---

## Summary

**Best Approach**: Universal link with smart platform detection

**Setup Steps**:
1. Update redirect URL to `https://usynapse.com/reset-password`
2. Upload smart HTML page to web server
3. Configure Supabase redirect URLs
4. Test on both mobile and desktop

**User Experience**:
- **Mobile**: Seamless app opening
- **Desktop**: Friendly guidance to use mobile

This provides the best security (PKCE) with the best UX across all platforms!
