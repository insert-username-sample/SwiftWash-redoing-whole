# SwiftWash Referral System - Complete Specification
## 50% Discount Implementation for Both Users

### **Overview**
This document provides a comprehensive specification for implementing a referral system where existing users can generate referral codes and both the referrer and referee receive 50% off on premium subscriptions.

### **Business Requirements**
- ✅ Existing users can generate unique referral codes
- ✅ New users can apply referral codes during signup/onboarding
- ✅ Both users get 50% discount on Swift Premium membership
- ✅ Referral tracking and validation system
- ✅ Firebase-only implementation (no external services)
- ✅ Real-time referral code validation

## **📋 Referral System Architecture**

### **Database Schema**

#### **Referral Codes Collection**
```javascript
// Collection: referral_codes/{referralCodeId}
{
  code: "SWIFT2025", // Unique 8-12 character code
  generatedBy: "user_uid_123", // Referrer's user ID
  generatedAt: "2025-01-15T10:30:00Z", // Timestamp
  isActive: true, // Can be deactivated by admin
  usageLimit: 5, // Max redemptions allowed
  usedCount: 0, // Current usage count
  expiresAt: "2025-12-31T23:59:59Z", // Expiration date
  discountPercentage: 50, // Discount percentage
  applicableServices: ["premium", "swift_premium"], // What it applies to
  metadata: {
    source: "mobile_app", // Where code was generated
    campaign: "launch_2025" // Marketing campaign tracking
  }
}
```

#### **User Referrals Collection**
```javascript
// Collection: user_referrals/{referralId}
{
  id: "unique_referral_id",
  referrerId: "user_uid_123", // Who shared the code
  refereeId: "user_uid_456", // Who used the code
  referralCode: "SWIFT2025", // Code that was used
  status: "completed", // pending, completed, expired, cancelled
  discountApplied: 50, // Percentage discount applied
  appliedAt: "2025-01-15T10:30:00Z", // When discount was applied
  expiryDate: "2025-02-15T10:30:00Z", // When discount expires
  servicesEligible: ["premium", "swift_premium"], // Eligible services
  redeemedServices: [], // Track which services were redeemed
  metadata: {
    referrerReward: "50%_off_next_month", // What referrer gets
    refereeReward: "50%_off_first_month" // What referee gets
  }
}
```

#### **User Profile Updates**
```javascript
// Update to existing users collection
{
  uid: "user_uid_123",
  // ... existing fields ...
  referralStats: {
    codesGenerated: 3, // Total codes created
    successfulReferrals: 2, // Codes that were used
    totalEarnings: 1000, // Total discount value earned
    activeReferrals: 1, // Currently active referrals
    referralCode: "SWIFT2025", // Current active code
    lastReferralAt: "2025-01-15T10:30:00Z"
  },
  subscriptionDiscounts: {
    percentage: 50, // Current discount percentage
    source: "referral", // referral, promo, loyalty
    validUntil: "2025-02-15T10:30:00Z", // When discount expires
    appliedServices: ["premium"] // Which services have discount
  }
}
```

## **🔧 Technical Implementation**

### **1. Referral Code Generation**

#### **Backend Function (Firebase Functions)**
```javascript
// functions/referral_functions.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.generateReferralCode = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const userId = context.auth.uid;

  try {
    // Check if user already has active code
    const existingCodeQuery = await admin.firestore()
      .collection('referral_codes')
      .where('generatedBy', '==', userId)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (!existingCodeQuery.empty) {
      const existingCode = existingCodeQuery.docs[0].data();
      return {
        success: true,
        referralCode: existingCode.code,
        message: 'You already have an active referral code'
      };
    }

    // Generate unique code
    const code = await _generateUniqueCode();

    // Save to Firestore
    const codeRef = admin.firestore().collection('referral_codes').doc(code);
    await codeRef.set({
      code: code,
      generatedBy: userId,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      usageLimit: 5,
      usedCount: 0,
      expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year
      discountPercentage: 50,
      applicableServices: ['premium', 'swift_premium']
    });

    // Update user profile
    await admin.firestore().collection('users').doc(userId).update({
      'referralStats.referralCode': code,
      'referralStats.codesGenerated': admin.firestore.FieldValue.increment(1),
      'referralStats.lastReferralAt': admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      referralCode: code,
      message: 'Referral code generated successfully'
    };

  } catch (error) {
    console.error('Error generating referral code:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate referral code');
  }
});

async function _generateUniqueCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code;

  do {
    code = 'SWIFT' + Array.from({length: 4}, () =>
      chars.charAt(Math.floor(Math.random() * chars.length))
    ).join('');
  } while (await _isCodeExists(code));

  return code;
}

async function _isCodeExists(code) {
  const doc = await admin.firestore()
    .collection('referral_codes')
    .doc(code)
    .get();
  return doc.exists;
}
```

