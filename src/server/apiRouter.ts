import { Router, type NextFunction, type Request, type Response } from 'express';
import { formatTimestamp, store, toPublicUser, toTaskResource, type StoredUser } from './store.js';
import { sendOtpForEmail, verifyOtpCode } from './services/otpService.js';
import {
  buildGoogleAuthorizationUrl,
  exchangeGoogleAuthorizationCode,
  upsertUserFromGoogleProfile,
  verifyGoogleAccessToken,
  verifyGoogleIdToken,
} from './services/googleAuthService.js';
import type { OtpPurpose, TaskPriority, TaskStatus } from '../types.js';

interface AuthenticatedRequest extends Request {
  authUser?: StoredUser;
  authToken?: string;
}

const VALID_STATUSES: TaskStatus[] = ['Pending', 'In Progress', 'Completed'];
const VALID_PRIORITIES: TaskPriority[] = ['Low', 'Medium', 'High'];
const VALID_OTP_PURPOSES: OtpPurpose[] = ['verify_email', 'login', 'reset_password'];
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const PRIORITY_WEIGHT: Record<TaskPriority, number> = {
  High: 3,
  Medium: 2,
  Low: 1,
};

function authenticate(req: AuthenticatedRequest, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401).json({ message: 'Unauthenticated.' });
    return;
  }

  const token = header.slice('Bearer '.length).trim();
  const user = store.getUserByToken(token);
  if (!user) {
    res.status(401).json({ message: 'Unauthenticated.' });
    return;
  }

  req.authUser = user;
  req.authToken = token;
  next();
}

function validateDueDate(value: unknown): { valid: boolean; normalized: string | null } {
  if (value === undefined || value === null || value === '') {
    return { valid: true, normalized: null };
  }
  if (typeof value !== 'string') {
    return { valid: false, normalized: null };
  }
  const parsed = Date.parse(value);
  if (Number.isNaN(parsed)) {
    return { valid: false, normalized: null };
  }
  return { valid: true, normalized: value.trim() };
}

function validateTaskPayload(body: Record<string, unknown>, partial = false) {
  const errors: Record<string, string[]> = {};
  const hasTitle = Object.prototype.hasOwnProperty.call(body, 'title');
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const hasDescription = Object.prototype.hasOwnProperty.call(body, 'description');
  const description =
    body.description === null || body.description === undefined
      ? null
      : typeof body.description === 'string'
        ? body.description
        : null;
  const hasStatus = Object.prototype.hasOwnProperty.call(body, 'status') && body.status !== undefined && body.status !== null;
  const status = body.status as TaskStatus | undefined;
  const hasPriority = Object.prototype.hasOwnProperty.call(body, 'priority') && body.priority !== undefined && body.priority !== null;
  const priority = body.priority as TaskPriority | undefined;
  const hasDueDate = Object.prototype.hasOwnProperty.call(body, 'due_date');
  const dueDateCheck = validateDueDate(body.due_date);

  if (!partial || hasTitle) {
    if (!body.title || typeof body.title !== 'string' || title.length === 0) {
      errors.title = ['حقل العنوان مطلوب.'];
    } else if (title.length > 255) {
      errors.title = ['لا يجوز أن يتجاوز العنوان 255 حرفًا.'];
    }
  }

  if (hasDescription && body.description !== null && body.description !== undefined && typeof body.description !== 'string') {
    errors.description = ['يجب أن يكون الوصف نصًا.'];
  }

  if (hasStatus && !VALID_STATUSES.includes(status!)) {
    errors.status = ['الحالة المختارة غير موجودة في النطاق المسموح.'];
  }

  if (hasPriority && !VALID_PRIORITIES.includes(priority!)) {
    errors.priority = ['الأولوية المختارة غير موجودة في النطاق المسموح.'];
  }

  if (hasDueDate && !dueDateCheck.valid) {
    errors.due_date = ['صيغة تاريخ الاستحقاق غير صحيحة.'];
  }

  return {
    errors,
    data: {
      ...(hasTitle || !partial ? { title } : {}),
      ...(hasDescription ? { description } : {}),
      ...(hasStatus ? { status } : !partial ? { status: 'Pending' as TaskStatus } : {}),
      ...(hasPriority ? { priority } : !partial ? { priority: 'Medium' as TaskPriority } : {}),
      ...(hasDueDate ? { due_date: dueDateCheck.normalized } : {}),
    },
  };
}

