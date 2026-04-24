// functions/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendNewOrderNotification = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data.data();
  if (!order) return;

  const db = getFirestore();
  const tokenDoc = await db.collection("adminTokens").doc("mainAdmin").get();
  if (!tokenDoc.exists) {
    console.log("❌ No admin token found");
    return null;
  }

  const adminToken = tokenDoc.data().token;
  const messaging = getMessaging();

  const message = {
    token: adminToken,
    notification: {
      title: "🛍️ New Order Received!",
      body: `${order.customerName} placed a ${order.orderType} order.`,
    },
    android: {
      notification: {
        sound: "default",
        channelId: "high_importance_channel", // optional, if you use custom channel in Flutter
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log("✅ Notification sent successfully:", response);
    return response;
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    return null;
  }
});
