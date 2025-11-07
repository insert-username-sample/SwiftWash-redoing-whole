const functions = require("firebase-functions");
const {onCall} = require("firebase-functions/v2/https");
const {VertexAI} = require("@google-cloud/vertexai");
const admin = require("firebase-admin");

admin.initializeApp();

const CITY_MAPPINGS = [
  // Maharashtra
  {pincodeRange: /^440/, code: "NGP", name: "Nagpur", lat: 21.1458, lng: 79.0882, state: "MH"},
  {pincodeRange: /^411/, code: "PUN", name: "Pune", lat: 18.5204, lng: 73.8567, state: "MH"},
  {pincodeRange: /^400/, code: "MUM", name: "Mumbai", lat: 19.0760, lng: 72.8777, state: "MH"},
  {pincodeRange: /^431/, code: "AUR", name: "Aurangabad", lat: 19.8762, lng: 75.3433, state: "MH"},
  {pincodeRange: /^422/, code: "NSK", name: "Nashik", lat: 19.9975, lng: 73.7898, state: "MH"},

  // Karnataka
  {pincodeRange: /^560/, code: "BLR", name: "Bangalore", lat: 12.9716, lng: 77.5946, state: "KA"},
  {pincodeRange: /^580/, code: "HBL", name: "Hubli", lat: 15.3647, lng: 75.1240, state: "KA"},

  // Telangana
  {pincodeRange: /^500/, code: "HYD", name: "Hyderabad", lat: 17.3850, lng: 78.4867, state: "TS"},

  // Delhi NCR
  {pincodeRange: /^110/, code: "DEL", name: "Delhi", lat: 28.7041, lng: 77.1025, state: "DL"},

  // Default mapping for unknown areas
  {pincodeRange: /.*/, code: "GEN", name: "General", lat: 20.5937, lng: 78.9629, state: "IN"},
];

exports.generateSmartOrderId = onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const {userId, orderType, isUrgent = false, isReferred = false, isStudent = false} = data;

  if (!userId || !orderType) {
    throw new functions.https.HttpsError("invalid-argument", "User ID and order type required");
  }

  try {
    // Get user address for location data
    const userAddresses = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("addresses")
        .limit(1)
        .get();

    if (userAddresses.empty) {
      throw new functions.https.HttpsError("failed-precondition", "No address found for user");
    }

    const address = userAddresses.docs[0].data();
    const {lat, lng, pincode, city} = address;

    // Determine city code
    const cityCode = getCityCode(pincode, city, lat, lng);

    // Calculate direction from city center
    const cityCenter = getCityCenter(cityCode);
    const direction = getDirectionFromCoordinates(lat, lng, cityCenter.lat, cityCenter.lng);

    // Get pincode prefix (first 3 digits)
    const pincodePrefix = pincode.substring(0, 3);

    // Get order type code
    const typeCode = getOrderTypeCode(orderType);

    // Generate daily sequence number
    const dateString = getDateString();
    const sequenceNumber = await getNextSequenceNumber(cityCode, dateString);

    // Build flags
    const flags = [];
    if (isUrgent) flags.push("URG");
    if (isReferred) flags.push("RFR");
    if (isStudent) flags.push("STD");

    // Construct final order ID
    const orderId = `SW-${cityCode}-${direction}-${pincodePrefix}-${typeCode}-${sequenceNumber}${flags.length > 0 ? `-${flags.join("-")}` : ""}`;

    // Log generation for audit trail
    await admin.firestore().collection("order_id_generations").add({
      orderId: orderId,
      userId: userId,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      components: {
        cityCode: cityCode,
        direction: direction,
        pincodePrefix: pincodePrefix,
        typeCode: typeCode,
        sequenceNumber: sequenceNumber,
        flags: flags,
      },
      location: {
        lat: lat,
        lng: lng,
        pincode: pincode,
        city: city,
      },
    });

    return {
      success: true,
      orderId: orderId,
      components: {
        cityCode: cityCode,
        direction: direction,
        pincodePrefix: pincodePrefix,
        typeCode: typeCode,
        sequenceNumber: sequenceNumber,
        flags: flags,
      },
    };
  } catch (error) {
    console.error("Error generating smart order ID:", error);
    throw new functions.https.HttpsError("internal", "Failed to generate order ID");
  }
});

