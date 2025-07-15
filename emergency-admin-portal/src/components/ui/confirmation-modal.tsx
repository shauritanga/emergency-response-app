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
          iconBg: "bg-red-100",
          iconColor: "text-red-600",
          icon: Trash2,
          confirmButtonClass: "bg-red-600 hover:bg-red-700 text-white",
        };
      case "warning":
        return {
          iconBg: "bg-yellow-100",
          iconColor: "text-yellow-600",
          icon: AlertTriangle,
          confirmButtonClass: "bg-yellow-600 hover:bg-yellow-700 text-white",
        };
      case "info":
        return {
          iconBg: "bg-blue-100",
          iconColor: "text-blue-600",
          icon: AlertTriangle,
          confirmButtonClass: "bg-blue-600 hover:bg-blue-700 text-white",
        };
      default:
        return {
          iconBg: "bg-red-100",
          iconColor: "text-red-600",
          icon: Trash2,
          confirmButtonClass: "bg-red-600 hover:bg-red-700 text-white",
        };
    }
  };

  const styles = getVariantStyles();
  const Icon = styles.icon;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md bg-card border-border">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3 text-card-foreground">
            <div
              className={`p-2 ${styles.iconBg} dark:${styles.iconBg.replace(
                "100",
                "900/30"
              )} rounded-lg`}
            >
              <Icon
                className={`h-5 w-5 ${
                  styles.iconColor
                } dark:${styles.iconColor.replace("600", "400")}`}
              />
            </div>
            {title}
          </DialogTitle>
        </DialogHeader>

        <div className="bg-card border border-border rounded-lg p-6">
          <div className="py-4">
            <p className="text-muted-foreground leading-relaxed">
              {description}
            </p>
          </div>

          <DialogFooter className="pt-6">
            <Button
              variant="outline"
              onClick={onClose}
              disabled={isLoading}
              className="bg-background border-input hover:bg-accent"
            >
              <X className="h-4 w-4 mr-2" />
              {cancelText}
            </Button>
            <Button
              onClick={onConfirm}
              disabled={isLoading}
              className={styles.confirmButtonClass}
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
