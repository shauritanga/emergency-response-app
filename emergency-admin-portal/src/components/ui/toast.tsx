import React, { createContext, useContext, useState, useCallback } from "react";
import { CheckCircle, AlertCircle, AlertTriangle, Info, X } from "lucide-react";

interface Toast {
  id: string;
  type: "success" | "error" | "warning" | "info";
  title: string;
  description?: string;
  duration?: number;
}

interface ToastContextType {
  toasts: Toast[];
  addToast: (toast: Omit<Toast, "id">) => void;
  removeToast: (id: string) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast must be used within a ToastProvider");
  }
  return context;
};

export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback((toast: Omit<Toast, "id">) => {
    const id = Math.random().toString(36).substr(2, 9);
    const newToast = { ...toast, id };
    
    setToasts((prev) => [...prev, newToast]);

    // Auto remove after duration
    setTimeout(() => {
      removeToast(id);
    }, toast.duration || 5000);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
      <ToastContainer />
    </ToastContext.Provider>
  );
};

const ToastContainer: React.FC = () => {
  const { toasts, removeToast } = useToast();

  return (
    <div className="fixed top-4 right-4 z-50 space-y-2">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onRemove={removeToast} />
      ))}
    </div>
  );
};

const ToastItem: React.FC<{
  toast: Toast;
  onRemove: (id: string) => void;
}> = ({ toast, onRemove }) => {
  const getToastStyles = (type: Toast["type"]) => {
    switch (type) {
      case "success":
        return {
          bg: "bg-green-50 border-green-200",
          icon: CheckCircle,
          iconColor: "text-green-600",
          titleColor: "text-green-800",
          descColor: "text-green-700",
        };
      case "error":
        return {
          bg: "bg-red-50 border-red-200",
          icon: AlertCircle,
          iconColor: "text-red-600",
          titleColor: "text-red-800",
          descColor: "text-red-700",
        };
      case "warning":
        return {
          bg: "bg-yellow-50 border-yellow-200",
          icon: AlertTriangle,
          iconColor: "text-yellow-600",
          titleColor: "text-yellow-800",
          descColor: "text-yellow-700",
        };
      case "info":
        return {
          bg: "bg-blue-50 border-blue-200",
          icon: Info,
          iconColor: "text-blue-600",
          titleColor: "text-blue-800",
          descColor: "text-blue-700",
        };
      default:
        return {
          bg: "bg-gray-50 border-gray-200",
          icon: Info,
          iconColor: "text-gray-600",
          titleColor: "text-gray-800",
          descColor: "text-gray-700",
        };
    }
  };

  const styles = getToastStyles(toast.type);
  const Icon = styles.icon;

  return (
    <div
      className={`${styles.bg} border rounded-lg shadow-lg p-4 min-w-80 max-w-md animate-in slide-in-from-right-full duration-300`}
    >
      <div className="flex items-start gap-3">
        <Icon className={`h-5 w-5 ${styles.iconColor} mt-0.5 flex-shrink-0`} />
        <div className="flex-1 min-w-0">
          <h4 className={`text-sm font-semibold ${styles.titleColor}`}>
            {toast.title}
          </h4>
          {toast.description && (
            <p className={`text-sm ${styles.descColor} mt-1`}>
              {toast.description}
            </p>
          )}
        </div>
        <button
          onClick={() => onRemove(toast.id)}
          className="text-gray-400 hover:text-gray-600 transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};

// Convenience hooks
export const useSuccessToast = () => {
  const { addToast } = useToast();
  return useCallback(
    (title: string, description?: string) => {
      addToast({ type: "success", title, description });
    },
    [addToast]
  );
};

export const useErrorToast = () => {
  const { addToast } = useToast();
  return useCallback(
    (title: string, description?: string) => {
      addToast({ type: "error", title, description });
    },
    [addToast]
  );
};

export const useWarningToast = () => {
  const { addToast } = useToast();
  return useCallback(
    (title: string, description?: string) => {
      addToast({ type: "warning", title, description });
    },
    [addToast]
  );
};

export const useInfoToast = () => {
  const { addToast } = useToast();
  return useCallback(
    (title: string, description?: string) => {
      addToast({ type: "info", title, description });
    },
    [addToast]
  );
};
