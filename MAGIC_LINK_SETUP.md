# Magic Link Authentication Setup Guide

This guide explains how to complete the setup of magic link authentication for Lifestreak using Supabase.

## Prerequisites

- A Supabase account (https://supabase.com)
- A Resend account for SMTP email delivery (https://resend.com)
- Access to your app's platform configurations (Android/iOS)

## Step 1: Configure Supabase Project

1. **Create a Supabase project** (if not already created):
   - Go to https://app.supabase.com
   - Click "New Project"
   - Fill in project details and click "Create new project"

2. **Enable Email Authentication**:
   - Go to Authentication → Providers
   - Enable "Email" provider
   - Enable "Confirm email" option
   - Save changes

3. **Configure SMTP with Resend**:
   - Go to Authentication → Email Templates
   - Click "SMTP Settings"
   - Enter your Resend SMTP credentials:
     - Host: `smtp.resend.com`
     - Port: `465` or `587`
     - Username: `resend` (literal value)
     - Password: Your Resend API key
   - Sender email: Your verified domain email in Resend
   - Save changes

4. **Configure Magic Link Template**:
   - Go to Authentication → Email Templates
   - Select "Magic Link"
   - Customize the email template as desired
   - Ensure the link points to: `{{ .ConfirmationURL }}`
   - Save changes

5. **Add Redirect URL**:
   - Go to Authentication → URL Configuration
   - Add `lifestreak://login-callback` to the list of Redirect URLs
   - Save changes

## Step 2: Update App Configuration

1. **Add Supabase credentials** to `lib/config/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     static const String redirectUrl = 'lifestreak://login-callback';
   }
   ```

   Get your credentials from:
   - Supabase Dashboard → Settings → API
   - URL: Project URL
   - Anon Key: anon/public key

## Step 3: Test the Authentication Flow

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test sign-in**:
   - Enter your email address
   - Click "Send Sign-In Link"
   - Check your email inbox (and spam folder)
   - Click the magic link in the email
   - App should open and you should be signed in

3. **Verify the flow**:
   - User should be redirected to the main app screen
   - Session should persist across app restarts
   - Sign-out should work correctly

## Step 4: Platform-Specific Configuration (Already Done)

### Android
Deep linking is configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="lifestreak" android:host="login-callback"/>
</intent-filter>
```

### iOS
Deep linking is configured in `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>lifestreak</string>
        </array>
    </dict>
</array>
```

## Troubleshooting

### Email not received
- Check Supabase logs: Authentication → Logs
- Verify SMTP configuration in Supabase
- Check spam/promotions folder
- Verify Resend API key is valid and has sending permissions
- Ensure sender email is verified in Resend

### Deep link not working
- Verify redirect URL is added in Supabase: `lifestreak://login-callback`
- On Android, check if the app is set to handle the custom scheme
- On iOS, ensure Info.plist is properly configured
- Clear app data and reinstall

### App crashes on startup
- Verify Supabase credentials are correct in `supabase_config.dart`
- Check that `flutter pub get` was run successfully
- Review error logs in the console

### Session not persisting
- Check that SessionStorage is working correctly
- Verify Supabase session is being created
- Check auth state listener in auth_provider.dart

## Architecture Overview

The authentication system consists of:

1. **Supabase Config** (`lib/config/supabase_config.dart`):
   - Stores Supabase URL and keys
   - Defines redirect URL

2. **Auth Provider** (`lib/providers/auth_provider.dart`):
   - Manages authentication state
   - Listens to Supabase auth state changes
   - Handles sign-in and sign-out

3. **Auth Screen** (`lib/screens/auth_screen.dart`):
   - Email input form
   - Sends magic link
   - Shows success message

4. **Deep Link Service** (`lib/services/deep_link_service.dart`):
   - Listens for deep link callbacks
   - Handles magic link redirects

5. **Platform Configuration**:
   - Android: AndroidManifest.xml
   - iOS: Info.plist

## Security Notes

- Never commit Supabase credentials to version control
- Use environment variables for production builds
- Ensure HTTPS is used for all Supabase API calls
- Magic links expire after 1 hour by default (configurable in Supabase)
- Sessions are stored securely using flutter_secure_storage

## Apple App Review Compatibility

This implementation is designed to pass Apple App Review:
- Real email delivery via Resend SMTP
- No hardcoded test accounts
- No developer intervention required
- Works end-to-end on TestFlight builds
- No password required (passwordless authentication)

## Support

For issues related to:
- **Supabase**: https://supabase.com/docs
- **Resend**: https://resend.com/docs
- **Flutter**: https://flutter.dev/docs
- **uni_links**: https://pub.dev/packages/uni_links
