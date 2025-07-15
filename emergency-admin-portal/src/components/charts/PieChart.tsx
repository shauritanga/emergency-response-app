import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface PieChartData {
  label: string;
  value: number;
  color: string;
}

interface PieChartProps {
  data: PieChartData[];
  title: string;
  size?: number;
  showLegend?: boolean;
}

export const PieChart: React.FC<PieChartProps> = ({
  data,
  title,
  size = 200,
  showLegend = true,
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

  const total = data.reduce((sum, item) => sum + item.value, 0);
  const radius = size / 2 - 10;
  const center = size / 2;

  // Calculate angles for each slice
  let currentAngle = -90; // Start from top
  const slices = data.map((item) => {
    const percentage = (item.value / total) * 100;
    const angle = (item.value / total) * 360;
    const startAngle = currentAngle;
    const endAngle = currentAngle + angle;

    currentAngle += angle;

    // Calculate path for the slice
    const startAngleRad = (startAngle * Math.PI) / 180;
    const endAngleRad = (endAngle * Math.PI) / 180;

    const x1 = center + radius * Math.cos(startAngleRad);
    const y1 = center + radius * Math.sin(startAngleRad);
    const x2 = center + radius * Math.cos(endAngleRad);
    const y2 = center + radius * Math.sin(endAngleRad);

    const largeArcFlag = angle > 180 ? 1 : 0;

    const pathData = [
      `M ${center} ${center}`,
      `L ${x1} ${y1}`,
      `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${x2} ${y2}`,
      "Z",
    ].join(" ");

    return {
      ...item,
      pathData,
      percentage,
      startAngle,
      endAngle,
    };
  });

  return (
    <Card className="bg-card border-border">
      <CardHeader>
        <CardTitle className="text-card-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col lg:flex-row items-center gap-6">
          {/* Pie Chart */}
          <div className="relative">
            <svg width={size} height={size} className="transform rotate-0">
              {slices.map((slice, index) => (
                <g key={index}>
                  <path
                    d={slice.pathData}
                    fill={slice.color}
                    className="hover:opacity-80 transition-opacity cursor-pointer"
                    stroke="white"
                    strokeWidth="2"
                  >
                    <title>
                      {slice.label}: {slice.value} (
                      {slice.percentage.toFixed(1)}%)
                    </title>
                  </path>
                </g>
              ))}

              {/* Center circle for donut effect */}
              <circle
                cx={center}
                cy={center}
                r={radius * 0.6}
                fill="hsl(var(--card))"
                stroke="hsl(var(--border))"
                strokeWidth="2"
              />

              {/* Center text */}
              <text
                x={center}
                y={center - 10}
                textAnchor="middle"
                className="text-2xl font-bold fill-card-foreground"
              >
                {total}
              </text>
              <text
                x={center}
                y={center + 10}
                textAnchor="middle"
                className="text-sm fill-muted-foreground"
              >
                Total
              </text>
            </svg>
          </div>

          {/* Legend */}
          {showLegend && (
            <div className="flex-1 space-y-2">
              {slices.map((slice, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-2 rounded-lg bg-muted/30"
                >
                  <div className="flex items-center gap-2">
                    <div
                      className="w-4 h-4 rounded-full"
                      style={{ backgroundColor: slice.color }}
                    ></div>
                    <span className="text-sm font-medium text-card-foreground">
                      {slice.label}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline" className="text-xs">
                      {slice.value}
                    </Badge>
                    <span className="text-xs text-muted-foreground">
                      {slice.percentage.toFixed(1)}%
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Summary */}
        <div className="mt-6 pt-4 border-t border-border">
          <div className="grid grid-cols-2 gap-4 text-center">
            <div>
              <div className="text-lg font-semibold text-card-foreground">
                {data.length}
              </div>
              <div className="text-xs text-muted-foreground">Categories</div>
            </div>
            <div>
              <div className="text-lg font-semibold text-card-foreground">
                {total}
              </div>
              <div className="text-xs text-muted-foreground">Total Items</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

// Predefined color palettes
export const colorPalettes = {
  status: {
    pending: "#ef4444", // Red for pending
    reported: "#ef4444", // Red for reported
    dispatched: "#f59e0b", // Orange for dispatched
    in_progress: "#3b82f6", // Blue for in progress
    active: "#3b82f6", // Blue for active
    resolved: "#22c55e", // Green for resolved
    completed: "#22c55e", // Green for completed
    cancelled: "#6b7280", // Gray for cancelled
  },
  priority: {
    critical: "#dc2626", // Dark red
    high: "#ea580c", // Orange-red
    medium: "#ca8a04", // Yellow-orange
    low: "#16a34a", // Green
    normal: "#3b82f6", // Blue
  },
  type: {
    fire: "#dc2626", // Red
    medical: "#059669", // Teal
    police: "#2563eb", // Blue
    accident: "#7c3aed", // Purple
    rescue: "#059669", // Teal
    other: "#6b7280", // Gray
    unknown: "#6b7280", // Gray
  },
  department: {
    fire: "#dc2626", // Red
    police: "#2563eb", // Blue
    medical: "#059669", // Teal
    rescue: "#7c3aed", // Purple
    emergency: "#f59e0b", // Orange
  },
  // Default color sequence for when specific colors aren't defined
  default: [
    "#3b82f6", // Blue
    "#ef4444", // Red
    "#22c55e", // Green
    "#f59e0b", // Orange
    "#7c3aed", // Purple
    "#059669", // Teal
    "#dc2626", // Dark red
    "#ca8a04", // Yellow
    "#6b7280", // Gray
    "#ec4899", // Pink
    "#14b8a6", // Cyan
    "#f97316", // Orange-red
  ],
};

// Helper function to get color for data item
export const getColorForItem = (
  key: string,
  palette: keyof typeof colorPalettes,
  index: number = 0
): string => {
  // First try to get color from specific palette
  if (palette !== "default" && colorPalettes[palette]) {
    const paletteColors = colorPalettes[palette] as Record<string, string>;
    if (paletteColors[key.toLowerCase()]) {
      return paletteColors[key.toLowerCase()];
    }
  }

  // Fall back to default color sequence
  return colorPalettes.default[index % colorPalettes.default.length];
};
