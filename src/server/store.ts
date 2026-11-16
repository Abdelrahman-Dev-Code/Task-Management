import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';
import type {
  AuthProvider,
  NotificationItem,
  OtpPurpose,
  Task,
  TaskPriority,
  TaskStatus,
  User,
} from '../types.js';

export interface StoredUser extends User {
  passwordHash: string | null;
}

export interface StoredTask extends Task {
  user_id: number;
}

export interface TokenRecord {
  token: string;
  userId: number;
  deviceName: string;
  createdAt: string;
}

export interface OtpRecord {
  email: string;
  purpose: OtpPurpose;
  codeHash: string;
  expiresAt: number;
  attempts: number;
  lastSentAt: number;
}

export interface ResetTokenRecord {
  email: string;
  expiresAt: number;
}

export function formatTimestamp(date: Date = new Date()): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
}

export function toPublicUser(user: StoredUser): User {
  const { passwordHash: _passwordHash, ...publicUser } = user;
  return publicUser;
}

export function toTaskResource(task: StoredTask): Task {
  const { user_id: _userId, ...resource } = task;
  return resource;
}

const users = new Map<number, StoredUser>();
const usersByEmail = new Map<string, number>();
const usersByGoogleId = new Map<string, number>();
const tasks = new Map<number, StoredTask>();
const tokens = new Map<string, TokenRecord>();
const otpRecords = new Map<string, OtpRecord>();
const resetTokens = new Map<string, ResetTokenRecord>();
const notifications = new Map<number, NotificationItem[]>();

let nextUserId = 1;
let nextTaskId = 1;
let nextNotificationId = 1;

function otpKey(email: string, purpose: OtpPurpose): string {
  return `${purpose}:${email.trim().toLowerCase()}`;
}

function seedInitialData(): void {
  const now = formatTimestamp();
  const demoUser: StoredUser = {
    id: nextUserId++,
    name: 'أحمد محمد',
    email: 'ahmed@example.com',
    avatar: null,
    provider: 'local',
    google_id: null,
    passwordHash: bcrypt.hashSync('12345678', 10),
    email_verified_at: now,
    created_at: now,
    updated_at: now,
  };
  users.set(demoUser.id, demoUser);
  usersByEmail.set(demoUser.email.toLowerCase(), demoUser.id);

  const initialTasks: Array<{
    title: string;
    description: string;
    status: TaskStatus;
    priority: TaskPriority;
    due_date: string | null;
  }> = [
    {
      title: 'إعداد واجهات برمجة التطبيقات للمصادقة',
      description: 'تجهيز نقاط النهاية الخاصة بتسجيل الدخول و OTP والمتابعة باستخدام جوجل.',
      status: 'Completed',
      priority: 'High',
      due_date: null,
    },
    {
      title: 'ربط تطبيق Flutter مع لوحة المهام',
      description: 'تنفيذ شاشات المصادقة وعرض المهام وإدارتها عبر REST API.',
      status: 'In Progress',
      priority: 'High',
      due_date: null,
    },
    {
      title: 'اختبار مسارات التحقق من رمز OTP',
      description: 'التأكد من عمل إرسال والتحقق من رمز OTP لتأكيد البريد وتسجيل الدخول.',
      status: 'Pending',
      priority: 'Medium',
      due_date: null,
    },
    {
      title: 'تحديث وثائق API لفريق الموبايل',
      description: 'توضيح صيغ الطلبات والاستجابات لجميع نقاط النهاية في README.',
      status: 'Pending',
      priority: 'Low',
      due_date: null,
    },
  ];

  for (const item of initialTasks) {
    const id = nextTaskId++;
    tasks.set(id, {
      id,
      user_id: demoUser.id,
      title: item.title,
      description: item.description,
      status: item.status,
      priority: item.priority,
      due_date: item.due_date,
      created_at: now,
      updated_at: now,
    });
  }

  notifications.set(demoUser.id, [
    {
      id: nextNotificationId++,
      type: 'welcome',
      title: 'مرحباً بك في واجهة برمجة تطبيقات إدارة المهام',
      body: 'حسابك التجريبي جاهز للاستخدام مع تطبيق Flutter.',
      read_at: null,
      data: null,
      created_at: now,
    },
  ]);
}

