const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Trigger on new message → send push to recipient
exports.onNewMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    const chatSnap = await admin.firestore()
      .collection("chats").doc(context.params.chatId).get();
    const chat = chatSnap.data();

    if (!chat) return null;

    // Determine recipient
    const recipientId = msg.senderId === chat.userId
      ? chat.providerId
      : chat.userId;

    const recipientSnap = await admin.firestore()
      .collection("users").doc(recipientId).get();
    const token = recipientSnap.data()?.fcmToken;

    if (!token) return null;

    return admin.messaging().send({
      token,
      notification: {
        title: "Naya message aya hai",
        body: msg.message.substring(0, 80),
      },
      data: {
        chatId: context.params.chatId,
        type: "message",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "khuzdar_marketplace_channel",
        },
      },
    });
  });

// Trigger on agreement → notify both parties
exports.onAgreementUpdate = functions.firestore
  .document("chats/{chatId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before.agreement?.contactVisible && after.agreement?.contactVisible) {
      const userSnap = await admin.firestore()
        .collection("users").doc(after.userId).get();
      const providerSnap = await admin.firestore()
        .collection("users").doc(after.providerId).get();

      const userToken = userSnap.data()?.fcmToken;
      const providerToken = providerSnap.data()?.fcmToken;

      const messages = [];
      if (userToken) {
        messages.push({
          token: userToken,
          notification: {
            title: "Contact reveal ho gaya! 🎉",
            body: "Dono tayyar hain. Ab number dekh saktay hain.",
          },
        });
      }
      if (providerToken) {
        messages.push({
          token: providerToken,
          notification: {
            title: "Contact reveal ho gaya! 🎉",
            body: "Dono tayyar hain. Ab number dekh saktay hain.",
          },
        });
      }

      if (messages.length > 0) {
        return admin.messaging().sendEach(messages);
      }
    }
    return null;
  });
