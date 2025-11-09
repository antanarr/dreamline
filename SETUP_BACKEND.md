# Backend Setup Guide

## Issue: "Sky cache is quiet"

Your app shows this error because the Firebase Cloud Functions backend is not deployed or configured yet.

## Prerequisites

1. **Firebase CLI** - Install if you haven't:
   ```bash
   npm install -g firebase-tools
   ```

2. **OpenAI API Key** - Get one from https://platform.openai.com/api-keys

3. **Firebase Project** - Your project ID is `dreamline-16dae`

## Setup Steps

### Step 1: Login to Firebase

```bash
cd /Users/vidau/Desktop/Dreamline
firebase login
```

### Step 2: Set the OpenAI API Key

You need to configure the OpenAI API key as a secret:

```bash
cd functions
./setup-secret.sh
```

Or manually:
```bash
firebase functions:secrets:set OPENAI_API_KEY
# Then paste your OpenAI API key when prompted
```

### Step 3: Deploy the Functions

```bash
# Install dependencies first (if not done already)
cd functions
npm install

# Deploy to Firebase
firebase deploy --only functions
```

This will deploy these endpoints:
- `horoscopeRead` - Fetches cached horoscopes
- `horoscopeCompose` - Generates new horoscopes using OpenAI
- `oracleExtract` - Extracts symbols from dreams
- `oracleInterpret` - Interprets dreams with astrology
- `oracleChat` - Chat with the oracle

### Step 4: Test the App

Once deployed:
1. Open the app on your device
2. Navigate to the "Today" tab
3. Pull to refresh on the "Sky Window" section
4. You should see your personalized horoscope!

## Troubleshooting

### "firebase: command not found"
Install Firebase CLI: `npm install -g firebase-tools`

### "Project not found"
Make sure you're logged in: `firebase login`

### "Permission denied"
Ensure you have owner/editor access to the Firebase project `dreamline-16dae`

### "OpenAI API quota exceeded"
You need to add payment method to your OpenAI account at https://platform.openai.com/account/billing

### Still seeing "Sky cache is quiet"
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify deployment: `firebase functions:list`
3. Test the endpoint directly:
   ```bash
   curl https://us-central1-dreamline-16dae.cloudfunctions.net/horoscopeRead
   ```

## Cost Estimates

- **Firebase Functions**: Free tier includes 2M invocations/month
- **OpenAI API**: ~$0.01-0.05 per horoscope generation
- Expected monthly cost: $5-20 depending on usage

## Alternative: Local Development

To test locally before deploying:

```bash
cd functions
npm run serve
```

Then update Info.plist temporarily:
```xml
<key>FunctionsBaseURL</key>
<string>http://localhost:5001/dreamline-16dae/us-central1</string>
```

## Need Help?

- Firebase Functions docs: https://firebase.google.com/docs/functions
- OpenAI API docs: https://platform.openai.com/docs

