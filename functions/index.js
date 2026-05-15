// functions/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const OpenAI = require("openai");

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

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

exports.identifyProductFromImage = onCall(
    {
      secrets: [OPENAI_API_KEY],
      cors: true,
    },
    async (request) => {
      const imageBase64 = request.data?.imageBase64;

      if (!imageBase64 || typeof imageBase64 !== "string") {
        throw new HttpsError("invalid-argument", "imageBase64 is required");
      }

      try {
        const apiKey = OPENAI_API_KEY.value()?.trim();
        if (!apiKey) {
          console.error("OPENAI_API_KEY secret not loaded");
          throw new HttpsError("internal", "API configuration error");
        }

        console.log("Initializing OpenAI client with API key...");
        const client = new OpenAI({apiKey});

        console.log("Sending image to OpenAI...");
        const completion = await client.chat.completions.create({
          model: "gpt-4o",
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "text",
                  text: "What product is in this image? Reply with a short product name like 'HP Laptop', 'Nike Shoes', or 'Red Apple'.",
                },
                {
                  type: "image_url",
                  image_url: {
                    url: `data:image/jpeg;base64,${imageBase64}`,
                  },
                },
              ],
            },
          ],
          max_tokens: 30,
        });

        console.log("OpenAI response received:", completion.choices?.[0]?.message?.content);
        const label = completion.choices?.[0]?.message?.content?.trim();
        if (!label) {
          console.error("No label returned by OpenAI model");
          throw new HttpsError("internal", "No label returned by model");
        }

        console.log("Successfully identified product:", label);
        return {label};
      } catch (error) {
        console.error("OpenAI identifyProductFromImage error:", {
          message: error?.message || String(error),
          status: error?.status,
          code: error?.code,
          type: error?.type,
        });
        if (error instanceof HttpsError) {
          throw error;
        }
        throw new HttpsError("internal", error.message || "Image analysis failed");
      }
    },
);