// Helper Functions
function getCityCode(pincode, cityName, lat, lng) {
  // First try pincode matching
  for (const mapping of CITY_MAPPINGS) {
    if (mapping.pincodeRange.test(pincode)) {
      return mapping.code;
    }
  }

  // Fallback to city name matching
  const cityLower = cityName.toLowerCase();
  if (cityLower.includes("nagpur")) return "NGP";
  if (cityLower.includes("pune")) return "PUN";
  if (cityLower.includes("mumbai")) return "MUM";
  if (cityLower.includes("bangalore") || cityLower.includes("bengaluru")) return "BLR";
  if (cityLower.includes("hyderabad")) return "HYD";
  if (cityLower.includes("delhi")) return "DEL";

  // Final fallback to coordinate-based detection
  return getCityFromCoordinates(lat, lng);
}

function getCityFromCoordinates(lat, lng) {
  // Find closest city center
  let closestCity = CITY_MAPPINGS[0];
  let minDistance = Number.MAX_VALUE;

  for (const city of CITY_MAPPINGS) {
    const distance = getDistance(lat, lng, city.lat, city.lng);
    if (distance < minDistance) {
      minDistance = distance;
      closestCity = city;
    }
  }

  return closestCity.code;
}

function getDirectionFromCoordinates(lat, lng, centerLat, centerLng) {
  const deltaLat = lat - centerLat;
  const deltaLng = lng - centerLng;

  let angle = Math.atan2(deltaLng, deltaLat) * (180 / Math.PI);
  if (angle < 0) angle += 360;

  const directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
  const sector = Math.floor((angle + 22.5) / 45) % 8;

  return directions[sector];
}

function getOrderTypeCode(orderType) {
  switch (orderType.toLowerCase()) {
    case "ironing":
    case "iron":
      return "IRN";
    case "wash":
    case "washing":
    case "laundry":
      return "WSH";
    case "swift":
    case "express":
      return "SFT";
    default:
      return "GEN";
  }
}

function getDateString() {
  const now = new Date();
  const year = (now.getFullYear() % 100).toString().padStart(2, "0");
  const month = (now.getMonth() + 1).toString().padStart(2, "0");
  const day = now.getDate().toString().padStart(2, "0");
  return `${year}${month}${day}`;
}

async function getNextSequenceNumber(cityCode, dateString) {
  const counterRef = admin.firestore()
      .collection("order_counters")
      .doc(`${cityCode}-${dateString}`);

  return await admin.firestore().runTransaction(async (transaction) => {
    const counterDoc = await transaction.get(counterRef);

    let sequenceNumber = 1;
    if (counterDoc.exists()) {
      sequenceNumber = (counterDoc.data().current || 0) + 1;
    }

    transaction.set(counterRef, {
      current: sequenceNumber,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    return sequenceNumber.toString().padStart(3, "0");
  });
}

function getDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}
function getCityCenter(cityCode) {
  const city = CITY_MAPPINGS.find((c) => c.code === cityCode);
  return city ? {lat: city.lat, lng: city.lng} : {lat: 20.5937, lng: 78.9629};
}
exports.setUserRole = onCall(async (request) => {
  if (!request.auth || !request.auth.token.customClaims ||
      !request.auth.token.customClaims.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required",
    );
  }
  const {email, role} = request.data;
  if (!email || typeof email !== "string" ||
      !role || typeof role !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid email or role",
    );
  }
  const rateLimitRef = admin.firestore()
      .collection("rate_limits")
      .doc(`admin_${request.auth.uid}_${Math.floor(Date.now() / 300000)}`);
  const rateLimitDoc = await rateLimitRef.get();
  if (rateLimitDoc.exists && rateLimitDoc.data().count >= 5) {
    throw new functions.https.HttpsError(
        "resource-exhausted",
        "Admin rate limit exceeded",
    );
  }
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, {[role]: true});
    return {message: `Success! ${email} has been made a ${role}.`};
  } catch (error) {
    console.error("Role assignment error:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to update user role",
    );
  }
});

