import React, { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { UserRole, UserStatus } from "@/types";
import { useCreateUser } from "@/hooks/useUsers";
import { useUserActionFeedback } from "@/hooks/useActionFeedback";
import {
  UserPlus,
  Mail,
  Phone,
  Shield,
  Save,
  X,
  User as UserIcon,
} from "lucide-react";

interface UserCreateModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const UserCreateModal: React.FC<UserCreateModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    role: UserRole.CITIZEN as UserRole,
    status: UserStatus.ACTIVE as UserStatus,
    department: "",
    specializations: [] as string[],
    password: "",
    confirmPassword: "",
    sendPasswordReset: true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const createUserMutation = useCreateUser();
  const { createUser, isExecuting, SuccessModal, ErrorModal, LoadingModal } =
    useUserActionFeedback();

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = "Name is required";
    }

    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Email is invalid";
    }

    if (!formData.phone.trim()) {
      newErrors.phone = "Phone number is required";
    }

    if (formData.role === UserRole.RESPONDER && !formData.department.trim()) {
      newErrors.department = "Department is required for responders";
    }

    // Password validation (only if not sending password reset)
    if (!formData.sendPasswordReset) {
      if (!formData.password.trim()) {
        newErrors.password = "Password is required";
      } else if (formData.password.length < 6) {
        newErrors.password = "Password must be at least 6 characters long";
      }

      if (formData.password !== formData.confirmPassword) {
        newErrors.confirmPassword = "Passwords do not match";
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    const result = await createUser(async () => {
      return await createUserMutation.mutateAsync({
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        role: formData.role,
        status: formData.status,
        department: formData.department,
        specializations: formData.specializations,
        avatar: "",
        location: undefined,
        isOnline: false,
        lastSeen: new Date(),
        lastActive: new Date(),
        metadata: {},
        password: formData.sendPasswordReset ? undefined : formData.password,
        sendPasswordReset: formData.sendPasswordReset,
      });
    });

    if (result) {
      // Reset form and close modal on success
      setFormData({
        name: "",
        email: "",
        phone: "",
        role: UserRole.CITIZEN as UserRole,
        status: UserStatus.ACTIVE as UserStatus,
        department: "",
        specializations: [],
        password: "",
        confirmPassword: "",
        sendPasswordReset: true,
      });
      setErrors({});
      onClose();
    }
  };

  const handleClose = () => {
    setFormData({
      name: "",
      email: "",
      phone: "",
      role: UserRole.CITIZEN as UserRole,
      status: UserStatus.ACTIVE as UserStatus,
      department: "",
      specializations: [],
      password: "",
      confirmPassword: "",
      sendPasswordReset: true,
    });
    setErrors({});
    onClose();
  };

  return (
    <>
      <Dialog open={isOpen} onOpenChange={handleClose}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto bg-white border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3 text-card-foreground">
              <div className="p-2 bg-green-100 dark:bg-green-900/30 rounded-lg">
                <UserPlus className="h-5 w-5 text-green-600 dark:text-green-400" />
              </div>
              Create New User
            </DialogTitle>
          </DialogHeader>

          <div className="bg-card border border-border rounded-lg p-6">
            <form onSubmit={handleSubmit} className="space-y-6">
              {errors.submit && (
                <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                  <p className="text-sm text-red-600 dark:text-red-400">
                    {errors.submit}
                  </p>
                </div>
              )}

              {/* Basic Information */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-card-foreground">
                  Basic Information
                </h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="name" className="text-card-foreground">
                      Full Name *
                    </Label>
                    <div className="relative">
                      <UserIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="name"
                        value={formData.name}
                        onChange={(e) =>
                          setFormData({ ...formData, name: e.target.value })
                        }
                        className={`pl-10 bg-background border-input text-foreground ${
                          errors.name
                            ? "border-red-500 dark:border-red-400"
                            : ""
                        }`}
                        placeholder="Enter full name"
                      />
                    </div>
                    {errors.name && (
                      <p className="text-sm text-red-600 dark:text-red-400">
                        {errors.name}
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="email" className="text-card-foreground">
                      Email Address *
                    </Label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="email"
                        type="email"
                        value={formData.email}
                        onChange={(e) =>
                          setFormData({ ...formData, email: e.target.value })
                        }
                        className={`pl-10 bg-background border-input text-foreground ${
                          errors.email
                            ? "border-red-500 dark:border-red-400"
                            : ""
                        }`}
                        placeholder="Enter email address"
                      />
                    </div>
                    {errors.email && (
                      <p className="text-sm text-red-600 dark:text-red-400">
                        {errors.email}
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="phone" className="text-card-foreground">
                      Phone Number *
                    </Label>
                    <div className="relative">
                      <Phone className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="phone"
                        value={formData.phone}
                        onChange={(e) =>
                          setFormData({ ...formData, phone: e.target.value })
                        }
                        className={`pl-10 bg-background border-input text-foreground ${
                          errors.phone
                            ? "border-red-500 dark:border-red-400"
                            : ""
                        }`}
                        placeholder="Enter phone number"
                      />
                    </div>
                    {errors.phone && (
                      <p className="text-sm text-red-600 dark:text-red-400">
                        {errors.phone}
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label
                      htmlFor="department"
                      className="text-card-foreground"
                    >
                      Department
                    </Label>
                    <div className="relative">
                      <Shield className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="department"
                        value={formData.department}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            department: e.target.value,
                          })
                        }
                        className={`pl-10 bg-background border-input text-foreground ${
                          errors.department
                            ? "border-red-500 dark:border-red-400"
                            : ""
                        }`}
                        placeholder="Enter department (required for responders)"
                      />
                    </div>
                    {errors.department && (
                      <p className="text-sm text-red-600 dark:text-red-400">
                        {errors.department}
                      </p>
                    )}
                  </div>
                </div>
              </div>

              {/* Role and Status */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-card-foreground">
                  Role & Status
                </h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="role" className="text-card-foreground">
                      User Role *
                    </Label>
                    <Select
                      value={formData.role}
                      onValueChange={(value: UserRole) =>
                        setFormData({ ...formData, role: value })
                      }
                    >
                      <SelectTrigger className="bg-background border-input">
                        <SelectValue placeholder="Select role" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value={UserRole.CITIZEN}>
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                            Citizen
                          </div>
                        </SelectItem>
                        <SelectItem value={UserRole.RESPONDER}>
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                            Responder
                          </div>
                        </SelectItem>
                        <SelectItem value={UserRole.ADMIN}>
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                            Admin
                          </div>
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="status" className="text-card-foreground">
                      Initial Status
                    </Label>
                    <Select
                      value={formData.status}
                      onValueChange={(value: UserStatus) =>
                        setFormData({ ...formData, status: value })
                      }
                    >
                      <SelectTrigger className="bg-background border-input">
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value={UserStatus.ACTIVE}>
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                            Active
                          </div>
                        </SelectItem>
                        <SelectItem value={UserStatus.PENDING}>
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 bg-yellow-500 rounded-full"></div>
                            Pending
                          </div>
                        </SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              {/* Role-specific Information */}
              {formData.role === UserRole.RESPONDER && (
                <div className="p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
                  <h4 className="font-medium text-blue-900 dark:text-blue-200 mb-2">
                    Responder Information
                  </h4>
                  <p className="text-sm text-blue-700 dark:text-blue-300">
                    This user will have access to emergency response features
                    and will be able to receive emergency assignments. Make sure
                    to specify their department for proper emergency routing.
                  </p>
                </div>
              )}

              {formData.role === UserRole.ADMIN && (
                <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                  <h4 className="font-medium text-red-900 dark:text-red-200 mb-2">
                    Admin Privileges
                  </h4>
                  <p className="text-sm text-red-700 dark:text-red-300">
                    This user will have full administrative access to the
                    system, including user management, emergency oversight, and
                    system configuration.
                  </p>
                </div>
              )}

              {/* Password Configuration */}
              <div className="p-4 bg-gray-50 dark:bg-gray-900/20 border border-gray-200 dark:border-gray-800 rounded-lg">
                <h4 className="font-medium text-gray-900 dark:text-gray-200 mb-3">
                  Password Configuration
                </h4>

                <div className="space-y-4">
                  <div className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      id="sendPasswordReset"
                      checked={formData.sendPasswordReset}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          sendPasswordReset: e.target.checked,
                        })
                      }
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                    <Label
                      htmlFor="sendPasswordReset"
                      className="text-sm text-gray-700 dark:text-gray-300"
                    >
                      Send password reset email (recommended)
                    </Label>
                  </div>

                  <p className="text-xs text-gray-600 dark:text-gray-400">
                    {formData.sendPasswordReset
                      ? "A temporary password will be generated and a password reset email will be sent to the user."
                      : "You can set a custom password below. The user should change it on first login."}
                  </p>

                  {!formData.sendPasswordReset && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label
                          htmlFor="password"
                          className="text-card-foreground"
                        >
                          Password *
                        </Label>
                        <Input
                          id="password"
                          type="password"
                          value={formData.password}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              password: e.target.value,
                            })
                          }
                          className={`bg-background border-input text-foreground ${
                            errors.password
                              ? "border-red-500 dark:border-red-400"
                              : ""
                          }`}
                          placeholder="Enter password"
                        />
                        {errors.password && (
                          <p className="text-sm text-red-600 dark:text-red-400">
                            {errors.password}
                          </p>
                        )}
                      </div>

                      <div className="space-y-2">
                        <Label
                          htmlFor="confirmPassword"
                          className="text-card-foreground"
                        >
                          Confirm Password *
                        </Label>
                        <Input
                          id="confirmPassword"
                          type="password"
                          value={formData.confirmPassword}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              confirmPassword: e.target.value,
                            })
                          }
                          className={`bg-background border-input text-foreground ${
                            errors.confirmPassword
                              ? "border-red-500 dark:border-red-400"
                              : ""
                          }`}
                          placeholder="Confirm password"
                        />
                        {errors.confirmPassword && (
                          <p className="text-sm text-red-600 dark:text-red-400">
                            {errors.confirmPassword}
                          </p>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>

              <DialogFooter className="pt-6">
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleClose}
                  disabled={isExecuting}
                  className="bg-background border-input hover:bg-accent"
                >
                  <X className="h-4 w-4 mr-2" />
                  Cancel
                </Button>
                <Button
                  type="submit"
                  disabled={isExecuting}
                  className="bg-primary text-primary-foreground hover:bg-primary/90"
                >
                  <Save className="h-4 w-4 mr-2" />
                  {isExecuting ? "Creating..." : "Create User"}
                </Button>
              </DialogFooter>
            </form>
          </div>
        </DialogContent>
      </Dialog>

      {/* Feedback Modals */}
      <SuccessModal />
      <ErrorModal />
      <LoadingModal />
    </>
  );
};
