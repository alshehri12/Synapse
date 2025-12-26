# Password Reset PKCE Flow Fix

## Problem Identified

The password reset was failing with "Invalid Link" error because:

1. **Supabase is using PKCE flow** (Proof Key for Code Exchange) instead of implicit flow
2. The reset page was expecting `access_token` and `refresh_token` in the URL hash
3. But Supabase was actually sending a `code` parameter in the query string: `?code=xxx`
4. The code needed to be **exchanged for a session** using `exchangeCodeForSession()`

## URL Comparison

### What we expected (Implicit Flow):
```
https://usynapse.com/reset-password.html#access_token=xxx&refresh_token=xxx&type=recovery
```

### What Supabase actually sends (PKCE Flow):
```
https://usynapse.com/reset-password.html?code=xxx
```

## The Fix

Updated [reset-password.html](web/reset-password.html) to handle **both flows**:

### PKCE Flow (Current):
```javascript
const code = queryParams.get('code')

if (code) {
    const { data, error } = await supabaseClient.auth.exchangeCodeForSession(code)
    // Session is now established
}
```

### Implicit Flow (Fallback):
```javascript
const accessToken = hashParams.get('access_token')
const refreshToken = hashParams.get('refresh_token')

if (accessToken && refreshToken) {
    const { data, error } = await supabaseClient.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken
    })
    // Session is now established
}
```

## Files Updated

1. ✅ [web/reset-password-FIXED.html](web/reset-password-FIXED.html) - Fixed version with PKCE support
2. ✅ [web/reset-password.html](web/reset-password.html) - Replaced with fixed version
3. ✅ [Synapse/Managers/SupabaseManager.swift:434](Synapse/Managers/SupabaseManager.swift#L434) - Changed back to reset-password.html
4. ✅ [web/debug-url.html](web/debug-url.html) - Created for debugging URL parameters

## Deployment Steps

### 1. Upload Fixed File to Web Server
Upload `web/reset-password.html` to your web server:
```bash
# Upload to: https://usynapse.com/reset-password.html
```

### 2. Verify Supabase Configuration
Go to Supabase Dashboard:
1. Open: https://supabase.com/dashboard
2. Select your Synapse project
3. Navigate to: **Authentication → URL Configuration**
4. Under **Redirect URLs**, ensure this is added:
   ```
   https://usynapse.com/reset-password.html
   ```
5. Click **Save**
6. Wait 2-3 minutes for changes to propagate

### 3. Clean Build & Test
In Xcode:
1. **Clean Build Folder**: `Cmd + Shift + K`
2. **Build**: `Cmd + B`
3. **Run** the app

### 4. Test the Flow
1. Open the app
2. Tap "Forgot Password?"
3. Enter your email
4. Tap "Send Reset Link"
5. Check your email
6. Click "Reset My Password"
7. **You should now see the password reset form** (not "Invalid Link")
8. Enter a new password
9. Submit and verify success message

## Why PKCE is Better

PKCE (Proof Key for Code Exchange) is more secure than the implicit flow:

- ✅ **More secure**: Code can only be exchanged once
- ✅ **Protection against interception**: Code is useless without the code verifier
- ✅ **Industry standard**: Recommended by OAuth 2.0 best practices
- ✅ **One-time use**: Code expires after exchange

## Technical Details

### PKCE Flow Sequence:
1. User requests password reset
2. Supabase sends email with link containing `code` parameter
3. User clicks link → redirects to `reset-password.html?code=xxx`
4. Web page calls `exchangeCodeForSession(code)`
5. Supabase validates code and returns session tokens
6. Session is established
7. User can now call `updateUser({ password: newPassword })`

### Code Exchange Function:
```javascript
// Exchange the one-time code for a session
const { data, error } = await supabaseClient.auth.exchangeCodeForSession(code)

if (error) {
    // Code is invalid or expired
    throw error
}

// Session is now established in the Supabase client
// data.session contains access_token and refresh_token
```

## Troubleshooting

### If you still see "Invalid Link":

1. **Check the URL in browser**: Does it have `?code=xxx` parameter?
   - ✅ Yes → Page should work now
   - ❌ No → Check Supabase redirect URL configuration

2. **Check browser console**: Open Developer Tools (F12) and look for errors

3. **Verify file upload**: Make sure the updated `reset-password.html` is on the server

4. **Clear browser cache**: The old version might be cached

5. **Check Supabase logs**:
   - Go to Supabase Dashboard → Logs → Auth Logs
   - Look for password reset events

### If code exchange fails:

**Error: "Code has expired"**
- The code is only valid for a short time (typically 5-10 minutes)
- Request a new password reset link

**Error: "Code has already been used"**
- Codes can only be exchanged once
- Request a new password reset link

**Error: "Invalid code"**
- The code parameter might be corrupted
- Check if the email link was fully copied
- Request a new password reset link

## Testing with Debug Page

If you need to debug URL parameters, you can temporarily use `debug-url.html`:

1. Change redirect in [SupabaseManager.swift:434](Synapse/Managers/SupabaseManager.swift#L434):
   ```swift
   let redirectURL = URL(string: "https://usynapse.com/debug-url.html")!
   ```

2. Upload `web/debug-url.html` to your server

3. Clean build and test

4. The debug page will show all URL parameters

5. Remember to change back to `reset-password.html` after debugging!

## Summary

✅ **Root cause**: Supabase using PKCE flow with `code` parameter
✅ **Solution**: Added `exchangeCodeForSession()` to handle PKCE flow
✅ **Backward compatible**: Still supports implicit flow with tokens
✅ **Files updated**: reset-password.html now handles both flows
✅ **Next step**: Upload to web server and test!

---

**Created**: December 26, 2024
**Issue**: Password reset link showing "Invalid Link"
**Fix**: Added PKCE flow support with `exchangeCodeForSession()`
