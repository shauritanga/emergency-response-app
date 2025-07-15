import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { TrendingUp, TrendingDown } from "lucide-react";

interface DataPoint {
  date: string;
  count: number;
  resolved: number;
  avgResponseTime: number;
}

interface EmergencyTrendsChartProps {
  data: DataPoint[];
  title?: string;
  height?: number;
}

export const EmergencyTrendsChart: React.FC<EmergencyTrendsChartProps> = ({
  data,
  title = "Emergency Trends",
  height = 300,
}) => {
  if (!data || data.length === 0) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="text-card-foreground">{title}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center h-64 text-muted-foreground">
            No data available
          </div>
        </CardContent>
      </Card>
    );
  }

  const maxCount = Math.max(...data.map((d) => d.count));
  const maxResolved = Math.max(...data.map((d) => d.resolved));
  const maxValue = Math.max(maxCount, maxResolved);

  // Calculate trend
  const firstWeek = data.slice(0, Math.floor(data.length / 2));
  const secondWeek = data.slice(Math.floor(data.length / 2));
  
  const firstWeekAvg = firstWeek.reduce((sum, d) => sum + d.count, 0) / firstWeek.length;
  const secondWeekAvg = secondWeek.reduce((sum, d) => sum + d.count, 0) / secondWeek.length;
  
  const trend = secondWeekAvg - firstWeekAvg;
  const trendPercentage = firstWeekAvg > 0 ? (trend / firstWeekAvg) * 100 : 0;

  return (
    <Card className="bg-card border-border">
      <CardHeader>
        <CardTitle className="flex items-center justify-between text-card-foreground">
          <span>{title}</span>
          <div className="flex items-center gap-1 text-sm">
            {trend >= 0 ? (
              <TrendingUp className="h-4 w-4 text-red-500" />
            ) : (
              <TrendingDown className="h-4 w-4 text-green-500" />
            )}
            <span
              className={`font-medium ${
                trend >= 0 ? "text-red-600 dark:text-red-400" : "text-green-600 dark:text-green-400"
              }`}
            >
              {Math.abs(trendPercentage).toFixed(1)}%
            </span>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Legend */}
          <div className="flex items-center gap-4 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-red-500 rounded-full"></div>
              <span className="text-muted-foreground">Total Emergencies</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-muted-foreground">Resolved</span>
            </div>
          </div>

          {/* Chart */}
          <div className="relative" style={{ height: `${height}px` }}>
            <svg width="100%" height="100%" className="overflow-visible">
              {/* Grid lines */}
              {[0, 0.25, 0.5, 0.75, 1].map((ratio) => (
                <g key={ratio}>
                  <line
                    x1="0"
                    y1={height * ratio}
                    x2="100%"
                    y2={height * ratio}
                    stroke="currentColor"
                    strokeWidth="1"
                    className="text-border opacity-30"
                  />
                  <text
                    x="0"
                    y={height * ratio - 5}
                    className="text-xs fill-muted-foreground"
                  >
                    {Math.round(maxValue * (1 - ratio))}
                  </text>
                </g>
              ))}

              {/* Data lines */}
              <g>
                {/* Total emergencies line */}
                <polyline
                  fill="none"
                  stroke="#ef4444"
                  strokeWidth="2"
                  points={data
                    .map((d, i) => {
                      const x = (i / (data.length - 1)) * 100;
                      const y = height - (d.count / maxValue) * height;
                      return `${x}%,${y}`;
                    })
                    .join(" ")}
                />

                {/* Resolved emergencies line */}
                <polyline
                  fill="none"
                  stroke="#22c55e"
                  strokeWidth="2"
                  points={data
                    .map((d, i) => {
                      const x = (i / (data.length - 1)) * 100;
                      const y = height - (d.resolved / maxValue) * height;
                      return `${x}%,${y}`;
                    })
                    .join(" ")}
                />

                {/* Data points */}
                {data.map((d, i) => {
                  const x = (i / (data.length - 1)) * 100;
                  const yTotal = height - (d.count / maxValue) * height;
                  const yResolved = height - (d.resolved / maxValue) * height;

                  return (
                    <g key={i}>
                      {/* Total emergencies point */}
                      <circle
                        cx={`${x}%`}
                        cy={yTotal}
                        r="4"
                        fill="#ef4444"
                        className="hover:r-6 transition-all cursor-pointer"
                      >
                        <title>
                          {new Date(d.date).toLocaleDateString()}: {d.count} emergencies
                        </title>
                      </circle>

                      {/* Resolved emergencies point */}
                      <circle
                        cx={`${x}%`}
                        cy={yResolved}
                        r="4"
                        fill="#22c55e"
                        className="hover:r-6 transition-all cursor-pointer"
                      >
                        <title>
                          {new Date(d.date).toLocaleDateString()}: {d.resolved} resolved
                        </title>
                      </circle>
                    </g>
                  );
                })}
              </g>
            </svg>

            {/* X-axis labels */}
            <div className="absolute bottom-0 left-0 right-0 flex justify-between text-xs text-muted-foreground mt-2">
              {data.map((d, i) => {
                if (i % Math.ceil(data.length / 5) === 0 || i === data.length - 1) {
                  return (
                    <span key={i}>
                      {new Date(d.date).toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                      })}
                    </span>
                  );
                }
                return null;
              })}
            </div>
          </div>

          {/* Summary stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-border">
            <div className="text-center">
              <div className="text-lg font-semibold text-card-foreground">
                {data.reduce((sum, d) => sum + d.count, 0)}
              </div>
              <div className="text-xs text-muted-foreground">Total</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-semibold text-green-600 dark:text-green-400">
                {data.reduce((sum, d) => sum + d.resolved, 0)}
              </div>
              <div className="text-xs text-muted-foreground">Resolved</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-semibold text-blue-600 dark:text-blue-400">
                {(
                  data.reduce((sum, d) => sum + d.avgResponseTime, 0) / data.length
                ).toFixed(1)}m
              </div>
              <div className="text-xs text-muted-foreground">Avg Response</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
