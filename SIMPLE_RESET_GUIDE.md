# Simple Password Reset Setup - No Web Hosting Needed!

## The Easiest Way (5 Minutes)

Instead of hosting a web page, we can use a **deep link** to send users directly back to the app!

## Step-by-Step Setup

### Step 1: Configure URL Scheme in Xcode (2 minutes)

1. Open your Synapse project in Xcode
2. Select the **Synapse** target (blue app icon at the top)
3. Go to the **Info** tab
4. Scroll down to **URL Types**
5. Click the **+** button to add a new URL type
6. Fill in:
   - **Identifier**: `com.synapse.app`
   - **URL Schemes**: `synapse`
   - **Role**: Editor
7. Done! ✅

**What this does**: Allows links like `synapse://reset-password` to open your app

### Step 2: Update SupabaseManager.swift (30 seconds)

Change line 429 from:
```swift
let redirectURL = URL(string: "https://yourdomain.com/auth/reset-password")!
```

To:
```swift
let redirectURL = URL(string: "synapse://reset-password")!
```

### Step 3: Add URL Handler in Your App (2 minutes)

We need to catch the deep link when the app opens. Let me create this for you...

### Step 4: Configure Supabase Dashboard (1 minute)

1. Go to https://supabase.com/dashboard
2. Select your Synapse project
3. Click **Authentication** in the left sidebar
4. Click **URL Configuration**
5. Under **Redirect URLs**, click **Add URL**
6. Add: `synapse://reset-password`
7. Click **Save**

## How It Will Work

1. User clicks "Forgot Password?" in app
2. Enters their email
3. Receives email with reset link
4. Clicks link → Opens your app directly! 🎉
5. App shows a screen to enter new password
6. Password is reset ✅

## Implementation Code

I'll create a simple ResetPasswordView that appears when the deep link opens.

---

## Alternative: Use Supabase's Default Page (Even Simpler!)

If you don't want to create the deep link handling:

### Option: Just Remove the redirectTo Parameter

Change the resetPassword function to:

```swift
@MainActor
func resetPassword(email: String) async throws {
    try await supabaseClient.auth.resetPasswordForEmail(email)
}
```

**What happens**:
- Users get an email with a Supabase default page
- They enter their new password on Supabase's page
- Password is reset
- They return to your app and login

**Pros**: Zero configuration needed
**Cons**: Uses Supabase's generic page (not branded)

---

## Which Should You Choose?

### ✅ I Recommend: Deep Link Approach
- Professional (keeps users in your app)
- No web hosting needed
- Fully branded experience
- Takes 5 minutes to set up

### ⚠️ Quick Fix: Remove redirectTo
- Works immediately
- No configuration
- But uses Supabase's generic page

Let me know which approach you prefer, and I'll implement it for you!
