# Password Reset Web Page - Deployment Instructions

## 📋 Overview

You now have a complete password reset system! This guide will help you deploy the web page and configure everything correctly.

## 📁 What You Have

- **HTML File**: `/web/reset-password.html` - Beautiful, responsive password reset page
- **Updated Code**: `SupabaseManager.swift` already configured to use the web-based approach
- **Documentation**: `PASSWORD_RESET_SETUP.md` - Detailed technical documentation

## 🚀 Quick Setup (3 Steps)

### Step 1: Get Your Supabase Credentials

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your Synapse project
3. Go to **Settings** → **API**
4. Copy these two values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### Step 2: Update the HTML File

Open `/web/reset-password.html` and find these lines (around line 211):

```javascript
const supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL'  // e.g., 'https://xxxxx.supabase.co'
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY'     // Your public anon key
```

Replace with your actual values:

```javascript
const supabaseUrl = 'https://your-actual-project.supabase.co'
const supabaseKey = 'eyJhbGc...' // Your actual anon key
```

**Optional**: Update the App Store link (line 295):
```javascript
window.location.href = 'https://apps.apple.com/app/synapse/YOUR_APP_ID'
```

### Step 3: Choose Your Hosting Option

You need to host this HTML file on the web. Here are your options:

---

## 🌐 Hosting Options

### Option A: GitHub Pages (FREE, Easiest)

**Perfect if**: You're already using GitHub for your project

**Steps**:

1. **Create a new repository** or use existing one
   ```bash
   cd /path/to/your/repo
   mkdir docs
   cp /Users/abdulrahmanalshehri/Desktop/RMP/Synapse/web/reset-password.html docs/reset-password.html
   git add docs/reset-password.html
   git commit -m "Add password reset page"
   git push
   ```

2. **Enable GitHub Pages**:
   - Go to your repository on GitHub
   - Settings → Pages
   - Source: Deploy from `main` branch, `/docs` folder
   - Save

3. **Your URL will be**:
   ```
   https://YOUR-USERNAME.github.io/YOUR-REPO/reset-password.html
   ```

4. **Update SupabaseManager.swift**:
   ```swift
   let redirectURL = URL(string: "https://YOUR-USERNAME.github.io/YOUR-REPO/reset-password.html")!
   ```

5. **Add to Supabase Dashboard**:
   - Go to: Authentication → URL Configuration → Redirect URLs
   - Add: `https://YOUR-USERNAME.github.io/YOUR-REPO/reset-password.html`

**Pros**: ✅ Free, ✅ Easy, ✅ No server needed
**Cons**: ❌ Public repository required (or GitHub Pro for private)

---

### Option B: Netlify (FREE, Professional)

**Perfect if**: You want a custom domain and professional hosting

**Steps**:

