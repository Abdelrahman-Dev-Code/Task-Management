import express, { type NextFunction, type Request, type Response } from 'express';
import { createApiRouter } from './src/server/apiRouter.js';

const PORT = Number(process.env.PORT) || 3000;
const HOST = '0.0.0.0';
const startedAt = Date.now();

const app = express();

// CORS middleware for Flutter (Mobile, Web, Desktop) and API clients
app.use((req: Request, res: Response, next: NextFunction) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  next();
});

app.use(express.json());

// Handle malformed JSON bodies cleanly
app.use((err: Error & { status?: number }, _req: Request, res: Response, next: NextFunction) => {
  if (err instanceof SyntaxError && err.status === 400) {
    res.status(400).json({ message: 'صيغة JSON في الطلب غير صالحة.' });
    return;
  }
  next(err);
});

app.get('/', (_req: Request, res: Response) => {
  res.status(200).json({
    service: 'Task Management API',
    mode: 'api-only',
    status: 'ok',
    message: 'API-only application ready for Flutter integration.',
    endpoints: {
      health: ['GET /health', 'GET /up'],
      auth: [
        'POST /api/register',
        'POST /api/login',
        'POST /api/logout',
        'POST /api/logout-all',
        'GET /api/user',
        'PUT /api/user',
        'PATCH /api/user',
      ],
      otp: [
        'POST /api/otp/send (purpose: verify_email | login | reset_password)',
        'POST /api/otp/verify',
        'POST /api/auth/otp/request',
        'POST /api/auth/otp/verify',
        'POST /api/password/forgot',
        'POST /api/password/reset',
      ],
      google_auth: [
        'POST /api/auth/google (id_token or access_token from Flutter google_sign_in)',
        'GET /api/auth/google/url',
        'GET /api/auth/google/callback',
      ],
      tasks: [
        'GET /api/tasks/stats',
        'GET /api/tasks (?search,status,priority,sort_by,sort_dir,page,per_page)',
        'POST /api/tasks',
        'GET /api/tasks/:id',
        'PUT /api/tasks/:id',
        'PATCH /api/tasks/:id',
        'DELETE /api/tasks/:id',
        'DELETE /api/tasks/completed',
      ],
      notifications: [
        'GET /api/notifications',
        'PATCH /api/notifications/:id/read',
        'POST /api/notifications/read-all',
      ],
    },
  });
});

app.get(['/health', '/up'], (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    service: 'task-management-api',
    uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
    timestamp: new Date().toISOString(),
  });
});

app.use('/api', createApiRouter());

app.use((_req: Request, res: Response) => {
  res.status(404).json({
    message: 'This application is API-only. See / or /api for available endpoints.',
  });
});

app.listen(PORT, HOST, () => {
  console.log(`Task Management API server listening on http://${HOST}:${PORT}`);
});
