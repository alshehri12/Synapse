# 🌐 Setup Password Reset on usynapse.com

## ✅ Best Solution: Host Reset Page on Your Domain

Using `usynapse.com/reset-password` is the **BEST** and most professional approach!

---

## 📁 What You Need to Do

### **Step 1: Upload HTML File to Your Website**

1. **The File:** `web/reset-password-page.html`
2. **Upload To:** Your `usynapse.com` hosting
3. **Final URL:** `https://usynapse.com/reset-password`

---

## 🚀 Hosting Options for usynapse.com

### **Option A: cPanel / File Manager** (Most Common)

1. **Login to your hosting cPanel**
   - Usually: `usynapse.com/cpanel`
   - Or through your hosting provider dashboard

2. **Open File Manager**
   - Navigate to `public_html/` folder

3. **Upload the file:**
   - Upload `reset-password-page.html`
   - Rename it to: `reset-password.html`

4. **Verify it works:**
   - Visit: `https://usynapse.com/reset-password.html`
   - Should show the password reset page ✅

5. **Optional - Remove .html extension:**
   - Create `.htaccess` file in `public_html/`
   - Add this code:
     ```apache
     RewriteEngine On
     RewriteCond %{REQUEST_FILENAME} !-f
     RewriteRule ^reset-password$ /reset-password.html [L]
     ```
   - Now works at: `https://usynapse.com/reset-password` (no .html)

---

### **Option B: FTP Upload**

1. **Connect via FTP:**
   - Use FileZilla or Cyberduck
   - Host: `ftp.usynapse.com` (or your FTP address)
   - Username: (from hosting provider)
   - Password: (from hosting provider)

2. **Navigate to web root:**
   - Usually: `/public_html/` or `/www/` or `/htdocs/`

3. **Upload file:**
   - Upload `reset-password-page.html`
   - Rename to: `reset-password.html`

4. **Test:**
   - Visit: `https://usynapse.com/reset-password.html`

---

### **Option C: If Using Vercel/Netlify for Landing Page**

1. **Add to your project:**
   - Copy `reset-password-page.html` to your project
   - Rename to: `reset-password.html`

2. **Deploy:**
   ```bash
   # If using Vercel
   vercel --prod

   # If using Netlify
   netlify deploy --prod
   ```

3. **Verify:**
   - `https://usynapse.com/reset-password.html`

---

### **Option D: Create a Folder (Cleaner URLs)**

1. **In `public_html/`:**
   - Create folder: `reset-password/`
   - Upload file as: `index.html`

2. **URL becomes:**
   - `https://usynapse.com/reset-password/` (no .html!)

---

## ⚙️ Step 2: Update Supabase Configuration

### **Update SupabaseManager.swift:**

1. **Open:** `Synapse/Managers/SupabaseManager.swift`

2. **Find line ~429** (resetPassword function)

3. **Change from:**
   ```swift
   let redirectURL = URL(string: "synapse://reset-password")!
   ```