exports.createUser = onCall(async (request) => {
  if (!request.auth || !request.auth.token.customClaims ||
      !request.auth.token.customClaims.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required",
    );
  }
  const {email, password} = request.data;
  if (!email || !password || password.length < 8) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid email or weak password",
    );
  }
  const rateLimitRef = admin.firestore()
      .collection("rate_limits")
      .doc(`admin_${request.auth.uid}_${Math.floor(Date.now() / 300000)}`);
  const rateLimitDoc = await rateLimitRef.get();
  if (rateLimitDoc.exists && rateLimitDoc.data().count >= 10) {
    throw new functions.https.HttpsError(
        "resource-exhausted",
        "Admin rate limit exceeded",
    );
  }
  await rateLimitRef.set({
    count: (rateLimitDoc.exists ? rateLimitDoc.data().count : 0) + 1,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });
    return {uid: userRecord.uid, message: "User created successfully"};
  } catch (error) {
    console.error("User creation error:", error);
    throw new functions.https.HttpsError("internal", "Failed to create user");
  }
});

exports.updateUserPassword = onCall(async (request) => {
  if (!request.auth || !request.auth.token.customClaims ||
      !request.auth.token.customClaims.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access required",
    );
  }
  const {email, password} = request.data;
  if (!email || !password || password.length < 8) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid email or weak password",
    );
  }
  const rateLimitRef = admin.firestore()
      .collection("rate_limits")
      .doc(`admin_${request.auth.uid}_${Math.floor(Date.now() / 300000)}`);
  const rateLimitDoc = await rateLimitRef.get();
  if (rateLimitDoc.exists && rateLimitDoc.data().count >= 10) {
    throw new functions.https.HttpsError(
        "resource-exhausted",
        "Admin rate limit exceeded",
    );
  }
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, {
      password: password,
    });
    return {message: `Success! Password for ${email} has been updated.`};
  } catch (error) {
    console.error("Password update error:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to update password",
    );
  }
});


exports.chatWithSwiftBot = onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }
  const {message} = request.data;
  const userId = request.auth.uid;
  if (!message || typeof message !== "string" || message.length > 500) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid message format",
    );
  }
  const rateLimitRef = admin.firestore()
      .collection("rate_limits")
      .doc(`chat_${userId}_${Math.floor(Date.now() / 60000)}`);
  const rateLimitDoc = await rateLimitRef.get();
  if (rateLimitDoc.exists && rateLimitDoc.data().count >= 10) {
    throw new functions.https.HttpsError(
        "resource-exhausted",
        "Rate limit exceeded",
    );
  }
  await rateLimitRef.set({
    count: (rateLimitDoc.exists ? rateLimitDoc.data().count : 0) + 1,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  try {
    const vertexAI = new VertexAI({
      project: "swiftwash-alpha",
      location: "us-central1",
    });
    const model = "gemini-1.5-flash";
    const generativeModel = vertexAI.preview.getGenerativeModel({
      model: model,
      generationConfig: {
        "maxOutputTokens": 2048,
        "temperature": 0.7,
        "topP": 0.95,
      },
      safetySettings: [
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE",
        },
      ],
    });
    const requestData = {
      contents: [{role: "user", parts: [{text: message}]}],
    };
    if (message.toLowerCase().includes("cancel")) {
      return {
        response: "Sure, I can help with that. What is the order ID " +
                  "you would like to cancel?",
        userId: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      };
    }
    if (message.toLowerCase().includes("reschedule")) {
      return {
        response: "Sure, I can help with that. What is the order ID " +
                  "you would like to reschedule?",
        userId: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      };
    }
    const streamingResp = await generativeModel.generateContentStream(
        requestData,
    );
    const aggregatedResponse = await streamingResp.response;
    const response = aggregatedResponse.candidates[0].content.parts[0].text;
    if (!response || response.length > 2000) {
      throw new functions.https.HttpsError(
          "internal",
          "AI response validation failed",
      );
    }
    return {
      response: response,
      userId: userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error) {
    console.error("Chat error:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Chat service temporarily unavailable",
    );
  }
});

