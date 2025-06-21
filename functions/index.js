const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyEmergency = onCall(async (request) => {
  console.log("Received request data:", request.data);

  // Handle both array and object formats
  const data = Array.isArray(request.data) ? request.data[0] : request.data;
  const { emergencyId, type, latitude, longitude, description } = data;

  // Validate required fields
  if (!emergencyId || !type || latitude === undefined || longitude === undefined) {
    throw new HttpsError("invalid-argument", "Missing required emergency data");
  }

  try {
    // Safely handle description
    const safeDescription = description || "No description provided";
    const truncatedDescription = safeDescription.length > 100
      ? safeDescription.substring(0, 100) + "..."
      : safeDescription;

    // Notification payload
    const message = {
      notification: {
        title: `New ${type} Emergency`,
        body: `Emergency reported: ${truncatedDescription}`,
      },
      data: {
        emergencyId: String(emergencyId),
        type: String(type),
      },
    };

    // 1. Notify responders in the department (using topic)
    try {
      await admin.messaging().send({
        ...message,
        topic: type,
      });
      console.log(`Notification sent to topic: ${type}`);
    } catch (topicError) {
      console.warn(`Failed to send topic notification: ${topicError.message}`);
      // Continue execution - don't fail the entire function
    }

    // 2. Notify nearby citizens (within 5km)
    const usersSnapshot = await admin.firestore().collection("users").get();
    const nearbyUserTokens = [];
    console.log(`Checking ${usersSnapshot.docs.length} users for proximity`);

    for (const userDoc of usersSnapshot.docs) {
      try {
        const user = userDoc.data();
        if (user.role === "citizen" && user.lastLocation && user.deviceToken) {
          const { latitude: userLat, longitude: userLon } = user.lastLocation;

          // Validate coordinates
          if (typeof userLat === "number" && typeof userLon === "number") {
            const distance = getDistance(latitude, longitude, userLat, userLon);
            if (distance > 0.05 && distance <= 5) {
              // 5km radius, exclude very close (< 50m) to avoid self-notification
              nearbyUserTokens.push(user.deviceToken);
            }
          }
        }
      } catch (userError) {
        console.warn(`Error processing user ${userDoc.id}: ${userError.message}`);
        // Continue with next user
      }
    }

    const nearByMessage = {
      notification: {
        title: `Emergency Nearby (${type})`,
        body: `An emergency was reported near your location: ${truncatedDescription}`,
      },
      data: {
        emergencyId: String(emergencyId),
        type: String(type),
      },
    };

    const uniqueTokens = [...new Set(nearbyUserTokens)];
    console.log(`Found ${uniqueTokens.length} nearby users to notify`);

    if (uniqueTokens.length > 0) {
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: uniqueTokens,
          ...nearByMessage,
        });
        console.log(`Notification sent to ${response.successCount}/${uniqueTokens.length} nearby users`);

        if (response.failureCount > 0) {
          console.warn(`Failed to send to ${response.failureCount} users`);
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const errorMessage = resp.error && resp.error.message ? resp.error.message : "Unknown error";
              console.warn(`Failed token ${uniqueTokens[idx]}: ${errorMessage}`);
            }
          });
        }
      } catch (multicastError) {
        console.error(`Multicast notification failed: ${multicastError.message}`);
        // Don't fail the entire function - topic notifications might have succeeded
      }
    }

    return {
      success: true,
      notifiedNearbyUsers: uniqueTokens.length,
      timestamp: new Date().toISOString()
    };
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
