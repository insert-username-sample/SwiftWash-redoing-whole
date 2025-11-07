const functions = require("firebase-functions");
const {onCall} = require("firebase-functions/v2/https");
const {VertexAI} = require("@google-cloud/vertexai");
const admin = require("firebase-admin");

admin.initializeApp();

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

exports.generateOrderId = onCall(async (request) => {
  const {userId} = request.data;
  try {
    const cityMappings = [
      {
        pincodeRange: /^440/,
        code: "NGP",
        name: "Nagpur",
        lat: 21.1,
        lng: 79.05,
      },
      {
        pincodeRange: /^411/,
        code: "PUN",
        name: "Pune",
        lat: 18.52,
        lng: 73.85,
      },
    ];
    const addressesSnapshot = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("addresses")
        .limit(1)
        .get();
    let cityCode = "NGP";
    if (!addressesSnapshot.empty) {
      const address = addressesSnapshot.docs[0].data();
      const pincode = address.pincode || "";
      const matchingCity = cityMappings.find((mapping) =>
        mapping.pincodeRange.test(pincode),
      );
      if (matchingCity) {
        cityCode = matchingCity.code;
      } else {
        const street = (address.street || "").toLowerCase();
        const landmark = (address.landmark || "").toLowerCase();
        if (street.includes("mumbai") || landmark.includes("mumbai")) {
          cityCode = "MUM";
        } else if (street.includes("hyderabad") ||
                   landmark.includes("hyderabad")) {
          cityCode = "HYD";
        }
      }
    }
    const now = new Date();
    const year = (now.getFullYear() % 100).toString().padStart(2, "0");
    const month = (now.getMonth() + 1).toString().padStart(2, "0");
    const day = now.getDate().toString().padStart(2, "0");
    const dateString = `${year}${month}${day}`;
    const counterRef = admin.firestore()
        .collection("counters")
        .doc(`${cityCode}-${dateString}`);
    const newOrderId = await admin.firestore().runTransaction(
        async (transaction) => {
          const counterDoc = await transaction.get(counterRef);
          let sequenceNumber = 1;
          if (counterDoc.exists) {
            sequenceNumber = (counterDoc.data() &&
            counterDoc.data().currentOrder || 0) + 1;
          }
          transaction.set(counterRef, {currentOrder: sequenceNumber},
              {merge: true});
          const paddedNumber = sequenceNumber.toString().padStart(3, "0");
          return `${cityCode}${paddedNumber}`;
        },
    );
    return {orderId: newOrderId, cityCode};
  } catch (error) {
    console.error("Error generating order ID:", error);
    return {error: error.message};
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
