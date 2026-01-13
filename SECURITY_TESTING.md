# Security Fixes Testing Guide

This guide provides instructions for manually testing the 3 critical security vulnerabilities that were fixed in commit `aa0636f`.

## Commits
- **Security Fixes**: `aa0636f` - Fix critical security vulnerabilities from security audit
- **Compilation Fix**: `890be3a` - Fix compilation error in pin_setup_screen.dart

## Testing Environment

You can test on any of these platforms:
- **Android Device/Emulator** (recommended for full testing)
- **iOS Device/Simulator** (recommended for full testing)
- **Flutter Web** (limited testing - screenshot protection won't work)

### Quick Start
```bash
# For Android
flutter run -d <android-device-id>

# For iOS
flutter run -d <ios-device-id>

# For Web (lighter on resources)
flutter run -d chrome
```

## Test 1: HTTPS Enforcement ✅

**Location**: `lib/services/idena_service.dart:18-27`

**What was fixed**: All RPC connections now enforce HTTPS-only, preventing man-in-the-middle attacks.

### How to Test

1. **Run the app** and create/import an account
2. **Verify HTTPS is working**: The app should successfully connect to `https://rpc.idena.dev`
3. **Test HTTP rejection** (requires code modification):
   ```dart
   // Temporarily modify lib/services/idena_service.dart line 9:
   // Change: static const String defaultNodeUrl = 'https://rpc.idena.dev';
   // To:     static const String defaultNodeUrl = 'http://rpc.idena.dev';
   ```
4. **Expected behavior**: App should show error message: "Security Error: Only HTTPS connections are allowed..."
5. **Revert the test change** after verification

### Expected Results
- ✅ HTTPS connections work normally
- ✅ HTTP connections are blocked with clear security error
- ✅ Error message explains the security risk

---

## Test 2: Clipboard Auto-Clear for Mnemonic ✅

**Location**: `lib/screens/backup_mnemonic_screen.dart:289-319`

**What was fixed**: Mnemonic phrase automatically clears from clipboard after 60 seconds.

### How to Test

1. **Run the app** and select "Create New Account"
2. **View the backup mnemonic screen**
3. **Tap "Tap to Reveal Recovery Phrase"**
4. **Tap "Copy to Clipboard"**
5. **Verify the snackbar message**: "Recovery phrase copied. Will auto-clear in 60 seconds for security."
6. **Paste into a text editor immediately** - mnemonic should paste successfully
7. **Wait 60 seconds**
8. **Paste again** - clipboard should now be empty or contain different content

### Expected Results
- ✅ Mnemonic copies to clipboard successfully
- ✅ User sees notification about 60-second auto-clear
- ✅ After 60 seconds, mnemonic is cleared from clipboard
- ✅ If user copies something else within 60 seconds, that content is preserved (only clears if mnemonic is still present)

### Alternative Quick Test
1. Copy mnemonic to clipboard
2. Check clipboard content in a terminal:
   ```bash
   # Linux
   xclip -o -selection clipboard

   # macOS
   pbpaste
   ```
3. Wait 60 seconds
4. Check clipboard again - should be empty

---

## Test 3: Screenshot Protection 📱

**Location**:
- `lib/screens/backup_mnemonic_screen.dart:25-38`
- `lib/screens/import_private_key_screen.dart:21-40`
- `lib/screens/pin_screen.dart:39-55`
- `lib/screens/pin_setup_screen.dart:22-37`

**What was fixed**: Screenshot/screen recording protection enabled on sensitive screens.

### ⚠️ Platform Requirements
- ✅ **Android**: Uses `FLAG_SECURE` - screenshots blocked at OS level
- ✅ **iOS**: Uses blur effect in app switcher
- ❌ **Web**: Not supported (web apps cannot block screenshots)

### How to Test on Android

1. **Run the app on Android device/emulator**
2. **Navigate to each sensitive screen**:
   - PIN setup screen
   - PIN entry screen
   - Backup mnemonic screen (after revealing phrase)
   - Import private key screen
3. **Try to take a screenshot** on each screen (Volume Down + Power)
4. **Expected behavior**:
   - Screenshot should fail
   - Android shows toast: "Can't take screenshot due to security policy"
   - Or screenshot appears completely black

### How to Test on iOS

1. **Run the app on iOS device/simulator**
2. **Navigate to a sensitive screen** (PIN, mnemonic, etc.)
3. **Press home button** or **swipe up** to access app switcher
4. **Expected behavior**:
   - App preview in switcher should be blurred
   - Cannot see sensitive content in app switcher
5. **Try to take a screenshot**:
   - Screenshot may succeed, but content should be blurred/hidden

### How to Test on Web

Screenshot protection **does not work on web** - this is a known limitation. The native platform channels are not available on web.

---

## Additional Security Tests

### Rate Limiting Test
**Location**: `lib/services/idena_service.dart:29-46`

The service now limits to 10 requests per second to prevent API abuse.

**Manual Test** (requires code):
```dart
// Add this test function to test rate limiting
Future<void> testRateLimit() async {
  final service = IdenaService();
  for (int i = 0; i < 15; i++) {
    final start = DateTime.now();
    await service.getEpochInfo();
    print('Request $i took: ${DateTime.now().difference(start).inMilliseconds}ms');
  }
}
```

**Expected**: After 10 requests, subsequent requests should be delayed by ~100ms each.

### Request Timeout Test
**Location**: `lib/services/idena_service.dart:16, 70-77`

All RPC requests have a 30-second timeout.

**Manual Test**: Disconnect from internet and try to create an account.

**Expected**: Should show error after ~30 seconds: "RPC request timed out after 30 seconds"

---

## Verification Checklist

After testing, verify these behaviors:

- [ ] App only connects via HTTPS
- [ ] HTTP connections are blocked with clear error message
- [ ] Mnemonic auto-clears from clipboard after 60 seconds
- [ ] Screenshot protection works on Android (black screenshot or blocked)
- [ ] Screenshot protection works on iOS (blur in app switcher)
- [ ] No compilation errors
- [ ] App builds and runs successfully
- [ ] All screens navigate correctly
- [ ] PIN setup and unlock work properly

---

## Testing on Limited Hardware

If your computer cannot run Android emulator:

### Option 1: Flutter Web (Partial Testing)
```bash
flutter run -d chrome
```
- ✅ Can test HTTPS enforcement
- ✅ Can test clipboard auto-clear
- ❌ Cannot test screenshot protection

### Option 2: Physical Android Device
```bash
# Enable USB debugging on your Android phone
# Connect via USB
flutter devices
flutter run -d <device-id>
```
- ✅ Can test all security features
- ✅ Much lighter on computer resources than emulator

### Option 3: Remote Testing
- Use GitHub Actions for Android build tests
- Use BrowserStack or similar cloud testing platforms
- Request community members to test on their devices

---

## Known Issues

### Web Platform Limitations
- Screenshot protection does not work on web (expected)
- Biometric authentication not available on web
- Some native features may not work

### Compilation Notes
- The `pin_setup_screen.dart` file was converted from `StatelessWidget` to `StatefulWidget` to support lifecycle methods
- This is required for `initState()` and `dispose()` to enable/disable screenshot protection

---

## Reporting Issues

If you find any security issues during testing:

1. **DO NOT** post sensitive details publicly
2. Create a GitHub issue with:
   - Platform (Android/iOS/Web)
   - Flutter version (`flutter --version`)
   - Steps to reproduce
   - Expected vs actual behavior
3. Label as `security` and `bug`

---

## Next Steps

After verifying these fixes work correctly, consider addressing the **5 high-priority** and **6 medium-priority** security issues from the original audit report.

High-priority items include:
- Add NSFaceIDUsageDescription to iOS Info.plist
- Add USE_BIOMETRIC permission to Android manifest
- Improve error message handling (don't expose stack traces)
- Add server certificate pinning
- Implement biometric authentication cooldown
