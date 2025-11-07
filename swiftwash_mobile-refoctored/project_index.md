# SwiftWash Codebase Documentation

This document provides a comprehensive overview of the entire SwiftWash codebase, including the mobile app, driver app, operator app, admin app, backend functions, and supporting files.

## Project Status

### Completed Tasks

- [x] **Fix Payment Flow:** Implemented `Future<bool>` in `RazorpayService` to handle payment success and failure; Updated `Step4Widget` to `await` the payment result and handle success and failure cases; Added a dialog to `Step4Widget` to inform the user of payment failure.
- [x] **Fix "My Orders" Screen:** Switched from `FutureBuilder` to `StreamBuilder` to prevent infinite loading and enable real-time updates; Removed the back button to fix the black screen issue; The `OrderCard` now displays the actual items and a formatted timestamp; Added the `items` to the order document in `_saveOrder`.
- [x] **Fix Address Handling:** Updated `add_address_screen.dart` to save addresses to the correct Firestore collection; Updated `order_details_screen.dart` to fetch addresses from the correct collection; Updated `step_3_widget.dart` to use a `StreamBuilder` to display addresses in real-time.
- [x] **Fix Order Details Screen:** The `OrderDetailsScreen` now handles cases where the `items` and `statusHistory` fields are null.
- [x] **Customize Promo Codes:** The discount label is now dynamic based on the promo code used; Added new promo codes for "Aman".
- [x] **Firestore Rules and Indexes:** Created and deployed `firestore.rules` to allow users to read and write their own orders and addresses; Created and deployed `firestore.indexes.json` to support the query in the "My Orders" screen.
- [x] **Fix Address List:** The address list in `step_3_widget.dart` no longer disappears.
- [x] **Implement Location Services:** Integrate Google Maps to allow users to select their location when adding an address; Save the user's latitude and longitude when they save an address.
- [x] **Build Store Operator App:** Create a new Flutter project for the Store Operator app; Implement the login screen for operators; Create the home screen to list orders from Firestore; Build the order details screen with the ability to change the order status; Implement static credentials for operator login; Implemented Google Sign-In.
- [x] **Build Driver App:** Create a new Flutter project for the Driver app; Implement the driver signup and login flow; Create the home screen to show assigned orders.
- [x] **Implement Notifications:** Set up FCM for all three apps.
- [x] **Resolve Build Error:** Fix the build issue related to the `flutter_ringtone_player` package in the operator and driver apps.
- [x] **Mobile App UI and Authentication:** Implemented a splash screen with the correct logo; Fixed UI overflow issues on the login, "Review Your Order", and "Add Address" screens; Updated Firestore security rules to allow authenticated users to read the `orders` collection and read/write to the `addresses` collection; Fixed authentication flow to use `AuthWrapper`.
- [x] **2025 UI Rendering & Safe Area Fixes:** Added `SafeArea` wrappers to `step_1_widget.dart`, `step_2_widget.dart`, `step_3_widget.dart`, `step_4_widget.dart` to prevent bottom buttons from being cut off by Android navigation bar; Added `SafeArea` wrapper to logout confirmation modal to prevent buttons from being hidden behind system UI; Implemented `SafeArea(top: false)` with custom height (82px) for perfect Android safe area handling and clean rendering; Resolved all `RenderFlex overflowed` errors by optimizing nav bar height and removing excessive padding from gradient active indicators; Increased bottom navigation icon size from 24px to 28px and optimized text sizing for better touch targets and readability.
- [x] **UI and Bug Fixes:** Fixed layout issues in `step_2_widget.dart` and `step_3_widget.dart`; Corrected Firestore permissions in `firestore.rules`; Adjusted map marker alignment in `set_pickup_address_screen.dart`; Redesigned the address type selector in `add_address_screen.dart`; Fixed payment flow for zero-value transactions in `step_4_widget.dart`; Resolved a crash on the login screen in `login_screen.dart`; Fixed the "Track Order" button visibility in `home_screen.dart`; Corrected UI overflow in `order_card.dart`; Fixed the item list in `order_details_screen.dart`.
- [x] **Recent Orders Cleanup:** Removed the unused `_RecentOrderCard` widget and related unused state management from `home_screen.dart`; Cleaned up imports and removed unnecessary keywords; Optimized home screen performance by removing unused streams and widgets.
- [x] **Authentication Popup Errors Fix:** Removed problematic Firebase auth state listener from home screen initState that was causing setState during widget destruction; Removed failed clearPersistence call that was causing app crashes; Cleaned up excessive empty lines in home_screen.dart.
- [x] **Tracking Screen Navigation Fixes:** Fixed Android back button closing the app instead of navigating properly; Made navigation consistent between top-left back button and Android navigation back button; Fixed overflow errors in status view with responsive design; Updated Razorpay Flutter version to resolve build issues.

