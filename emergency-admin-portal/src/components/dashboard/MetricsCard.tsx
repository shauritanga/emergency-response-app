import React from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import type { LucideProps } from "lucide-react";
import { cn } from "@/lib/utils";

interface MetricsCardProps {
  title: string;
  value: string | number;
  description?: string;
  icon: React.ComponentType<LucideProps>;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  badge?: {
    text: string;
    variant?: "default" | "secondary" | "destructive" | "outline";
  };
  className?: string;
  gradient?: string;
  iconBg?: string;
}

export const MetricsCard: React.FC<MetricsCardProps> = ({
  title,
  value,
  description,
  icon: Icon,
  trend,
  badge,
  className,
  gradient = "from-blue-500 to-blue-600",
  iconBg = "bg-blue-500",
}) => {
  return (
    <Card
      className={cn(
        "relative overflow-hidden border-0 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 bg-white",
        className
      )}
    >
      {/* Subtle background gradient */}
      <div
        className={cn("absolute inset-0 bg-gradient-to-br opacity-3", gradient)}
      />

      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3 relative">
        <CardTitle className="text-sm font-semibold text-gray-600 uppercase tracking-wide">
          {title}
        </CardTitle>
        <div className="flex items-center space-x-2">
          {badge && (
            <Badge
              variant={badge.variant || "default"}
              className="text-xs shadow-sm"
            >
              {badge.text}
            </Badge>
          )}
          <div
            className={cn(
              "p-2.5 rounded-xl shadow-sm transition-transform hover:scale-110",
              iconBg
            )}
          >
            <Icon className="h-5 w-5 text-white" />
          </div>
        </div>
      </CardHeader>
      <CardContent className="relative">
        <div className="text-3xl font-bold text-gray-900 mb-1 tracking-tight">
          {value}
        </div>
        {description && (
          <p className="text-sm text-gray-500 mb-3">{description}</p>
        )}
        {trend && (
          <div className="flex items-center">
            <div
              className={cn(
                "flex items-center px-2.5 py-1 rounded-full text-xs font-semibold shadow-sm",
                trend.isPositive
                  ? "bg-emerald-100 text-emerald-700 border border-emerald-200"
                  : "bg-red-100 text-red-700 border border-red-200"
              )}
            >
              <span className="mr-1 text-sm">
                {trend.isPositive ? "↗" : "↘"}
              </span>
              {Math.abs(trend.value)}%
            </div>
            <span className="text-xs text-gray-400 ml-2 font-medium">
              from last month
            </span>
          </div>
        )}
      </CardContent>
    </Card>
  );
};
