/**
 * FairBiz CRM - User Embedded Floating Chat Widget
 * Automatically connects to Socket.IO & REST APIs using the SSO token cookie.
 */

(function () {
  'use strict';

  // Helper to read cookies
  function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
  }

  const token = getCookie('chat_token') || getCookie('token');
  if (!token) {
    // User is not logged in, do not render chat widget
    return;
  }

  // Inject Styles
  const style = document.createElement('style');
  style.innerHTML = `
    #fb-chat-widget-launcher {
      position: fixed;
      bottom: 24px;
      right: 24px;
      width: 60px;
      height: 60px;
      border-radius: 30px;
      background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
      box-shadow: 0 8px 24px rgba(99, 102, 241, 0.4);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      z-index: 999999;
      transition: transform 0.2s ease, box-shadow 0.2s ease;
    }
    #fb-chat-widget-launcher:hover {
      transform: scale(1.08);
      box-shadow: 0 12px 28px rgba(99, 102, 241, 0.5);
    }
    #fb-chat-widget-launcher svg {
      width: 28px;
      height: 28px;
      fill: #ffffff;
    }
    #fb-chat-widget-container {
      position: fixed;
      bottom: 96px;
      right: 24px;
      width: 380px;
      max-width: calc(100vw - 32px);
      height: 520px;
      max-height: calc(100dvh - 120px);
      background: #1e1b4b;
      background: linear-gradient(180deg, #1e1b4b 0%, #0f172a 100%);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 20px;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
      z-index: 999999;
      display: none;
      flex-direction: column;
      overflow: hidden;
      box-sizing: border-box;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    #fb-chat-widget-container.active {
      display: flex;
    }
    .fb-chat-header {
      padding: 16px 20px;
      background: rgba(255, 255, 255, 0.05);
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-shrink: 0;
    }
    .fb-chat-header h4 {
      margin: 0;
      color: #ffffff;
      font-size: 16px;
      font-weight: 600;
    }
    .fb-chat-header .status-indicator {
      font-size: 12px;
      color: #34d399;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .fb-chat-header .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #34d399;
    }
    .fb-chat-close-btn {
      background: none;
      border: none;
      color: #94a3b8;
      font-size: 20px;
      cursor: pointer;
    }
    .fb-chat-close-btn:hover { color: #ffffff; }
    .fb-chat-messages {
      flex: 1 1 0%;
      padding: 16px;
      overflow-y: auto;
      min-height: 0;
      display: flex;
      flex-direction: column;
      gap: 12px;
      -webkit-overflow-scrolling: touch;
    }
    .fb-chat-msg {
      max-width: 80%;
      padding: 10px 14px;
      border-radius: 14px;
      font-size: 14px;
      line-height: 1.4;
      word-break: break-word;
    }
    .fb-chat-msg.me {
      align-self: flex-end;
      background: #6366f1;
      color: #ffffff;
      border-bottom-right-radius: 2px;
    }
    .fb-chat-msg.other {
      align-self: flex-start;
      background: rgba(255, 255, 255, 0.1);
      color: #f1f5f9;
      border-bottom-left-radius: 2px;
    }
    .fb-chat-input-area {
      padding: 12px;
      padding-bottom: max(12px, calc(12px + env(safe-area-inset-bottom, 0px)));
      background: rgba(255, 255, 255, 0.03);
      border-top: 1px solid rgba(255, 255, 255, 0.1);
      display: flex;
      align-items: center;
      gap: 8px;
      flex-shrink: 0;
      width: 100%;
      box-sizing: border-box;
    }
    .fb-chat-input {
      flex: 1 1 0%;
      min-width: 0;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 20px;
      padding: 10px 16px;
      color: #ffffff;
      font-size: 14px;
      outline: none;
      box-sizing: border-box;
    }
    .fb-chat-send-btn {
      background: #6366f1;
      border: none;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      color: #ffffff;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      flex-shrink: 0;
    }
    .fb-chat-send-btn:hover { background: #4f46e5; }

    @media (max-width: 600px) {
      #fb-chat-widget-container {
        width: 100vw !important;
        max-width: 100vw !important;
        height: 100vh !important;
        height: 100dvh !important;
        max-height: 100dvh !important;
        bottom: 0 !important;
        right: 0 !important;
        left: 0 !important;
        top: 0 !important;
        border-radius: 0 !important;
      }
    }
  `;
  document.head.appendChild(style);

  // Inject DOM Elements
  const launcher = document.createElement('div');
  launcher.id = 'fb-chat-widget-launcher';
  launcher.innerHTML = `
    <svg viewBox="0 0 24 24">
      <path d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 9h12v2H6V9zm8 5H6v-2h8v2zm4-6H6V6h12v2z"/>
    </svg>
  `;

  const container = document.createElement('div');
  container.id = 'fb-chat-widget-container';
  container.innerHTML = `
    <div class="fb-chat-header">
      <div>
        <h4>Customer Support</h4>
        <div class="status-indicator"><span class="status-dot"></span> Live Support</div>
      </div>
      <button class="fb-chat-close-btn" id="fb-chat-close">&times;</button>
    </div>
    <div class="fb-chat-messages" id="fb-chat-msgs">
      <div class="fb-chat-msg other">Hello! How can we assist you today?</div>
    </div>
    <div class="fb-chat-input-area">
      <input type="text" class="fb-chat-input" id="fb-chat-input" placeholder="Type a message..." />
      <button class="fb-chat-send-btn" id="fb-chat-send">➤</button>
    </div>
  `;

  document.body.appendChild(launcher);
  document.body.appendChild(container);

  function makeChatWidgetMovable(el) {
    if (!el || el._isMovableInitialized) return;
    el._isMovableInitialized = true;

    el.style.touchAction = 'none';
    el.style.userSelect = 'none';
    el.style.webkitUserSelect = 'none';
    el.style.cursor = 'grab';

    let isPointerDown = false;
    let isDragging = false;
    let startX = 0;
    let startY = 0;
    let initialLeft = 0;
    let initialTop = 0;
    const dragThreshold = 6;

    try {
      const saved = localStorage.getItem('fb_chat_widget_pos');
      if (saved) {
        const pos = JSON.parse(saved);
        const maxX = window.innerWidth - (el.offsetWidth || 60) - 8;
        const maxY = window.innerHeight - (el.offsetHeight || 60) - 8;
        if (typeof pos.left === 'number' && typeof pos.top === 'number') {
          const clampedX = Math.min(Math.max(8, pos.left), Math.max(8, maxX));
          const clampedY = Math.min(Math.max(8, pos.top), Math.max(8, maxY));
          el.style.setProperty('left', clampedX + 'px', 'important');
          el.style.setProperty('top', clampedY + 'px', 'important');
          el.style.setProperty('right', 'auto', 'important');
          el.style.setProperty('bottom', 'auto', 'important');
        }
      }
    } catch (e) {}

    function onPointerStart(e) {
      if (e.type === 'mousedown' && e.button !== 0) return;

      isPointerDown = true;
      isDragging = false;

      const point = e.touches ? e.touches[0] : e;
      startX = point.clientX;
      startY = point.clientY;

      const rect = el.getBoundingClientRect();
      initialLeft = rect.left;
      initialTop = rect.top;

      el.style.setProperty('left', initialLeft + 'px', 'important');
      el.style.setProperty('top', initialTop + 'px', 'important');
      el.style.setProperty('right', 'auto', 'important');
      el.style.setProperty('bottom', 'auto', 'important');
    }

    function onPointerMove(e) {
      if (!isPointerDown) return;

      const point = e.touches ? e.touches[0] : e;
      const dx = point.clientX - startX;
      const dy = point.clientY - startY;

      if (!isDragging) {
        if (Math.hypot(dx, dy) >= dragThreshold) {
          isDragging = true;
          el.style.cursor = 'grabbing';
          el.style.setProperty('transition', 'none', 'important');
          el.style.setProperty('transform', 'scale(1.08)', 'important');
          el.style.setProperty('box-shadow', '0 18px 36px rgba(0, 0, 0, 0.35)', 'important');
        } else {
          return;
        }
      }

      if (e.cancelable) {
        e.preventDefault();
      }

      const btnWidth = el.offsetWidth || 60;
      const btnHeight = el.offsetHeight || 60;
      const minX = 8;
      const maxX = window.innerWidth - btnWidth - 8;
      const minY = 8;
      const maxY = window.innerHeight - btnHeight - 8;

      const newLeft = Math.min(Math.max(minX, initialLeft + dx), Math.max(minX, maxX));
      const newTop = Math.min(Math.max(minY, initialTop + dy), Math.max(minY, maxY));

      el.style.setProperty('left', newLeft + 'px', 'important');
      el.style.setProperty('top', newTop + 'px', 'important');
    }

    function onPointerEnd(e) {
      if (!isPointerDown) return;
      isPointerDown = false;

      if (isDragging) {
        isDragging = false;
        el.style.cursor = 'grab';
        el.style.removeProperty('transition');
        el.style.removeProperty('transform');
        el.style.removeProperty('box-shadow');

        try {
          const rect = el.getBoundingClientRect();
          localStorage.setItem('fb_chat_widget_pos', JSON.stringify({
            left: Math.round(rect.left),
            top: Math.round(rect.top)
          }));
        } catch (e) {}

        const suppressClick = function(clickEvt) {
          clickEvt.stopPropagation();
          clickEvt.preventDefault();
          window.removeEventListener('click', suppressClick, true);
        };
        window.addEventListener('click', suppressClick, true);
      }
    }

    el.addEventListener('mousedown', onPointerStart);
    window.addEventListener('mousemove', onPointerMove, { passive: false });
    window.addEventListener('mouseup', onPointerEnd);

    el.addEventListener('touchstart', onPointerStart, { passive: true });
    window.addEventListener('touchmove', onPointerMove, { passive: false });
    window.addEventListener('touchend', onPointerEnd);
    window.addEventListener('touchcancel', onPointerEnd);

    window.addEventListener('resize', function() {
      const rect = el.getBoundingClientRect();
      const btnWidth = el.offsetWidth || 60;
      const btnHeight = el.offsetHeight || 60;
      const maxX = window.innerWidth - btnWidth - 8;
      const maxY = window.innerHeight - btnHeight - 8;

      if (rect.left > maxX || rect.top > maxY) {
        const clampedX = Math.min(Math.max(8, rect.left), Math.max(8, maxX));
        const clampedY = Math.min(Math.max(8, rect.top), Math.max(8, maxY));
        el.style.setProperty('left', clampedX + 'px', 'important');
        el.style.setProperty('top', clampedY + 'px', 'important');
      }
    });
  }

  // Toggle Visibility
  launcher.addEventListener('click', () => container.classList.toggle('active'));
  document.getElementById('fb-chat-close').addEventListener('click', () => container.classList.remove('active'));
  makeChatWidgetMovable(launcher);

  // Load Socket.IO client dynamically if missing
  function loadSocketIO(callback) {
    if (window.io) return callback();
    const script = document.createElement('script');
    script.src = '/socket.io/socket.io.js';
    script.onload = callback;
    script.onerror = () => {
      console.log('Socket.IO script load fallback to /chat/socket.io/socket.io.js');
      const fallbackScript = document.createElement('script');
      fallbackScript.src = '/chat/socket.io/socket.io.js';
      fallbackScript.onload = callback;
      document.head.appendChild(fallbackScript);
    };
    document.head.appendChild(script);
  }

  loadSocketIO(() => {
    if (!window.io) return;
    const socket = window.io({
      auth: { token: token },
      transports: ['websocket', 'polling']
    });

    const msgsContainer = document.getElementById('fb-chat-msgs');
    const input = document.getElementById('fb-chat-input');
    const sendBtn = document.getElementById('fb-chat-send');

    function appendMessage(text, isMe) {
      const msgDiv = document.createElement('div');
      msgDiv.className = `fb-chat-msg ${isMe ? 'me' : 'other'}`;
      msgDiv.textContent = text;
      msgsContainer.appendChild(msgDiv);
      msgsContainer.scrollTop = msgsContainer.scrollHeight;
    }

    function sendMessage() {
      const text = input.value.trim();
      if (!text) return;
      appendMessage(text, true);
      socket.emit('message', { text: text });
      input.value = '';
    }

    sendBtn.addEventListener('click', sendMessage);
    input.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });

    socket.on('message', (data) => {
      if (data && data.text) {
        appendMessage(data.text, false);
      }
    });
  });
})();
