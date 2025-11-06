# API Keys Setup Guide

## ⚠️ IMPORTANT: Never Commit API Keys to Git

This project uses external APIs that require secret keys. **Never commit these keys to Git!**

## OpenAI API Key (Content Moderation)

Your app uses OpenAI for content moderation. The API key is stored locally only.

### Setup Instructions

**Option 1: Use Local Config File (Current Setup)**

1. The file `Secrets.xcconfig` contains your OpenAI API key
2. This file is in `.gitignore` and will NOT be committed to Git
3. Keep this file on your local machine only
4. Other developers need to create their own `Secrets.xcconfig`

**Option 2: Manually Update Info.plist (Not Recommended)**

1. Open `Synapse/Info.plist`
2. Find `<key>OpenAIAPIKey</key>`
3. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual key
4. **DO NOT commit this change**

---

## Current API Key Location

Your OpenAI API key is currently stored in:
- ✅ `Secrets.xcconfig` (ignored by Git, safe)
- ⚠️ Not in `Info.plist` (stays as placeholder)

---

## For Team Members / Other Developers

If someone else clones this repo, they need to:

1. Get their own OpenAI API key from https://platform.openai.com/api-keys
2. Create `Secrets.xcconfig` in the project root:
   ```
   OPENAI_API_KEY = your-key-here
   ```
3. The app will read from this file

---

## Security Best Practices

### ✅ DO:
- Keep API keys in local config files
- Add config files to `.gitignore`
- Use environment variables
- Rotate keys periodically
- Use different keys for dev/production

### ❌ DON'T:
- Commit API keys to Git
- Share keys publicly
- Hardcode keys in source code
- Use the same key across all environments
- Push keys to GitHub (it will block you!)

---

## GitHub Push Protection

GitHub automatically scans commits for exposed secrets. If you try to commit an API key, you'll see:

```
remote: error: GH013: Repository rule violations found
remote: - Push cannot contain secrets
```

This is **good** - it prevents security breaches!

---

## Production Deployment (Future)

For App Store release, consider:

1. **Backend Proxy** (Best Practice)
   - Create a backend service (Node.js, Python, etc.)
   - Store API key on server only
   - App calls your backend
   - Backend calls OpenAI
   - Never expose key to app

2. **Environment Variables**
   - Use Xcode build configurations
   - Different keys for Debug/Release
   - Inject at build time

3. **Secret Management Services**
   - AWS Secrets Manager
   - Google Secret Manager
   - Azure Key Vault

---

## Current Configuration

**File:** `Info.plist`
```xml
<key>OpenAIAPIKey</key>
<string>YOUR_OPENAI_API_KEY_HERE</string>
```

**File:** `Secrets.xcconfig` (local only, not in Git)
```
OPENAI_API_KEY = sk-proj-[your-actual-key]
```

**How the app reads it:**

The app currently reads from `Info.plist`. To use the config file approach, you would need to:
1. Update build settings to use the `.xcconfig` file
2. Modify code to read from environment

For now, the simplest approach:
- **Keep `Secrets.xcconfig` as backup**
- **Manually paste key into `Info.plist` on your local machine**
- **Never commit `Info.plist` with real key**

---

## Your OpenAI Key (Saved Locally)

Your key is safely stored in `Secrets.xcconfig` which is gitignored.

**To use it:**
1. Open `Info.plist`
2. Copy key from `Secrets.xcconfig`
3. Paste into `Info.plist` locally
4. **Do not commit this change**

Or keep it as is - the key is in the safe file!

---

## Questions?

- How to get OpenAI key: https://platform.openai.com/api-keys
- GitHub secret scanning: https://docs.github.com/code-security/secret-scanning
- iOS security best practices: https://developer.apple.com/documentation/security

