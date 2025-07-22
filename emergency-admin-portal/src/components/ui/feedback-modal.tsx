import React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { 
  CheckCircle, 
  AlertCircle, 
  AlertTriangle, 
  Info, 
  X,
  Loader2,
  RefreshCw
} from "lucide-react";

interface FeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
  type: "success" | "error" | "warning" | "info" | "loading";
  title: string;
  description: string;
  details?: string;
  primaryAction?: {
    label: string;
    onClick: () => void;
    variant?: "default" | "destructive" | "outline";
  };
  secondaryAction?: {
    label: string;
    onClick: () => void;
  };
  showCloseButton?: boolean;
  autoClose?: boolean;
  autoCloseDelay?: number;
}

export const FeedbackModal: React.FC<FeedbackModalProps> = ({
  isOpen,
  onClose,
  type,
  title,
  description,
  details,
  primaryAction,
  secondaryAction,
  showCloseButton = true,
  autoClose = false,
  autoCloseDelay = 3000,
}) => {
  React.useEffect(() => {
    if (autoClose && isOpen && type === "success") {
      const timer = setTimeout(() => {
        onClose();
      }, autoCloseDelay);
      return () => clearTimeout(timer);
    }
  }, [autoClose, isOpen, type, onClose, autoCloseDelay]);

  const getTypeConfig = () => {
    switch (type) {
      case "success":
        return {
          icon: CheckCircle,
          iconBg: "bg-green-100 dark:bg-green-900/30",
          iconColor: "text-green-600 dark:text-green-400",
          borderColor: "border-green-200 dark:border-green-800",
          bgColor: "bg-green-50/50 dark:bg-green-900/10",
        };
      case "error":
        return {
          icon: AlertCircle,
          iconBg: "bg-red-100 dark:bg-red-900/30",
          iconColor: "text-red-600 dark:text-red-400",
          borderColor: "border-red-200 dark:border-red-800",
          bgColor: "bg-red-50/50 dark:bg-red-900/10",
        };
      case "warning":
        return {
          icon: AlertTriangle,
          iconBg: "bg-yellow-100 dark:bg-yellow-900/30",
          iconColor: "text-yellow-600 dark:text-yellow-400",
          borderColor: "border-yellow-200 dark:border-yellow-800",
          bgColor: "bg-yellow-50/50 dark:bg-yellow-900/10",
        };
      case "info":
        return {
          icon: Info,
          iconBg: "bg-blue-100 dark:bg-blue-900/30",
          iconColor: "text-blue-600 dark:text-blue-400",
          borderColor: "border-blue-200 dark:border-blue-800",
          bgColor: "bg-blue-50/50 dark:bg-blue-900/10",
        };
      case "loading":
        return {
          icon: Loader2,
          iconBg: "bg-blue-100 dark:bg-blue-900/30",
          iconColor: "text-blue-600 dark:text-blue-400",
          borderColor: "border-blue-200 dark:border-blue-800",
          bgColor: "bg-blue-50/50 dark:bg-blue-900/10",
        };
      default:
        return {
          icon: Info,
          iconBg: "bg-gray-100 dark:bg-gray-900/30",
          iconColor: "text-gray-600 dark:text-gray-400",
          borderColor: "border-gray-200 dark:border-gray-800",
          bgColor: "bg-gray-50/50 dark:bg-gray-900/10",
        };
    }
  };

  const config = getTypeConfig();
  const Icon = config.icon;

  return (
    <Dialog open={isOpen} onOpenChange={showCloseButton ? onClose : undefined}>
      <DialogContent className="max-w-md bg-background dark:bg-gray-900 border-border shadow-2xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3 text-foreground">
            <div className={`p-2 ${config.iconBg} rounded-lg`}>
              <Icon
                className={`h-5 w-5 ${config.iconColor} ${
                  type === "loading" ? "animate-spin" : ""
                }`}
              />
            </div>
            {title}
          </DialogTitle>
        </DialogHeader>

        <div className={`${config.bgColor} border ${config.borderColor} rounded-lg p-6`}>
          <div className="space-y-4">
            <p className="text-foreground/80 dark:text-gray-300 leading-relaxed">
              {description}
            </p>

            {details && (
              <div className="bg-muted/50 dark:bg-gray-800/50 rounded-md p-3">
                <p className="text-sm text-foreground/70 dark:text-gray-400 font-mono">
                  {details}
                </p>
              </div>
            )}
          </div>

          {(primaryAction || secondaryAction || showCloseButton) && type !== "loading" && (
            <DialogFooter className="pt-6 gap-3">
              {secondaryAction && (
                <Button
                  variant="outline"
                  onClick={secondaryAction.onClick}
                  className="bg-background dark:bg-gray-800 border-input dark:border-gray-600 hover:bg-accent dark:hover:bg-gray-700 text-foreground"
                >
                  {secondaryAction.label}
                </Button>
              )}

              {primaryAction && (
                <Button
                  onClick={primaryAction.onClick}
                  variant={primaryAction.variant || "default"}
                  className="cursor-pointer bg-primary dark:bg-primary hover:bg-primary/90 dark:hover:bg-primary/90 text-primary-foreground"
                >
                  {primaryAction.label}
                </Button>
              )}

              {showCloseButton && !primaryAction && (
                <Button
                  variant="outline"
                  onClick={onClose}
                  className="bg-background dark:bg-gray-800 border-input dark:border-gray-600 hover:bg-accent dark:hover:bg-gray-700 text-foreground"
                >
                  <X className="h-4 w-4 mr-2" />
                  Close
                </Button>
              )}
            </DialogFooter>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};

// Convenience hooks for different feedback types
export const useSuccessFeedback = () => {
  const [isOpen, setIsOpen] = React.useState(false);
  const [config, setConfig] = React.useState<{
    title: string;
    description: string;
    details?: string;
    autoClose?: boolean;
  }>({ title: "", description: "" });

  const showSuccess = React.useCallback((
    title: string, 
    description: string, 
    details?: string,
    autoClose = true
  ) => {
    setConfig({ title, description, details, autoClose });
    setIsOpen(true);
  }, []);

  const hideSuccess = React.useCallback(() => {
    setIsOpen(false);
  }, []);

  const SuccessModal = React.useCallback(() => (
    <FeedbackModal
      isOpen={isOpen}
      onClose={hideSuccess}
      type="success"
      title={config.title}
      description={config.description}
      details={config.details}
      autoClose={config.autoClose}
    />
  ), [isOpen, hideSuccess, config]);

  return { showSuccess, hideSuccess, SuccessModal };
};

export const useErrorFeedback = () => {
  const [isOpen, setIsOpen] = React.useState(false);
  const [config, setConfig] = React.useState<{
    title: string;
    description: string;
    details?: string;
    retry?: () => void;
  }>({ title: "", description: "" });

  const showError = React.useCallback((
    title: string, 
    description: string, 
    details?: string,
    retry?: () => void
  ) => {
    setConfig({ title, description, details, retry });
    setIsOpen(true);
  }, []);

  const hideError = React.useCallback(() => {
    setIsOpen(false);
  }, []);

  const ErrorModal = React.useCallback(() => (
    <FeedbackModal
      isOpen={isOpen}
      onClose={hideError}
      type="error"
      title={config.title}
      description={config.description}
      details={config.details}
      primaryAction={config.retry ? {
        label: "Try Again",
        onClick: () => {
          hideError();
          config.retry?.();
        }
      } : undefined}
      secondaryAction={config.retry ? {
        label: "Cancel",
        onClick: hideError
      } : undefined}
    />
  ), [isOpen, hideError, config]);

  return { showError, hideError, ErrorModal };
};

export const useLoadingFeedback = () => {
  const [isOpen, setIsOpen] = React.useState(false);
  const [config, setConfig] = React.useState<{
    title: string;
    description: string;
  }>({ title: "", description: "" });

  const showLoading = React.useCallback((title: string, description: string) => {
    setConfig({ title, description });
    setIsOpen(true);
  }, []);

  const hideLoading = React.useCallback(() => {
    setIsOpen(false);
  }, []);

  const LoadingModal = React.useCallback(() => (
    <FeedbackModal
      isOpen={isOpen}
      onClose={() => {}} // Prevent closing during loading
      type="loading"
      title={config.title}
      description={config.description}
      showCloseButton={false}
    />
  ), [isOpen, config]);

  return { showLoading, hideLoading, LoadingModal };
};