4. **To:**
   ```swift
   let redirectURL = URL(string: "https://usynapse.com/reset-password")!
   ```
   *(Or `https://usynapse.com/reset-password.html` if you didn't remove extension)*

5. **Save the file**

---

### **Update Supabase Dashboard:**

1. **Go to:** https://supabase.com/dashboard

2. **Select:** Your Synapse project

3. **Navigate to:**
   ```
   Authentication → URL Configuration → Redirect URLs
   ```

4. **Add this URL:**
   ```
   https://usynapse.com/reset-password
   ```
   *(Exact URL where you uploaded the file)*

5. **Click Save**

---

## 🎯 Step 3: Update the HTML File

The file already has your Supabase credentials filled in! But verify them:

1. **Open:** `web/reset-password-page.html`

2. **Lines 214-215** should have:
   ```javascript
   const supabaseUrl = 'https://oocegnwdfnnjgoworrwh.supabase.co'
   const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
   ```

3. **These are YOUR credentials** (I got them from your Info.plist) ✅

4. **Optional:** Update App Store URL (line 296):
   ```javascript
   window.location.href = 'https://apps.apple.com/app/synapse/YOUR_APP_ID'
   ```

---

## ✅ Complete Setup Checklist

- [ ] Upload `reset-password-page.html` to `usynapse.com`
- [ ] Rename to `reset-password.html` (or `index.html` in folder)
- [ ] Verify page loads at: `https://usynapse.com/reset-password`
- [ ] Update `SupabaseManager.swift` with new URL
- [ ] Rebuild app (Cmd + B)
- [ ] Update Supabase Dashboard Redirect URLs
- [ ] Save Supabase changes
- [ ] Test password reset flow

---

## 🧪 How to Test

### **Test 1: Access the Page**

1. Open browser
2. Go to: `https://usynapse.com/reset-password`
3. Should see beautiful green reset page ✅

### **Test 2: Full Reset Flow**

1. **In your app:**
   - Tap "Forgot Password?"
   - Enter your email
   - Tap "Send Reset Link"

2. **Check email:**
   - Should receive email with "Reset My Password" button

3. **Click button:**
   - Should open: `https://usynapse.com/reset-password?...`
   - NOT a blank page ✅

4. **Enter new password:**
   - Type new password
   - Confirm password
   - Click "Reset Password"

5. **Success:**
   - Should show success message ✅
   - Can click "Open Synapse App" to return

6. **Verify:**
   - Close app completely
   - Reopen app
   - Login with NEW password ✅

---

## 🎨 Customize the Page (Optional)

### **Change Colors:**

Find these lines and update:

```css
/* Line 18 - Page background */
background: linear-gradient(135deg, #E8F5F0 0%, #F0FFF4 100%);

/* Line 38 - Logo background */
background: linear-gradient(135deg, #10b981 0%, #059669 100%);

/* Line 88 - Button color */
background: linear-gradient(135deg, #10b981 0%, #059669 100%);
```

### **Change Logo:**

Find line 185:
```html
<div class="logo-icon">🧠</div>
```

Replace with your logo:
```html
<div class="logo-icon">
    <img src="/logo.png" alt="Synapse" style="width: 60px; height: 60px;">
</div>
```

---

## 📊 Why This Solution is Best

| Approach | Pros | Cons |
|----------|------|------|
| **Deep Link Only** | Simple setup | ❌ Doesn't work on desktop<br>❌ Shows blank page |
| **Supabase Default** | No hosting needed | ❌ Generic Supabase page<br>❌ Not branded |
| **Your Domain** ✅ | ✅ Professional<br>✅ Branded<br>✅ Works everywhere<br>✅ SEO friendly<br>✅ Full control | Requires hosting (you already have!) |

---

## 🔧 Troubleshooting

### **Issue 1: Page shows blank**

**Cause:** File not uploaded correctly

**Fix:**
1. Verify file uploaded to correct folder
2. Check file permissions (should be 644)
3. Visit URL directly in browser
4. Check browser console for errors (F12)

---

### **Issue 2: "Invalid link" error on page**

**Cause:** URL doesn't match Supabase redirect URL

**Fix:**
1. Check exact URL in Supabase Dashboard
2. Make sure it matches where file is hosted
3. Include or exclude `/` at end consistently

---

### **Issue 3: Password reset doesn't work**

**Cause:** Supabase credentials wrong

**Fix:**
1. Verify `supabaseUrl` and `supabaseKey` in HTML
2. Should match values in `Info.plist`
3. Re-upload file after fixing

---

### **Issue 4: Can't find file on hosting**

**Cause:** Looking in wrong folder

**Fix:**
- Common folders:
  - `/public_html/`
  - `/www/`
  - `/htdocs/`
  - `/html/`
  - `/domains/usynapse.com/public_html/`

---

## 📱 Mobile vs Desktop Experience

### **On Mobile (iPhone/Android):**
1. User taps link in email
2. Opens Safari/Chrome
3. Shows password reset page
4. Enters new password
5. Clicks "Open Synapse App"
6. App opens (via deep link)

### **On Desktop:**
1. User clicks link in email
2. Opens in browser
3. Shows password reset page
4. Enters new password
5. Success message shown
6. User manually opens app on phone

Both work perfectly! ✅

---

## 🚀 Quick Setup (5 Minutes)

1. **Upload file** to `usynapse.com/public_html/`
2. **Rename** to `reset-password.html`
3. **Update** `SupabaseManager.swift`:
   ```swift
   let redirectURL = URL(string: "https://usynapse.com/reset-password.html")!
   ```
4. **Rebuild** app
5. **Add URL** to Supabase Redirect URLs
6. **Test** → Done! ✅

---

## 📝 Summary

**What to Do:**
1. Upload `reset-password-page.html` to `usynapse.com`
2. Update `SupabaseManager.swift` with URL
3. Update Supabase Redirect URLs
4. Test password reset flow

**Result:**
- ✅ Professional branded page
- ✅ Works on mobile and desktop
- ✅ No blank pages
- ✅ Full control over design
- ✅ Users can reset password easily

**Your URL:**
`https://usynapse.com/reset-password`

Perfect for a professional app! 🎉
