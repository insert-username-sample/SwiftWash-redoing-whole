# SwiftWash Admin App - Complete Technical Specification

## 📋 Overview

This document provides the complete technical specification for the SwiftWash Admin App, including all API configurations, security measures, database structure, and implementation requirements.

## 🔐 Authentication & Security

### Admin Profile Structure

Based on your existing database, here's the admin profile structure:

```javascript
{
  createdAt: "September 28, 2025 at 12:00:00 AM UTC+5:30", // timestamp
  isEmailVerified: false, // boolean
  isPhoneVerified: false, // boolean
  managedStoreIds: [""], // array of store IDs
  name: "Kashi Admin", // string
  permissions: { // map of permissions
    manageAdmins: true, // boolean
    manageOperators: true, // boolean
    manageSettings: true, // boolean
    manageStores: true, // boolean
    manageSupport: true, // boolean
    viewAllData: true, // boolean
    viewReports: true // boolean
  },
  phone: "9372393537", // string
  profileImageUrl: null, // null
  role: 0, // number (0 = super admin, 1 = store admin, 2 = support admin)
  username: "kashi" // string
}
```

### Required Admin Users

**Super Admin:**
- Username: `kashi`
- Phone: `9372393537`
- Role: `0` (Super Admin)
- Permissions: All permissions enabled

**Additional Admin:**
- Username: `manas`
- Phone: `9359652870`
- Role: `0` (Super Admin)
- Permissions: All permissions enabled

## 🔑 API Keys & Configuration

### Google Cloud Console APIs (Required)

#### 1. Google Maps Platform APIs
- **Maps SDK for Android**: For displaying maps in the Android app.
  - **Restriction**: Android apps
  - **Package name**: `com.example.swiftwash_mobile`
  - **SHA-1 fingerprint**: `C7:01:B9:C3:F4:64:40:77:9D:6D:C9:FD:51:2D:8C:20:E5:97:D0:D2`
- **Places API**: For location search and autocomplete.
  - **Restriction**: Android apps
  - **Package name**: `com.example.swiftwash_mobile`
  - **SHA-1 fingerprint**: `C7:01:B9:C3:F4:64:40:77:9D:6D:C9:FD:51:2D:8C:20:E5:97:D0:D2`
- **Geocoding API**: For converting addresses to coordinates and vice-versa.
  - **Restriction**: Android apps
  - **Package name**: `com.example.swiftwash_mobile`
  - **SHA-1 fingerprint**: `C7:01:B9:C3:F4:64:40:77:9D:6D:C9:FD:51:2D:8C:20:E5:97:D0:D2`
- **Directions API**: For calculating routes and directions.
  - **Restriction**: Android apps
  - **Package name**: `com.example.swiftwash_mobile`
  - **SHA-1 fingerprint**: `C7:01:B9:C3:F4:64:40:77:9D:6D:C9:FD:51:2D:8C:20:E5:97:D0:D2`

**Note**: For iOS, separate API keys with iOS app restrictions (Bundle ID) will be required.

#### 2. Firebase Project Configuration

- **Project ID**: `swiftwash-v0-1`
- **Project Number**: `926846064467`
- **Web API Key**: `AIzaSyBRDqcI8o-BM85YNr-OhzzDlynqGe3GMpk` (This is the unrestricted key from `google-services.json`. It is recommended to use a restricted key for client-side applications.)

#### 3. OAuth 2.0 Client IDs (for Google Sign-In)

- **Android Client**:
  - **Package name**: `com.example.swiftwash_mobile`
  - **SHA-1 fingerprint**: `C7:01:B9:C3:F4:64:40:77:9D:6D:C9:FD:51:2D:8C:20:E5:97:D0:D2`
  - **Status**: Needs to be added in Firebase Console under Authentication -> Sign-in method -> Google.

#### 4. UPI Payment Configuration

- **UPI Handle**: `manas-kashinath@ptaxis`
- **Merchant Name**: `SwiftWash Laundry`
- **Currency**: `INR`

### Environment Variables (`.env` file)

The `.env` file should contain the following variables. Replace placeholder values with your actual restricted keys and configurations.

```env
# Google Maps API Key (Restricted for Android)
GOOGLE_MAPS_API_KEY=YOUR_RESTRICTED_GOOGLE_MAPS_API_KEY_HERE

# Supabase Configuration (if applicable)
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

# UPI Payment Configuration
UPI_HANDLE=manas-kashinath@ptaxis
MERCHANT_NAME=SwiftWash Laundry
CURRENCY=INR

# OpenAI API Key (if using AI features)
OPENAI_API_KEY=YOUR_OPENAI_API_KEY

# Firebase Configuration (from google-services.json or Firebase Console)
FIREBASE_API_KEY=AIzaSyBRDqcI8o-BM85YNr-OhzzDlynqGe3GMpk # Replace with a restricted key if possible
FIREBASE_AUTH_DOMAIN=swiftwash-v0-1.firebaseapp.com
FIREBASE_PROJECT_ID=swiftwash-v0-1
FIREBASE_STORAGE_BUCKET=swiftwash-v0-1.appspot.com
FIREBASE_MESSAGING_SENDER_ID=926846064467
FIREBASE_APP_ID=1:926846064467:android:99c9f8dda987d2df1a73a6
```

