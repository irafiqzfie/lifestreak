# Deploy Delete Account Edge Function

## Prerequisites

Install Supabase CLI:
```powershell
# Windows (via Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Or via NPM
npm install -g supabase
```

## Deployment Steps

### 1. Login to Supabase
```powershell
supabase login
```

### 2. Link to Your Project
```powershell
cd C:\Users\Afiq\lifestreak
supabase link --project-ref ovjhpwaraktkrmgpdwyn
```

### 3. Deploy the Edge Function
```powershell
supabase functions deploy delete-account
```

### 4. Verify Deployment
Go to: https://app.supabase.com/project/ovjhpwaraktkrmgpdwyn/functions

You should see `delete-account` listed.

## Test the Function

### From Flutter App
1. Run the app: `flutter run -d chrome`
2. Sign in
3. Go to Settings
4. Tap "Delete Account"
5. Confirm deletion
6. Should delete account and return to login

### Manual Test (Optional)
```powershell
# Get your JWT token from the app first
$TOKEN = "your_jwt_token_here"

curl -X POST "https://ovjhpwaraktkrmgpdwyn.supabase.co/functions/v1/delete-account" `
  -H "Authorization: Bearer $TOKEN" `
  -H "Content-Type: application/json"
```

Expected response:
```json
{"success":true}
```

## Troubleshooting

### "supabase: command not found"
Install Supabase CLI (see Prerequisites above)

### "Project not linked"
Run: `supabase link --project-ref ovjhpwaraktkrmgpdwyn`

### "Unauthorized" error
- Make sure user is signed in
- Check that JWT token is valid
- Verify Authorization header is being sent

### Function not found (404)
- Deploy the function: `supabase functions deploy delete-account`
- Check it exists in Supabase dashboard

## What This Does

When a user deletes their account:
1. ✅ Flutter calls backend API to delete user data
2. ✅ Flutter calls Edge Function `delete-account`
3. ✅ Edge Function verifies authentication
4. ✅ Edge Function deletes auth user using Admin API
5. ✅ Flutter signs out locally
6. ✅ Flutter navigates to login screen

## Security

- ✅ Edge Function uses service role key (server-side only)
- ✅ User ID comes from JWT, not client input
- ✅ Only authenticated users can call the function
- ✅ Admin API is never exposed to client
- ✅ Complies with Apple App Store guidelines

## Files

- Edge Function: `supabase/functions/delete-account/index.ts`
- Flutter Code: `lib/screens/settings_screen.dart`