exports.requestHumanSupport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const {phoneNumber, reason, conversationId} = data;
  const userId = context.auth.uid;

  try {
    // Verify phone number format
    if (!phoneNumber || !isValidPhoneNumber(phoneNumber)) {
      throw new functions.https.HttpsError("invalid-argument", "Valid phone number required");
    }

    // Get user profile for verification
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();

    // Check if provided number matches user's registered number
    const registeredPhone = userData.phoneNumber;
    const isPhoneVerified = phoneNumber === registeredPhone;

    if (!isPhoneVerified) {
      // Store phone verification request
      const verificationId = admin.firestore().collection("phone_verifications").doc().id;
      await admin.firestore().collection("phone_verifications").doc(verificationId).set({
        id: verificationId,
        userId: userId,
        requestedPhone: phoneNumber,
        registeredPhone: registeredPhone,
        status: "pending",
        reason: reason,
        conversationId: conversationId,
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
      });

      return {
        success: false,
        requiresVerification: true,
        verificationId: verificationId,
        message: "Phone number verification required before connecting to human support",
      };
    }

    // Phone is verified, proceed with human support request
    await initiateHumanSupport(userId, phoneNumber, reason, conversationId);

    return {
      success: true,
      message: "Human support request submitted. You will receive a call shortly.",
    };
  } catch (error) {
    console.error("Human support request error:", error);
    throw new functions.https.HttpsError("internal", "Failed to request human support");
  }
});

function isValidPhoneNumber(phone) {
  // Basic Indian phone number validation
  const phoneRegex = /^(\+91|91|0)?[6-9]\d{9}$/;
  return phoneRegex.test(phone.replace(/[\s\-\(\)]/g, ""));
}

async function initiateHumanSupport(userId, phoneNumber, reason, conversationId) {
  // Create human support request
  const supportRequestId = admin.firestore().collection("human_support_requests").doc().id;

  await admin.firestore().collection("human_support_requests").doc(supportRequestId).set({
    id: supportRequestId,
    userId: userId,
    phoneNumber: phoneNumber,
    reason: reason,
    conversationId: conversationId,
    status: "pending",
    priority: determinePriority(reason),
    requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    assignedTo: null,
    callStartedAt: null,
    callEndedAt: null,
    outcome: null,
    notes: [],
  });

  // Notify all available admins
  await notifyAdminsOfSupportRequest(supportRequestId, userId, phoneNumber, reason);

  // Log the support request
  await admin.firestore().collection("support_audit_logs").add({
    type: "human_support_requested",
    userId: userId,
    supportRequestId: supportRequestId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata: {
      reason: reason,
      phoneNumber: phoneNumber,
      source: "ai_escalation",
    },
  });
}

function determinePriority(reason) {
  const urgentKeywords = ["emergency", "urgent", "asap", "immediate", "critical"];
  const reasonLower = reason.toLowerCase();

  if (urgentKeywords.some((keyword) => reasonLower.includes(keyword))) {
    return "high";
  }

  return "normal";
}

async function notifyAdminsOfSupportRequest(supportRequestId, userId, phoneNumber, reason) {
  // Get all active admins
  const adminsSnapshot = await admin.firestore()
      .collection("admins")
      .where("isActive", "==", true)
      .get();

  const notifications = [];

  adminsSnapshot.forEach((adminDoc) => {
    const adminData = adminDoc.data();

    notifications.push({
      userId: adminDoc.id,
      type: "human_support_request",
      title: "Customer Needs Human Support",
      body: `Customer ${userId} is requesting human assistance. Reason: ${reason}`,
      data: {
        supportRequestId: supportRequestId,
        customerPhone: phoneNumber,
        customerId: userId,
        priority: determinePriority(reason),
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });
  });

  // Save notifications to Firestore
  for (const notification of notifications) {
    await admin.firestore().collection("admin_notifications").add(notification);
  }

  // Send FCM push notifications if tokens are available
  await sendFCMNotifications(notifications);
}

async function sendFCMNotifications(notifications) {
  // Implementation for FCM push notifications to admin devices
  // This would use Firebase Cloud Messaging
}

exports.getPendingSupportRequests = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied", "Admin access required");
  }

  try {
    const requestsSnapshot = await admin.firestore()
        .collection("human_support_requests")
        .where("status", "==", "pending")
        .orderBy("requestedAt", "asc")
        .get();

    const requests = requestsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      requestedAt: (doc.data().requestedAt && doc.data().requestedAt.toDate && doc.data().requestedAt.toDate().toISOString()) || null,
    }));

    return {
      success: true,
      requests: requests,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", "Failed to get support requests");
  }
});