### Pending Tasks

- [ ] **Mobile App:** Fix address not being saved after login; Implement a sliding "Track Order" card for multiple ongoing orders.
- [ ] **Driver App:** Continue with implementation - Basic framework completed.
- [ ] **Implement Notifications:** Build the ringing notification feature for the operator and driver apps.

## Project Architecture Overview

SwiftWash is a comprehensive laundry and dry cleaning service platform consisting of **four Flutter applications**:

1. **SwiftWash Mobile App** (`swiftwash_mobile/`) - Customer-facing application for placing orders
2. **SwiftWash Operator App** (`swiftwash_operator/`) - For operators managing orders and driver assignments
3. **SwiftWash Driver App** (`swiftwash_driver/`) - For drivers to receive and complete orders
4. **SwiftWash Admin App** (`swiftwash_admin/`) - Founder-exclusive administrative dashboard

All apps are built with Flutter and use Firebase for backend services including Authentication, Firestore, Cloud Functions, and Notifications.

## Directory Structure

### Root Level
- `add_dependency.bat` - Batch script for adding dependencies
- `build_and_run.bat` - Automated build and run scripts
- `build_app.bat`, `build_apps.bat`, `build_mobile_app.bat` - Build scripts for different apps
- `deploy_functions.bat`, `deploy_index.bat`, `deploy_rules.bat` - Firebase deployment scripts
- `run_app.bat`, `run_mobile_app.bat`, `run_driver_app.bat`, `run_operator_app.bat` - Run scripts for different apps
- `update_dependencies.bat`, `update_mobile_dependencies.bat` - Dependency update scripts
- `get_sha1.bat`, `get_sha1_keytool.bat` - SHA-1 key generation scripts
- `setup_firebase_apps.bat`, `verify_firebase_setup.bat` - Firebase configuration scripts
- `reset_password.bat` - Password reset utility
- `SwiftWash.mp3` - Audio file
- `lib/` - Shared libraries
- `swiftwash_mobile/` - Main mobile app
- `swiftwash_operator/` - Operator management app
- `swiftwash_driver/` - Driver delivery app
- `swiftwash_admin/` - Administrative dashboard

### Shared Libraries (`lib/`)
- `screens/otp_screen.dart` - Shared OTP verification screen

## SwiftWash Mobile App (`swiftwash_mobile/`)

### Main Libraries and Services

#### Core Services
- `api_service.dart` - API communication utilities
- `cart_service.dart` - Shopping cart management
- `razorpay_service.dart` - Payment processing integration
- `notification_service.dart` - Push notifications handling
- `gps_tracking_service.dart` - Location tracking services

#### Advanced Services
- `enhanced_order_service.dart` - Enhanced order management
- `enhanced_tracking_service.dart` - Advanced GPS tracking
- `audio_ring_service.dart` - Audio notifications
- `custom_marker_service.dart` - Custom map markers
- `image_cache_service.dart` - Image caching utilities
- `crash_analytics_service.dart` - Crash reporting
- `offline_manager.dart` - Offline data handling
- `facility_service.dart` - Facility management
- `express_order_service.dart` - Express delivery handling

### Models
- `order_model.dart` - Order data structures
- `enhanced_order_model.dart` - Advanced order models
- `order_status_model.dart` - Order status definitions

### Screens (25 Total)

