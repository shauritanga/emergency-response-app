import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { 
  Users, 
  UserCheck, 
  Shield, 
  Activity,
  TrendingUp,
  Clock,
  MapPin,
  AlertTriangle
} from "lucide-react";

interface UserStatsProps {
  users: any[];
  loading?: boolean;
}

export const UserStats: React.FC<UserStatsProps> = ({ users, loading }) => {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[1, 2, 3, 4].map((i) => (
          <Card key={i} className="border-0 shadow-lg">
            <CardContent className="p-6">
              <div className="animate-pulse space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gray-200 rounded-lg"></div>
                  <div className="h-4 bg-gray-200 rounded w-24"></div>
                </div>
                <div className="h-8 bg-gray-200 rounded w-16"></div>
                <div className="h-2 bg-gray-200 rounded w-full"></div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  // Calculate user statistics
  const totalUsers = users.length;
  const activeUsers = users.filter(u => u.status === 'active').length;
  const responders = users.filter(u => u.role === 'responder').length;
  const admins = users.filter(u => u.role === 'admin').length;
  const citizens = users.filter(u => u.role === 'citizen').length;
  
  // Calculate activity metrics
  const recentlyActive = users.filter(u => {
    if (!u.lastActive) return false;
    const lastActive = new Date(u.lastActive);
    const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    return lastActive > dayAgo;
  }).length;

  const newUsersThisWeek = users.filter(u => {
    if (!u.createdAt) return false;
    const created = new Date(u.createdAt);
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    return created > weekAgo;
  }).length;

  const statsCards = [
    {
      title: "Total Users",
      value: totalUsers,
      description: "All registered users",
      icon: Users,
      color: "text-blue-600",
      bgColor: "bg-blue-50",
      progress: 100,
      trend: `+${newUsersThisWeek} this week`
    },
    {
      title: "Active Users",
      value: activeUsers,
      description: "Currently active",
      icon: Activity,
      color: "text-green-600",
      bgColor: "bg-green-50",
      progress: totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0,
      trend: `${recentlyActive} active today`
    },
    {
      title: "Responders",
      value: responders,
      description: "Emergency responders",
      icon: UserCheck,
      color: "text-orange-600",
      bgColor: "bg-orange-50",
      progress: totalUsers > 0 ? (responders / totalUsers) * 100 : 0,
      trend: `${Math.round((responders / totalUsers) * 100)}% of users`
    },
    {
      title: "Administrators",
      value: admins,
      description: "System administrators",
      icon: Shield,
      color: "text-purple-600",
      bgColor: "bg-purple-50",
      progress: totalUsers > 0 ? (admins / totalUsers) * 100 : 0,
      trend: `${Math.round((admins / totalUsers) * 100)}% of users`
    }
  ];

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statsCards.map((stat, index) => (
          <Card key={index} className="border-0 shadow-lg hover:shadow-xl transition-all duration-300">
            <CardContent className="p-6">
              <div className="flex items-center justify-between mb-4">
                <div className={`p-3 rounded-lg ${stat.bgColor}`}>
                  <stat.icon className={`h-6 w-6 ${stat.color}`} />
                </div>
                <Badge variant="outline" className="text-xs">
                  {stat.trend}
                </Badge>
              </div>
              
              <div className="space-y-3">
                <div>
                  <h3 className="text-sm font-medium text-gray-600">{stat.title}</h3>
                  <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                  <p className="text-xs text-gray-500">{stat.description}</p>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-xs text-gray-500">
                    <span>Distribution</span>
                    <span>{stat.progress.toFixed(0)}%</span>
                  </div>
                  <Progress value={stat.progress} className="h-2" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Detailed Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Role Distribution */}
        <Card className="border-0 shadow-lg">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5 text-blue-500" />
              User Role Distribution
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[
                { name: 'Citizens', count: citizens, color: 'bg-green-500', percentage: (citizens / totalUsers) * 100 },
                { name: 'Responders', count: responders, color: 'bg-orange-500', percentage: (responders / totalUsers) * 100 },
                { name: 'Administrators', count: admins, color: 'bg-purple-500', percentage: (admins / totalUsers) * 100 }
              ].map((role, index) => (
                <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className={`w-4 h-4 rounded-full ${role.color}`}></div>
                    <span className="font-medium text-gray-900">{role.name}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-right">
                      <div className="text-lg font-bold text-gray-900">{role.count}</div>
                      <div className="text-xs text-gray-500">{role.percentage.toFixed(1)}%</div>
                    </div>
                    <div className="w-16 bg-gray-200 rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full transition-all duration-700 ${role.color}`}
                        style={{ width: `${role.percentage}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Activity Overview */}
        <Card className="border-0 shadow-lg">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-500" />
              User Activity Overview
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="text-center p-4 bg-blue-50 rounded-lg">
                <div className="text-3xl font-bold text-blue-600">{recentlyActive}</div>
                <div className="text-sm text-gray-600">Active in last 24 hours</div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <div className="text-xl font-bold text-gray-900">{newUsersThisWeek}</div>
                  <div className="text-xs text-gray-600">New this week</div>
                </div>
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <div className="text-xl font-bold text-gray-900">{Math.round((activeUsers / totalUsers) * 100)}%</div>
                  <div className="text-xs text-gray-600">Active rate</div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