exports.acceptSupportRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied", "Admin access required");
  }

  const {supportRequestId} = data;
  const adminId = context.auth.uid;

  try {
    // Update support request
    await admin.firestore()
        .collection("human_support_requests")
        .doc(supportRequestId)
        .update({
          status: "in_progress",
          assignedTo: adminId,
          callStartedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    // Get customer phone number
    const requestDoc = await admin.firestore()
        .collection("human_support_requests")
        .doc(supportRequestId)
        .get();

    const requestData = requestDoc.data();

    return {
      success: true,
      customerPhone: requestData.phoneNumber,
      message: "Support request accepted. Customer phone number retrieved.",
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", "Failed to accept support request");
  }
});

exports.generateReferralCode = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const userId = context.auth.uid;

  try {
    // Check if user already has active code
    const existingCodeQuery = await admin.firestore()
        .collection("referral_codes")
        .where("generatedBy", "==", userId)
        .where("isActive", "==", true)
        .limit(1)
        .get();

    if (!existingCodeQuery.empty) {
      const existingCode = existingCodeQuery.docs[0].data();
      return {
        success: true,
        referralCode: existingCode.code,
        message: "You already have an active referral code",
      };
    }

    // Generate unique code
    const code = await _generateUniqueCode();

    // Save to Firestore
    const codeRef = admin.firestore().collection("referral_codes").doc(code);
    await codeRef.set({
      code: code,
      generatedBy: userId,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      usageLimit: 5,
      usedCount: 0,
      expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year
      discountPercentage: 50,
      applicableServices: ["premium", "swift_premium"],
    });

    // Update user profile
    await admin.firestore().collection("users").doc(userId).update({
      "referralStats.referralCode": code,
      "referralStats.codesGenerated": admin.firestore.FieldValue.increment(1),
      "referralStats.lastReferralAt": admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      referralCode: code,
      message: "Referral code generated successfully",
    };
  } catch (error) {
    console.error("Error generating referral code:", error);
    throw new functions.https.HttpsError("internal", "Failed to generate referral code");
  }
});

async function _generateUniqueCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let code;

  do {
    code = "SWIFT" + Array.from({length: 4}, () =>
      chars.charAt(Math.floor(Math.random() * chars.length)),
    ).join("");
  } while (await _isCodeExists(code));

  return code;
}

async function _isCodeExists(code) {
  const doc = await admin.firestore()
      .collection("referral_codes")
      .doc(code)
      .get();
  return doc.exists;
}

exports.redeemReferralCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const {referralCode} = data;
  const refereeId = context.auth.uid;

  if (!referralCode || typeof referralCode !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Valid referral code required");
  }

  try {
    // Check if code exists and is valid
    const codeRef = admin.firestore().collection("referral_codes").doc(referralCode);
    const codeDoc = await codeRef.get();

    if (!codeDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Invalid referral code");
    }

    const codeData = codeDoc.data();

    // Validate code
    if (!codeData.isActive) {
      throw new functions.https.HttpsError("failed-precondition", "Referral code is inactive");
    }

    if (codeData.usedCount >= codeData.usageLimit) {
      throw new functions.https.HttpsError("failed-precondition", "Referral code usage limit reached");
    }

    if (new Date() > codeData.expiresAt.toDate()) {
      throw new functions.https.HttpsError("failed-precondition", "Referral code has expired");
    }

    // Check if user already used a referral code
    const existingReferralQuery = await admin.firestore()
        .collection("user_referrals")
        .where("refereeId", "==", refereeId)
        .where("status", "==", "completed")
        .limit(1)
        .get();

    if (!existingReferralQuery.empty) {
      throw new functions.https.HttpsError("failed-precondition", "User has already used a referral code");
    }

    // Check if trying to use own code
    if (codeData.generatedBy === refereeId) {
      throw new functions.https.HttpsError("failed-precondition", "Cannot use your own referral code");
    }

    // Create referral record
    const referralId = admin.firestore().collection("user_referrals").doc().id;
    const referralRef = admin.firestore().collection("user_referrals").doc(referralId);

    await referralRef.set({
      id: referralId,
      referrerId: codeData.generatedBy,
      refereeId: refereeId,
      referralCode: referralCode,
      status: "completed",
      discountApplied: 50,
      appliedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      servicesEligible: ["premium", "swift_premium"],
      redeemedServices: [],
    });

    // Update code usage count
    await codeRef.update({
      usedCount: admin.firestore.FieldValue.increment(1),
    });

    // Update referrer stats
    await admin.firestore().collection("users").doc(codeData.generatedBy).update({
      "referralStats.successfulReferrals": admin.firestore.FieldValue.increment(1),
      "referralStats.activeReferrals": admin.firestore.FieldValue.increment(1),
    });

    // Apply discount to referee
    await admin.firestore().collection("users").doc(refereeId).update({
      subscriptionDiscounts: {
        percentage: 50,
        source: "referral",
        validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        appliedServices: [],
      },
    });

    return {
      success: true,
      discountPercentage: 50,
      validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      message: "Referral code applied successfully! You now have 50% off premium services.",
    };
  } catch (error) {
    console.error("Error redeeming referral code:", error);
    throw new functions.https.HttpsError("internal", "Failed to redeem referral code");
  }
});