#### Authentication & Onboarding
- `login_screen.dart` - User login interface
- `otp_screen.dart` - OTP verification
- `phone_verification_screen.dart` - Phone verification flow
- `phone_verification_test.dart` - Phone verification testing
- `onboarding_screen.dart` - Initial app onboarding
- `splash_screen.dart` - App startup screen
- `personal_details_screen.dart` - User profile setup

#### Address Management
- `saved_addresses_screen.dart` - Address list management
- `add_address_screen.dart` - Address creation/editing
- `set_pickup_address_screen.dart` - Map-based address selection

#### Services & Ordering
- `service_selection_screen.dart` - Service type selection
- `order_process_screen.dart` - Multi-step ordering flow
- `step_1_screen.dart`, `step_2_screen.dart`, `step_3_screen.dart`, `step_4_screen.dart` - Order flow steps
- `pickup_and_delivery_screen.dart` - Schedule pickup/delivery

#### Order Management
- `orders_screen.dart` - Complete order history management
- `order_details_screen.dart` - Individual order details
- `tracking_screen.dart` - Real-time order tracking
- `enhanced_tracking_screen.dart` - Advanced tracking interface
- `enhanced_orders_screen.dart` - Enhanced order list view
- `enhanced_order_details_screen.dart` - Advanced order details

#### Additional Features
- `main_screen.dart` - Main app container
- `home_screen.dart` - Service discovery and dashboard
- `profile_screen.dart` - User profile management
- `user_profile_screen.dart` - Advanced profile settings
- `help_and_support_screen.dart` - Customer support chat
- `premium_screen.dart` - Premium features
- `payment_methods_screen.dart` - Payment method management
- `avatar_selection_screen.dart` - User avatar selection
- `coming_soon_screen.dart` - Placeholder for upcoming features
- `test_screen.dart` - Testing/debugging interface

### Widgets (25 Total)

#### Core UI Components
- `iron_icon.dart`, `washing_machine_icon.dart` - Service-specific icons
- `gradient_progress_bar.dart` - Progress indicators
- `custom_icons.dart` - Custom icon implementations

#### Step Flow Widgets
- `step_1_widget.dart`, `step_2_widget.dart`, `step_3_widget.dart`, `step_4_widget.dart` - Order flow widget components

#### Enhanced Components
- `enhanced_order_card.dart` - Advanced order display
- `order_timeline_widget.dart` - Order progress timeline

#### UI Elements
- `order_card.dart` - Order list/display cards
- `order_summary_widget.dart` - Order summary display
- `dynamic_card_widget.dart` - Flexible card layouts
- `timeline_widget.dart` - Order status timelines

#### Utility Widgets
- `dynamic_steps_widget.dart` - Dynamic step indicators
- `order_timeline_widget.dart` - Order progress visualization

### Assets
- 6 logo variations in different formats and resolutions
- `SwiftWash logo S no bgn.png` - Logo without background
- `washing machine minimal.png` - Service-specific icons

### Firebase Functions
Located in `swiftwash_mobile/functions/swiftwash-alpha/`

#### Main Functions (`index.js`)
- `setUserRole` - Sets custom claims for role-based access
- `createUser` - Creates new user accounts
- `updateUserPassword` - Password management
- `generateOrderId` - Unique order ID generation with city codes
- `chatWithSwiftBot` - AI-powered customer support chatbot

#### Configuration Files
- `firebase.json` - Firebase project configuration
- `firestore.rules` - Database security rules
- `firestore.indexes.json` - Query optimization indexes
- `package.json` - Node.js dependencies
- `.firebaserc` - Project aliases

### Backend (Legacy)
Located in `swiftwash_mobile/backend/` (appears to be legacy/unused)
- Basic Node.js setup with Express patterns
- `.env`, `.gitignore` - Configuration files

## SwiftWash Operator App (`swiftwash_operator/`)

### Architecture
- Flutter app for operators managing laundry operations
- Provider pattern for state management
- Real-time order tracking and driver assignment

