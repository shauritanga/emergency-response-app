import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { 
  Clock, 
  Target, 
  TrendingUp, 
  TrendingDown,
  CheckCircle,
  AlertCircle,
  Users,
  MapPin
} from "lucide-react";

interface PerformanceMetricsProps {
  emergencies: any[];
  loading?: boolean;
}

export const PerformanceMetrics: React.FC<PerformanceMetricsProps> = ({ emergencies, loading }) => {
  // Calculate performance metrics
  const calculateMetrics = () => {
    const resolvedEmergencies = emergencies.filter(e => e.status === 'resolved');
    const activeEmergencies = emergencies.filter(e => e.status === 'pending' || e.status === 'in_progress');
    
    // Response time calculation (mock data for now)
    const avgResponseTime = resolvedEmergencies.length > 0 ? 
      resolvedEmergencies.reduce((acc, emergency) => {
        // Mock response time calculation
        const responseTime = Math.random() * 15 + 2; // 2-17 minutes
        return acc + responseTime;
      }, 0) / resolvedEmergencies.length : 0;

    // Resolution rate
    const resolutionRate = emergencies.length > 0 ? 
      (resolvedEmergencies.length / emergencies.length) * 100 : 0;

    // Today's metrics
    const today = new Date();
    const todayEmergencies = emergencies.filter(e => {
      const emergencyDate = new Date(e.createdAt || new Date());
      return emergencyDate.toDateString() === today.toDateString();
    });

    // Emergency types distribution
    const typeDistribution = emergencies.reduce((acc, emergency) => {
      const type = emergency.type || 'unknown';
      acc[type] = (acc[type] || 0) + 1;
      return acc;
    }, {});

    return {
      avgResponseTime,
      resolutionRate,
      totalEmergencies: emergencies.length,
      activeEmergencies: activeEmergencies.length,
      resolvedEmergencies: resolvedEmergencies.length,
      todayEmergencies: todayEmergencies.length,
      typeDistribution
    };
  };

  const metrics = calculateMetrics();

  const performanceCards = [
    {
      title: "Avg Response Time",
      value: `${metrics.avgResponseTime.toFixed(1)} min`,
      target: "< 5 min",
      progress: Math.max(0, 100 - (metrics.avgResponseTime / 5) * 100),
      trend: metrics.avgResponseTime < 5 ? "up" : "down",
      icon: Clock,
      color: metrics.avgResponseTime < 5 ? "text-green-600" : "text-red-600",
      bgColor: metrics.avgResponseTime < 5 ? "bg-green-50" : "bg-red-50"
    },
    {
      title: "Resolution Rate",
      value: `${metrics.resolutionRate.toFixed(1)}%`,
      target: "> 90%",
      progress: metrics.resolutionRate,
      trend: metrics.resolutionRate > 90 ? "up" : "down",
      icon: Target,
      color: metrics.resolutionRate > 90 ? "text-green-600" : "text-yellow-600",
      bgColor: metrics.resolutionRate > 90 ? "bg-green-50" : "bg-yellow-50"
    },
    {
      title: "Active Cases",
      value: metrics.activeEmergencies.toString(),
      target: "< 10",
      progress: Math.max(0, 100 - (metrics.activeEmergencies / 10) * 100),
      trend: metrics.activeEmergencies < 10 ? "up" : "down",
      icon: AlertCircle,
      color: metrics.activeEmergencies < 10 ? "text-green-600" : "text-red-600",
      bgColor: metrics.activeEmergencies < 10 ? "bg-green-50" : "bg-red-50"
    },
    {
      title: "Today's Reports",
      value: metrics.todayEmergencies.toString(),
      target: "Daily tracking",
      progress: Math.min(100, (metrics.todayEmergencies / 20) * 100),
      trend: "neutral",
      icon: CheckCircle,
      color: "text-blue-600",
      bgColor: "bg-blue-50"
    }
  ];

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

  return (
    <div className="space-y-6">
      {/* Performance Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {performanceCards.map((card, index) => (
          <Card key={index} className="border-0 shadow-lg hover:shadow-xl transition-all duration-300">
            <CardContent className="p-6">
              <div className="flex items-center justify-between mb-4">
                <div className={`p-3 rounded-lg ${card.bgColor}`}>
                  <card.icon className={`h-6 w-6 ${card.color}`} />
                </div>
                <div className="flex items-center gap-1">
                  {card.trend === "up" && <TrendingUp className="h-4 w-4 text-green-500" />}
                  {card.trend === "down" && <TrendingDown className="h-4 w-4 text-red-500" />}
                  <Badge variant="outline" className="text-xs">
                    {card.target}
                  </Badge>
                </div>
              </div>
              
              <div className="space-y-3">
                <div>
                  <h3 className="text-sm font-medium text-gray-600">{card.title}</h3>
                  <p className="text-2xl font-bold text-gray-900">{card.value}</p>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-xs text-gray-500">
                    <span>Performance</span>
                    <span>{card.progress.toFixed(0)}%</span>
                  </div>
                  <Progress value={card.progress} className="h-2" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Detailed Performance Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Response Time Breakdown */}
        <Card className="border-0 shadow-lg">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5 text-blue-500" />
              Response Time Analysis
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex justify-between items-center p-3 bg-green-50 rounded-lg">
                <span className="text-sm font-medium">Under 5 minutes</span>
                <div className="flex items-center gap-2">
                  <div className="w-20 bg-gray-200 rounded-full h-2">
                    <div className="bg-green-500 h-2 rounded-full" style={{ width: '75%' }}></div>
                  </div>
                  <span className="text-sm font-bold text-green-600">75%</span>
                </div>
              </div>
              
              <div className="flex justify-between items-center p-3 bg-yellow-50 rounded-lg">
                <span className="text-sm font-medium">5-10 minutes</span>
                <div className="flex items-center gap-2">
                  <div className="w-20 bg-gray-200 rounded-full h-2">
                    <div className="bg-yellow-500 h-2 rounded-full" style={{ width: '20%' }}></div>
                  </div>
                  <span className="text-sm font-bold text-yellow-600">20%</span>
                </div>
              </div>
              
              <div className="flex justify-between items-center p-3 bg-red-50 rounded-lg">
                <span className="text-sm font-medium">Over 10 minutes</span>
                <div className="flex items-center gap-2">
                  <div className="w-20 bg-gray-200 rounded-full h-2">
                    <div className="bg-red-500 h-2 rounded-full" style={{ width: '5%' }}></div>
                  </div>
                  <span className="text-sm font-bold text-red-600">5%</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Geographic Performance */}
        <Card className="border-0 shadow-lg">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MapPin className="h-5 w-5 text-green-500" />
              Geographic Coverage
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="text-center p-4 bg-blue-50 rounded-lg">
                <div className="text-3xl font-bold text-blue-600">{metrics.totalEmergencies}</div>
                <div className="text-sm text-gray-600">Total Emergencies Handled</div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <div className="text-xl font-bold text-gray-900">95%</div>
                  <div className="text-xs text-gray-600">Coverage Area</div>
                </div>
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <div className="text-xl font-bold text-gray-900">4.2</div>
                  <div className="text-xs text-gray-600">Avg Distance (km)</div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};