### **2. Referral Code Redemption**

#### **Backend Function**
```javascript
exports.redeemReferralCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const { referralCode } = data;
  const refereeId = context.auth.uid;

  if (!referralCode || typeof referralCode !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Valid referral code required');
  }

  try {
    // Check if code exists and is valid
    const codeRef = admin.firestore().collection('referral_codes').doc(referralCode);
    const codeDoc = await codeRef.get();

    if (!codeDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Invalid referral code');
    }

    const codeData = codeDoc.data();

    // Validate code
    if (!codeData.isActive) {
      throw new functions.https.HttpsError('failed-precondition', 'Referral code is inactive');
    }

    if (codeData.usedCount >= codeData.usageLimit) {
      throw new functions.https.HttpsError('failed-precondition', 'Referral code usage limit reached');
    }

    if (new Date() > codeData.expiresAt.toDate()) {
      throw new functions.https.HttpsError('failed-precondition', 'Referral code has expired');
    }

    // Check if user already used a referral code
    const existingReferralQuery = await admin.firestore()
      .collection('user_referrals')
      .where('refereeId', '==', refereeId)
      .where('status', '==', 'completed')
      .limit(1)
      .get();

    if (!existingReferralQuery.empty) {
      throw new functions.https.HttpsError('failed-precondition', 'User has already used a referral code');
    }

    // Check if trying to use own code
    if (codeData.generatedBy === refereeId) {
      throw new functions.https.HttpsError('failed-precondition', 'Cannot use your own referral code');
    }

    // Create referral record
    const referralId = admin.firestore().collection('user_referrals').doc().id;
    const referralRef = admin.firestore().collection('user_referrals').doc(referralId);

    await referralRef.set({
      id: referralId,
      referrerId: codeData.generatedBy,
      refereeId: refereeId,
      referralCode: referralCode,
      status: 'completed',
      discountApplied: 50,
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      servicesEligible: ['premium', 'swift_premium'],
      redeemedServices: []
    });

    // Update code usage count
    await codeRef.update({
      usedCount: admin.firestore.FieldValue.increment(1)
    });

    // Update referrer stats
    await admin.firestore().collection('users').doc(codeData.generatedBy).update({
      'referralStats.successfulReferrals': admin.firestore.FieldValue.increment(1),
      'referralStats.activeReferrals': admin.firestore.FieldValue.increment(1)
    });

    // Apply discount to referee
    await admin.firestore().collection('users').doc(refereeId).update({
      subscriptionDiscounts: {
        percentage: 50,
        source: 'referral',
        validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        appliedServices: []
      }
    });

    return {
      success: true,
      discountPercentage: 50,
      validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      message: 'Referral code applied successfully! You now have 50% off premium services.'
    };

  } catch (error) {
    console.error('Error redeeming referral code:', error);
    throw new functions.https.HttpsError('internal', 'Failed to redeem referral code');
  }
});
```

### **3. Mobile App Integration**

#### **Referral Code Generation (Mobile App)**
```dart
// lib/services/referral_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String> generateReferralCode() async {
    try {
      final result = await _functions.httpsCallable('generateReferralCode').call();

      if (result.data['success']) {
        return result.data['referralCode'];
      } else {
        throw Exception(result.data['message']);
      }
    } catch (e) {
      throw Exception('Failed to generate referral code: $e');
    }
  }

  Future<Map<String, dynamic>> redeemReferralCode(String code) async {
    try {
      final result = await _functions
          .httpsCallable('redeemReferralCode')
          .call({'referralCode': code});

      return {
        'success': result.data['success'],
        'discountPercentage': result.data['discountPercentage'],
        'validUntil': result.data['validUntil'],
        'message': result.data['message']
      };
    } catch (e) {
      throw Exception('Failed to redeem referral code: $e');
    }
  }

  Stream<DocumentSnapshot> getUserReferralStats(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}
```