### Key Screens
- `login_screen.dart`, `otp_screen.dart`, `phone_login_screen.dart` - Authentication
- `google_login_screen.dart` - Alternative authentication
- `home_screen.dart` - Main dashboard with order management
- `enhanced_operator_home_screen.dart` - Advanced dashboard
- `order_details_screen.dart` - Detailed order view
- `driver_assignment_screen.dart` - Assign drivers to orders
- `processing_status_screen.dart` - Order status management
- `temp_set_role_screen.dart` - Role assignment utilities

### Models
- `order_model.dart` - Order data structures
- `driver_model.dart` - Driver information
- `enhanced_operator_order_model.dart` - Advanced order models

### Providers
- `order_provider.dart` - Order state management
- `admin_provider.dart` (likely for future admin functions)

### Services
- `order_service.dart` - Order CRUD operations
- `driver_service.dart` - Driver management
- `enhanced_operator_service.dart` - Advanced operations
- `notification_service.dart` - Push notifications

### Widgets
- `enhanced_operator_order_card.dart` - Order display components

## SwiftWash Driver App (`swiftwash_driver/`)

### Architecture
- Flutter app designed for drivers managing deliveries
- Comprehensive onboarding and profile management
- Real-time GPS tracking and order assignment

### Key Screens
- `login_screen.dart`, `home_screen.dart` - Core navigation
- `driver_home_screen.dart` - Main driver interface
- `driver_onboarding_screen.dart` - Multi-step onboarding process
- `order_details_screen.dart` - Order details for drivers

### Models
- `driver_profile_model.dart` - Comprehensive driver profiles including employment, performance, and vehicle data

### Providers
- `driver_onboarding_provider.dart` - Onboarding state management

### Services
- `driver_service.dart` - Driver data and operations
- `background_location_service.dart` - GPS tracking
- `notification_service.dart` - Push notifications

### Utilities
- `validators.dart` - Input validation utilities

### Widgets
- `driver_order_card.dart` - Driver-specific order display
- `onboarding/` subdirectory with step-by-step onboarding widgets
  - `bank_details_step.dart` - Bank account setup
  - `documents_step.dart` - Document uploads
  - `emergency_contact_step.dart` - Emergency contact info
  - `personal_info_step.dart` - Personal information
  - `vehicle_info_step.dart` - Vehicle registration
  - `document_upload_section.dart` - Reusable upload component

## SwiftWash Admin App (`swiftwash_admin/`)

### Architecture
- Founder-exclusive administrative dashboard
- No Firebase Authentication - hardcoded credentials for founders only
- Comprehensive business analytics and management tools

### Authentication
- `auth_provider.dart` - Founder authentication system
- `login_screen.dart` - Simple username/password login
- Only two users: `manas-founder` and `kashinath-founder`

### Dashboard Features
- `dashboard_screen.dart` - Main analytics dashboard
- Real-time business metrics including orders, users, drivers, revenue
- Analytics cards, revenue charts, recent orders display
- Management tabs for users, drivers, and orders

### Dashboard Widgets
Located in `widgets/dashboard/` subdirectory:
- `analytics_cards.dart` - Key performance indicators
- `driver_stats_card.dart` - Driver performance metrics
- `recent_orders_card.dart` - Order history overview
- `revenue_chart.dart` - Revenue visualization

### State Management
- `dashboard_provider.dart` - Analytics data management
- `admin_provider.dart` - Administrative operations

### Services
- `secure_api_service.dart` - Secure API communications

### Utilities
- `app_theme.dart` - Application theming
- `env_config.dart` - Environment configuration
- `security_utils.dart` - Security utilities

## Configuration and Assets

### Firebase Setup
5 Firebase apps configured across all Flutter applications:
- 2 iOS apps (Mobile + Operator)
- 3 Android apps (Mobile + Operator + Driver + Admin)

### Theme System
- Applied to all apps using Material Design 3
- Custom color palettes and typography
- Inter font family for modern appearance

