import React from "react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import {
  LayoutDashboard,
  AlertTriangle,
  Users,
  MapPin,
  BarChart3,
  Settings,
  Bell,
  Shield,
  Activity,
  FileText,
  UserCheck,
  Radio,
} from "lucide-react";
import { useActiveEmergenciesCount } from "@/hooks/useRealtime";

interface SidebarProps {
  collapsed: boolean;
  activeItem: string;
  onItemClick: (item: string) => void;
}

interface NavItem {
  id: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: number;
  badgeColor?: string;
}

export const Sidebar: React.FC<SidebarProps> = ({
  collapsed,
  activeItem,
  onItemClick,
}) => {
  // Get real active emergencies count for the badge
  const { count: activeEmergenciesCount, loading: emergenciesLoading } =
    useActiveEmergenciesCount();

  // Create navigation items with real data
  const navigationItems: NavItem[] = [
    {
      id: "dashboard",
      label: "Dashboard",
      icon: LayoutDashboard,
    },
    {
      id: "emergencies",
      label: "Emergency Management",
      icon: AlertTriangle,
      badge: emergenciesLoading ? undefined : activeEmergenciesCount,
      badgeColor: activeEmergenciesCount > 0 ? "bg-red-500" : "bg-gray-500",
    },
    {
      id: "users",
      label: "User Management",
      icon: Users,
    },
    {
      id: "monitoring",
      label: "Real-time Monitoring",
      icon: Radio,
    },
    {
      id: "reports",
      label: "Reports & Analytics",
      icon: BarChart3,
    },
    {
      id: "notifications",
      label: "Notifications",
      icon: Bell,
      // For now, we'll remove the static badge until we implement a proper notification system
      // badge: 3,
    },
    {
      id: "settings",
      label: "System Settings",
      icon: Settings,
    },
  ];
  const NavItemComponent = ({ item }: { item: NavItem }) => {
    const isActive = activeItem === item.id;

    const buttonContent = (
      <Button
        variant={isActive ? "secondary" : "ghost"}
        className={cn(
          "w-full justify-start h-10 min-w-0 cursor-pointer",
          collapsed ? "px-2" : "px-3",
          isActive && "bg-blue-100 text-blue-700 border-r-2 border-blue-600"
        )}
        onClick={() => onItemClick(item.id)}
      >
        <item.icon
          className={cn(
            "h-4 w-4 flex-shrink-0",
            collapsed ? "mx-auto" : "mr-3"
          )}
        />
        {!collapsed && (
          <>
            <span className="flex-1 text-left truncate min-w-0">
              {item.label}
            </span>
            {item.badge !== undefined && item.badge > 0 && (
              <span
                className={`ml-auto ${
                  item.badgeColor || "bg-red-500"
                } text-white text-xs rounded-full px-2 py-0.5 min-w-[20px] text-center flex-shrink-0`}
              >
                {item.badge}
              </span>
            )}
          </>
        )}
      </Button>
    );

    if (collapsed) {
      return (
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>{buttonContent}</TooltipTrigger>
            <TooltipContent side="right" className="flex items-center gap-2">
              {item.label}
              {item.badge !== undefined && item.badge > 0 && (
                <span
                  className={`${
                    item.badgeColor || "bg-red-500"
                  } text-white text-xs rounded-full px-2 py-0.5`}
                >
                  {item.badge}
                </span>
              )}
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      );
    }

    return buttonContent;
  };

  return (
    <div
      className={cn(
        "fixed left-0 top-0 h-full bg-white border-r border-gray-200 transition-all duration-300 z-40 flex flex-col",
        collapsed ? "w-16" : "w-64"
      )}
    >
      {/* Logo Section */}
      <div className="h-16 flex items-center justify-center border-b border-gray-200 bg-gradient-to-r from-blue-600 to-indigo-600 flex-shrink-0">
        {collapsed ? (
          <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center">
            <Shield className="h-5 w-5 text-blue-600" />
          </div>
        ) : (
          <div className="flex items-center space-x-2 text-white px-4">
            <Shield className="h-6 w-6 flex-shrink-0" />
            <div className="min-w-0">
              <div className="font-bold text-sm truncate">
                Emergency Response
              </div>
              <div className="text-xs opacity-90 truncate">Admin Portal</div>
            </div>
          </div>
        )}
      </div>

      {/* Navigation - Takes up remaining space */}
      <nav className="flex-1 overflow-y-auto py-4 min-h-0">
        <div className="space-y-1 px-2">
          {navigationItems.map((item) => (
            <NavItemComponent key={item.id} item={item} />
          ))}
        </div>
      </nav>

      {/* User Section - Fixed at bottom */}
      <div className="border-t border-gray-200 p-2 flex-shrink-0">
        {collapsed ? (
          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger asChild>
                <div className="flex items-center justify-center p-2 rounded-lg hover:bg-gray-50 transition-colors cursor-pointer">
                  <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-white text-sm font-medium">A</span>
                  </div>
                </div>
              </TooltipTrigger>
              <TooltipContent side="right">
                <div className="text-sm">
                  <div className="font-medium">Admin User</div>
                  <div className="text-xs text-gray-500">
                    admin@emergency.com
                  </div>
                </div>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>
        ) : (
          <div className="flex items-center space-x-3 p-2 rounded-lg hover:bg-gray-50 transition-colors">
            <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white text-sm font-medium">A</span>
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium text-gray-900 truncate">
                Admin User
              </div>
              <div className="text-xs text-gray-500 truncate">
                admin@emergency.com
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
