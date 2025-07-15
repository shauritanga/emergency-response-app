import React, { useState, useEffect } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { AuthProvider } from "@/contexts/AuthContext";
import { ThemeProvider } from "@/contexts/ThemeContext";
import { ToastProvider } from "@/components/ui/toast";
import { ProtectedRoute } from "@/components/auth/ProtectedRoute";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Dashboard } from "@/pages/Dashboard";
import { UserManagement } from "@/pages/UserManagement";
import { EmergencyManagement } from "@/pages/EmergencyManagement";
import { Monitoring } from "@/pages/Monitoring";
import { Reports } from "@/pages/Reports";
import { Settings } from "@/pages/Settings";
import { Notifications } from "@/pages/Notifications";

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60000, // 1 minute
      retry: 3,
      refetchOnWindowFocus: false,
    },
  },
});

function App() {
  const [currentPage, setCurrentPage] = useState("dashboard");

  useEffect(() => {
    // Simple hash-based routing
    const handleHashChange = () => {
      const hash = window.location.hash.slice(1); // Remove the #
      if (hash.startsWith("/users")) {
        setCurrentPage("users");
      } else if (hash.startsWith("/emergencies")) {
        setCurrentPage("emergencies");
      } else if (hash.startsWith("/monitoring")) {
        setCurrentPage("monitoring");
      } else if (hash.startsWith("/reports")) {
        setCurrentPage("reports");
      } else if (hash.startsWith("/settings")) {
        setCurrentPage("settings");
      } else if (hash.startsWith("/notifications")) {
        setCurrentPage("notifications");
      } else {
        setCurrentPage("dashboard");
      }
    };

    // Listen for hash changes
    window.addEventListener("hashchange", handleHashChange);

    // Check initial hash
    handleHashChange();

    return () => {
      window.removeEventListener("hashchange", handleHashChange);
    };
  }, []);

  const renderCurrentPage = () => {
    switch (currentPage) {
      case "users":
        return <UserManagement />;
      case "emergencies":
        return <EmergencyManagement />;
      case "monitoring":
        return <Monitoring />;
      case "reports":
        return <Reports />;
      case "settings":
        return <Settings />;
      case "notifications":
        return <Notifications />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider defaultTheme="system" storageKey="emergency-admin-theme">
        <ToastProvider>
          <AuthProvider>
            <ProtectedRoute>
              <DashboardLayout
                currentPage={currentPage}
                onNavigate={setCurrentPage}
              >
                {renderCurrentPage()}
              </DashboardLayout>
            </ProtectedRoute>
          </AuthProvider>
        </ToastProvider>
      </ThemeProvider>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}

export default App;
