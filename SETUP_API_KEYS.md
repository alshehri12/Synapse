# 🔑 API Keys Setup Guide

## OpenAI API Key Configuration

To enable content moderation, you need to add your OpenAI API key:

### Step 1: Get Your API Key
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign up or log in
3. Click "Create new secret key"
4. Copy the key (starts with `sk-proj-...`)

### Step 2: Add to Your Project

#### Option A: Info.plist (For Development)
1. Open `Synapse/Info.plist`
2. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual API key:
```xml
<key>OpenAIAPIKey</key>
<string>sk-proj-your_actual_api_key_here</string>
```

#### Option B: Environment Variable (Recommended for Production)
```bash
export OPENAI_API_KEY="sk-proj-your_actual_api_key_here"
```

## Security Notes

⚠️ **IMPORTANT**: 
- Never commit API keys to version control
- Use environment variables in production
- The OpenAI Moderation API is FREE
- Set usage limits in OpenAI dashboard for safety

## Testing

After adding your API key:
1. Run the app
2. Go to Profile → "Test Content Moderation"
3. Verify the connection works

## Cost Information

- OpenAI Moderation API: **FREE**
- No rate limits for reasonable usage
- Monitor at: https://platform.openai.com/usage
