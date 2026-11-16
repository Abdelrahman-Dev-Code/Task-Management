import crypto from 'node:crypto';
import type { OtpPurpose } from '../../types.js';
import { store } from '../store.js';

const OTP_TTL_MS = 10 * 60 * 1000;
const OTP_RESEND_COOLDOWN_MS = 30 * 1000;
const OTP_MAX_ATTEMPTS = 5;

const OTP_SECRET = process.env.OTP_SECRET || 'task-management-otp-secret';

function hashOtp(email: string, purpose: OtpPurpose, code: string): string {
  return crypto
    .createHmac('sha256', OTP_SECRET)
    .update(`${purpose}:${email.trim().toLowerCase()}:${code}`)
    .digest('hex');
}

function generateOtpCode(): string {
  return String(crypto.randomInt(100000, 1000000));
}

async function deliverOtpEmail(
  email: string,
  code: string,
  purpose: OtpPurpose
): Promise<{ deliveredVia: 'resend' | 'dev_preview' }> {
  const resendApiKey = process.env.RESEND_API_KEY;
  const fromAddress = process.env.MAIL_FROM_ADDRESS || 'onboarding@resend.dev';

  const purposeTitles: Record<OtpPurpose, string> = {
    verify_email: 'تأكيد البريد الإلكتروني',
    login: 'رمز تسجيل الدخول',
    reset_password: 'إعادة تعيين كلمة المرور',
  };

  if (resendApiKey) {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromAddress,
        to: [email],
        subject: `${purposeTitles[purpose]} - لوحة المهام`,
        html: `<div dir="rtl" style="font-family: Arial, sans-serif; line-height: 1.6;">
          <h2>${purposeTitles[purpose]}</h2>
          <p>رمز التحقق الخاص بك هو:</p>
          <p style="font-size: 28px; font-weight: bold; letter-spacing: 6px; color: #4f46e5;">${code}</p>
          <p>صلاحية الرمز 10 دقائق. لا تشارك هذا الرمز مع أي شخص.</p>
        </div>`,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text().catch(() => '');
      throw new Error(`فشل إرسال البريد الإلكتروني عبر مزود البريد: ${errorText || response.status}`);
    }

    return { deliveredVia: 'resend' };
  }

  console.info(`[OTP:${purpose}] ${email} => ${code}`);
  return { deliveredVia: 'dev_preview' };
}

export async function sendOtpForEmail(
  email: string,
  purpose: OtpPurpose,
  options: { bypassCooldown?: boolean } = {}
): Promise<{
  expiresInSeconds: number;
  deliveredVia: 'resend' | 'dev_preview';
  devOtp?: string;
}> {
  const normalizedEmail = email.trim().toLowerCase();
  const existing = store.getOtp(normalizedEmail, purpose);

  if (!options.bypassCooldown && existing) {
    const elapsed = Date.now() - existing.lastSentAt;
    if (elapsed < OTP_RESEND_COOLDOWN_MS) {
      const retryAfter = Math.ceil((OTP_RESEND_COOLDOWN_MS - elapsed) / 1000);
      const err = new Error(`يرجى الانتظار ${retryAfter} ثانية قبل إعادة إرسال الرمز.`) as Error & {
        statusCode?: number;
        retryAfter?: number;
      };
      err.statusCode = 429;
      err.retryAfter = retryAfter;
      throw err;
    }
  }

  const code = generateOtpCode();
  const now = Date.now();
  store.saveOtp({
    email: normalizedEmail,
    purpose,
    codeHash: hashOtp(normalizedEmail, purpose, code),
    expiresAt: now + OTP_TTL_MS,
    attempts: 0,
    lastSentAt: now,
  });

  const delivery = await deliverOtpEmail(normalizedEmail, code, purpose);
  const exposeDevOtp =
    delivery.deliveredVia === 'dev_preview' && process.env.NODE_ENV !== 'production';

  return {
    expiresInSeconds: Math.floor(OTP_TTL_MS / 1000),
    deliveredVia: delivery.deliveredVia,
    ...(exposeDevOtp ? { devOtp: code } : {}),
  };
}

export function verifyOtpCode(
  email: string,
  purpose: OtpPurpose,
  code: string
): { ok: true } | { ok: false; statusCode: number; message: string } {
  const normalizedEmail = email.trim().toLowerCase();
  const record = store.getOtp(normalizedEmail, purpose);

  if (!record) {
    return {
      ok: false,
      statusCode: 422,
      message: 'لم يتم العثور على رمز تحقق نشط، يرجى طلب رمز جديد.',
    };
  }

  if (Date.now() > record.expiresAt) {
    store.deleteOtp(normalizedEmail, purpose);
    return {
      ok: false,
      statusCode: 410,
      message: 'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد.',
    };
  }

  if (record.attempts >= OTP_MAX_ATTEMPTS) {
    store.deleteOtp(normalizedEmail, purpose);
    return {
      ok: false,
      statusCode: 429,
      message: 'تم تجاوز الحد الأقصى لمحاولات التحقق، يرجى طلب رمز جديد.',
    };
  }

  const candidateHash = hashOtp(normalizedEmail, purpose, code.trim());
  const expectedBuffer = Buffer.from(record.codeHash, 'hex');
  const candidateBuffer = Buffer.from(candidateHash, 'hex');

  const matches =
    expectedBuffer.length === candidateBuffer.length &&
    crypto.timingSafeEqual(expectedBuffer, candidateBuffer);

  if (!matches) {
    const attempts = store.incrementOtpAttempts(normalizedEmail, purpose);
    const remaining = Math.max(0, OTP_MAX_ATTEMPTS - attempts);
    return {
      ok: false,
      statusCode: 422,
      message:
        remaining > 0
          ? `رمز التحقق غير صحيح. المحاولات المتبقية: ${remaining}.`
          : 'رمز التحقق غير صحيح وتم استنفاد المحاولات.',
    };
  }

  store.deleteOtp(normalizedEmail, purpose);
  return { ok: true };
}