exports.purchaseSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const {subscriptionType, paymentMethod} = data;
  const userId = context.auth.uid;

  try {
    // Get user discount information
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
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
    const basePrice = subscriptionType === "premium" ? 299 : 499;
    const discountAmount = (basePrice * discountPercentage) / 100;
    const finalPrice = basePrice - discountAmount;

    // Create subscription record
    const subscriptionId = admin.firestore().collection("subscriptions").doc().id;
    await admin.firestore().collection("subscriptions").doc(subscriptionId).set({
      id: subscriptionId,
      userId: userId,
      subscriptionType: subscriptionType,
      basePrice: basePrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      discountSource: discountSource,
      status: "active",
      startDate: new Date(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user referral stats if discount was used
    if (discountPercentage > 0 && discountSource === "referral") {
      await admin.firestore().collection("users").doc(userId).update({
        "subscriptionDiscounts.appliedServices": admin.firestore.FieldValue.arrayUnion(subscriptionType),
      });
    }

    return {
      success: true,
      subscriptionId: subscriptionId,
      originalPrice: basePrice,
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      message: `Subscription activated with ${discountPercentage}% discount!`,
    };
  } catch (error) {
    console.error("Subscription purchase error:", error);
    throw new functions.https.HttpsError("internal", "Failed to purchase subscription");
  }
});

exports.getReferralAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError("permission-denied", "Admin access required");
  }

  try {
    // Get total referral codes
    const codesSnapshot = await admin.firestore()
        .collection("referral_codes")
        .where("isActive", "==", true)
        .get();

    // Get successful referrals
    const referralsSnapshot = await admin.firestore()
        .collection("user_referrals")
        .where("status", "==", "completed")
        .get();

    // Calculate analytics
    const analytics = {
      totalCodes: codesSnapshot.size,
      activeCodes: codesSnapshot.docs.filter((doc) => doc.data().usedCount > 0).length,
      totalReferrals: referralsSnapshot.size,
      totalDiscountValue: referralsSnapshot.docs.reduce((sum, doc) =>
        sum + (doc.data().discountApplied || 0), 0,
      ),
      topReferrers: await _getTopReferrers(),
    };

    return {success: true, analytics};
  } catch (error) {
    throw new functions.https.HttpsError("internal", "Failed to get analytics");
  }
});

async function _getTopReferrers() {
  const referralsSnapshot = await admin.firestore()
      .collection("user_referrals")
      .where("status", "==", "completed")
      .get();

  const referrerCounts = {};
  referralsSnapshot.forEach((doc) => {
    const referrerId = doc.data().referrerId;
    referrerCounts[referrerId] = (referrerCounts[referrerId] || 0) + 1;
  });

  const sortedReferrers = Object.entries(referrerCounts).sort((a, b) => b[1] - a[1]);

  const topReferrers = [];
  for (let i = 0; i < Math.min(sortedReferrers.length, 5); i++) {
    const [userId, count] = sortedReferrers[i];
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    topReferrers.push({...userDoc.data(), referralCount: count});
  }

  return topReferrers;
}
