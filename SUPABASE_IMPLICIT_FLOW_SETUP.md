# Supabase: Enable Implicit Flow for Password Reset

## Problem
PKCE flow doesn't work for web-based password reset because web browsers don't have access to the `code_verifier`.

## Solution
Configure Supabase to use **Implicit Flow** for password reset emails, which sends tokens directly in the URL hash.

---

## Step-by-Step Setup

### 1. Go to Supabase Dashboard

1. Open: https://supabase.com/dashboard
2. Select your **Synapse** project
3. Navigate to: **Authentication** → **URL Configuration**

### 2. Add Redirect URL

In the **Redirect URLs** section, add:
```
https://usynapse.com/reset-password
```

Click **Save**.

### 3. Disable PKCE for Password Reset (Option A - Recommended)

**Note**: Supabase doesn't have a UI toggle for this. You need to use the API:

```bash
curl -X PATCH 'https://oocegnwdfnnjgoworrwh.supabase.co/auth/v1/admin/config' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "SECURITY_UPDATE_PASSWORD_REQUIRE_REAUTHENTICATION": false
  }'
```

**OR** continue with Option B below.

### 4. Update Email Template (Option B - Easier)

Go to: **Authentication** → **Email Templates** → **Change Email**

Find the password reset template and update the link to use `{{ .RedirectTo }}` with explicit hash parameters:

**Old template:**
```html
<a href="{{ .ConfirmationURL }}">Reset Password</a>
```

**New template:**
```html
<a href="{{ .RedirectTo }}#access_token={{ .Token }}&type=recovery">Reset Password</a>
```

This forces the token to be in the hash instead of using PKCE.

---

## Alternative: Use Supabase CLI

If you have Supabase CLI installed:

```bash
# Install CLI if needed
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref oocegnwdfnnjgoworrwh

# Update config
supabase functions config set SECURITY_UPDATE_PASSWORD_REQUIRE_REAUTHENTICATION=false
```

---

## Verify the Setup

### Test the Flow:

1. **Request password reset** from your app
2. **Check the email** you receive
3. **Inspect the reset link** - it should look like:

**With PKCE (doesn't work on web):**
```
https://usynapse.com/reset-password?code=abc123xyz
```

**With Implicit Flow (works everywhere!):**
```
https://usynapse.com/reset-password#access_token=eyJhbGc...&refresh_token=abc...&type=recovery
```

4. **Click the link** - should open web form to reset password

---

## Important Security Notes

### PKCE vs Implicit Flow

**PKCE (Current):**
- ✅ More secure (code can only be used once with verifier)
- ✅ Recommended for mobile apps
- ❌ Doesn't work on web browsers
- ❌ Requires app to be installed

**Implicit Flow (Recommended for Web):**
- ✅ Works on all browsers (desktop + mobile)
- ✅ No app installation required
- ✅ Tokens in URL hash (not sent to server)
- ⚠️ Less secure (tokens visible in URL)
- ⚠️ Tokens can be captured via browser history

### Best Practice Recommendation

**Use BOTH flows:**
- **For mobile app deep links**: Keep PKCE (`synapse://`)
- **For web reset pages**: Use Implicit Flow (`https://`)

**How to implement:**

```swift
// In SupabaseManager.swift
func resetPassword(email: String, useWebFlow: Bool = true) async throws {
    let redirectURL: URL

    if useWebFlow {
        // Web-based reset (works everywhere)
        redirectURL = URL(string: "https://usynapse.com/reset-password")!
    } else {
        // App-based reset (mobile only, more secure)
        redirectURL = URL(string: "synapse://reset-password")!
    }

    try await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectURL
    )
}
```

---

## Update Your App Code

### Option 1: Use Web Flow Only (Simplest)

Already done! Your current code uses:
```swift
let redirectURL = URL(string: "https://usynapse.com/reset-password")!
```

Just make sure the web page is uploaded.

### Option 2: Let User Choose

Add a toggle in the forgot password screen:

```swift
struct ForgotPasswordView: View {
    @State private var useWebReset = true

    var body: some View {
        VStack {
            // ... email field ...

            Toggle("Reset in browser", isOn: $useWebReset)
                .padding()

            Button("Send Reset Link") {
                resetPassword(useWeb: useWebReset)
            }
        }
    }
}
```

---

## Upload Web Page

Upload `reset-password-universal.html` to your web server:

**Location:** `https://usynapse.com/reset-password.html`

The page will:
- ✅ Work with implicit flow (hash tokens)
- ✅ Detect PKCE code and show "use mobile app" message
- ✅ Real-time password validation
- ✅ Beautiful, responsive design
- ✅ Works on all devices

---

## Testing Checklist

- [ ] Update Supabase redirect URL
- [ ] Configure email template or disable PKCE reauthentication
- [ ] Upload reset-password-universal.html to web server
- [ ] Test: Request password reset from app
- [ ] Test: Open email on desktop browser
- [ ] Test: Click reset link → Should show web form
- [ ] Test: Enter new password → Should succeed
- [ ] Test: Open email on mobile browser
- [ ] Test: Should work the same way

---

## Troubleshooting

### Link shows "Invalid Link"

**Check:**
- Is the URL using hash parameters? (`#access_token=...`)
- Or is it using query parameters? (`?code=...`)

If using `?code=...`, PKCE is still enabled. Go back to email template setup.

### "Session not established" error

**Check:**
- Open browser console (F12)
- Look for errors in the console
- Verify tokens are in URL hash
- Check if Supabase credentials are correct in HTML file

### Link expires immediately

**Possible causes:**
- Tokens have default expiry (usually 1 hour)
- User clicked old link
- Request new reset link

---

## Summary

**To make web-based password reset work:**

1. Configure Supabase to use Implicit Flow
2. Upload reset-password-universal.html to your server
3. Test on both desktop and mobile browsers

**Benefits:**
- ✅ Works on ANY browser (desktop, mobile, tablet)
- ✅ No app installation required
- ✅ Same UX as Gmail, Facebook, etc.
- ✅ Users can reset password from any device

**Trade-off:**
- ⚠️ Slightly less secure than PKCE (but still industry standard)
- ⚠️ Tokens visible in URL (but in hash, not sent to server)

This is the **standard approach** used by most web applications!
