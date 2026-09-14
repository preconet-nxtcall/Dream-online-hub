import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { router as apiRouter } from './routes/api.routes.js';
import { verifyToken } from './services/auth.service.js';
import { config } from './config/env.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const app = express();

app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));

// Helper function to parse cookies from headers
function getCookie(req, name) {
  try {
    const cookieHeader = req.headers.cookie;
    if (!cookieHeader) return null;
    const cookies = cookieHeader.split(';');
    for (let i = 0; i < cookies.length; i++) {
      const cookie = cookies[i].trim();
      const eqIdx = cookie.indexOf('=');
      if (eqIdx !== -1 && cookie.substring(0, eqIdx).trim() === name) {
        const val = cookie.substring(eqIdx + 1).trim();
        try { return decodeURIComponent(val); } catch (e) { return val; }
      }
    }
  } catch (err) {
    return null;
  }
  return null;
}

// Helper function to extract user from session cookie token
function getUserFromSession(req) {
  let token = getCookie(req, 'token') || getCookie(req, 'chat_token');
  if (!token && req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) return null;

  // Bypass token check for fixed API token (if configured)
  if (config.fixedApiToken && config.fixedApiToken.trim() !== '' && token === config.fixedApiToken) {
    const actAsEmail = req.headers['x-act-as-email'] || 'developer';
    const actAsRole = req.headers['x-act-as-role'] || 'admin';
    const actAsName = req.headers['x-act-as-name'] || 'Developer';
    const actAsAgentId = req.headers['x-act-as-agent-id'] || ((actAsRole === 'agent' || actAsRole === 'admin') ? actAsEmail : null);
    return {
      _id: actAsEmail,
      emailId: actAsEmail,
      name: actAsName,
      role: actAsRole,
      agentId: actAsAgentId
    };
  }

  try {
    return verifyToken(token);
  } catch (err) {
    return null;
  }
}

// 1. Root route: Redirect based on role and login status
app.get('/', (req, res) => {
  const user = getUserFromSession(req);
  if (!user) {
    return res.redirect('/office/');
  }
  if (user.role === 'agent' || user.role === 'admin') {
    return res.redirect('/chat/chat.html');
  } else {
    return res.redirect('/home');
  }
});

// 2. Login pages: Redirect if already logged in
app.get(['/view/login.html', '/login.html'], (req, res) => {
  const user = getUserFromSession(req);
  if (user) {
    if (user.role === 'agent' || user.role === 'admin') {
      return res.redirect('/chat/chat.html');
    } else {
      return res.redirect('/home');
    }
  }
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  res.sendFile(path.join(__dirname, '../public/view/login.html'));
});

// 4. Agent views: Restrict access to agent and admin only
app.get(['/chat.html', '/admin.html', '/chat/chat.html', '/chat/admin.html'], (req, res) => {
  const user = getUserFromSession(req);
  if (!user) {
    return res.redirect('/office/');
  }
  if (user.role !== 'agent' && user.role !== 'admin') {
    return res.redirect('/home');
  }
  const page = req.path.split('/').pop() || 'chat.html';
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  res.sendFile(path.join(__dirname, `../public/${page}`));
});

// 5. Player views: Restrict access to players (users) only
app.get(['/view/home.html', '/view/recharge.html', '/view/records.html'], (req, res) => {
  const user = getUserFromSession(req);
  if (!user) {
    return res.redirect('/chat/view/login.html');
  }
  if (user.role == 'admin' || user.role == 'agent') {
    return res.redirect('/chat/chat.html');
  }
  const page = req.path.split('/').pop() || 'home.html';
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  res.sendFile(path.join(__dirname, `../public/view/${page}`));
});

// Serve Static Testing UI Dashboard (static assets, JS, CSS, images)
app.use(express.static(path.join(__dirname, '../public')));

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// API Routes V1
app.use('/api/v1', apiRouter);


// 404 Handler
app.use((req, res) => {
  if (req.accepts('html')) {
    return res.status(404).sendFile(path.join(__dirname, '../public/404.html'));
  }
  res.status(404).json({ error: 'Route not found' });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error('[App] Unhandled Error:', err);
  if (req.accepts('html')) {
    return res.status(err.status || 500).sendFile(path.join(__dirname, '../public/404.html'));
  }
  res.status(err.status || 500).json({
    error: err.name || 'InternalServerError',
    message: err.message || 'An unexpected error occurred'
  });
});
