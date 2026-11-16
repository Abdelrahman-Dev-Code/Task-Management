import { formatTimestamp, store, toPublicUser } from '../store.js';
import type { User } from '../../types.js';

export interface GoogleUserProfile {
  googleId: string;
  email: string;
  name: string;
  avatar: string | null;
  emailVerified: boolean;
}

function getAllowedClientIds(): string[] {
  const ids = [
    process.env.GOOGLE_CLIENT_ID,
    ...(process.env.GOOGLE_ALLOWED_CLIENT_IDS?.split(',') ?? []),
  ]
    .map((id) => id?.trim())
    .filter((id): id is string => Boolean(id));
  return Array.from(new Set(ids));
}

export async function verifyGoogleIdToken(idToken: string): Promise<GoogleUserProfile> {
  const response = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
  );

  if (!response.ok) {
    throw new Error('رمز مصادقة جوجل (ID Token) غير صالح أو منتهي الصلاحية.');
  }

  const payload = (await response.json()) as Record<string, string | boolean | undefined>;
  const sub = typeof payload.sub === 'string' ? payload.sub : '';
  const email = typeof payload.email === 'string' ? payload.email.trim().toLowerCase() : '';
  const emailVerified = payload.email_verified === true || payload.email_verified === 'true';
  const aud = typeof payload.aud === 'string' ? payload.aud : '';

  if (!sub || !email) {
    throw new Error('تعذر استخراج بيانات الحساب من رمز جوجل.');
  }

  if (!emailVerified) {
    throw new Error('البريد الإلكتروني في حساب جوجل غير مؤكد.');
  }

  const allowedClientIds = getAllowedClientIds();
  if (allowedClientIds.length > 0 && !allowedClientIds.includes(aud)) {
    throw new Error('رمز جوجل لا يطابق معرف التطبيق (Client ID) المعتمد.');
  }

  return {
    googleId: sub,
    email,
    name: typeof payload.name === 'string' && payload.name.trim() ? payload.name.trim() : email.split('@')[0],
    avatar: typeof payload.picture === 'string' ? payload.picture : null,
    emailVerified,
  };
}

export async function verifyGoogleAccessToken(accessToken: string): Promise<GoogleUserProfile> {
  const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error('رمز الوصول (Access Token) الخاص بجوجل غير صالح.');
  }

  const payload = (await response.json()) as Record<string, string | boolean | undefined>;
  const sub = typeof payload.sub === 'string' ? payload.sub : '';
  const email = typeof payload.email === 'string' ? payload.email.trim().toLowerCase() : '';
  const emailVerified = payload.email_verified !== false && payload.email_verified !== 'false';

  if (!sub || !email) {
    throw new Error('تعذر جلب معلومات المستخدم من جوجل.');
  }

  if (!emailVerified) {
    throw new Error('البريد الإلكتروني في حساب جوجل غير مؤكد.');
  }

  return {
    googleId: sub,
    email,
    name: typeof payload.name === 'string' && payload.name.trim() ? payload.name.trim() : email.split('@')[0],
    avatar: typeof payload.picture === 'string' ? payload.picture : null,
    emailVerified,
  };
}

export function getGoogleOAuthRedirectUri(customRedirectUri?: string): string {
  if (customRedirectUri && customRedirectUri.trim()) {
    return customRedirectUri.trim();
  }
  const appUrl = (process.env.APP_URL || `http://localhost:${process.env.PORT || 3000}`).replace(/\/+$/, '');
  return `${appUrl}/api/auth/google/callback`;
}

export function buildGoogleAuthorizationUrl(options: {
  redirectUri?: string;
  state?: string;
}): string {
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim();
  if (!clientId) {
    const err = new Error('إعدادات GOOGLE_CLIENT_ID غير مضبوطة على الخادم.') as Error & {
      statusCode?: number;
    };
    err.statusCode = 503;
    throw err;
  }

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: getGoogleOAuthRedirectUri(options.redirectUri),
    response_type: 'code',
    scope: 'openid email profile',
    access_type: 'offline',
    prompt: 'select_account',
  });

  if (options.state) {
    params.set('state', options.state);
  }

  return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
}

export async function exchangeGoogleAuthorizationCode(
  code: string,
  redirectUri?: string
): Promise<GoogleUserProfile> {
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim();
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET?.trim();

  if (!clientId || !clientSecret) {
    const err = new Error('إعدادات GOOGLE_CLIENT_ID أو GOOGLE_CLIENT_SECRET غير مضبوطة.') as Error & {
      statusCode?: number;
    };
    err.statusCode = 503;
    throw err;
  }

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: getGoogleOAuthRedirectUri(redirectUri),
      grant_type: 'authorization_code',
    }).toString(),
  });

  const tokenPayload = (await tokenRes.json().catch(() => ({}))) as Record<string, unknown>;
  if (!tokenRes.ok) {
    throw new Error(
      typeof tokenPayload.error_description === 'string'
        ? tokenPayload.error_description
        : 'فشل تبادل رمز تفويض جوجل.'
    );
  }

  if (typeof tokenPayload.id_token === 'string') {
    return verifyGoogleIdToken(tokenPayload.id_token);
  }

  if (typeof tokenPayload.access_token === 'string') {
    return verifyGoogleAccessToken(tokenPayload.access_token);
  }

  throw new Error('لم يُرجع خادم جوجل رمز تحقق صالح.');
}

export function upsertUserFromGoogleProfile(
  profile: GoogleUserProfile,
  deviceName = 'flutter-google'
): { user: User; token: string; isNewUser: boolean } {
  const now = formatTimestamp();
  let existing =
    store.findUserByGoogleId(profile.googleId) ?? store.findUserByEmail(profile.email);
  let isNewUser = false;

  if (!existing) {
    existing = store.createUser({
      name: profile.name,
      email: profile.email,
      password: null,
      provider: 'google',
      google_id: profile.googleId,
      avatar: profile.avatar,
      email_verified_at: profile.emailVerified ? now : null,
    });
    isNewUser = true;

    store.addNotification(existing.id, {
      type: 'auth_google',
      title: 'تم إنشاء حسابك عبر جوجل',
      body: 'مرحباً بك! يمكنك الآن إدارة مهامك من تطبيق Flutter.',
      data: { provider: 'google' },
    });
  } else {
    existing = store.updateUser(existing.id, {
      name: existing.name || profile.name,
      avatar: profile.avatar ?? existing.avatar,
      google_id: profile.googleId,
      email_verified_at: existing.email_verified_at ?? (profile.emailVerified ? now : null),
    })!;
  }

  const token = store.issueToken(existing.id, deviceName);
  return {
    user: toPublicUser(existing),
    token,
    isNewUser,
  };
}