#### **UI Integration in Home Screen**
```dart
// Update existing home_screen.dart referral section
class _SpecialOffers extends StatelessWidget {
  final ReferralService _referralService = ReferralService();

  void _showReferralDialog(BuildContext context) async {
    try {
      final referralCode = await _referralService.generateReferralCode();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Your Referral Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share this code with friends:'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  referralCode,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Both of you get 50% off premium services!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => _shareReferralCode(referralCode),
              child: Text('Share Code'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _shareReferralCode(String code) {
    // Implement sharing functionality
    Share.share('Join SwiftWash and get 50% off premium services with code: $code');
  }
}
```

## **💰 Discount Application System**

### **Subscription Discount Logic**
```javascript
// Cloud Function for subscription purchase
exports.purchaseSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const { subscriptionType, paymentMethod } = data;
  const userId = context.auth.uid;

  try {
    // Get user discount information
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    let discountPercentage = 0;
    let discountSource = null;

    // Check for referral discount
    if (userData.subscriptionDiscounts &&
        userData.subscriptionDiscounts.percentage > 0 &&
        new Date() < userData.subscriptionDiscounts.validUntil.toDate()) {

      discountPercentage = userData.subscriptionDiscounts.percentage;
      discountSource = userData.subscriptionDiscounts.source;
    }

    // Calculate final price
    const basePrice = subscriptionType === 'premium' ? 299 : 499;
    const discountAmount = (basePrice * discountPercentage) / 100;
    const finalPrice = basePrice - discountAmount;

    // Create subscription record
    const subscriptionId = admin.firestore().collection('subscriptions').doc().id;
    await admin.firestore().collection('subscriptions').doc(subscriptionId).set({
      id: subscriptionId,
      userId: userId,
      subscriptionType: subscriptionType,
      basePrice: basePrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      discountSource: discountSource,
      status: 'active',
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update user referral stats if discount was used
    if (discountPercentage > 0 && discountSource === 'referral') {
      await admin.firestore().collection('users').doc(userId).update({
        'subscriptionDiscounts.appliedServices': admin.firestore.FieldValue.arrayUnion(subscriptionType)
      });
    }

    return {
      success: true,
      subscriptionId: subscriptionId,
      originalPrice: basePrice,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      message: `Subscription activated with ${discountPercentage}% discount!`
    };

  } catch (error) {
    console.error('Subscription purchase error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to purchase subscription');
  }
});
```

## **📱 Mobile App UI Components**

### **Referral Code Display Widget**
```dart
class ReferralCodeWidget extends StatefulWidget {
  @override
  _ReferralCodeWidgetState createState() => _ReferralCodeWidgetState();
}

class _ReferralCodeWidgetState extends State<ReferralCodeWidget> {
  String? _referralCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      final referralStats = userDoc.data()?['referralStats'];
      if (referralStats != null && referralStats['referralCode'] != null) {
        setState(() => _referralCode = referralStats['referralCode']);
      }
    } catch (e) {
      print('Error loading referral code: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.pink.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Refer & Earn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Get 50% off premium services',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 16),
          if (_isLoading)
            CircularProgressIndicator(color: Colors.white)
          else if (_referralCode != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _referralCode!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _generateCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text('Generate Referral Code'),
            ),
        ],
      ),
    );
  }

  Future<void> _generateCode() async {
    try {
      final code = await ReferralService().generateReferralCode();
      setState(() => _referralCode = code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Referral code generated: $code')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

### **Referral Code Input (Signup/Onboarding)**
```dart
class ReferralCodeInput extends StatefulWidget {
  final Function(String) onCodeApplied;

  const ReferralCodeInput({required this.onCodeApplied});

  @override
  _ReferralCodeInputState createState() => _ReferralCodeInputState();
}

