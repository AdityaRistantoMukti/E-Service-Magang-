# TODO: Replace Splash Screen with Video

## Tasks
- [x] Add video_player dependency to pubspec.yaml
- [x] Add splash_screen.mp4 asset to pubspec.yaml
- [x] Modify main.dart to use VideoPlayer instead of animation for splash screen
- [x] Ensure navigation logic remains unchanged after video playback
- [x] Test the changes to verify video plays and navigation works

# TODO: Test Birthday Notification Service

## Tasks
- [x] Create unit tests for BirthdayNotificationService
- [x] Test resetDailyNotifications functionality
- [x] Test scheduleDailyBirthdayCheck method
- [x] Verify dummy data structure for testing
- [x] Run tests and ensure they pass

# TODO: Integrate Midtrans Payment with WebView

## Tasks
- [x] Create MidtransWebView widget for in-app payment processing
- [x] Update PaymentService to use WebView instead of external browser
- [x] Remove url_launcher dependency from PaymentService
- [x] Run flutter analyze to check for code issues
- [x] Prepare production-ready configuration
  - [x] Add environment-based configuration (dev/prod URLs and keys)
  - [x] Include webhook URL for production real-time notifications
  - [x] Create WebhookService for handling Midtrans callbacks
  - [x] Optimize polling frequency for production (5s vs 3s in dev)
- [x] Fix Navigator lock error when pressing "Leave this page" button in MidtransWebView
