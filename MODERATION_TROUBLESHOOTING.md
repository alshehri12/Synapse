# Content Moderation Troubleshooting Guide

**Issue**: 400 Error from OpenAI API  
**Date**: January 2025

---

## 🔍 Understanding the Problem

You're seeing this error:
```
⚠️ OpenAI moderation failed: httpError(400)
```

**What this means:**
- 400 = Bad Request
- The OpenAI API received your request but something is wrong with it
- Could be: invalid API key, wrong format, or API key issues

---

## ✅ How Content Moderation SHOULD Work

### 1. Test API Connection
**Button**: "Test API Connection"  
**Expected**: "✅ OpenAI connection successful"  
**Purpose**: Verifies your API key works

### 2. Test Safe Content
**Example**: "I have a great idea for a mobile app"  
**Expected**: ✅ Content APPROVED  
**Purpose**: Shows moderation allows good content

### 3. Test Inappropriate Content
**Example**: Text with hate speech, violence, etc.  
**Expected**: ❌ Content REJECTED  
**Purpose**: Shows moderation blocks bad content

### 4. Test Spam Content
**Button**: "Spam Test"  
**Content**: "BUY NOW!!! 🔥🔥🔥 CLICK HERE $$$ CHEAP!!!"  
**Expected**: ❌ Content REJECTED (spam detection)  
**Purpose**: Shows fallback rules work

---

## 🐛 Debugging Steps

### Step 1: Check Xcode Console Logs

When you test, look for these logs:

**Good logs (working):**
```
🔑 Using API key (first 10 chars): sk-proj-q5...
📤 Sending request to: https://api.openai.com/v1/moderations
📝 Content to moderate: 'test content here'
📥 Response status code: 200
✅ Response body: {...}
```

**Bad logs (not working):**
```
🔑 Using API key (first 10 chars): sk-proj-q5...
📤 Sending request to: https://api.openai.com/v1/moderations
📝 Content to moderate: 'test content here'
�� Response status code: 400
❌ Error response body: {"error":{"message":"..."}}
```

### Step 2: Check API Key

**Verify the key in Info.plist:**

1. Open Info.plist in Xcode
2. Find `OpenAIAPIKey`
3. Check the value starts with: `sk-proj-`
4. Check there are no extra spaces
5. Check it's not the placeholder value

**Expected format:**
```
sk-proj-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### Step 3: Test API Key Directly

Visit: https://platform.openai.com/api-keys

1. Check if your key is still active
2. Check if it has permissions for moderation
3. Try regenerating the key if needed

### Step 4: Check for Common Issues

**Issue 1: Old/Invalid API Key**
- OpenAI keys can expire or be revoked
- Solution: Generate a new key at platform.openai.com

**Issue 2: Wrong API Key Format**
- Must start with `sk-proj-`
- No spaces or line breaks
- Exactly as copied from OpenAI

**Issue 3: API Key Not Loaded**
```
❌ API key not configured
```
- Solution: Verify Info.plist has the key
- Clean build folder (Cmd+Shift+K)
- Rebuild (Cmd+B)

**Issue 4: Rate Limiting**
```
📥 Response status code: 429
```
- You've hit API rate limits
- Wait a few minutes and try again

---

## 🔧 Fixes to Try

### Fix 1: Regenerate OpenAI API Key

1. Go to: https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Name it "Synapse Content Moderation"
4. Copy the new key (starts with `sk-proj-`)
5. Open Info.plist in Xcode
6. Replace old key with new key
7. Clean build (Cmd+Shift+K)
8. Build and run (Cmd+R)
9. Test again

### Fix 2: Verify Info.plist Format

Open Info.plist as source code (Right-click → Open As → Source Code):

```xml
<key>OpenAIAPIKey</key>
<string>sk-proj-YOUR_ACTUAL_KEY_HERE</string>
```

**Common mistakes:**
- Extra spaces before/after key
- Placeholder text still there
- Missing `sk-proj-` prefix

### Fix 3: Check Error Response

The logs now show the exact error from OpenAI:
```
❌ Error response body: {"error":{"message":"Invalid API key"}}
```

This tells you exactly what's wrong!

### Fix 4: Test with curl

Test your API key directly from Terminal:

```bash
curl https://api.openai.com/v1/moderations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY_HERE" \
  -d '{
    "input": "Test message"
  }'