1. **Sign up** at [netlify.com](https://netlify.com) (free)

2. **Drag and drop** your `/web` folder to Netlify dashboard

3. **Your URL will be**:
   ```
   https://your-site-name.netlify.app/reset-password.html
   ```

4. **Custom domain** (optional):
   - Go to Domain Settings
   - Add your custom domain (e.g., `synapse-app.com`)
   - Follow DNS setup instructions
   - Your URL becomes: `https://synapse-app.com/reset-password.html`

5. **Update SupabaseManager.swift**:
   ```swift
   let redirectURL = URL(string: "https://your-site-name.netlify.app/reset-password.html")!
   ```

6. **Add to Supabase Dashboard**:
   - Authentication → URL Configuration → Redirect URLs
   - Add your Netlify URL

**Pros**: ✅ Free, ✅ Custom domain, ✅ Auto-deploy, ✅ HTTPS
**Cons**: None really!

---

### Option C: Vercel (FREE, Developer-Friendly)

**Perfect if**: You like modern deployment tools

**Steps**:

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Deploy**:
   ```bash
   cd /Users/abdulrahmanalshehri/Desktop/RMP/Synapse/web
   vercel
   ```

3. **Follow prompts**, and you'll get a URL like:
   ```
   https://your-project.vercel.app/reset-password.html
   ```

4. **Update SupabaseManager.swift** and **Supabase Dashboard** with your Vercel URL

**Pros**: ✅ Free, ✅ Fast, ✅ CLI deployment
**Cons**: Requires npm/node installed

---

### Option D: Firebase Hosting (FREE)

**Perfect if**: You're familiar with Firebase

**Steps**:

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize**:
   ```bash
   cd /Users/abdulrahmanalshehri/Desktop/RMP/Synapse/web
   firebase init hosting
   ```

3. **Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

4. **URL**: `https://your-project.web.app/reset-password.html`

**Pros**: ✅ Free, ✅ Google infrastructure
**Cons**: Requires Firebase setup

---

### Option E: Your Own Domain/Server

**Perfect if**: You already have web hosting

**Steps**:

1. **Upload via FTP/SFTP**:
   - Upload `reset-password.html` to your server
   - Example path: `/public_html/auth/reset-password.html`

2. **Verify it's accessible**:
   - Visit: `https://yourdomain.com/auth/reset-password.html`

3. **Update SupabaseManager.swift** and **Supabase Dashboard**

**Pros**: ✅ Full control
**Cons**: Requires existing hosting

---

## ⚙️ Final Configuration

After deploying, you MUST complete these steps:

### 1. Update SupabaseManager.swift

Replace the placeholder URL in [SupabaseManager.swift:429](SupabaseManager.swift#L429):

```swift
// Change this:
let redirectURL = URL(string: "https://yourdomain.com/auth/reset-password")!

// To your actual URL:
let redirectURL = URL(string: "https://your-actual-site.com/reset-password.html")!
```

### 2. Configure Supabase Dashboard

**CRITICAL**: Add your URL to Supabase allowed redirects:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. **Authentication** → **URL Configuration**
4. Under **Redirect URLs**, click **Add URL**
5. Paste your complete URL (e.g., `https://your-site.netlify.app/reset-password.html`)
6. Click **Save**

**Without this step, the reset link will show a Supabase error page!**

### 3. Optional: Configure Deep Link

If you want the "Open Synapse App" button to work:

1. Open Xcode
2. Select your Synapse target
3. Go to **Info** tab
4. **URL Types** → Click **+**
5. Add:
   - **Identifier**: `com.yourcompany.synapse`
   - **URL Schemes**: `synapse`
6. Save and rebuild

Now the button will open your app directly!

---

## ✅ Testing Checklist

After deployment, test everything:

- [ ] HTML file is accessible at your URL
- [ ] URL is added to Supabase Dashboard Redirect URLs
- [ ] SupabaseManager.swift has correct redirect URL
- [ ] App is rebuilt with new redirect URL
- [ ] Test the full flow:
  1. Open app
  2. Go to login screen
  3. Tap "Forgot Password?"
  4. Enter email
  5. Check email inbox
  6. Click reset link
  7. Should open your web page (not Supabase error)
  8. Enter new password
  9. Should show success message
  10. Return to app and login with new password

---

## 🎨 Customization (Optional)

### Change Colors

Edit the CSS in `reset-password.html`:

```css
/* Line 41-42 - Main gradient color */
background: linear-gradient(135deg, #YOUR_COLOR_1 0%, #YOUR_COLOR_2 100%);

/* Line 54-55 - Logo background */
background: linear-gradient(135deg, #YOUR_PRIMARY 0%, #YOUR_SECONDARY 100%);

/* Line 129-130 - Button color */
background: linear-gradient(135deg, #YOUR_PRIMARY 0%, #YOUR_SECONDARY 100%);
```

### Change Logo

Replace the brain emoji (line 202):

```html
<div class="logo-icon">🧠</div>
```

With your logo:

```html
<div class="logo-icon">
    <img src="your-logo.png" alt="Synapse" style="width: 100%; height: 100%;">
</div>
```

### Update Branding

Change company name and copyright (line 317):

```html
<div class="footer">
    © 2025 Your Company. All rights reserved.
</div>
```

---

## 🆘 Troubleshooting

### "Invalid Link" Error in Browser

**Cause**: URL not added to Supabase Redirect URLs
**Fix**: Add your URL in Supabase Dashboard → Authentication → URL Configuration

### Email Link Shows Supabase Error Page

**Cause**: Redirect URL mismatch
**Fix**: Make sure the URL in SupabaseManager.swift exactly matches the URL in Supabase Dashboard

### "Open App" Button Doesn't Work

**Cause**: URL scheme not configured in Xcode
**Fix**: Follow "Configure Deep Link" instructions above OR change button to link to App Store

### Password Reset Fails

**Cause**: Supabase credentials incorrect in HTML
**Fix**: Double-check you copied the correct URL and anon key from Supabase Dashboard

---

## 📱 App Store Notes

When submitting to App Store:

1. ✅ This solution is App Store compliant
2. ✅ Uses standard OAuth flows
3. ✅ No private APIs
4. ✅ User data stays secure

Make sure your privacy policy mentions password reset functionality!

---

## 🎯 Recommended: Netlify

**For most users, I recommend Netlify because**:

1. ✅ Completely free
2. ✅ Dead simple drag-and-drop deployment
3. ✅ Automatic HTTPS
4. ✅ Custom domain support
5. ✅ Professional and reliable
6. ✅ No command line required

**Quick Netlify Setup**:

1. Go to [netlify.com/drop](https://app.netlify.com/drop)
2. Drag your `/web` folder
3. Done! Copy the URL
4. Update SupabaseManager.swift and Supabase Dashboard

---

## 📚 Additional Resources

- **Detailed Guide**: See `PASSWORD_RESET_SETUP.md` for all 3 implementation options
- **Supabase Docs**: [Password Recovery](https://supabase.com/docs/guides/auth/auth-password-recovery)
- **Support**: If you need help, check Supabase Discord or GitHub issues

---

## ✨ You're All Set!

Once you complete these steps, your password reset flow will be:

1. User taps "Forgot Password?" in app
2. Enters email
3. Receives beautiful email
4. Clicks link → Opens professional web page
5. Enters new password
6. Success! Returns to app

**Professional, secure, and user-friendly!** 🎉
