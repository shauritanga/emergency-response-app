import React, { useState, useEffect } from "react";
import { collection, getDocs, query, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export const FirebaseDebug: React.FC = () => {
  const [emergencyData, setEmergencyData] = useState<any[]>([]);
  const [userData, setUserData] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [foundCollectionName, setFoundCollectionName] =
    useState<string>("emergencies");

  const testFirebaseConnection = async () => {
    setLoading(true);
    setError(null);

    try {
      console.log("Testing Firebase connection...");

      // Test emergencies collection - try different collection names
      let emergenciesSnapshot;
      let collectionName = "emergencies";

      try {
        const emergenciesRef = collection(db, "emergencies");
        const emergenciesQuery = query(emergenciesRef, limit(10));
        emergenciesSnapshot = await getDocs(emergenciesQuery);
        console.log(
          "Found",
          emergenciesSnapshot.size,
          "documents in 'emergencies' collection"
        );
      } catch (err) {
        console.log("Error with 'emergencies' collection:", err);

        // Try alternative collection names
        try {
          const altRef = collection(db, "emergency_reports");
          const altQuery = query(altRef, limit(10));
          emergenciesSnapshot = await getDocs(altQuery);
          collectionName = "emergency_reports";
          setFoundCollectionName("emergency_reports");
          console.log(
            "Found",
            emergenciesSnapshot.size,
            "documents in 'emergency_reports' collection"
          );
        } catch (err2) {
          console.log("Error with 'emergency_reports' collection:", err2);

          try {
            const altRef2 = collection(db, "reports");
            const altQuery2 = query(altRef2, limit(10));
            emergenciesSnapshot = await getDocs(altQuery2);
            collectionName = "reports";
            setFoundCollectionName("reports");
            console.log(
              "Found",
              emergenciesSnapshot.size,
              "documents in 'reports' collection"
            );
          } catch (err3) {
            console.log("Error with 'reports' collection:", err3);
            throw new Error(
              "Could not find emergency data in any expected collection"
            );
          }
        }
      }

      console.log("Emergencies collection size:", emergenciesSnapshot.size);

      const emergencies = emergenciesSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      setEmergencyData(emergencies);

      // Test users collection
      const usersRef = collection(db, "users");
      const usersQuery = query(usersRef, limit(5));
      const usersSnapshot = await getDocs(usersQuery);

      console.log("Users collection size:", usersSnapshot.size);

      const users = usersSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      setUserData(users);

      console.log("Firebase data retrieved successfully");
      console.log("Emergency collection used:", foundCollectionName);
      console.log("Emergency data sample:", emergencies.slice(0, 2));
    } catch (err) {
      console.error("Firebase connection error:", err);
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    testFirebaseConnection();
  }, []);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            Firebase Connection Debug
            <Button onClick={testFirebaseConnection} disabled={loading}>
              {loading ? "Testing..." : "Refresh"}
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
              <h4 className="text-red-800 font-medium">Error:</h4>
              <p className="text-red-700">{error}</p>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Emergencies Data */}
            <div>
              <h3 className="text-lg font-semibold mb-3">
                Emergencies Collection: "{foundCollectionName}" (
                {emergencyData.length} items)
              </h3>
              <div className="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
                <pre className="text-sm">
                  {JSON.stringify(emergencyData, null, 2)}
                </pre>
              </div>
            </div>

            {/* Users Data */}
            <div>
              <h3 className="text-lg font-semibold mb-3">
                Users Collection ({userData.length} items)
              </h3>
              <div className="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
                <pre className="text-sm">
                  {JSON.stringify(userData, null, 2)}
                </pre>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