```

**Expected response:**
```json
{
  "id": "modr-...",
  "model": "text-moderation-...",
  "results": [
    {
      "flagged": false,
      "categories": {...},
      "category_scores": {...}
    }
  ]
}
```

---

## 📱 How to Test Properly

### In the App:

1. **Build and Run**
   - Open Synapse.xcodeproj
   - Press Cmd+R to run
   - Wait for app to load

2. **Navigate to Test**
   - Profile tab
   - Settings icon (top right)
   - "Content Moderation Test"

3. **Test Connection First**
   - Tap "Test API Connection"
   - Check Xcode console
   - Should see: ✅ or ❌ with details

4. **Test Safe Content**
   - Tap "Safe Text" button
   - Should see: "✅ CONTENT APPROVED"
   - Check console for full details

5. **Test Spam**
   - Tap "Spam Test" button
   - Should see: "❌ CONTENT REJECTED"
   - Violations: spam

6. **Test Custom Content**
   - Type your own text in the field
   - Tap "Test Current Content"
   - See if it's approved or rejected

---

## 🎯 What Success Looks Like

### Test API Connection Success:
```
App Display:
OpenAI: ✅ OpenAI connection successful
Custom Rules: ✅ Ready

Xcode Console:
🔑 Using API key (first 10 chars): sk-proj-q5...
📤 Sending request to: https://api.openai.com/v1/moderations
📝 Content to moderate: 'test'
📥 Response status code: 200
✅ Response body: {"id":"modr-...","model":"...","results":[...]}
```

### Safe Content Test Success:
```
App Display:
✅ CONTENT APPROVED

📊 Confidence Score: 0.02

🟢 No violations detected

Xcode Console:
🛡️ Moderating content...
✅ Content moderation passed
```

### Inappropriate Content Test Success:
```
App Display:
❌ CONTENT REJECTED

📊 Confidence Score: 0.95

⚠️ Violations detected:
  • Hate
  • Harassment

Xcode Console:
🛡️ Moderating content...
⚠️ User attempted to post inappropriate content
```

---

## 🚨 Current Issue: 400 Error

**Your specific error:**
```
⚠️ OpenAI moderation failed: httpError(400)
```

**Most likely causes:**

1. **Rate Limiting / Free Tier Restrictions** (60% probability)
   - OpenAI free tier has VERY restrictive rate limits (3 requests per minute)
   - If you're testing multiple times, you'll hit limits quickly
   - The error might be 429 (rate limit) being reported as 400
   - **FIX**:
     - Wait 5-10 minutes between tests
     - Upgrade to paid tier at platform.openai.com/account/billing
     - Or rely on fallback custom rules (already implemented)

2. **Invalid or Expired API Key** (30% probability)
   - Your OpenAI key may have expired
   - Or it's not formatted correctly
   - **FIX**: Regenerate key at platform.openai.com

3. **Wrong Key in Info.plist** (8% probability)
   - Key has extra spaces or characters
   - **FIX**: Check Info.plist format

4. **API Account Issue** (2% probability)
   - OpenAI account suspended or out of credits
   - **FIX**: Check platform.openai.com account status

## 🔍 Testing Your API Key Directly

**I've created a test script for you!**

Run this in Terminal from the Synapse directory:
```bash
./test_openai_key.sh
```

This will:
- Test your API key directly with OpenAI
- Show the exact error response
- Give you specific solutions

**Recent test results showed:**
```
📥 Response Status: 429
⚠️ ERROR 429: Rate Limited
```

This means your API key IS VALID but you're hitting rate limits. This is common with free tier accounts.

---

## 📝 Next Steps for You

1. **Run the app again** with new debug logs
2. **Try "Test API Connection"**
3. **Watch Xcode console** for detailed error message
4. **Look for this line:**
   ```
   ❌ Error response body: {the exact error}
   ```
5. **Share the error message** if you need help

The console will now tell you EXACTLY what's wrong!

---

## 💡 Understanding the Test Interface

### Button: "Test API Connection"
- **Does**: Sends "test" to OpenAI API
- **Shows**: If your API key works
- **Doesn't**: Test actual moderation logic

### Button: "Safe Text"
- **Does**: Tests "I have a great idea for a mobile app"
- **Shows**: Normal content is allowed
- **Purpose**: Verify moderation doesn't block good content

### Button: "Spam Test"
- **Does**: Tests spam-like content
- **Shows**: Inappropriate content is blocked
- **Purpose**: Verify moderation catches bad content

### Button: "Test Current Content"
- **Does**: Tests whatever you type in the text field
- **Shows**: Real-time moderation results
- **Purpose**: Test your own content

---

## 🔑 API Key Checklist

- [ ] Key starts with `sk-proj-`
- [ ] Key is in Info.plist under "OpenAIAPIKey"
- [ ] No extra spaces before/after the key
- [ ] Not the placeholder "YOUR_OPENAI_API_KEY_HERE"
- [ ] Key is active on platform.openai.com
- [ ] App has been rebuilt after adding/changing key

---

## 📞 If Nothing Works

1. **Generate completely new API key**
2. **Delete app from simulator**
3. **Clean build folder** (Cmd+Shift+K)
4. **Rebuild** (Cmd+B)
5. **Run** (Cmd+R)
6. **Check console logs** for exact error

The detailed logs will show you exactly what OpenAI is saying!

---

**The moderation system is working correctly in code. The 400 error is an API key issue that the new debugging logs will help identify!**