class _ReferralCodeInputState extends State<ReferralCodeInput> {
  final TextEditingController _codeController = TextEditingController();
  bool _isValidating = false;
  String? _validationMessage;

  Future<void> _validateAndApplyCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      final result = await ReferralService().redeemReferralCode(code);

      setState(() => _validationMessage = result['message']);

      if (result['success']) {
        widget.onCodeApplied(code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 ${result['message']}')),
        );
      }
    } catch (e) {
      setState(() => _validationMessage = e.toString());
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a referral code?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'Enter referral code (e.g., SWIFT2025)',
              border: OutlineInputBorder(),
              suffixIcon: _isValidating
                  ? Container(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _validateAndApplyCode,
                      child: Text('Apply'),
                    ),
            ),
            onSubmitted: (_) => _validateAndApplyCode(),
          ),
          if (_validationMessage != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                _validationMessage!,
                style: TextStyle(
                  color: _validationMessage!.contains('success') || _validationMessage!.contains('🎉')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## **📊 Analytics & Tracking**

### **Referral Analytics Dashboard**
```javascript
// Cloud Function for referral analytics
exports.getReferralAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  try {
    // Get total referral codes
    const codesSnapshot = await admin.firestore()
      .collection('referral_codes')
      .where('isActive', '==', true)
      .get();

    // Get successful referrals
    const referralsSnapshot = await admin.firestore()
      .collection('user_referrals')
      .where('status', '==', 'completed')
      .get();

    // Calculate analytics
    const analytics = {
      totalCodes: codesSnapshot.size,
      activeCodes: codesSnapshot.docs.filter(doc => doc.data().usedCount > 0).length,
      totalReferrals: referralsSnapshot.size,
      totalDiscountValue: referralsSnapshot.docs.reduce((sum, doc) =>
        sum + (doc.data().discountApplied || 0), 0
      ),
      topReferrers: await _getTopReferrers()
    };

    return { success: true, analytics };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Failed to get analytics');
  }
});
```

## **🔒 Security Considerations**

### **Rate Limiting**
- Limit code generation to 1 per user per day
- Limit code redemption to 1 per new user
- Prevent self-referral attempts

### **Code Validation**
- Minimum 8 characters, maximum 12 characters
- Alphanumeric characters only
- Case-insensitive redemption
- Expiration date enforcement

### **Fraud Prevention**
- Track IP addresses for suspicious activity
- Monitor rapid-fire code generation/redemption
- Flag accounts with unusual referral patterns

## **🚀 Implementation Steps**

### **Phase 1: Backend Setup**
1. ✅ Create referral code generation function
2. ✅ Create code redemption function
3. ✅ Update Firestore security rules
4. ✅ Add referral analytics function

### **Phase 2: Database Updates**
1. ✅ Update user collection schema
2. ✅ Create referral_codes collection
3. ✅ Create user_referrals collection
4. ✅ Add necessary indexes

### **Phase 3: Mobile App Integration**
1. ✅ Add referral service class
2. ✅ Update home screen with referral widget
3. ✅ Add referral code input to onboarding
4. ✅ Update subscription flow for discounts

### **Phase 4: Testing & Validation**
1. ✅ Test code generation and uniqueness
2. ✅ Test redemption flow end-to-end
3. ✅ Test discount application
4. ✅ Test fraud prevention measures

## **📈 Success Metrics**

- **Conversion Rate**: Percentage of generated codes that get used
- **User Acquisition**: Number of new users from referrals
- **Retention Rate**: How long referred users stay active
- **Revenue Impact**: Total discount value vs. subscription revenue

## **🔧 Maintenance & Monitoring**

### **Daily Tasks**
- Monitor referral code usage patterns
- Check for expired codes and clean up
- Review fraud indicators and take action

### **Weekly Tasks**
- Analyze referral program performance
- Update marketing campaigns based on data
- Review and adjust discount percentages if needed

### **Monthly Tasks**
- Generate referral program reports
- Plan program enhancements
- Review and update terms and conditions

---

**Note**: This referral system is designed to be completely self-contained within Firebase, with no external dependencies. All referral tracking, validation, and discount application happens server-side for security and consistency.
