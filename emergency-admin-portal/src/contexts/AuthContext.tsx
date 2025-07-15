import React, { createContext, useContext, useEffect, useState } from "react";
import * as firebaseAuth from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { SplashScreen } from "@/components/ui/splash-screen";

interface AuthContextType {
  currentUser: firebaseAuth.User | null;
  isAdmin: boolean;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<firebaseAuth.User | null>(
    null
  );
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  const checkAdminStatus = async (user: firebaseAuth.User) => {
    try {
      const userDoc = await getDoc(doc(db, "users", user.uid));
      if (userDoc.exists()) {
        const userData = userDoc.data();
        return userData.role === "admin";
      }
      return false;
    } catch (error) {
      console.error("Error checking admin status:", error);
      return false;
    }
  };

  const login = async (email: string, password: string) => {
    try {
      const result = await firebaseAuth.signInWithEmailAndPassword(
        auth,
        email,
        password
      );
      const adminStatus = await checkAdminStatus(result.user);

      if (!adminStatus) {
        await firebaseAuth.signOut(auth);
        throw new Error("Access denied. Admin privileges required.");
      }

      setIsAdmin(true);
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error("Failed to sign in");
    }
  };

  const logout = async () => {
    try {
      await firebaseAuth.signOut(auth);
      setIsAdmin(false);
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error("Failed to sign out");
    }
  };

  useEffect(() => {
    const unsubscribe = firebaseAuth.onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);

      if (user) {
        const adminStatus = await checkAdminStatus(user);
        setIsAdmin(adminStatus);
      } else {
        setIsAdmin(false);
      }

      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const value: AuthContextType = {
    currentUser,
    isAdmin,
    loading,
    login,
    logout,
  };

  if (loading) {
    return <SplashScreen message="Initializing Admin Portal..." />;
  }

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};
