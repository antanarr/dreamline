# Firebase Deployment Guide

## Prerequisites
You've already done the initial setup (Firebase CLI installed, logged in), so we just need to deploy the updated functions.

## Step 1: Build the Functions

```bash
cd /Users/vidau/Desktop/Dreamline/functions
npm run build
```

**What this does:** Compiles your TypeScript code (`src/index.ts`) to JavaScript in the `lib/` folder.

**Expected output:** Should complete without errors. If you see TypeScript errors, let me know.

## Step 2: Deploy to Firebase

```bash
firebase deploy --only functions
```

**What this does:** 
- Uploads your compiled functions to Firebase
- Creates 2 new endpoints:
  - `bestDaysForWeek` - Returns favorable days for the week
  - `submitAccuracyFeedback` - Stores user feedback in Firestore
- Updates existing `horoscopeCompose` with the new schema (enforces 6 life areas)

**Expected output:**
```
✔  functions[bestDaysForWeek(us-central1)] Successful create operation.
✔  functions[submitAccuracyFeedback(us-central1)] Successful create operation.
✔  functions[horoscopeCompose(us-central1)] Successful update operation.
... (other functions)

Deploy complete!
```

**Deployment time:** Usually 2-5 minutes

## Step 3: Verify Deployment

Check that your new functions are live:

```bash
firebase functions:list
```

You should see:
- `bestDaysForWeek`
- `submitAccuracyFeedback`
- Plus all your existing functions

## Step 4: Test the Endpoints (Optional but Recommended)

### Test bestDaysForWeek:
```bash
curl -X POST https://us-central1-dreamline-16dae.cloudfunctions.net/bestDaysForWeek \
  -H "Content-Type: application/json" \
  -d '{"uid":"test-user","birthISO":""}'
```

**Expected response:**
```json
{
  "days": [
    {
      "date": "2025-11-10",
      "title": "Best day for risks",
      "reason": "Mars trine Sun",
      "dreamContext": null
    },
    {
      "date": "2025-11-12",
      "title": "Great day for therapy",
      "reason": "Moon conjunct Neptune",
      "dreamContext": null
    }
  ]
}
```

### Test submitAccuracyFeedback:
```bash
curl -X POST https://us-central1-dreamline-16dae.cloudfunctions.net/submitAccuracyFeedback \
  -H "Content-Type: application/json" \
  -d '{"uid":"test-user","areaId":"relationships","horoscopeDate":"2025-11-09","accurate":true}'
```

**Expected response:**
```json
{"success":true}
```

## Step 5: Verify Horoscope Returns 6 Areas

Test the horoscope endpoint to ensure it now returns exactly 6 life areas:

```bash
curl -X POST https://us-central1-dreamline-16dae.cloudfunctions.net/horoscopeCompose \
  -H "Content-Type: application/json" \
  -d '{"uid":"me","period":"day","tz":"America/Los_Angeles","force":true}'
```

Look for:
```json
{
  "item": {
    "areas": [ /* Should have exactly 6 items */ ]
  }
}
```

## Troubleshooting

### Error: "npm: command not found"
You already have npm installed, but if you see this:
```bash
which npm
```
Should return: `/opt/homebrew/bin/npm` or similar

### Error: "firebase: command not found"
```bash
firebase --version
```
You already have Firebase CLI v14.23.0

### Error: "EACCES: permission denied"
You already fixed the npm cache permissions with:
```bash
sudo chown -R 501:20 "/Users/vidau/.npm"
```

### Error during deployment: "Function source code not found"
Make sure you're in the `/Users/vidau/Desktop/Dreamline/functions` directory when running commands.

### Error: "Exceeded your quota for function count"
Firebase free plan has limits. You shouldn't hit this with these additions, but if you do, you may need to upgrade your Firebase plan.

## What Changed in the Backend

### New Endpoints

1. **bestDaysForWeek**
   - URL: `https://us-central1-dreamline-16dae.cloudfunctions.net/bestDaysForWeek`
   - Method: POST
   - Input: `{ uid, birthISO }`
   - Output: `{ days: [{ date, title, reason, dreamContext }] }`
   - Current behavior: Returns placeholder favorable days (placeholder logic)
   - Future: Will calculate actual favorable transits based on natal chart

2. **submitAccuracyFeedback**
   - URL: `https://us-central1-dreamline-16dae.cloudfunctions.net/submitAccuracyFeedback`
   - Method: POST
   - Input: `{ uid, areaId, horoscopeDate, accurate }`
   - Stores feedback in Firestore `feedback` collection
   - No response needed from app (fire-and-forget)

### Updated Endpoint

3. **horoscopeCompose**
   - Now enforces exactly 6 life areas in the response
   - Schema updated: `minItems: 6, maxItems: 6` in `functions/src/schemas.ts`
   - Each area must include: id, title, score, bullets, actions (do/don't)
   - Area IDs: relationships, work_money, home_body, creativity_learning, spirituality, routine_habits

## Monitoring

After deployment, monitor your functions:

### View Logs:
```bash
firebase functions:log
```

### View Logs for Specific Function:
```bash
firebase functions:log --only bestDaysForWeek
firebase functions:log --only submitAccuracyFeedback
```

### Check for Errors:
```bash
firebase functions:log --only horoscopeCompose | grep -i error
```

## Firebase Console

You can also monitor in the Firebase Console:
1. Go to: https://console.firebase.google.com/project/dreamline-16dae/functions
2. Click on each function to see:
   - Request count
   - Error rate
   - Execution time
   - Logs

## Cost Monitoring

These new functions should have minimal cost impact:
- **bestDaysForWeek**: Called once per app open (~1-5 times/day per user)
- **submitAccuracyFeedback**: Called when user provides feedback (infrequent)
- Both are simple, fast operations

Monitor costs at: https://console.firebase.google.com/project/dreamline-16dae/usage

## Next Steps After Deployment

1. **Add files to Xcode** (see `BUILD_FIXES_NEEDED.md`)
2. **Build the app** in Xcode (Cmd+B)
3. **Test on simulator** to verify:
   - Hero card shows horoscope headline
   - 6 life areas appear (2 unlocked for free tier)
   - "Behind This Forecast" section shows transits
   - Zodiac season displays correctly
   - Best Days section appears (may show empty initially)
4. **Test accuracy feedback**: Tap an area → scroll down → tap "ACCURATE" or "NOT ACCURATE"
5. **Check Firestore**: Verify feedback is being stored in `feedback` collection

## Rollback (if needed)

If something goes wrong:
```bash
firebase functions:delete bestDaysForWeek
firebase functions:delete submitAccuracyFeedback
```

Then redeploy previous version if you have it.

## Summary

✅ **You need to run:**
1. `cd /Users/vidau/Desktop/Dreamline/functions`
2. `npm run build`
3. `firebase deploy --only functions`

✅ **Expected time:** 5-10 minutes total

✅ **What you'll see:** New functions deployed, URLs printed in console

Let me know if you see any errors during deployment!

