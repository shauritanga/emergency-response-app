const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyEmergency = onCall(async (request) => {
  const { emergencyId, type, latitude, longitude, description } =
    request.data[0];
  console.log(request.data);

  try {
    // Notification payload
    const message = {
      notification: {
        title: `New ${type} Emergency`,
        body: `Emergency reported: ${(description || "").substring(0, 100)}...`,
      },
      data: {
        emergencyId: emergencyId,
        type: type,
      },
    };

    // 1. Notify responders in the department (using topic)
    await admin.messaging().send({
      ...message,
      topic: type,
    });

    // 2. Notify nearby citizens (within 5km)
    const usersSnapshot = await admin.firestore().collection("users").get();
    const nearbyUserTokens = [];

    for (const userDoc of usersSnapshot.docs) {
      const user = userDoc.data();
      if (user.role === "citizen" && user.lastLocation) {
        const { latitude: userLat, longitude: userLon } = user.lastLocation;
        const distance = getDistance(latitude, longitude, userLat, userLon);
        if (distance > 0.05 && distance <= 5 && user.deviceToken) {
          // 5km radius
          nearbyUserTokens.push(user.deviceToken);
        }
      }
    }

    const nearByMessage = {
      notification: {
        title: `Emergency Nearby (${type})`,
        body: `An emergency was reported near your location: ${description.substring(
          0,
          100
        )}...`,
      },
      data: {
        emergencyId: emergencyId,
        type: type,
      },
    };

    const uniqueTokens = [...new Set(nearbyUserTokens)];

    if (uniqueTokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens: uniqueTokens,
        ...nearByMessage,
      });
      console.log(`Notification sent to ${uniqueTokens.length} nearby users`);
    }

    return { success: true };
  } catch (error) {
    console.error("Error sending notifications:", error);
    throw new HttpsError("internal", "Failed to send notifications");
  }
});

// Helper function to calculate distance (Haversine formula)
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in km
}