### Shared Dependencies
- `flutter/material.dart` - Core Flutter UI framework
- `firebase_core`, `firebase_auth` - Firebase Authentication
- `cloud_firestore` - Database operations
- `firebase_messaging` - Push notifications
- `google_maps_flutter`, `location` - Maps and location services
- `razorpay_flutter` - Payment processing

### Unique Dependencies per App
- **Mobile:** `google_fonts`, `dots_indicator`, `font_awesome_flutter`
- **Operator:** `provider`, `url_launcher`, `permission_handler`
- **Driver:** `image_picker`, `intl`
- **Admin:** Custom implementation with crypto for founder authentication

## Recent Updates and Bug Fixes

### Step 3 Order Review Screen Button Fixes
- **Fixed "+" (Add Address) Button**: Replaced non-responsive GestureDetector with improved HitTestBehavior.opaque implementation and enhanced visual styling (larger blue icon with background)
- **Enhanced Back Button Debugging**: Added diagnostic logging to track button tap events for navigation debugging
- **Improved Button Responsiveness**: Increased touch targets and visual feedback for better user experience

### Order Placement Navigation and Error Handling
- **fixed Red Error Screen After Order Placement**: Resolved problematic double navigation calls (`pushNamedAndRemoveUntil` + `pushReplacement`) causing widget lifecycle errors
- **Added Widget Lifecycle Checks**: Implemented `mounted` property checks in async operations to prevent state updates on disposed widgets
- **Improved Navigation Flow**: Simplified order placement success/failure navigation paths with proper delays for UI completion
- **Enhanced Async Error Handling**: Added proper try-catch blocks and error boundary management for payment operations

### Widget Lifecycle and Framework Stability
- **Fixed Competing Positioned Widgets**: Resolved "Incorrect use of ParentDataWidget" error by removing duplicate Positioned wrapper in `_StackedTrackOrderCards` widget
- **Eliminated Build During Build Errors**: Prevented `setState()` calls during widget build phase that were causing framework exceptions
- **Stable Home Screen**: Ensured home screen loads properly without widget conflicts after hot restart
- **Zone Mismatch Resolution**: Fixed Flutter binding initialization zone conflicts during app startup

### Performance and Reliability
- **Enhanced Payment Flow**: Improved Razorpay integration with robust error handling for both paid and free (promo code) transactions
- **Stream Management**: Better cleanup of Firebase streams to prevent memory leaks and subscription conflicts
- **Firebase Query Optimization**: Enhanced address loading using StreamBuilder for real-time updates and better performance

### Authentication Stability
- Removed problematic Firebase auth state listeners causing popup errors
- Cleaned up stream subscriptions and state management
- Fixed framework crashes during sign-in/sign-out transitions

### UI/UX Improvements
- Optimized home screen by removing unused components
- Enhanced safe area handling for Android navigation
- Improved touch targets and visual hierarchy

### Performance Optimizations
- Cleaned up unused widgets and streams
- Minimized Firebase clearPersistence calls
- Streamlined auth flows for reduced errors

## Build and Deployment Scripts

### Batch Files Summary
- `build_apps.bat` - Build all Flutter apps
- `run_app.bat` series - Run individual apps
- `deploy_functions.bat` - Deploy Firebase Cloud Functions
- `deploy_rules.bat`, `deploy_index.bat` - Deploy Firestore configuration
- Firebase setup and verification utilities

## Cross-Platform Support

All Flutter apps support:
- Android (primary target with native services)
- iOS (secondary with iOS-specific adaptations)
- Web (fallback with limited functionality)
- Windows, Linux, macOS (native desktop builds)

## Development Environment

- Flutter SDK: ^3.9.0
- Firebase CLI: Required for functions deployment
- Android Studio: For native Android modifications
- Xcode: For iOS development
- VS Code: Recommended IDE

The SwiftWash ecosystem represents a production-ready, scalable laundry and dry cleaning service platform with comprehensive mobile and administrative capabilities.

---

## Summary

This documentation covers the complete SwiftWash multi-app Flutter ecosystem providing end-to-end laundry and dry cleaning services. The architecture includes customer mobile app, driver delivery app, operator management app, administrative dashboard, and Firebase backend services for a comprehensive business solution.
