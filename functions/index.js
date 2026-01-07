const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");
const dotenv = require("dotenv");

dotenv.config(); // loads functions/.env locally (and in deploy build)

admin.initializeApp();

exports.verifyKhaltiAndUpgrade = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");

  const token = request.data?.token;
  const amount = request.data?.amount; // paisa
  if (!token || !amount) {
    throw new HttpsError("invalid-argument", "token and amount are required.");
  }

  const EXPECTED_AMOUNT = 50000; // Rs 500
  if (amount !== EXPECTED_AMOUNT) {
    throw new HttpsError("failed-precondition", "Amount mismatch.");
  }

  const secretKey = process.env.KHALTI_SECRET_KEY;
  if (!secretKey) {
    throw new HttpsError("failed-precondition", "Khalti secret not configured.");
  }

  // Verify with Khalti
  try {
    await axios.post(
      "https://khalti.com/api/v2/payment/verify/",
      { token, amount },
      {
        headers: { Authorization: `Key ${secretKey}` },
        timeout: 15000,
      }
    );
  } catch (err) {
    console.error("Khalti verify failed:", err?.response?.data || err?.message);
    throw new HttpsError("unavailable", "Khalti verification failed.");
  }

  // Upgrade user
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const expiry = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
  );

  const userRef = db.collection("users").doc(uid);
  const payRef = db.collection("payments").doc();

  await db.runTransaction(async (tx) => {
    tx.set(payRef, {
      userId: uid,
      provider: "khalti",
      token,
      amountPaisa: amount,
      amountRs: amount / 100,
      planGranted: "pro",
      validUntil: expiry,
      createdAt: now,
    });

    tx.update(userRef, {
      plan: "pro",
      planExpiry: expiry,
      updatedAt: now,
    });
  });

  return { ok: true, plan: "pro", planExpiry: expiry.toDate().toISOString() };
});
