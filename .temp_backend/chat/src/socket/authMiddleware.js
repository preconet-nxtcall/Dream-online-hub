import { verifyToken } from '../services/auth.service.js';
import { config } from '../config/env.js';

export function socketAuthMiddleware(socket, next) {
  try {
    let token =
      socket.handshake.auth?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token && socket.handshake.headers?.cookie) {
      const cookies = socket.handshake.headers.cookie.split(';');
      for (let i = 0; i < cookies.length; i++) {
        const cookie = cookies[i].trim();
        const eqIdx = cookie.indexOf('=');
        if (eqIdx !== -1) {
          const name = cookie.substring(0, eqIdx).trim();
          if (name === 'token' || name === 'chat_token') {
            try {
              token = decodeURIComponent(cookie.substring(eqIdx + 1).trim());
            } catch (e) {
              token = cookie.substring(eqIdx + 1).trim();
            }
            break;
          }
        }
      }
    }

    if (!token) {
      return next(new Error('Authentication error: JWT token missing'));
    }

    // Bypass token check for fixed API token (if configured)
    if (config.fixedApiToken && config.fixedApiToken.trim() !== '' && token === config.fixedApiToken) {
      const actAsEmail = socket.handshake.auth?.actAsEmail || socket.handshake.headers?.['x-act-as-email'] || 'developer';
      const actAsRole = socket.handshake.auth?.actAsRole || socket.handshake.headers?.['x-act-as-role'] || 'user';
      const actAsName = socket.handshake.auth?.actAsName || socket.handshake.headers?.['x-act-as-name'] || 'App User';
      const actAsAgentId = socket.handshake.auth?.actAsAgentId || socket.handshake.headers?.['x-act-as-agent-id'] || ((actAsRole === 'agent' || actAsRole === 'admin') ? actAsEmail : null);

      socket.data.user = {
        _id: actAsEmail,
        emailId: actAsEmail,
        role: actAsRole,
        agentId: actAsAgentId,
        name: actAsName
      };
      return next();
    }

    const decoded = verifyToken(token);
    let staffId = decoded.agentId;
    if (!staffId && (decoded.role === 'agent' || decoded.role === 'admin')) {
      const numId = decoded.id || '1';
      staffId = decoded.role === 'admin' ? (numId == 1 ? 'ADMIN-1' : `ADMIN-${numId}`) : `AGENCY-${numId}`;
    }
    socket.data.user = {
      _id: decoded._id || decoded.emailId || decoded.id,
      emailId: decoded.emailId || decoded.id,
      role: decoded.role || 'user',
      agentId: staffId,
      name: decoded.name
    };
    return next();
  } catch (err) {
    console.error('[SocketAuth] Authentication failed:', err.message);
    next(new Error(`Authentication error: ${err.message}`));
  }
}