seedInitialData();

export const store = {
  findUserByEmail(email: string): StoredUser | undefined {
    const id = usersByEmail.get(email.trim().toLowerCase());
    return id !== undefined ? users.get(id) : undefined;
  },

  findUserByGoogleId(googleId: string): StoredUser | undefined {
    const id = usersByGoogleId.get(googleId);
    return id !== undefined ? users.get(id) : undefined;
  },

  findUserById(id: number): StoredUser | undefined {
    return users.get(id);
  },

  createUser(input: {
    name: string;
    email: string;
    password?: string | null;
    provider?: AuthProvider;
    google_id?: string | null;
    avatar?: string | null;
    email_verified_at?: string | null;
  }): StoredUser {
    const now = formatTimestamp();
    const id = nextUserId++;
    const normalizedEmail = input.email.trim().toLowerCase();
    const user: StoredUser = {
      id,
      name: input.name.trim(),
      email: normalizedEmail,
      avatar: input.avatar ?? null,
      provider: input.provider ?? 'local',
      google_id: input.google_id ?? null,
      passwordHash: input.password ? bcrypt.hashSync(input.password, 10) : null,
      email_verified_at: input.email_verified_at ?? null,
      created_at: now,
      updated_at: now,
    };
    users.set(id, user);
    usersByEmail.set(normalizedEmail, id);
    if (user.google_id) {
      usersByGoogleId.set(user.google_id, id);
    }
    return user;
  },

  updateUser(
    id: number,
    patch: {
      name?: string;
      avatar?: string | null;
      google_id?: string | null;
      provider?: AuthProvider;
      email_verified_at?: string | null;
      password?: string;
    }
  ): StoredUser | undefined {
    const existing = users.get(id);
    if (!existing) return undefined;

    const updated: StoredUser = {
      ...existing,
      name: patch.name !== undefined ? patch.name.trim() : existing.name,
      avatar: patch.avatar !== undefined ? patch.avatar : existing.avatar,
      google_id: patch.google_id !== undefined ? patch.google_id : existing.google_id,
      provider: patch.provider !== undefined ? patch.provider : existing.provider,
      email_verified_at:
        patch.email_verified_at !== undefined ? patch.email_verified_at : existing.email_verified_at,
      passwordHash: patch.password ? bcrypt.hashSync(patch.password, 10) : existing.passwordHash,
      updated_at: formatTimestamp(),
    };

    users.set(id, updated);
    if (updated.google_id) {
      usersByGoogleId.set(updated.google_id, id);
    }
    return updated;
  },

  verifyPassword(user: StoredUser, password: string): boolean {
    if (!user.passwordHash) return false;
    return bcrypt.compareSync(password, user.passwordHash);
  },

  hasPassword(user: StoredUser): boolean {
    return user.passwordHash !== null;
  },

  issueToken(userId: number, deviceName = 'api-token'): string {
    const token = crypto.randomBytes(32).toString('hex');
    tokens.set(token, {
      token,
      userId,
      deviceName,
      createdAt: formatTimestamp(),
    });
    return token;
  },

  getUserByToken(token: string): StoredUser | undefined {
    const record = tokens.get(token);
    if (!record) return undefined;
    return users.get(record.userId);
  },

  revokeToken(token: string): void {
    tokens.delete(token);
  },

  revokeAllUserTokens(userId: number): number {
    let count = 0;
    for (const [token, record] of tokens.entries()) {
      if (record.userId === userId) {
        tokens.delete(token);
        count++;
      }
    }
    return count;
  },

  getTasksByUserId(userId: number): StoredTask[] {
    return Array.from(tasks.values())
      .filter((task) => task.user_id === userId)
      .sort((a, b) => b.id - a.id);
  },

  findTaskById(id: number): StoredTask | undefined {
    return tasks.get(id);
  },

  createTask(
    userId: number,
    data: {
      title: string;
      description?: string | null;
      status?: TaskStatus;
      priority?: TaskPriority;
      due_date?: string | null;
    }
  ): StoredTask {
    const now = formatTimestamp();
    const id = nextTaskId++;
    const task: StoredTask = {
      id,
      user_id: userId,
      title: data.title.trim(),
      description: data.description?.trim() ? data.description.trim() : null,
      status: data.status ?? 'Pending',
      priority: data.priority ?? 'Medium',
      due_date: data.due_date ?? null,
      created_at: now,
      updated_at: now,
    };
    tasks.set(id, task);
    return task;
  },

  updateTask(
    id: number,
    data: {
      title?: string;
      description?: string | null;
      status?: TaskStatus;
      priority?: TaskPriority;
      due_date?: string | null;
    }
  ): StoredTask | undefined {
    const existing = tasks.get(id);
    if (!existing) return undefined;
    const updated: StoredTask = {
      ...existing,
      title: data.title !== undefined ? data.title.trim() : existing.title,
      description:
        data.description !== undefined
          ? data.description?.trim()
            ? data.description.trim()
            : null
          : existing.description,
      status: data.status ?? existing.status,
      priority: data.priority ?? existing.priority,
      due_date: data.due_date !== undefined ? data.due_date : existing.due_date,
      updated_at: formatTimestamp(),
    };
    tasks.set(id, updated);
    return updated;
  },

  deleteTask(id: number): StoredTask | undefined {
    const existing = tasks.get(id);
    if (!existing) return undefined;
    tasks.delete(id);
    return existing;
  },

  deleteCompletedTasks(userId: number): number {
    let deleted = 0;
    for (const [id, task] of tasks.entries()) {
      if (task.user_id === userId && task.status === 'Completed') {
        tasks.delete(id);
        deleted++;
      }
    }
    return deleted;
  },

  addNotification(
    userId: number,
    input: { type: string; title: string; body: string; data?: Record<string, unknown> | null }
  ): NotificationItem {
    const item: NotificationItem = {
      id: nextNotificationId++,
      type: input.type,
      title: input.title,
      body: input.body,
      read_at: null,
      data: input.data ?? null,
      created_at: formatTimestamp(),
    };
    const list = notifications.get(userId) ?? [];
    list.unshift(item);
    notifications.set(userId, list);
    return item;
  },

  getNotificationsByUser(userId: number): NotificationItem[] {
    return notifications.get(userId) ?? [];
  },

  markNotificationRead(userId: number, notificationId: number): NotificationItem | undefined {
    const list = notifications.get(userId) ?? [];
    const target = list.find((item) => item.id === notificationId);
    if (!target) return undefined;
    if (!target.read_at) {
      target.read_at = formatTimestamp();
    }
    return target;
  },

  markAllNotificationsRead(userId: number): number {
    const list = notifications.get(userId) ?? [];
    const now = formatTimestamp();
    let count = 0;
    for (const item of list) {
      if (!item.read_at) {
        item.read_at = now;
        count++;
      }
    }
    return count;
  },

  saveOtp(record: OtpRecord): void {
    otpRecords.set(otpKey(record.email, record.purpose), record);
  },

  getOtp(email: string, purpose: OtpPurpose): OtpRecord | undefined {
    return otpRecords.get(otpKey(email, purpose));
  },

  incrementOtpAttempts(email: string, purpose: OtpPurpose): number {
    const key = otpKey(email, purpose);
    const existing = otpRecords.get(key);
    if (!existing) return 0;
    existing.attempts += 1;
    otpRecords.set(key, existing);
    return existing.attempts;
  },

  deleteOtp(email: string, purpose: OtpPurpose): void {
    otpRecords.delete(otpKey(email, purpose));
  },

  issueResetToken(email: string): string {
    const token = crypto.randomBytes(24).toString('hex');
    resetTokens.set(token, {
      email: email.trim().toLowerCase(),
      expiresAt: Date.now() + 15 * 60 * 1000,
    });
    return token;
  },

  consumeResetToken(token: string, email: string): boolean {
    const record = resetTokens.get(token);
    if (!record) return false;
    resetTokens.delete(token);
    if (Date.now() > record.expiresAt) return false;
    return record.email === email.trim().toLowerCase();
  },
};
