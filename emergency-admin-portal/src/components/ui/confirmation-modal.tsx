import React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { AlertTriangle, Trash2, X } from "lucide-react";

interface ConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description: string;
  confirmText?: string;
  cancelText?: string;
  variant?: "danger" | "warning" | "info";
  isLoading?: boolean;
}

export const ConfirmationModal: React.FC<ConfirmationModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  description,
  confirmText = "Confirm",
  cancelText = "Cancel",
  variant = "danger",
  isLoading = false,
}) => {
  const getVariantStyles = () => {
    switch (variant) {
      case "danger":
        return {
          iconBg: "bg-red-100 dark:bg-red-900/30",
          iconColor: "text-red-600 dark:text-red-400",
          icon: Trash2,
          confirmButtonClass: "bg-red-600 hover:bg-red-700 dark:bg-red-600 dark:hover:bg-red-700 text-white",
          borderColor: "border-red-200 dark:border-red-800",
          bgColor: "bg-red-50/50 dark:bg-red-900/10",
        };
      case "warning":
        return {
          iconBg: "bg-yellow-100 dark:bg-yellow-900/30",
          iconColor: "text-yellow-600 dark:text-yellow-400",
          icon: AlertTriangle,
          confirmButtonClass: "bg-yellow-600 hover:bg-yellow-700 dark:bg-yellow-600 dark:hover:bg-yellow-700 text-white",
          borderColor: "border-yellow-200 dark:border-yellow-800",
          bgColor: "bg-yellow-50/50 dark:bg-yellow-900/10",
        };
      case "info":
        return {
          iconBg: "bg-blue-100 dark:bg-blue-900/30",
          iconColor: "text-blue-600 dark:text-blue-400",
          icon: AlertTriangle,
          confirmButtonClass: "bg-blue-600 hover:bg-blue-700 dark:bg-blue-600 dark:hover:bg-blue-700 text-white",
          borderColor: "border-blue-200 dark:border-blue-800",
          bgColor: "bg-blue-50/50 dark:bg-blue-900/10",
        };
      default:
        return {
          iconBg: "bg-red-100 dark:bg-red-900/30",
          iconColor: "text-red-600 dark:text-red-400",
          icon: Trash2,
          confirmButtonClass: "bg-red-600 hover:bg-red-700 dark:bg-red-600 dark:hover:bg-red-700 text-white",
          borderColor: "border-red-200 dark:border-red-800",
          bgColor: "bg-red-50/50 dark:bg-red-900/10",
        };
    }
  };

  const styles = getVariantStyles();
  const Icon = styles.icon;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md bg-background dark:bg-gray-900 border-border shadow-2xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3 text-foreground">
            <div className={`p-2 ${styles.iconBg} rounded-lg`}>
              <Icon className={`h-5 w-5 ${styles.iconColor}`} />
            </div>
            {title}
          </DialogTitle>
        </DialogHeader>

        <div className={`${styles.bgColor} border ${styles.borderColor} rounded-lg p-6`}>
          <div className="py-4">
            <p className="text-foreground/80 dark:text-gray-300 leading-relaxed">
              {description}
            </p>
          </div>

          <DialogFooter className="pt-6 gap-3">
            <Button
              variant="outline"
              onClick={onClose}
              disabled={isLoading}
              className="bg-background dark:bg-gray-800 border-input dark:border-gray-600 hover:bg-accent dark:hover:bg-gray-700 text-foreground"
            >
              <X className="h-4 w-4 mr-2" />
              {cancelText}
            </Button>
            <Button
              onClick={onConfirm}
              disabled={isLoading}
              className={`${styles.confirmButtonClass} disabled:opacity-50 disabled:cursor-not-allowed`}
            >
              <Icon className="h-4 w-4 mr-2" />
              {isLoading ? "Processing..." : confirmText}
            </Button>
          </DialogFooter>
        </div>
      </DialogContent>
    </Dialog>
  );
};