## 🗺️ Database Structure (Firestore)

### Collections Overview

- **`users`**: Stores customer profiles.
- **`addresses`**: Stores customer addresses, linked to `users`.
- **`orders`**: Manages laundry orders.
- **`admins`**: Stores admin user profiles and their permissions.
- **`drivers`**: Stores delivery personnel profiles.
- **`subscriptions`**: Manages premium subscriptions.
- **`support_chats`**: Stores support chat sessions.
- **`support_messages`**: Stores messages within support chats.
- **`notifications`**: Manages user notifications.
- **`system`**: Stores global system configurations (admin-only).
- **`public`**: Stores publicly accessible data.

### Detailed Collection Schemas

#### 1. `users` Collection
- **Document ID**: Firebase Auth `uid`
- **Fields**:
  - `uid`: string (Firebase Auth User ID)
  - `email`: string
  - `phoneNumber`: string
  - `displayName`: string
  - `profileImageUrl`: string (optional)
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `isEmailVerified`: boolean
  - `isPhoneVerified`: boolean

#### 2. `addresses` Collection
- **Document ID**: Auto-generated
- **Fields**:
  - `userId`: string (Foreign key to `users` collection)
  - `addressType`: string (e.g., "Home", "Work", "Other")
  - `flatHouseNo`: string
  - `buildingName`: string (optional)
  - `street`: string
  - `landmark`: string (optional)
  - `city`: string
  - `pincode`: string
  - `latitude`: double
  - `longitude`: double
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

#### 3. `orders` Collection
- **Document ID**: Auto-generated
- **Fields**:
  - `orderId`: string (Custom generated ID, e.g., "ORD123-S")
  - `userId`: string (Foreign key to `users` collection)
  - `driverId`: string (Foreign key to `drivers` collection, optional)
  - `addressId`: string (Foreign key to `addresses` collection)
  - `itemTotal`: double
  - `swiftCharge`: double
  - `discount`: double
  - `finalTotal`: double
  - `status`: string (e.g., "new", "processing", "picked_up", "delivered", "cancelled")
  - `serviceName`: string (e.g., "Laundry Service", "Ironing Service")
  - `items`: array of maps (details of items in the order)
  - `currentProcessingStatus`: string (e.g., "sorting", "washing", "drying")
  - `processingStatuses`: array of maps (history of processing statuses with timestamps)
  - `paymentStatus`: string (e.g., "pending", "paid", "failed")
  - `paymentMethod`: string (e.g., "UPI", "Card", "Wallet")
  - `paymentId`: string (Transaction ID from payment gateway)
  - `pickupDate`: timestamp
  - `deliveryDate`: timestamp
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

#### 4. `admins` Collection
- **Document ID**: Firebase Auth `uid`
- **Fields**:
  - `uid`: string (Firebase Auth User ID)
  - `email`: string
  - `phoneNumber`: string
  - `name`: string
  - `username`: string
  - `profileImageUrl`: string (optional)
  - `role`: number (0 = Super Admin, 1 = Store Admin, 2 = Support Admin)
  - `permissions`: map (as defined in "Admin Profile Structure")
  - `managedStoreIds`: array of strings (store IDs managed by this admin)
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `isEmailVerified`: boolean
  - `isPhoneVerified`: boolean

#### 5. `drivers` Collection
- **Document ID**: Firebase Auth `uid`
- **Fields**:
  - `uid`: string (Firebase Auth User ID)
  - `email`: string
  - `phoneNumber`: string
  - `name`: string
  - `profileImageUrl`: string (optional)
  - `currentLocation`: geopoint (real-time location)
  - `status`: string (e.g., "available", "on_duty", "offline")
  - `assignedOrders`: array of strings (order IDs currently assigned)
  - `storeId`: string (Store ID the driver is assigned to)
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

#### 6. `subscriptions` Collection
- **Document ID**: Auto-generated
- **Fields**:
  - `userId`: string (Foreign key to `users` collection)
  - `planName`: string (e.g., "Premium", "Swift Premium")
  - `planPrice`: double
  - `startDate`: timestamp
  - `endDate`: timestamp
  - `status`: string (e.g., "active", "cancelled", "expired", "trial")
  - `paymentId`: string (Transaction ID for subscription payment)
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

#### 7. `support_chats` Collection
- **Document ID**: Auto-generated
- **Fields**:
  - `userId`: string (Foreign key to `users` collection)
  - `adminId`: string (Foreign key to `admins` collection, optional)
  - `status`: string (e.g., "open", "closed", "pending_user", "pending_admin")
  - `subject`: string
  - `lastMessageAt`: timestamp
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

#### 8. `support_messages` Collection
- **Document ID**: Auto-generated
- **Fields**:
  - `chatId`: string (Foreign key to `support_chats` collection)
  - `senderId`: string (Firebase Auth `uid` of sender - user or admin)
  - `message`: string
  - `timestamp`: timestamp
  - `readBy`: array of strings (UIDs of users who read the message)

