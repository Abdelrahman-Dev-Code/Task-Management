export type TaskStatus = 'Pending' | 'In Progress' | 'Completed';
export type TaskPriority = 'Low' | 'Medium' | 'High';
export type AuthProvider = 'local' | 'google' | 'otp';
export type OtpPurpose = 'verify_email' | 'login' | 'reset_password';

export interface User {
  id: number;
  name: string;
  email: string;
  avatar: string | null;
  provider: AuthProvider;
  google_id: string | null;
  email_verified_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: number;
  title: string;
  description: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  due_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface NotificationItem {
  id: number;
  type: string;
  title: string;
  body: string;
  read_at: string | null;
  data: Record<string, unknown> | null;
  created_at: string;
}
