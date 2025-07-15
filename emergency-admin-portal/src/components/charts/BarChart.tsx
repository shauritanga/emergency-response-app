import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface BarChartData {
  label: string;
  value: number;
  color?: string;
}

interface BarChartProps {
  data: BarChartData[];
  title: string;
  height?: number;
  horizontal?: boolean;
  showValues?: boolean;
}

export const BarChart: React.FC<BarChartProps> = ({
  data,
  title,
  height = 300,
  horizontal = false,
  showValues = true,
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

  const maxValue = Math.max(...data.map((d) => d.value));
  const defaultColor = "#3b82f6";

  if (horizontal) {
    return (
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="text-card-foreground">{title}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {data.map((item, index) => {
              const percentage = maxValue > 0 ? (item.value / maxValue) * 100 : 0;
              
              return (
                <div key={index} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-card-foreground">
                      {item.label}
                    </span>
                    {showValues && (
                      <Badge variant="outline" className="text-xs">
                        {item.value}
                      </Badge>
                    )}
                  </div>
                  <div className="w-full bg-muted rounded-full h-3">
                    <div
                      className="h-3 rounded-full transition-all duration-500 ease-out"
                      style={{
                        width: `${percentage}%`,
                        backgroundColor: item.color || defaultColor,
                      }}
                    ></div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="bg-card border-border">
      <CardHeader>
        <CardTitle className="text-card-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
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

              {/* Bars */}
              {data.map((item, index) => {
                const barWidth = 100 / data.length;
                const barHeight = maxValue > 0 ? (item.value / maxValue) * height : 0;
                const x = (index * barWidth) + (barWidth * 0.1);
                const y = height - barHeight;
                const width = barWidth * 0.8;

                return (
                  <g key={index}>
                    {/* Bar */}
                    <rect
                      x={`${x}%`}
                      y={y}
                      width={`${width}%`}
                      height={barHeight}
                      fill={item.color || defaultColor}
                      className="hover:opacity-80 transition-opacity cursor-pointer"
                      rx="4"
                    >
                      <title>
                        {item.label}: {item.value}
                      </title>
                    </rect>

                    {/* Value label */}
                    {showValues && item.value > 0 && (
                      <text
                        x={`${x + width / 2}%`}
                        y={y - 5}
                        textAnchor="middle"
                        className="text-xs fill-card-foreground font-medium"
                      >
                        {item.value}
                      </text>
                    )}
                  </g>
                );
              })}
            </svg>

            {/* X-axis labels */}
            <div className="absolute bottom-0 left-0 right-0 flex justify-between text-xs text-muted-foreground mt-2">
              {data.map((item, index) => {
                const barWidth = 100 / data.length;
                const x = (index * barWidth) + (barWidth / 2);
                
                return (
                  <div
                    key={index}
                    className="absolute transform -translate-x-1/2"
                    style={{ left: `${x}%` }}
                  >
                    <span className="block max-w-16 truncate text-center">
                      {item.label}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Summary stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-border">
            <div className="text-center">
              <div className="text-lg font-semibold text-card-foreground">
                {data.reduce((sum, d) => sum + d.value, 0)}
              </div>
              <div className="text-xs text-muted-foreground">Total</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-semibold text-blue-600 dark:text-blue-400">
                {maxValue}
              </div>
              <div className="text-xs text-muted-foreground">Highest</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-semibold text-green-600 dark:text-green-400">
                {(data.reduce((sum, d) => sum + d.value, 0) / data.length).toFixed(1)}
              </div>
              <div className="text-xs text-muted-foreground">Average</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