#### 9. `notifications` Collection
- **Document ID**: Auto-generated
- **Fields**:
  - `userId`: string (Foreign key to `users` collection, optional for broadcast)
  - `adminId`: string (Foreign key to `admins` collection, optional for admin-specific)
  - `storeId`: string (Foreign key to `stores` collection, optional for store-specific)
  - `title`: string
  - `body`: string
  - `type`: string (e.g., "order_update", "promotion", "system_alert")
  - `read`: boolean
  - `createdAt`: timestamp

#### 10. `system` Collection
- **Document ID**: `config` (singleton document)
- **Fields**:
  - `minAppVersion`: string
  - `maintenanceMode`: boolean
  - `featureFlags`: map (e.g., `{"newFeatureEnabled": true}`)
  - `updatedAt`: timestamp

## 🔥 Firebase Security Rules

The updated Firestore Security Rules (`functions/firestore.rules`) ensure a secure, role-based access control system for all collections.

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isAdmin() {
      return isAuthenticated() &&
             exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    // Users Collection (Mobile App Users)
    match /users/{userId} {
      // Users can read/write their own profile
      allow read, write: if isOwner(userId);

      // Admins can read all user profiles for management
      allow read: if isAdmin();

      // Allow creation of user profiles during registration
      allow create: if isAuthenticated();
    }

    // Addresses Collection
    match /addresses/{addressId} {
      // Users can read/write their own addresses
      allow read, write: if isAuthenticated() && isOwner(resource.data.userId);

      // Admins can read all addresses for management
      allow read: if isAdmin();

      // Allow creation of addresses by authenticated users
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);
    }

    // Orders Collection
    match /orders/{orderId} {
      // Users can read their own orders
      allow read: if isAuthenticated() && isOwner(resource.data.userId);

      // Users can create orders
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);

      // Users can update their own orders (for cancellation, etc.)
      allow write: if isAuthenticated() && isOwner(resource.data.userId);

      // Admins can read/write all orders for management
      allow read, write: if isAdmin();
    }

    // Admins Collection (Management App Users)
    match /admins/{adminId} {
      // Admins can read/write their own profile
      allow read, write: if isOwner(adminId) && isAdmin();

      // Super admins can read all admin profiles
      allow read: if isAdmin();

      // Allow creation of admin profiles (only by existing admins)
      allow create: if isAdmin() && isOwner(adminId);
    }

    // Drivers Collection (Delivery Personnel)
    match /drivers/{driverId} {
      // Drivers can read/write their own profile
      allow read, write: if isOwner(driverId) && isAuthenticated();

      // Admins can read/write all driver profiles for management
      allow read, write: if isAdmin();

      // Allow driver creation during onboarding
      allow create: if isAuthenticated() && isOwner(driverId);
    }

    // Subscriptions Collection (Premium Users)
    match /subscriptions/{subscriptionId} {
      // Users can read their own subscriptions
      allow read: if isAuthenticated() && isOwner(resource.data.userId);

      // Users can create subscriptions
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);

      // Admins can read all subscriptions for management
      allow read: if isAdmin();
    }

    // Support Collections (Customer Support)
    match /support_chats/{chatId} {
      // Users can read/write their own support chats
      allow read, write: if isAuthenticated() && (
        isOwner(resource.data.userId) ||
        isOwner(resource.data.adminId)
      );

      // Admins can read/write all support chats
      allow read, write: if isAdmin();

      // Allow creation of support chats
      allow create: if isAuthenticated();
    }

    match /support_messages/{messageId} {
      // Users can read/write messages in their support chats
      allow read, write: if isAuthenticated() && (
        isOwner(resource.data.userId) ||
        isOwner(resource.data.adminId)
      );

      // Admins can read/write all support messages
      allow read, write: if isAdmin();

      // Allow creation of support messages
      allow create: if isAuthenticated();
    }

    // Notifications Collection
    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if isAuthenticated() && isOwner(resource.data.userId);

      // Users can delete their own notifications
      allow delete: if isAuthenticated() && isOwner(resource.data.userId);

      // Admins can create notifications for users
      allow create: if isAdmin();

      // Admins can read all notifications
      allow read: if isAdmin();
    }

    // System Configuration (Admin Only)
    match /system/{document=**} {
      // Only admins can read/write system configuration
      allow read, write: if isAdmin();
    }

    // Public Data (Read-only for all authenticated users)
    match /public/{document=**} {
      allow read: if isAuthenticated();
      allow write: if false;
    }

    // Deny all other access by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 📊 Firestore Indexes

The `functions/firestore.indexes.json` file should contain the following composite indexes to support efficient querying:

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "storeId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "addresses",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "addressType",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "addresses",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "updatedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "phoneNumber",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "operators",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "storeId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "role",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

## 🚀 Next Steps

Now that the complete technical specification is ready, you can proceed with developing the SwiftWash Admin App.

**Would you like me to:**
1. **Create the basic Flutter project structure** for the `swiftwash_admin` app?
2. **Implement the user listing screen** as described in the README?
3. **Help you set up Firebase Authentication** for the admin app?

Let me know how you'd like to proceed with the implementation!</result>
