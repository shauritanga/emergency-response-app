import * as React from "react";
import * as SwitchPrimitive from "@radix-ui/react-switch";

import { cn } from "@/lib/utils";

function Switch({
  className,
  ...props
}: React.ComponentProps<typeof SwitchPrimitive.Root>) {
  return (
    <SwitchPrimitive.Root
      data-slot="switch"
      className={cn(
        // Modern iOS-style switch design
        "peer inline-flex h-7 w-12 shrink-0 cursor-pointer items-center rounded-full transition-all duration-200 ease-in-out",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 focus-visible:ring-offset-background",
        "disabled:cursor-not-allowed disabled:opacity-50",
        // Checked state - vibrant green like iOS
        "data-[state=checked]:bg-green-500 data-[state=checked]:shadow-inner",
        // Unchecked state - gray background
        "data-[state=unchecked]:bg-gray-300 dark:data-[state=unchecked]:bg-gray-600",
        // Hover effects for better interactivity
        "hover:data-[state=checked]:bg-green-600 hover:data-[state=unchecked]:bg-gray-400 dark:hover:data-[state=unchecked]:bg-gray-500",
        // Active state for click feedback
        "active:scale-95",
        className
      )}
      {...props}
    >
      <SwitchPrimitive.Thumb
        data-slot="switch-thumb"
        className={cn(
          // iOS-style thumb with proper sizing and shadow
          "pointer-events-none block h-5 w-5 rounded-full bg-white shadow-lg transition-all duration-200 ease-in-out",
          // Smooth translation with proper positioning
          "data-[state=checked]:translate-x-6 data-[state=unchecked]:translate-x-0.5",
          // Enhanced shadow and border for depth
          "border border-gray-200 dark:border-gray-300",
          "shadow-[0_2px_4px_rgba(0,0,0,0.2)]",
          // Subtle scale effect on state change
          "data-[state=checked]:scale-100 data-[state=unchecked]:scale-95"
        )}
      />
    </SwitchPrimitive.Root>
  );
}

export { Switch };
