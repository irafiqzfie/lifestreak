# Quick Start: Supabase Configuration

## 1. Get Your Supabase Credentials

1. Go to https://app.supabase.com
2. Select your project (or create a new one)
3. Click on **Settings** (gear icon in the sidebar)
4. Click on **API**
5. Copy the following values:

   - **Project URL**: Your Supabase project URL
   - **anon/public key**: Your anon public API key

## 2. Update Your App Configuration

Open `lib/config/supabase_config.dart` and replace:

```dart
class SupabaseConfig {
  // Replace with your actual Supabase project URL
  static const String supabaseUrl = 'https://xxxxxxxxxxxxx.supabase.co';
  
  // Replace with your actual Supabase anon/public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // This is already configured correctly
  static const String redirectUrl = 'lifestreak://login-callback';
}
```

## 3. Configure Resend for Email Delivery

### Get Resend API Key
1. Go to https://resend.com
2. Sign up or log in
3. Go to **API Keys**
4. Click **Create API Key**
5. Copy the API key (starts with `re_`)

### Add Domain (if not using resend.dev)
1. Go to **Domains**
2. Click **Add Domain**
3. Add your domain and verify DNS records

### Configure Supabase SMTP
1. In Supabase Dashboard, go to **Authentication** → **Providers**
2. Scroll down to **SMTP Settings**
3. Enter:
   - **Host**: `smtp.resend.com`
   - **Port**: `465`
   - **Username**: `resend`
   - **Password**: Your Resend API key (from step above)
   - **Sender email**: Your verified email (e.g., `noreply@yourdomain.com`)
   - **Sender name**: `Lifestreak` (or your app name)
4. Click **Save**

## 4. Configure Authentication Settings

### Enable Email Provider
1. Go to **Authentication** → **Providers**
2. Enable **Email** if not already enabled
3. **Disable** "Confirm email" (for magic link, confirmation is handled differently)
4. Click **Save**

### Add Redirect URL
1. Go to **Authentication** → **URL Configuration**
2. Under **Redirect URLs**, add:
   ```
   lifestreak://login-callback
   ```
3. Click **Save**

### Customize Magic Link Email (Optional)
1. Go to **Authentication** → **Email Templates**
2. Click on **Magic Link** template
3. Customize the email content as desired
4. Make sure the link uses: `{{ .ConfirmationURL }}`
5. Click **Save**

## 5. Test the Flow

1. Run your app: `flutter run`
2. Enter your email address
3. Click "Send Sign-In Link"
4. Check your email (including spam folder)
5. Click the magic link
6. App should open and authenticate you

## Common Issues

### "Invalid Supabase URL or key"
- Double-check that you copied the correct values from Supabase Dashboard → Settings → API
- Ensure there are no extra spaces or quotes
- Make sure you're using the **Project URL** (not the REST URL)
- Make sure you're using the **anon public** key (not the service role key)

### "Email not sent"
- Verify SMTP configuration in Supabase
- Check Resend API key is valid
- Ensure sender email is verified in Resend
- Check Supabase logs: Authentication → Logs

### "Deep link not opening app"
- Ensure you've run `flutter pub get`
- Rebuild the app completely: `flutter clean && flutter run`
- On Android, check that the scheme is properly configured in AndroidManifest.xml
- On iOS, check Info.plist configuration

### "Session not persisting"
- This is normal during development hot reload
- Do a full app restart to test persistence
- Check that flutter_secure_storage is working

## Next Steps

Once authentication is working:
- Test on physical devices
- Test on TestFlight (iOS)
- Test on Google Play Internal Testing (Android)
- Ensure it works for Apple reviewers (use a real email they can access)

## Environment Variables (Production)

For production, consider using environment variables instead of hardcoding:

```dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_DEFAULT_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_DEFAULT_KEY',
  );
}
```

Build with:
```bash
flutter build apk --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```