export function createApiRouter(): Router {
  const router = Router();

  /** نقطة فحص سريع لاتصال التطبيق بالخادم */
  router.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'ok',
      service: 'task-management-api',
      timestamp: new Date().toISOString(),
    });
  });

  // ============================
  // Authentication (Standard)
  // ============================

  const handleRegister = async (req: Request, res: Response) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const errors: Record<string, string[]> = {};

    const name = typeof body.name === 'string' ? body.name.trim() : '';
    const email = typeof body.email === 'string' ? body.email.trim() : '';
    const password = typeof body.password === 'string' ? body.password.trim() : '';
    const deviceName = typeof body.device_name === 'string' && body.device_name.trim() ? body.device_name.trim() : 'flutter-app';

    if (!name) {
      errors.name = ['الاسم مطلوب.'];
    } else if (name.length > 255) {
      errors.name = ['الاسم لا يجب أن يتجاوز 255 حرفًا.'];
    }

    if (!email) {
      errors.email = ['البريد الإلكتروني مطلوب.'];
    } else if (!EMAIL_REGEX.test(email)) {
      errors.email = ['صيغة البريد الإلكتروني غير صحيحة.'];
    } else if (email.length > 255) {
      errors.email = ['البريد الإلكتروني لا يجب أن يتجاوز 255 حرفًا.'];
    } else if (store.findUserByEmail(email)) {
      errors.email = ['هذا البريد الإلكتروني مسجل بالفعل.'];
    }

    if (!password) {
      errors.password = ['كلمة المرور مطلوبة.'];
    } else if (password.length < 6) {
      errors.password = ['كلمة المرور يجب أن تكون 6 أحرف على الأقل.'];
    } else if (password.length > 255) {
      errors.password = ['كلمة المرور لا يجب أن تتجاوز 255 حرفًا.'];
    }

    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const user = store.createUser({ name, email, password, provider: 'local' });
    const token = store.issueToken(user.id, deviceName);

    let otpMeta: Awaited<ReturnType<typeof sendOtpForEmail>> | null = null;
    try {
      otpMeta = await sendOtpForEmail(user.email, 'verify_email', { bypassCooldown: true });
    } catch {
      otpMeta = null;
    }

    store.addNotification(user.id, {
      type: 'account_registered',
      title: 'تم إنشاء حسابك بنجاح',
      body: 'يرجى تأكيد بريدك الإلكتروني باستخدام رمز التحقق المرسل إليك.',
      data: { email: user.email },
    });

    res.status(201).json({
      user: toPublicUser(user),
      token,
      otp_required: true,
      otp_expires_in_seconds: otpMeta?.expiresInSeconds ?? 600,
      ...(otpMeta?.devOtp ? { dev_otp: otpMeta.devOtp } : {}),
      message: 'تم تسجيل الحساب بنجاح. تم إرسال رمز التحقق إلى بريدك الإلكتروني.',
    });
  };

  const handleLogin = (req: Request, res: Response) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const errors: Record<string, string[]> = {};

    const email = typeof body.email === 'string' ? body.email.trim() : '';
    const password = typeof body.password === 'string' ? body.password : '';
    const deviceName = typeof body.device_name === 'string' && body.device_name.trim() ? body.device_name.trim() : 'flutter-app';

    if (!email) {
      errors.email = ['البريد الإلكتروني مطلوب.'];
    } else if (!EMAIL_REGEX.test(email)) {
      errors.email = ['صيغة البريد الإلكتروني غير صحيحة.'];
    }

    if (!password) {
      errors.password = ['كلمة المرور مطلوبة.'];
    } else if (password.length < 6) {
      errors.password = ['كلمة المرور يجب أن تكون 6 أحرف على الأقل.'];
    }

    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const user = store.findUserByEmail(email);
    if (!user) {
      res.status(401).json({ message: 'بيانات الدخول غير صحيحة.' });
      return;
    }

    if (!store.hasPassword(user)) {
      res.status(401).json({
        message: 'هذا الحساب مسجل عبر جوجل. يرجى المتابعة باستخدام جوجل أو تسجيل الدخول عبر رمز التحقق (OTP).',
      });
      return;
    }

    if (!store.verifyPassword(user, password)) {
      res.status(401).json({ message: 'بيانات الدخول غير صحيحة.' });
      return;
    }

    const token = store.issueToken(user.id, deviceName);
    res.status(200).json({
      user: toPublicUser(user),
      token,
      message: 'تم تسجيل الدخول بنجاح.',
    });
  };

  const handleLogout = (req: AuthenticatedRequest, res: Response) => {
    if (req.authToken) {
      store.revokeToken(req.authToken);
    }
    res.status(200).json({ message: 'تم تسجيل الخروج بنجاح.' });
  };

  router.post('/register', handleRegister);
  router.post('/auth/register', handleRegister);

  router.post('/login', handleLogin);
  router.post('/auth/login', handleLogin);

  router.post('/logout', authenticate, handleLogout);
  router.post('/auth/logout', authenticate, handleLogout);

  router.post('/logout-all', authenticate, (req: AuthenticatedRequest, res: Response) => {
    const revoked = store.revokeAllUserTokens(req.authUser!.id);
    res.status(200).json({
      revoked_tokens: revoked,
      message: 'تم تسجيل الخروج من جميع الأجهزة بنجاح.',
    });
  });

  // Current User & Profile
  const handleGetUser = (req: AuthenticatedRequest, res: Response) => {
    res.status(200).json(toPublicUser(req.authUser!));
  };

  const handleUpdateUser = (req: AuthenticatedRequest, res: Response) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const errors: Record<string, string[]> = {};
    const user = req.authUser!;

    const patch: { name?: string; avatar?: string | null; password?: string } = {};

    if (Object.prototype.hasOwnProperty.call(body, 'name')) {
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      if (!name) {
        errors.name = ['الاسم مطلوب.'];
      } else if (name.length > 255) {
        errors.name = ['الاسم لا يجب أن يتجاوز 255 حرفًا.'];
      } else {
        patch.name = name;
      }
    }

    if (Object.prototype.hasOwnProperty.call(body, 'avatar')) {
      if (body.avatar !== null && typeof body.avatar !== 'string') {
        errors.avatar = ['رابط الصورة الشخصية غير صالح.'];
      } else {
        patch.avatar = body.avatar;
      }
    }

    if (Object.prototype.hasOwnProperty.call(body, 'password') && body.password !== undefined) {
      const newPassword = typeof body.password === 'string' ? body.password.trim() : '';
      const currentPassword = typeof body.current_password === 'string' ? body.current_password : '';

      if (newPassword.length < 6) {
        errors.password = ['كلمة المرور يجب أن تكون 6 أحرف على الأقل.'];
      } else if (store.hasPassword(user) && !store.verifyPassword(user, currentPassword)) {
        errors.current_password = ['كلمة المرور الحالية غير صحيحة.'];
      } else {
        patch.password = newPassword;
      }
    }

    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const updated = store.updateUser(user.id, patch);
    res.status(200).json({
      user: toPublicUser(updated!),
      message: 'تم تحديث بيانات الحساب بنجاح.',
    });
  };

  router.get('/user', authenticate, handleGetUser);
  router.get('/auth/me', authenticate, handleGetUser);
  router.put('/user', authenticate, handleUpdateUser);
  router.patch('/user', authenticate, handleUpdateUser);

  // ============================
  // OTP System
  // ============================

  const handleSendOtp = async (req: Request, res: Response, forcedPurpose?: OtpPurpose) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const errors: Record<string, string[]> = {};

    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    const purpose = (forcedPurpose ?? (typeof body.purpose === 'string' ? body.purpose.trim() : 'verify_email')) as OtpPurpose;

    if (!email) {
      errors.email = ['البريد الإلكتروني مطلوب.'];
    } else if (!EMAIL_REGEX.test(email)) {
      errors.email = ['صيغة البريد الإلكتروني غير صحيحة.'];
    }

    if (!VALID_OTP_PURPOSES.includes(purpose)) {
      errors.purpose = ['غرض رمز التحقق غير صالح. القيم المسموحة: verify_email, login, reset_password.'];
    }

    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const user = store.findUserByEmail(email);
    if (!user) {
      res.status(404).json({ message: 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.' });
      return;
    }

    try {
      const result = await sendOtpForEmail(email, purpose);
      res.status(200).json({
        purpose,
        expires_in_seconds: result.expiresInSeconds,
        delivered_via: result.deliveredVia,
        ...(result.devOtp ? { dev_otp: result.devOtp } : {}),
        message: 'تم إرسال رمز التحقق (OTP) إلى بريدك الإلكتروني بنجاح.',
      });
    } catch (err) {
      const typed = err as Error & { statusCode?: number; retryAfter?: number };
      res.status(typed.statusCode ?? 500).json({
        message: typed.message || 'تعذر إرسال رمز التحقق.',
        ...(typed.retryAfter ? { retry_after_seconds: typed.retryAfter } : {}),
      });
    }
  };

  const handleVerifyOtp = (req: Request, res: Response, forcedPurpose?: OtpPurpose) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const errors: Record<string, string[]> = {};

    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    const otp = typeof body.otp === 'string' ? body.otp.trim() : typeof body.code === 'string' ? body.code.trim() : '';
    const purpose = (forcedPurpose ?? (typeof body.purpose === 'string' ? body.purpose.trim() : 'verify_email')) as OtpPurpose;
    const deviceName = typeof body.device_name === 'string' && body.device_name.trim() ? body.device_name.trim() : 'flutter-otp';

    if (!email) {
      errors.email = ['البريد الإلكتروني مطلوب.'];
    } else if (!EMAIL_REGEX.test(email)) {
      errors.email = ['صيغة البريد الإلكتروني غير صحيحة.'];
    }

    if (!otp || !/^\d{6}$/.test(otp)) {
      errors.otp = ['رمز التحقق يجب أن يتكون من 6 أرقام.'];
    }

    if (!VALID_OTP_PURPOSES.includes(purpose)) {
      errors.purpose = ['غرض رمز التحقق غير صالح.'];
    }

    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const user = store.findUserByEmail(email);
    if (!user) {
      res.status(404).json({ message: 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.' });
      return;
    }

    const verification = verifyOtpCode(email, purpose, otp);
    if (!verification.ok) {
      res.status(verification.statusCode).json({ message: verification.message });
      return;
    }

    if (purpose === 'verify_email') {
      const updated = store.updateUser(user.id, {
        email_verified_at: user.email_verified_at ?? formatTimestamp(),
      })!;
      res.status(200).json({
        verified: true,
        user: toPublicUser(updated),
        message: 'تم التحقق من البريد الإلكتروني بنجاح.',
      });
      return;
    }

    if (purpose === 'login') {
      const updated = store.updateUser(user.id, {
        email_verified_at: user.email_verified_at ?? formatTimestamp(),
      })!;
      const token = store.issueToken(updated.id, deviceName);
      res.status(200).json({
        verified: true,
        user: toPublicUser(updated),
        token,
        message: 'تم تسجيل الدخول بنجاح باستخدام رمز التحقق.',
      });
      return;
    }

    const resetToken = store.issueResetToken(email);
    res.status(200).json({
      verified: true,
      reset_token: resetToken,
      message: 'تم التحقق من الرمز بنجاح. يمكنك الآن تعيين كلمة مرور جديدة.',
    });
  };

  router.post('/otp/send', (req, res) => handleSendOtp(req, res));
  router.post('/otp/verify', (req, res) => handleVerifyOtp(req, res));
  router.post('/auth/otp/request', (req, res) => handleSendOtp(req, res, 'login'));
  router.post('/auth/otp/verify', (req, res) => handleVerifyOtp(req, res, 'login'));

  router.post('/password/forgot', (req, res) => handleSendOtp(req, res, 'reset_password'));
  router.post('/password/reset', (req: Request, res: Response) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const errors: Record<string, string[]> = {};

    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    const otp = typeof body.otp === 'string' ? body.otp.trim() : typeof body.code === 'string' ? body.code.trim() : '';
    const resetToken = typeof body.reset_token === 'string' ? body.reset_token.trim() : '';
    const password = typeof body.password === 'string' ? body.password.trim() : '';

    if (!email || !EMAIL_REGEX.test(email)) {
      errors.email = ['يرجى إدخال بريد إلكتروني صحيح.'];
    }

    if (!otp && !resetToken) {
      errors.otp = ['يرجى إدخال رمز التحقق (OTP) أو رمز إعادة التعيين.'];
    }

    if (!password || password.length < 6) {
      errors.password = ['كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.'];
    }

    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const user = store.findUserByEmail(email);
    if (!user) {
      res.status(404).json({ message: 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.' });
      return;
    }

    if (resetToken) {
      if (!store.consumeResetToken(resetToken, email)) {
        res.status(422).json({ message: 'رمز إعادة تعيين كلمة المرور غير صالح أو منتهي الصلاحية.' });
        return;
      }
    } else {
      const verification = verifyOtpCode(email, 'reset_password', otp);
      if (!verification.ok) {
        res.status(verification.statusCode).json({ message: verification.message });
        return;
      }
    }

    store.updateUser(user.id, {
      password,
      email_verified_at: user.email_verified_at ?? formatTimestamp(),
    });
    store.revokeAllUserTokens(user.id);

    res.status(200).json({
      message: 'تم إعادة تعيين كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
    });
  });

  // ============================
  // Continue with Google
  // ============================

  router.post('/auth/google', async (req: Request, res: Response) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const idToken =
      typeof body.id_token === 'string'
        ? body.id_token.trim()
        : typeof body.idToken === 'string'
          ? body.idToken.trim()
          : '';
    const accessToken =
      typeof body.access_token === 'string'
        ? body.access_token.trim()
        : typeof body.accessToken === 'string'
          ? body.accessToken.trim()
          : '';
    const deviceName =
      typeof body.device_name === 'string' && body.device_name.trim()
        ? body.device_name.trim()
        : 'flutter-google';

    if (!idToken && !accessToken) {
      res.status(422).json({
        message: 'يرجى إرسال id_token أو access_token للمتابعة باستخدام جوجل.',
        errors: {
          id_token: ['حقل id_token أو access_token مطلوب.'],
        },
      });
      return;
    }

    try {
      const profile = idToken
        ? await verifyGoogleIdToken(idToken)
        : await verifyGoogleAccessToken(accessToken);

      const authResult = upsertUserFromGoogleProfile(profile, deviceName);

      res.status(200).json({
        user: authResult.user,
        token: authResult.token,
        is_new_user: authResult.isNewUser,
        message: 'تم تسجيل الدخول باستخدام جوجل بنجاح.',
      });
    } catch (err) {
      res.status(401).json({
        message: err instanceof Error ? err.message : 'فشل التحقق من حساب جوجل.',
      });
    }
  });

  router.get('/auth/google/url', (req: Request, res: Response) => {
    try {
      const redirectUri = typeof req.query.redirect_uri === 'string' ? req.query.redirect_uri : undefined;
      const state = typeof req.query.state === 'string' ? req.query.state : undefined;
      const url = buildGoogleAuthorizationUrl({ redirectUri, state });
      res.status(200).json({
        url,
        message: 'تم إنشاء رابط المصادقة عبر جوجل بنجاح.',
      });
    } catch (err) {
      const typed = err as Error & { statusCode?: number };
      res.status(typed.statusCode ?? 500).json({
        message: typed.message || 'تعذر إنشاء رابط مصادقة جوجل.',
      });
    }
  });

  router.get(['/auth/google/callback', '/auth/google/callback/'], async (req: Request, res: Response) => {
    const code = typeof req.query.code === 'string' ? req.query.code.trim() : '';
    const errorParam = typeof req.query.error === 'string' ? req.query.error : '';
    const redirectUri = typeof req.query.redirect_uri === 'string' ? req.query.redirect_uri : undefined;

    if (errorParam) {
      res.status(400).json({ message: `تم إلغاء أو رفض المصادقة من جوجل: ${errorParam}` });
      return;
    }

    if (!code) {
      res.status(422).json({ message: 'رمز التفويض (code) مفقود.' });
      return;
    }

    try {
      const profile = await exchangeGoogleAuthorizationCode(code, redirectUri);
      const authResult = upsertUserFromGoogleProfile(profile, 'google-oauth-web');

      res.status(200).json({
        user: authResult.user,
        token: authResult.token,
        is_new_user: authResult.isNewUser,
        message: 'تم تسجيل الدخول باستخدام جوجل بنجاح.',
      });
    } catch (err) {
      const typed = err as Error & { statusCode?: number };
      res.status(typed.statusCode ?? 401).json({
        message: typed.message || 'فشل إتمام تسجيل الدخول عبر جوجل.',
      });
    }
  });

  // ============================
  // Tasks CRUD & Analytics
  // ============================

  const handleTaskStats = (req: AuthenticatedRequest, res: Response) => {
    const userTasks = store.getTasksByUserId(req.authUser!.id);
    const nowMs = Date.now();

    const stats = {
      total: userTasks.length,
      pending: userTasks.filter((t) => t.status === 'Pending').length,
      in_progress: userTasks.filter((t) => t.status === 'In Progress').length,
      completed: userTasks.filter((t) => t.status === 'Completed').length,
      by_priority: {
        low: userTasks.filter((t) => t.priority === 'Low').length,
        medium: userTasks.filter((t) => t.priority === 'Medium').length,
        high: userTasks.filter((t) => t.priority === 'High').length,
      },
      overdue: userTasks.filter(
        (t) => t.status !== 'Completed' && t.due_date && Date.parse(t.due_date) < nowMs
      ).length,
    };

    res.status(200).json({
      data: stats,
      message: 'تم جلب إحصائيات المهام بنجاح.',
    });
  };

  const handleDeleteCompleted = (req: AuthenticatedRequest, res: Response) => {
    const deletedCount = store.deleteCompletedTasks(req.authUser!.id);
    res.status(200).json({
      deleted_count: deletedCount,
      message: 'تم حذف المهام المكتملة بنجاح.',
    });
  };

  const handleListTasks = (req: AuthenticatedRequest, res: Response) => {
    const search = typeof req.query.search === 'string' ? req.query.search.trim().toLowerCase() : '';
    const status = typeof req.query.status === 'string' ? req.query.status.trim() : '';
    const priority = typeof req.query.priority === 'string' ? req.query.priority.trim() : '';
    const sortBy = typeof req.query.sort_by === 'string' ? req.query.sort_by.trim() : 'created_at';
    const sortDir = req.query.sort_dir === 'asc' ? 'asc' : 'desc';

    let userTasks = store.getTasksByUserId(req.authUser!.id);

    if (search) {
      userTasks = userTasks.filter(
        (t) =>
          t.title.toLowerCase().includes(search) ||
          (t.description ?? '').toLowerCase().includes(search)
      );
    }

    if (status) {
      userTasks = userTasks.filter((t) => t.status === status);
    }

    if (priority) {
      userTasks = userTasks.filter((t) => t.priority === priority);
    }

    if (req.query.overdue === 'true') {
      const nowMs = Date.now();
      userTasks = userTasks.filter(
        (t) => t.status !== 'Completed' && t.due_date && Date.parse(t.due_date) < nowMs
      );
    }

    userTasks.sort((a, b) => {
      let cmp = 0;
      if (sortBy === 'priority') {
        cmp = PRIORITY_WEIGHT[a.priority] - PRIORITY_WEIGHT[b.priority];
      } else if (sortBy === 'title') {
        cmp = a.title.localeCompare(b.title);
      } else if (sortBy === 'due_date') {
        const da = a.due_date ? Date.parse(a.due_date) : Number.MAX_SAFE_INTEGER;
        const db = b.due_date ? Date.parse(b.due_date) : Number.MAX_SAFE_INTEGER;
        cmp = da - db;
      } else if (sortBy === 'updated_at') {
        cmp = a.updated_at.localeCompare(b.updated_at) || a.id - b.id;
      } else {
        cmp = a.id - b.id;
      }
      return sortDir === 'asc' ? cmp : -cmp;
    });

    const total = userTasks.length;
    const pageParam = typeof req.query.page === 'string' ? Number(req.query.page) : undefined;
    const perPageParam = typeof req.query.per_page === 'string' ? Number(req.query.per_page) : undefined;

    let pagedTasks = userTasks;
    let meta: Record<string, number> | undefined;

    if (pageParam && Number.isFinite(pageParam) && pageParam > 0) {
      const perPage =
        perPageParam && Number.isFinite(perPageParam) && perPageParam > 0
          ? Math.min(100, Math.floor(perPageParam))
          : 15;
      const page = Math.floor(pageParam);
      const offset = (page - 1) * perPage;
      pagedTasks = userTasks.slice(offset, offset + perPage);
      meta = {
        total,
        page,
        per_page: perPage,
        last_page: Math.max(1, Math.ceil(total / perPage)),
      };
    }

    res.status(200).json({
      data: pagedTasks.map(toTaskResource),
      ...(meta ? { meta } : {}),
      message: 'تم جلب المهام بنجاح.',
    });
  };

  const handleShowTask = (req: AuthenticatedRequest, res: Response) => {
    const id = Number(req.params.id);
    const task = Number.isFinite(id) ? store.findTaskById(id) : undefined;
    if (!task || task.user_id !== req.authUser!.id) {
      res.status(404).json({ message: 'المهمة غير موجودة.' });
      return;
    }
    res.status(200).json({
      data: toTaskResource(task),
      message: 'تم جلب المهمة بنجاح.',
    });
  };

  const handleCreateTask = (req: AuthenticatedRequest, res: Response) => {
    const { errors, data } = validateTaskPayload((req.body ?? {}) as Record<string, unknown>, false);
    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const task = store.createTask(req.authUser!.id, {
      title: data.title!,
      description: data.description,
      status: data.status,
      priority: data.priority,
      due_date: data.due_date,
    });

    store.addNotification(req.authUser!.id, {
      type: 'task_created',
      title: 'تمت إضافة مهمة جديدة',
      body: `تم إنشاء المهمة "${task.title}" بأولوية ${task.priority}.`,
      data: { task_id: task.id },
    });

    res.status(201).json({
      data: toTaskResource(task),
      message: 'تم إنشاء المهمة بنجاح.',
    });
  };

  const handleUpdateTask = (req: AuthenticatedRequest, res: Response, partial: boolean) => {
    const id = Number(req.params.id);
    const existing = Number.isFinite(id) ? store.findTaskById(id) : undefined;
    if (!existing || existing.user_id !== req.authUser!.id) {
      res.status(404).json({ message: 'المهمة غير موجودة.' });
      return;
    }

    const { errors, data } = validateTaskPayload((req.body ?? {}) as Record<string, unknown>, partial);
    if (Object.keys(errors).length > 0) {
      const firstError = Object.values(errors)[0][0];
      res.status(422).json({ message: firstError, errors });
      return;
    }

    const updated = store.updateTask(id, data);
    res.status(200).json({
      data: toTaskResource(updated!),
      message: 'تم تحديث المهمة بنجاح.',
    });
  };

  const handleDeleteTask = (req: AuthenticatedRequest, res: Response) => {
    const id = Number(req.params.id);
    const existing = Number.isFinite(id) ? store.findTaskById(id) : undefined;
    if (!existing || existing.user_id !== req.authUser!.id) {
      res.status(404).json({ message: 'المهمة غير موجودة.' });
      return;
    }

    const deleted = store.deleteTask(id);
    res.status(200).json({
      message: 'تم حذف المهمة بنجاح.',
      data: deleted ? toTaskResource(deleted) : null,
    });
  };

  for (const basePath of ['/tasks', '/task']) {
    router.get(`${basePath}/stats`, authenticate, handleTaskStats);
    router.delete(`${basePath}/completed`, authenticate, handleDeleteCompleted);
    router.get(basePath, authenticate, handleListTasks);
    router.get(`${basePath}/:id`, authenticate, handleShowTask);
    router.post(basePath, authenticate, handleCreateTask);
    router.put(`${basePath}/:id`, authenticate, (req, res) => handleUpdateTask(req, res, false));
    router.patch(`${basePath}/:id`, authenticate, (req, res) => handleUpdateTask(req, res, true));
    router.delete(`${basePath}/:id`, authenticate, handleDeleteTask);
  }

  // ============================
  // Notifications
  // ============================

  router.get('/notifications', authenticate, (req: AuthenticatedRequest, res: Response) => {
    const list = store.getNotificationsByUser(req.authUser!.id);
    const unreadCount = list.filter((n) => !n.read_at).length;
    res.status(200).json({
      data: list,
      unread_count: unreadCount,
      message: 'تم جلب الإشعارات بنجاح.',
    });
  });

  router.patch('/notifications/:id/read', authenticate, (req: AuthenticatedRequest, res: Response) => {
    const id = Number(req.params.id);
    const item = Number.isFinite(id) ? store.markNotificationRead(req.authUser!.id, id) : undefined;
    if (!item) {
      res.status(404).json({ message: 'الإشعار غير موجود.' });
      return;
    }
    res.status(200).json({
      data: item,
      message: 'تم تحديد الإشعار كمقروء.',
    });
  });

  router.post('/notifications/read-all', authenticate, (req: AuthenticatedRequest, res: Response) => {
    const updatedCount = store.markAllNotificationsRead(req.authUser!.id);
    res.status(200).json({
      updated_count: updatedCount,
      message: 'تم تحديد جميع الإشعارات كمقروءة.',
    });
  });

  router.use((_req: Request, res: Response) => {
    res.status(404).json({ message: 'نقطة النهاية غير موجودة.' });
  });

  return router;
}
