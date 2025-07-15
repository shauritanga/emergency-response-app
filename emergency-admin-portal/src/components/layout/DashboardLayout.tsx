import React, { useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";
import { cn } from "@/lib/utils";

interface DashboardLayoutProps {
  children: React.ReactNode;
  currentPage: string;
  onNavigate: (page: string) => void;
}

export const DashboardLayout: React.FC<DashboardLayoutProps> = ({
  children,
  currentPage,
  onNavigate,
}) => {
  const { logout } = useAuth();
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error("Failed to log out:", error);
    }
  };

  const toggleSidebar = () => {
    setSidebarCollapsed(!sidebarCollapsed);
  };

  const handleItemClick = (item: string) => {
    // Handle direct navigation to pages
    onNavigate(item);
    window.location.hash = `#/${item}`;
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Sidebar */}
      <Sidebar
        collapsed={sidebarCollapsed}
        activeItem={currentPage}
        onItemClick={handleItemClick}
      />

      {/* Header */}
      <Header
        collapsed={sidebarCollapsed}
        onToggleSidebar={toggleSidebar}
        onLogout={handleLogout}
      />

      {/* Main Content */}
      <main
        className={cn(
          "pt-16 transition-all duration-300 min-h-screen bg-background text-foreground",
          sidebarCollapsed ? "ml-16" : "ml-64"
        )}
      >
        <div className="p-6">{children}</div>
      </main>
    </div>
  );
};
