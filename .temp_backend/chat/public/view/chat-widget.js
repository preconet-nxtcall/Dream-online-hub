(function() {
  // 1. Inject Styles
  const styleEl = document.createElement('style');
  styleEl.textContent = `
    :root {
      --primary: #008069;
      --primary-hover: #016b57;
      --primary-light: #d9fdd3;
      --gold: #d4af37;
      --gold-hover: #aa8c2c;
      --bg-dark: #0f172a;
      --bg-card: #1e293b;
      --border-color: #334155;
      --text-light: #f8fafc;
      --text-gray: #94a3b8;
      --status-online: #25d366;
      --msg-incoming: #f1f5f9;
      --msg-outgoing: #d9fdd3;
      --font-family: 'Inter', sans-serif;
    }

    .presence-online {
      color: #25d366 !important;
      font-weight: 600;
    }
    .presence-offline {
      color: rgba(255, 255, 255, 0.7) !important;
      font-weight: 500;
    }

    .chat-drawer {
      position: fixed;
      top: 0;
      right: 0;
      bottom: 0;
      width: 400px;
      max-width: 100vw;
      height: 100vh;
      height: 100dvh;
      max-height: 100%;
      background: #ffffff;
      color: #0f172a;
      border-radius: 20px 0 0 20px;
      box-shadow: -10px 0 35px rgba(0, 0, 0, 0.12);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      z-index: 1000;
      transform: translateX(100%);
      transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
      font-family: var(--font-family);
      box-sizing: border-box;
    }

    .chat-drawer.open {
      transform: translateX(0);
    }

    body.chat-drawer-open #fbChatWidgetFloatingBtn,
    body.chat-drawer-open button.fab-pulse,
    body.chat-drawer-open button.fixed.bottom-8.right-8,
    body.chat-drawer-open button.fixed.bottom-6.right-6 {
      display: none !important;
    }

    .widget-header {
      background: var(--primary);
      color: white;
      padding: 0.85rem 1rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-shrink: 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.08);
      min-height: 52px;
    }

    .btn-header-action {
      width: 32px !important;
      height: 32px !important;
      min-width: 32px !important;
      min-height: 32px !important;
      border-radius: 50% !important;
      background: rgba(255, 255, 255, 0.16);
      border: 1px solid rgba(255, 255, 255, 0.28);
      color: #ffffff;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
      padding: 0 !important;
      margin: 0 !important;
      outline: none;
      flex-shrink: 0;
      box-sizing: border-box;
    }
    .btn-header-action:hover {
      background: rgba(255, 255, 255, 0.28);
      border-color: rgba(255, 255, 255, 0.45);
      transform: scale(1.08);
      box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
    }
    .btn-header-action:active {
      transform: scale(0.92);
    }

    .btn-header-close {
      width: 32px !important;
      height: 32px !important;
      min-width: 32px !important;
      min-height: 32px !important;
      border-radius: 50% !important;
      background: rgba(255, 255, 255, 0.16);
      border: 1px solid rgba(255, 255, 255, 0.28);
      color: #ffffff;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
      padding: 0 !important;
      margin: 0 !important;
      outline: none;
      flex-shrink: 0;
      box-sizing: border-box;
    }
    .btn-header-close:hover {
      background: rgba(239, 68, 68, 0.85);
      border-color: rgba(239, 68, 68, 1);
      transform: rotate(90deg) scale(1.08);
      box-shadow: 0 4px 12px rgba(239, 68, 68, 0.35);
    }
    .btn-header-close:active {
      transform: rotate(90deg) scale(0.92);
    }

    .widget-content {
      flex: 1 1 0%;
      display: flex;
      flex-direction: column;
      min-height: 0;
      position: relative;
      background: #f8fafc;
      color: #0f172a;
      overflow: hidden;
      width: 100%;
    }

    .widget-chat-container {
      display: flex;
      flex-direction: column;
      height: 100%;
      min-height: 0;
      flex: 1 1 0%;
      overflow: hidden;
      width: 100%;
    }

    .convo-list-widget {
      flex: 1 1 0%;
      overflow-y: auto;
      min-height: 0;
      background: #ffffff;
    }

    .active-chat-widget {
      flex: 1 1 0%;
      display: flex;
      flex-direction: column;
      height: 100%;
      min-height: 0;
      overflow: hidden;
      width: 100%;
      background: #efeae2;
      background-image: url("https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png");
      background-repeat: repeat;
    }

    .conv-item-widget {
      padding: 0.75rem 1rem;
      border-bottom: 1px solid #f1f5f9;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 0.65rem;
      transition: background 0.15s;
    }
    .conv-item-widget:hover { background: #f8fafc; }

    .avatar-widget {
      width: 38px;
      height: 38px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 700;
      font-size: 0.85rem;
      flex-shrink: 0;
    }

    .widget-avatar {
      width: 30px;
      height: 30px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 700;
      font-size: 0.75rem;
      flex-shrink: 0;
      box-shadow: 0 1px 2px rgba(0,0,0,0.1);
    }

    .conv-info-widget {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 0.15rem;
    }

    .conv-name-widget {
      font-weight: 600;
      font-size: 0.85rem;
      color: #0f172a;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .conv-meta-widget {
      font-size: 0.725rem;
      color: #64748b;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .conv-meta-widget.virtual { color: var(--primary); font-style: italic; }

    .messages-widget {
      flex: 1 1 0%;
      overflow-y: auto;
      min-height: 0;
      padding: 1rem;
      display: flex;
      flex-direction: column;
      gap: 0.65rem;
      -webkit-overflow-scrolling: touch;
      overscroll-behavior-y: contain;
    }

    .bubble-widget {
      max-width: 75%;
      padding: 0.4rem 0.65rem 0.25rem;
      border-radius: 8px;
      font-size: 0.825rem;
      line-height: 1.35;
      display: flex;
      flex-direction: column;
      box-shadow: 0 1px 1px rgba(0,0,0,0.06);
    }
    .bubble-widget.incoming {
      align-self: flex-start;
      background: #ffffff;
      color: #0f172a;
      border-top-left-radius: 0;
    }
    .bubble-widget.outgoing {
      align-self: flex-end;
      background: var(--msg-outgoing);
      color: #0f172a;
      border-top-right-radius: 0;
    }

    .bubble-meta-widget {
      display: flex;
      align-items: center;
      justify-content: flex-end;
      gap: 0.25rem;
      font-size: 0.625rem;
      color: #64748b;
      align-self: flex-end;
      margin-top: 0.2rem;
    }

    .tick-widget { font-weight: 600; }
    .tick-widget.read { color: #53bdeb; }

    .voice-player-container {
      display: flex;
      align-items: center;
      gap: 0.6rem;
      padding: 0.4rem 0.5rem;
      background: rgba(0, 0, 0, 0.03);
      border-radius: 12px;
      min-width: 210px;
      max-width: 250px;
      margin-top: 0.2rem;
      user-select: none;
    }

    .bubble-widget.outgoing .voice-player-container {
      background: rgba(0, 0, 0, 0.04);
    }

    .voice-play-btn {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: var(--primary);
      border: none;
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.25, 0.8, 0.25, 1);
      box-shadow: 0 1px 3px rgba(0,0,0,0.12);
      flex-shrink: 0;
    }
    .voice-play-btn:hover {
      transform: scale(1.06);
      background: var(--primary-hover);
    }
    .voice-play-btn:active {
      transform: scale(0.96);
    }

    .voice-waveform-wrapper {
      display: flex;
      flex-direction: column;
      gap: 0.15rem;
      flex: 1;
      min-width: 0;
    }

    .voice-waveform {
      display: flex;
      align-items: center;
      gap: 2px;
      height: 18px;
      flex: 1;
    }

    .waveform-bar {
      flex: 1;
      background: #cbd5e1;
      border-radius: 1px;
      transition: background 0.15s ease;
      height: 60%;
    }
    .bubble-widget.outgoing .waveform-bar {
      background: #a3e4d7;
    }
    .waveform-bar.active {
      background: var(--primary);
    }
    .bubble-widget.outgoing .waveform-bar.active {
      background: #005a49;
    }

    .voice-time {
      font-size: 0.65rem;
      color: #64748b;
      font-weight: 500;
    }

    .input-bar-widget {
      padding: 0.5rem 0.75rem;
      padding-bottom: max(0.5rem, calc(0.5rem + env(safe-area-inset-bottom, 0px)));
      background: #f0f2f5;
      border-top: 1px solid #e2e8f0;
      display: flex;
      gap: 0.5rem;
      align-items: center;
      flex-shrink: 0;
      width: 100%;
      box-sizing: border-box;
      position: relative;
      z-index: 10;
    }

    .input-bar-widget input {
      flex: 1 1 0%;
      min-width: 0;
      border: 1px solid transparent;
      padding: 0.5rem 0.75rem;
      border-radius: 20px;
      font-size: 0.85rem;
      background: white;
      outline: none;
      color: #0f172a;
      box-sizing: border-box;
    }

    .btn-widget {
      background: var(--primary);
      color: white;
      border: none;
      border-radius: 50%;
      width: 38px;
      height: 38px;
      min-width: 38px;
      min-height: 38px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      flex-shrink: 0;
      padding: 0;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 2px 5px rgba(0, 128, 105, 0.25);
    }
    .btn-widget:hover {
      background: var(--primary-hover);
      transform: scale(1.08);
      box-shadow: 0 4px 10px rgba(0, 128, 105, 0.35);
    }
    .btn-widget:active {
      transform: scale(0.92);
    }

    .btn-widget-icon {
      background: white;
      color: #64748b;
      border: 1px solid #cbd5e1;
      border-radius: 50%;
      width: 38px;
      height: 38px;
      min-width: 38px;
      min-height: 38px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 1rem;
      flex-shrink: 0;
      padding: 0;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
    }
    .btn-widget-icon:hover {
      background: #f1f5f9;
      transform: scale(1.08);
      border-color: var(--primary);
      box-shadow: 0 3px 8px rgba(0, 0, 0, 0.1);
    }
    .btn-widget-icon:active {
      transform: scale(0.92);
    }
    .btn-widget-icon img {
      width: 21px;
      height: 21px;
      transition: transform 0.2s ease;
    }
    .btn-widget-icon:hover img {
      transform: scale(1.08);
    }

    .presence-online {
      color: var(--status-online);
      font-weight: 600;
    }
    .presence-offline {
      color: #94a3b8;
    }

    .action-tab-btn {
      flex: 1;
      background: white;
      border: 1px solid #cbd5e1;
      border-radius: 20px;
      padding: 0.45rem 0.75rem;
      font-size: 0.78rem;
      font-weight: 600;
      color: #334155;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0.35rem;
      transition: all 0.2s ease;
      box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }
    .action-tab-btn:hover {
      border-color: var(--primary);
      color: var(--primary);
      background: rgba(0, 128, 105, 0.04);
      transform: translateY(-1px);
    }
    .action-tab-btn img {
      width: 16px;
      height: 16px;
      object-fit: contain;
      flex-shrink: 0;
      transition: transform 0.2s ease;
    }
    .action-tab-btn:hover img {
      transform: scale(1.1);
    }
    .action-tab-btn img {
      width: 15px;
      height: 15px;
      object-fit: contain;
      flex-shrink: 0;
      transition: transform 0.2s ease;
    }
    .action-tab-btn:hover img {
      transform: scale(1.1);
    }

    .btn-amount-pre {
      flex: 1;
      background: #f1f5f9;
      border: 1px solid #cbd5e1;
      border-radius: 6px;
      padding: 0.3rem 0;
      font-size: 0.72rem;
      font-weight: 600;
      color: #334155;
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .btn-amount-pre:hover {
      background: var(--primary);
      border-color: var(--primary);
      color: white;
    }

    .quick-form-overlay {
      position: absolute;
      inset: 0;
      background: rgba(15, 23, 42, 0.55);
      backdrop-filter: blur(4px);
      -webkit-backdrop-filter: blur(4px);
      z-index: 150;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      animation: widgetFadeIn 0.25s ease-out;
      overflow: hidden;
      box-sizing: border-box;
    }

    .quick-form-card {
      width: 100%;
      background: white;
      border-top-left-radius: 18px;
      border-top-right-radius: 18px;
      box-shadow: 0 -8px 30px rgba(0,0,0,0.2);
      animation: widgetSlideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      display: flex;
      flex-direction: column;
      max-height: 88%;
      max-height: 88dvh;
      min-height: 0;
      overflow: hidden;
      box-sizing: border-box;
    }

    @keyframes widgetFadeIn { from { opacity: 0; } to { opacity: 1; } }
    @keyframes widgetSlideUp { from { transform: translateY(100%); } to { transform: translateY(0); } }

    .quick-form-header {
      padding: 0.75rem 1rem;
      border-bottom: 1px solid #e2e8f0;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-weight: 700;
      font-size: 0.85rem;
      color: #0f172a;
      flex-shrink: 0;
    }

    .quick-form-close-btn {
      background: none;
      border: none;
      font-size: 1.25rem;
      color: #64748b;
      cursor: pointer;
      line-height: 1;
      padding: 0.2rem;
    }
    .quick-form-close-btn:hover { color: #0f172a; }

    .quick-form-body {
      padding: 1rem 1rem calc(1rem + env(safe-area-inset-bottom, 0px));
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
      overscroll-behavior-y: contain;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
      min-height: 0;
      flex: 1 1 auto;
      box-sizing: border-box;
    }

    .quick-form-field {
      display: flex;
      flex-direction: column;
      gap: 0.3rem;
    }
    .quick-form-field label {
      font-size: 0.68rem;
      font-weight: 700;
      color: #64748b;
      text-transform: uppercase;
      letter-spacing: 0.02em;
    }
    .quick-form-field input, .quick-form-field select, .quick-form-field textarea {
      padding: 0.5rem 0.75rem;
      border-radius: 8px;
      border: 1px solid #cbd5e1;
      font-size: 0.8rem;
      outline: none;
      font-family: inherit;
    }
    .quick-form-field input:focus, .quick-form-field select:focus, .quick-form-field textarea:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 2px rgba(0, 128, 105, 0.1);
    }
    .quick-form-submit-btn {
      background: var(--primary);
      color: white;
      border: none;
      border-radius: 8px;
      padding: 0.65rem;
      font-weight: 700;
      font-size: 0.85rem;
      cursor: pointer;
      margin-top: 0.5rem;
      margin-bottom: 0.25rem;
      flex-shrink: 0;
      min-height: 42px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: background 0.2s;
    }
    .quick-form-submit-btn:hover { background: var(--primary-hover); }

    .qr-loader-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 1.5rem 1rem;
      gap: 0.75rem;
      color: #64748b;
      font-size: 0.8rem;
      font-weight: 500;
    }
    .qr-spinner {
      width: 32px;
      height: 32px;
      border: 3px solid #f1f5f9;
      border-top: 3px solid var(--primary);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    .widget-btn-text {
      display: inline;
    }
    .widget-btn-icon-only {
      display: none;
    }

    @media (max-width: 768px) {
      .chat-drawer {
        width: 100% !important;
        max-width: 100vw !important;
        height: 100vh !important;
        height: 100dvh !important;
        border-radius: 0 !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
      }
      .input-bar-widget {
        padding: 0.45rem 0.5rem max(0.45rem, calc(0.45rem + env(safe-area-inset-bottom, 0px))) !important;
        gap: 0.35rem !important;
        width: 100% !important;
        box-sizing: border-box !important;
      }
      .input-bar-widget input {
        padding: 0.45rem 0.6rem !important;
        font-size: 0.825rem !important;
        min-width: 0 !important;
        flex: 1 1 0% !important;
      }
      .quick-form-card {
        max-height: 92% !important;
        max-height: 92dvh !important;
        border-top-left-radius: 16px !important;
        border-top-right-radius: 16px !important;
      }
      .quick-form-body {
        padding: 0.85rem 0.85rem max(1.25rem, calc(1.25rem + env(safe-area-inset-bottom, 0px))) !important;
        gap: 0.65rem !important;
      }
      .quick-form-submit-btn {
        padding: 0.7rem !important;
        font-size: 0.85rem !important;
        min-height: 44px !important;
      }
      .btn-widget {
        width: 36px !important;
        height: 36px !important;
        min-width: 36px !important;
        min-height: 36px !important;
        padding: 0 !important;
        flex-shrink: 0 !important;
      }
      .btn-widget-icon {
        width: 36px !important;
        height: 36px !important;
        min-width: 36px !important;
        min-height: 36px !important;
        font-size: 0.9rem !important;
        flex-shrink: 0 !important;
      }
      .btn-widget-icon img {
        width: 20px !important;
        height: 20px !important;
      }
      .action-tab-btn {
        padding: 0.4rem 0.6rem !important;
        gap: 0.35rem !important;
        font-size: 0.75rem !important;
      }
    }

    .prepend-anim-class {
      animation: messagePrependEntry 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
    }

    @keyframes messagePrependEntry {
      from {
        opacity: 0;
        transform: translateY(-10px) scale(0.98);
      }
      to {
        opacity: 1;
        transform: translateY(0) scale(1);
      }
    }

    .older-messages-loader {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 8px;
      width: 100%;
      height: 32px;
      box-sizing: border-box;
    }

    .older-spinner {
      width: 16px;
      height: 16px;
      border: 2px solid #cbd5e1;
      border-top: 2px solid var(--primary);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    .image-loader-container {
      position: relative;
      max-width: 100%;
      max-height: 200px;
      min-width: 150px;
      min-height: 100px;
      border-radius: 8px;
      overflow: hidden;
      background: #f1f5f9;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-top: 4px;
    }
    
    .image-loader-spinner {
      width: 24px;
      height: 24px;
      border: 3px solid #cbd5e1;
      border-top: 3px solid var(--primary);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      position: absolute;
      z-index: 2;
    }

    .image-loader-container img {
      max-width: 100%;
      max-height: 200px;
      display: block;
      cursor: pointer;
      opacity: 0;
      transition: opacity 0.3s ease;
      z-index: 1;
    }

    .image-loader-container.sending img {
      opacity: 0.65;
    }
  `;
  document.head.appendChild(styleEl);

  // 2. Inject HTML Structure
  const drawerContainer = document.createElement('div');
  drawerContainer.id = 'chatDrawer';
  drawerContainer.className = 'chat-drawer';
  drawerContainer.innerHTML = `
    <!-- Widget Header -->
    <div class="widget-header">
      <div style="display: flex; align-items: center; gap: 0.55rem; min-width: 0;">
        <div id="widgetHeaderAvatar" class="widget-avatar" style="display: none;"></div>
        <div id="widgetHeaderDefaultIcon" style="display: flex; align-items: center;">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" xmlns="http://www.w3.org/2000/svg" style="vertical-align: middle;">
            <path d="M12 2C6.477 2 2 6.03 2 11c0 2.885 1.512 5.454 3.908 7.117L5 21l3.545-1.182C9.563 20.082 10.76 20.2 12 20.2c5.523 0 10-4.03 10-9.2C22 6.03 17.523 2 12 2z" fill="rgba(255,255,255,0.2)"/>
            <path d="M12 3c-4.97 0-9 3.582-9 8 0 2.502 1.34 4.743 3.447 6.136l-.603 1.808 2.373-.79C9.135 18.528 10.536 18.7 12 18.7c4.97 0 9-3.582 9-8s-4.03-8-9-8zm0-2c6.075 0 11 4.477 11 10s-4.925 10-11 10a11.187 11.187 0 01-4.71-.976L3.5 22.5l1.096-3.288A9.742 9.742 0 011 11c0-5.523 4.925-10 11-10z" fill="#ffffff"/>
            <circle cx="8" cy="11" r="1.5" fill="#ffffff"/>
            <circle cx="12" cy="11" r="1.5" fill="#ffffff"/>
            <circle cx="16" cy="11" r="1.5" fill="#ffffff"/>
          </svg>
        </div>
        <div style="display: flex; flex-direction: column; min-width: 0; line-height: 1.2;">
          <span id="widgetHeaderTitleText" style="font-weight: 700; font-size: 0.875rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Support Center</span>
          <span id="presenceIndicator" style="font-size: 0.68rem; font-weight: 500; display: none;" class="presence-offline">offline</span>
        </div>
      </div>
      <div class="widget-header-actions" style="display: flex; gap: 0.45rem; align-items: center; flex-shrink: 0;">
        <button id="btnWidgetBack" class="btn-header-action" style="display:none;" onclick="goBackToConvoList()" title="Back to Chats">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
          </svg>
        </button>
        <button class="btn-header-close" onclick="toggleChatDrawer(false)" title="Close Chat">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      </div>
    </div>

    <!-- Content area of the widget -->
    <div class="widget-content">
      <div id="drawerChatView" class="widget-chat-container">
        <!-- Conversation List -->
        <div id="widgetConvoList" class="convo-list-widget">
          <div style="padding:2rem; text-align:center; color:#64748b; font-size:0.8rem;">
            Loading active chats...
          </div>
        </div>

        <!-- Selected Active Chat -->
        <div id="widgetActiveChat" class="active-chat-widget" style="display: none; position: relative;">
          <!-- Quick Action Buttons -->
          <div class="quick-actions-bar" style="display: flex; gap: 0.4rem; padding: 0.35rem 0.65rem; background: #f8fafc; border-bottom: 1px solid #e2e8f0; flex-shrink: 0;">
            <button class="action-tab-btn" onclick="openQuickForm('deposit')"><img src="/chat/view/images/recharge_icon.svg" alt="Recharge" /> <span class="widget-btn-text">Recharge</span></button>
            <button class="action-tab-btn" onclick="openQuickForm('issue')"><img src="/chat/view/images/withdraw_icon.svg" alt="Withdraw" /> <span class="widget-btn-text">Withdraw</span></button>
          </div>

          <div id="widgetMessages" class="messages-widget">
            <!-- Messages go here -->
          </div>

          <div class="input-bar-widget">
            <input type="text" id="widgetMsgInput" placeholder="Type a message..." />
            <button class="btn-widget" onclick="sendWidgetText()" title="Send Message">
              <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" style="transform: rotate(-30deg) translate(1px, 0px);">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
              </svg>
            </button>
            <button class="btn-widget-icon" onclick="sendWidgetVoice()" title="Send Voice Simulation" style="display: inline-flex; align-items: center; justify-content: center;"><img src="/chat/view/images/mic.svg?v=2" style="width: 21px; height: 21px;" /></button>
            <button class="btn-widget-icon" onclick="sendWidgetImage()" title="Send Image" style="display: inline-flex; align-items: center; justify-content: center;"><img src="/chat/view/images/image.svg?v=2" style="width: 21px; height: 21px;" /></button>
            <input type="file" id="widgetImageFileInput" accept="image/*" style="display:none" onchange="uploadWidgetImage(this.files[0])" />
          </div>

          <!-- Quick Form Overlay -->
          <div id="quickFormOverlay" class="quick-form-overlay" style="display: none;">
            <div class="quick-form-card">
              <div class="quick-form-header">
                <span id="quickFormTitle">Quick Form</span>
                <button class="quick-form-close-btn" onclick="closeQuickForm()">×</button>
              </div>
              <div class="quick-form-body">
                <!-- Injected Form Fields -->
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  document.body.appendChild(drawerContainer);

  // 3. Client Logic Setup
  let socket = null;
  let currentToken = '';
  let currentUser = null;
  let activeConversation = null;
  let seedData = null;
  let presenceInterval = null;
  let messagesHasMore = false;
  let messagesNextCursor = null;
  let isLoadingOlder = false;
  let messagesObserver = null;

  function getAvatarColor(name) {
    const colors = ['#f56565', '#ed8936', '#ecc94b', '#48bb78', '#38b2ac', '#4299e1', '#667eea', '#9f7aea', '#ed64a6'];
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = name.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }

  function getInitials(name) {
    if (!name) return '?';
    const parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  function formatTime(seconds) {
    if (isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  function formatMessageText(text) {
    if (!text) return '';
    let escaped = text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
    escaped = escaped.replace(/\*(.*?)\*/g, '<strong>$1</strong>');
    escaped = escaped.replace(/\n/g, '<br>');
    return escaped;
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function escapeHtmlAttr(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function getApiUrl(url) {
    if (!url) return '';
    const origin = window.location.origin;
    let finalUrl = url;
    const cleanUrl = url.startsWith('/') ? url : '/' + url;
    if (cleanUrl.startsWith('/chat/api/v1')) {
      finalUrl = origin + cleanUrl;
    } else if (cleanUrl.startsWith('/api/v1')) {
      finalUrl = origin + '/chat' + cleanUrl;
    } else if (cleanUrl.startsWith('/chat/uploads') || cleanUrl.startsWith('/uploads')) {
      finalUrl = origin + (cleanUrl.startsWith('/chat') ? cleanUrl : '/chat' + cleanUrl);
    } else {
      finalUrl = origin + '/chat/api/v1' + cleanUrl;
    }
    console.log('[Widget API]', finalUrl);
    return finalUrl;
  }

  function formatAvatarUrl(url) {
    if (!url || url === 'null' || url === 'undefined') return '';
    let clean = String(url).trim();
    clean = clean.replace(/^https?:\/\/(www\.)?(office-manage|fairbizcrm\.com|telewiz\.in)\/?/i, '/');
    clean = clean.replace(/^\/\/(office-manage|fairbizcrm\.com|telewiz\.in)\/?/i, '/');

    // Detect direct image filename (e.g. 1784376403_Agency.jpg) without folder path
    const stripped = clean.replace(/^\/+/, '');
    if (!stripped.includes('/') && /\.(jpe?g|png|webp|gif|avif|bmp|svg)$/i.test(stripped)) {
      clean = 'uploads/photos/' + stripped;
    } else if (clean.startsWith('photos/')) {
      clean = 'uploads/' + clean;
    }

    if (clean.startsWith('uploads/')) {
      clean = '/' + clean;
    }
    if (clean.startsWith('/') && !clean.startsWith('//')) {
      clean = window.location.origin + clean;
    }
    return clean;
  }

  function getActivePartner(conv) {
    if (!conv || !currentUser) return null;
    const isStaff = currentUser.role === 'agent' || currentUser.role === 'admin';
    if (isStaff) {
      return conv.emailId || conv.participant2Details || conv.participant2;
    } else {
      return conv.agentId || conv.participant1Details || conv.participant1;
    }
  }

  function isMsgForActiveConv(msg, activeConv) {
    if (!msg || !activeConv) return false;

    if (msg.conversationId && activeConv._id && String(msg.conversationId) === String(activeConv._id)) {
      return true;
    }

    const p1 = activeConv.participant1Details || activeConv.participant1;
    const p2 = activeConv.participant2Details || activeConv.participant2;
    const ag = activeConv.agentIdDetails || activeConv.agentId;
    const em = activeConv.emailIdDetails || activeConv.emailId;

    const allPartnerIds = new Set();

    [p1, p2, ag, em, activeConv.participant1, activeConv.participant2].forEach(p => {
      if (!p) return;
      if (typeof p === 'string' || typeof p === 'number') {
        allPartnerIds.add(String(p).toLowerCase());
      } else if (typeof p === 'object') {
        if (p._id) allPartnerIds.add(String(p._id).toLowerCase());
        if (p.emailId) allPartnerIds.add(String(p.emailId).toLowerCase());
        if (p.email) allPartnerIds.add(String(p.email).toLowerCase());
        if (p.id) {
          allPartnerIds.add(String(p.id).toLowerCase());
          allPartnerIds.add(`agency-${p.id}`.toLowerCase());
          allPartnerIds.add(`admin-${p.id}`.toLowerCase());
        }
        if (p.agency_id) {
          allPartnerIds.add(String(p.agency_id).toLowerCase());
          allPartnerIds.add(`agency-${p.agency_id}`.toLowerCase());
        }
      }
    });

    if (currentUser) {
      const myUserIds = [currentUser._id, currentUser.emailId, currentUser.id];
      if (currentUser.role === 'agent' || currentUser.role === 'admin') {
        myUserIds.push(currentUser.agentId);
      }
      myUserIds.forEach(myId => {
        if (myId) allPartnerIds.delete(String(myId).toLowerCase());
      });
    }

    const senderStr = String(msg.senderId || '').toLowerCase();
    const recipStr = String(msg.recipientId || '').toLowerCase();
    const convIdStr = String(msg.conversationId || '').toLowerCase();

    for (const pid of allPartnerIds) {
      if (!pid) continue;
      if (senderStr === pid || recipStr === pid) return true;
      if (senderStr.includes(pid) || recipStr.includes(pid)) return true;
      if (convIdStr.includes(pid)) return true;
    }

    return false;
  }

  // Socket Connection
  function connectWebsocket() {
    if (socket) socket.disconnect();
    if (presenceInterval) clearInterval(presenceInterval);

    socket = io({
      auth: { token: currentToken },
      transports: ['websocket', 'polling']
    });

    socket.on('connect', () => {
      console.log('Socket connected successfully in widget');
      loadConversations();
    });

    socket.on('connect_error', (err) => {
      console.error('Socket connected error in widget:', err.message);
    });

    socket.on('message:new', (msg) => {
      if (!msg) return;
      const isStaff = currentUser?.role === 'agent' || currentUser?.role === 'admin';
      const myIds = [currentUser._id, currentUser.emailId, isStaff ? currentUser.agentId : null].filter(Boolean);
      const isSentByMe = myIds.some(id => String(id) === String(msg.senderId));
      if (isSentByMe) return;

      const isChatOpen = document.getElementById('chatDrawer').classList.contains('open');
      const isMatchingConv = isMsgForActiveConv(msg, activeConversation);
      if (isChatOpen && activeConversation && isMatchingConv) {
        if (msg.conversationId) activeConversation._id = msg.conversationId;
        if (activeConversation.isVirtual) activeConversation.isVirtual = false;
        appendMessageBubble(msg);
        socket.emit('message:read', {
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          messageIds: [msg._id]
        });
      } else {
        socket.emit('message:delivered', {
          messageId: msg._id,
          conversationId: msg.conversationId,
          senderId: msg.senderId
        });
      }
      loadConversations();
    });

    socket.on('message:sent', (data) => {
      updateTick(data._id || data.messageId, 'sent');
    });

    socket.on('message:delivered', (data) => {
      updateTick(data.messageId, 'delivered');
    });

    socket.on('message:read', (data) => {
      updateTick(null, 'read');
    });

    socket.on('presence:res', (res) => {
      const presenceIndicator = document.getElementById('presenceIndicator');
      if (presenceIndicator && activeConversation) {
        const partner = getActivePartner(activeConversation);
        const targetIds = [
          partner?._id,
          partner?.emailId,
          partner?.email,
          typeof partner === 'string' ? partner : null
        ].filter(Boolean).map(id => String(id).toLowerCase());

        const isMatch = res && res.emailId && (
          targetIds.includes(String(res.emailId).toLowerCase()) ||
          (res.targetId && targetIds.includes(String(res.targetId).toLowerCase()))
        );

        if (isMatch) {
          if (res.isOnline) {
             presenceIndicator.className = 'presence-online';
             presenceIndicator.textContent = 'online';
          } else {
             presenceIndicator.className = 'presence-offline';
             presenceIndicator.textContent = 'offline';
          }
        }
      }
    });
  }

  function getPartnerDisplayName(partner) {
    if (!partner) return 'Support Agent';
    let name = (typeof partner === 'object' && partner !== null) ? (partner.name || partner.emailId) : partner;
    if (name && typeof name === 'string' && isNaN(name) && !name.toUpperCase().startsWith('AGENCY-') && !name.toUpperCase().startsWith('ADMIN-')) {
      return name;
    }
    const pStr = String(name || (typeof partner === 'object' ? partner._id : partner) || '');
    if (pStr === '1' || pStr.toUpperCase().includes('ADMIN')) {
      return 'Admin Support';
    }
    if (pStr.toUpperCase().includes('AGENCY') || /^\d+$/.test(pStr)) {
      return 'Agency Support';
    }
    return 'Support Agent';
  }

  // Load Conversations List
  function goBackToConvoList() {
    activeConversation = null;
    if (presenceInterval) {
      clearInterval(presenceInterval);
      presenceInterval = null;
    }
    const presenceIndicator = document.getElementById('presenceIndicator');
    if (presenceIndicator) {
      presenceIndicator.style.display = 'none';
    }
    document.getElementById('widgetActiveChat').style.display = 'none';
    document.getElementById('widgetConvoList').style.display = 'block';
    document.getElementById('btnWidgetBack').style.display = 'none';
    document.getElementById('widgetHeaderTitleText').textContent = 'Support Center';

    const widgetHeaderAvatar = document.getElementById('widgetHeaderAvatar');
    const widgetHeaderDefaultIcon = document.getElementById('widgetHeaderDefaultIcon');
    if (widgetHeaderAvatar && widgetHeaderDefaultIcon) {
      widgetHeaderAvatar.style.display = 'none';
      widgetHeaderDefaultIcon.style.display = 'flex';
    }
  }

  async function loadConversations() {
    try {
      const res = await fetch(getApiUrl('/api/v1/conversations'), {
        headers: { Authorization: `Bearer ${currentToken}` }
      });
      const data = await res.json();
      let list = data.conversations || [];

      // Seed a virtual conversation if the user has an assigned agent and no existing conversation with them
      if (currentUser && currentUser.role === 'user') {
        const assignedAgentId = currentUser.agentId || (currentUser.agency_id ? `AGENCY-${currentUser.agency_id}` : null);
        if (assignedAgentId) {
          const hasConvoWithAgent = list.some(c => {
            const partner = c.agentId;
            const partnerId = partner?._id || partner?.emailId || partner;
            const partnerNum = partner?.id ? String(partner.id) : null;
            return partnerId === assignedAgentId || 
                   (partnerNum && String(assignedAgentId).includes(partnerNum)) ||
                   (typeof partnerId === 'string' && partnerId.includes(String(assignedAgentId)));
          });
          if (!hasConvoWithAgent) {
            const defaultLabel = getPartnerDisplayName(assignedAgentId);
            list.push({
              _id: `conv-${assignedAgentId}-${currentUser._id}`,
              agentId: {
                _id: assignedAgentId,
                name: defaultLabel,
                avatar: ''
              },
              emailId: currentUser,
              isVirtual: true,
              lastMessageAt: new Date(0).toISOString()
            });
          }
        }
      }

      list.sort((a, b) => new Date(b.lastMessageAt) - new Date(a.lastMessageAt));

      const convoListEl = document.getElementById('widgetConvoList');
      convoListEl.innerHTML = '';

      if (list.length > 0) {
        list.forEach(conv => {
          const partner = getActivePartner(conv);
          const partnerName = getPartnerDisplayName(partner);
          const initials = getInitials(partnerName);
          const avatarColor = getAvatarColor(partnerName);
          
          const isVirtual = conv.isVirtual;
          const lastMsg = isVirtual ? 'Start a new conversation' : 'View chat history';

          const formattedAvatar = formatAvatarUrl(partner?.avatar);
          const safeAvatar = (formattedAvatar || '').replace(/"/g, '&quot;');
          const safeName = (partnerName || '').replace(/"/g, '&quot;');
          const hasAvatar = Boolean(formattedAvatar);
          const avatarHtml = hasAvatar 
            ? `<img class="avatar-widget" src="${safeAvatar}" alt="${safeName}" onerror="this.onerror=null; this.outerHTML='<div class=&quot;avatar-widget&quot; style=&quot;background: ${avatarColor};&quot;>${initials}</div>';" style="object-fit: cover; border-radius: 50%; width: 36px; height: 36px;" />`
            : `<div class="avatar-widget" style="background:${avatarColor};">${initials}</div>`;

          const item = document.createElement('div');
          item.className = 'conv-item-widget';
          item.innerHTML = `
            ${avatarHtml}
            <div class="conv-info-widget">
              <div class="conv-name-widget">${partnerName}</div>
              <div class="conv-meta-widget ${isVirtual ? 'virtual' : ''}">${lastMsg}</div>
            </div>
          `;
          item.onclick = () => selectConversation(conv);
          convoListEl.appendChild(item);
        });
      } else {
        convoListEl.innerHTML = '<div style="padding:2rem; text-align:center; color:#64748b; font-size:0.8rem;">No contacts found.</div>';
      }
    } catch (err) {
      console.error('Load Conversations Error:', err.message);
    }
  }

  // Select Conversation
  function selectConversation(conv) {
    activeConversation = conv;
    const partner = getActivePartner(conv);
    const partnerName = getPartnerDisplayName(partner);
    const partnerId = partner?._id || partner;

    document.getElementById('widgetConvoList').style.display = 'none';
    document.getElementById('widgetActiveChat').style.display = 'flex';
    document.getElementById('btnWidgetBack').style.display = 'inline-flex';
    document.getElementById('widgetHeaderTitleText').textContent = partnerName;

    const widgetHeaderAvatar = document.getElementById('widgetHeaderAvatar');
    const widgetHeaderDefaultIcon = document.getElementById('widgetHeaderDefaultIcon');
    if (widgetHeaderAvatar && widgetHeaderDefaultIcon) {
      widgetHeaderAvatar.style.display = 'flex';
      widgetHeaderAvatar.textContent = getInitials(partnerName);
      widgetHeaderAvatar.style.backgroundColor = getAvatarColor(partnerName);
      widgetHeaderDefaultIcon.style.display = 'none';
    }

    const presenceIndicator = document.getElementById('presenceIndicator');
    if (presenceIndicator) {
      presenceIndicator.style.display = 'inline';
      presenceIndicator.textContent = 'checking...';
      presenceIndicator.className = 'presence-offline';
    }

    const msgEl = document.getElementById('widgetMessages');
    msgEl.innerHTML = '';

    if (conv.isVirtual) {
      msgEl.innerHTML = `
        <div style="margin:auto; text-align:center; color:#64748b; padding:1.5rem; font-size:0.75rem;">
          <div>👋</div>
          <strong>New Matchmaking Session</strong>
          <p style="margin-top:0.35rem; line-height:1.4;">Send a text message to boot history in MongoDB.</p>
        </div>
      `;
    } else {
      fetchMessages();
      if (socket && socket.connected) {
        socket.emit('message:read', {
          conversationId: conv._id,
          senderId: partnerId
        });
      }
    }

    if (presenceInterval) clearInterval(presenceInterval);
    presenceInterval = setInterval(() => checkPresence(partner), 8000);
    checkPresence(partner);
  }

  function checkPresence(target) {
    if (!socket || !socket.connected || !target) return;
    const targetId = typeof target === 'object' ? (target._id || target.emailId || target.email) : target;
    if (targetId) {
      socket.emit('presence:check', { emailId: targetId });
    }
  }

  async function fetchMessages() {
    if (!activeConversation || activeConversation.isVirtual) return;
    try {
      const res = await fetch(getApiUrl(`/api/v1/conversations/${activeConversation._id}/messages?limit=20`), {
        headers: { Authorization: `Bearer ${currentToken}` }
      });
      const data = await res.json();
      
      const msgEl = document.getElementById('widgetMessages');
      
      // Inject sentinel and loader at the top
      msgEl.innerHTML = `
        <div id="widgetMessagesSentinel" style="height: 1px; width: 100%;"></div>
        <div id="widgetMessagesOlderLoader" class="older-messages-loader" style="display: none;">
          <div class="older-spinner"></div>
        </div>
      `;

      messagesHasMore = data.hasMore || false;
      messagesNextCursor = data.nextCursor || null;
      isLoadingOlder = false;

      if (data.messages && data.messages.length > 0) {
        const sorted = [...data.messages].reverse();
        sorted.forEach(msg => appendMessageBubble(msg));
      } else {
        const emptyDiv = document.createElement('div');
        emptyDiv.style.margin = 'auto';
        emptyDiv.style.fontSize = '0.75rem';
        emptyDiv.style.color = '#64748b';
        emptyDiv.textContent = 'No messages yet.';
        msgEl.appendChild(emptyDiv);
      }
      msgEl.scrollTop = msgEl.scrollHeight;
      
      setupSentinelObserver();
    } catch (err) {
      console.error('Fetch messages error:', err);
    }
  }

  async function loadOlderMessages() {
    if (!activeConversation || isLoadingOlder || !messagesHasMore || !messagesNextCursor) return;
    
    const msgEl = document.getElementById('widgetMessages');
    const loader = document.getElementById('widgetMessagesOlderLoader');
    if (!msgEl) return;

    isLoadingOlder = true;
    if (loader) loader.style.display = 'flex';

    try {
      const res = await fetch(getApiUrl(`/api/v1/conversations/${activeConversation._id}/messages?limit=20&cursor=${messagesNextCursor}`), {
        headers: { Authorization: `Bearer ${currentToken}` }
      });
      const data = await res.json();

      messagesHasMore = data.hasMore || false;
      messagesNextCursor = data.nextCursor || null;

      if (data.messages && data.messages.length > 0) {
        const oldScrollHeight = msgEl.scrollHeight;
        
        // Loop through messages and prepend them
        const sorted = [...data.messages].reverse();
        sorted.forEach(msg => appendMessageBubble(msg, true));

        // Anchor scroll position to prevent layout shifts
        msgEl.scrollTop = msgEl.scrollHeight - oldScrollHeight;
      }
    } catch (err) {
      console.error('Error loading older messages:', err);
    } finally {
      isLoadingOlder = false;
      if (loader) loader.style.display = 'none';
    }
  }

  function setupSentinelObserver() {
    const sentinel = document.getElementById('widgetMessagesSentinel');
    const container = document.getElementById('widgetMessages');
    if (!sentinel || !container) return;

    if (messagesObserver) {
      messagesObserver.disconnect();
    }

    messagesObserver = new IntersectionObserver(async (entries) => {
      const entry = entries[0];
      if (entry.isIntersecting && messagesHasMore && !isLoadingOlder) {
        await loadOlderMessages();
      }
    }, {
      root: container,
      rootMargin: '50px 0px 0px 0px', // Fetch slightly before user hits absolute top
      threshold: 0.1
    });

    messagesObserver.observe(sentinel);
  }

  function createVoicePlayerHtml(msg) {
    const duration = msg.audio?.duration || 0;
    const formattedDuration = formatTime(duration);
    
    let barsHtml = '';
    const msgId = msg._id || 'msg-' + Math.random();
    let hash = 0;
    for (let i = 0; i < msgId.length; i++) {
      hash = msgId.charCodeAt(i) + ((hash << 5) - hash);
    }
    
    const barCount = 26;
    for (let i = 0; i < barCount; i++) {
      const seed = Math.abs(Math.sin(hash + i));
      const height = Math.round(20 + seed * 75);
      barsHtml += `<div class="waveform-bar" style="height:${height}%"></div>`;
    }

    const isSending = msg.status === 'sending';
    const buttonContent = isSending
      ? `<div style="width: 12px; height: 12px; border: 2px solid rgba(0,0,0,0.3); border-top-color: #333; border-radius: 50%; animation: spin 0.7s linear infinite;"></div>`
      : `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M8 5v14l11-7z"/></svg>`;
    const disabledAttr = isSending ? 'disabled' : '';

    return `
      <div class="voice-player-container" id="player-${msg._id}" data-duration="${duration}">
        <button class="voice-play-btn" ${disabledAttr} onclick="playVoiceNote(this, '${msg.audio?.key}', '${msg._id}', ${duration})">
          ${buttonContent}
        </button>
        <div class="voice-waveform-wrapper">
          <div class="voice-waveform">
            ${barsHtml}
          </div>
          <span class="voice-time">${formattedDuration}</span>
        </div>
      </div>
    `;
  }

  function createRechargeCardHtml(msg) {
    const recharge = msg.recharge || {};
    const bookName = recharge.bookName || 'Cricket Book 365';
    const amount = recharge.amount || 0;
    const transactionId = recharge.transactionId || 'N/A';
    const utrNo = recharge.utrNo || '';
    const userId = recharge.userId || 'N/A';
    const proofUrl = recharge.proofImageCdnUrl || recharge.proofImage || '';

    let proofImageHtml = '';
    if (proofUrl) {
      proofImageHtml = `
        <div style="margin-top: 8px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); background: #0f172a; position: relative; height: 110px; cursor: pointer;" onclick="window.open('${escapeHtmlAttr(proofUrl)}', '_blank')">
          <img src="${escapeHtmlAttr(proofUrl)}" alt="Payment Proof" style="width: 100%; height: 100%; object-fit: cover;" />
          <div style="position: absolute; bottom: 0; left: 0; right: 0; background: rgba(0,0,0,0.6); padding: 4px; text-align: center; font-size: 0.65rem; color: #34d399; font-weight: bold;">🔍 Click to View Receipt</div>
        </div>
      `;
    }

    return `
      <div class="recharge-card" style="
        background: #1e293b;
        border-radius: 12px;
        overflow: hidden;
        border: 1px solid rgba(255, 255, 255, 0.1);
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        font-family: 'Inter', sans-serif;
        color: #f8fafc;
        min-width: 230px;
        max-width: 270px;
        margin-top: 4px;
        text-align: left;
      ">
        <div style="
          background: linear-gradient(135deg, #10b981, #059669);
          padding: 8px 12px;
          font-weight: 700;
          font-size: 0.75rem;
          letter-spacing: 0.05em;
          text-transform: uppercase;
          display: flex;
          align-items: center;
          gap: 6px;
        ">
          <img src="/chat/view/images/recharge_icon.svg" alt="Recharge" style="width: 14px; height: 14px; filter: brightness(0) invert(1);" /> Recharge Request
        </div>
        
        <div style="padding: 12px; display: flex; flex-direction: column; gap: 8px;">
          <div style="display: flex; flex-direction: column; gap: 5px; font-size: 0.75rem;">
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">User ID:</span>
              <span style="font-weight: 600; color: #f1f5f9;">${escapeHtml(userId)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">Game Book:</span>
              <span style="font-weight: 600; color: #f1f5f9;">${escapeHtml(bookName)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">Amount:</span>
              <span style="font-weight: 700; color: #34d399; font-size: 0.85rem;">₹${escapeHtml(amount)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">Txn ID:</span>
              <span style="font-weight: 600; color: #f1f5f9; font-family: monospace;">${escapeHtml(transactionId)}</span>
            </div>
            ${utrNo ? `
            <div style="display: flex; justify-content: space-between; padding-bottom: 3px;">
              <span style="color: #94a3b8;">UTR No:</span>
              <span style="font-weight: 600; color: #f1f5f9; font-family: monospace;">${escapeHtml(utrNo)}</span>
            </div>
            ` : ''}
          </div>
          ${proofImageHtml}
        </div>
      </div>
    `;
  }

  function createWithdrawCardHtml(msg) {
    const withdraw = msg.withdraw || {};
    const bookName = withdraw.bookName || 'Unknown Book';
    const amount = withdraw.amount || 0;
    const bankDetails = withdraw.bankDetails || 'N/A';
    const userId = withdraw.userId || 'N/A';
    const transactionId = withdraw.transactionId || withdraw.withdrawalId || 'N/A';
    const proofUrl = withdraw.proofImageCdnUrl || withdraw.proofImage || '';

    let proofImageHtml = '';
    if (proofUrl) {
      proofImageHtml = `
        <div style="margin-top: 8px; border-radius: 8px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1); background: #0f172a; position: relative; height: 110px; cursor: pointer;" onclick="window.open('${escapeHtmlAttr(proofUrl)}', '_blank')">
          <img src="${escapeHtmlAttr(proofUrl)}" alt="QR Code" style="width: 100%; height: 100%; object-fit: cover;" />
          <div style="position: absolute; bottom: 0; left: 0; right: 0; background: rgba(0,0,0,0.6); padding: 4px; text-align: center; font-size: 0.65rem; color: #3b82f6; font-weight: bold;">🔍 Click to View QR Code</div>
        </div>
      `;
    }

    return `
      <div class="withdraw-card" style="
        background: #1e293b;
        border-radius: 12px;
        overflow: hidden;
        border: 1px solid rgba(255, 255, 255, 0.1);
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        font-family: 'Inter', sans-serif;
        color: #f8fafc;
        min-width: 230px;
        max-width: 270px;
        margin-top: 4px;
        text-align: left;
      ">
        <div style="
          background: linear-gradient(135deg, #3b82f6, #1d4ed8);
          padding: 8px 12px;
          font-weight: 700;
          font-size: 0.75rem;
          letter-spacing: 0.05em;
          text-transform: uppercase;
          display: flex;
          align-items: center;
          gap: 6px;
        ">
          <img src="/chat/view/images/withdraw_icon.svg" alt="Withdraw" style="width: 14px; height: 14px; filter: brightness(0) invert(1);" /> Withdraw Request
        </div>
        
        <div style="padding: 12px; display: flex; flex-direction: column; gap: 8px;">
          <div style="display: flex; flex-direction: column; gap: 5px; font-size: 0.75rem;">
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">User ID:</span>
              <span style="font-weight: 600; color: #f1f5f9;">${escapeHtml(userId)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">Game Book:</span>
              <span style="font-weight: 600; color: #f1f5f9;">${escapeHtml(bookName)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">Amount:</span>
              <span style="font-weight: 700; color: #60a5fa; font-size: 0.85rem;">₹${escapeHtml(amount)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; border-bottom: 1px solid rgba(255, 255, 255, 0.05); padding-bottom: 3px;">
              <span style="color: #94a3b8;">Txn ID:</span>
              <span style="font-weight: 600; color: #f1f5f9;">${escapeHtml(transactionId)}</span>
            </div>
            <div style="display: flex; flex-direction: column; gap: 2px;">
              <span style="color: #94a3b8;">Bank Account Details:</span>
              <span style="font-weight: 500; color: #e2e8f0; white-space: pre-wrap; font-size: 0.7rem; background: rgba(0,0,0,0.2); padding: 4px 6px; border-radius: 6px; margin-top: 2px;">${escapeHtml(bankDetails)}</span>
            </div>
          </div>
          ${proofImageHtml}
        </div>
      </div>
    `;
  }

  function appendMessageBubble(msg, prepend = false) {
    const msgEl = document.getElementById('widgetMessages');
    const empty = msgEl.querySelector('div[style*="margin:auto"]');
    if (empty) empty.remove();

    let bubble = msg._id ? msgEl.querySelector(`[data-msg-id="${msg._id}"]`) : null;
    const isNew = !bubble;

    if (isNew) {
      bubble = document.createElement('div');
      if (msg._id) bubble.dataset.msgId = msg._id;
    }

    const isOutgoing = msg.senderId === (currentUser._id || currentUser.emailId);
    bubble.className = `bubble-widget ${isOutgoing ? 'outgoing' : 'incoming'}`;
    if (msg.status === 'sending') {
      bubble.classList.add('sending');
    }

    let tickHtml = '';
    if (isOutgoing) {
      if (msg.status === 'sending') {
        tickHtml = `<span class="tick-widget" style="opacity: 0.5;">⏱</span>`;
      } else {
        const tickClass = msg.status === 'read' ? 'read' : '';
        const tickSymbol = msg.status === 'read' ? '✓✓' : (msg.status === 'delivered' ? '✓✓' : '✓');
        tickHtml = `<span class="tick-widget ${tickClass}">${tickSymbol}</span>`;
      }
    }

    const formattedTime = new Date(msg.createdAt || Date.now()).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});

    let contentHtml = `<div>${formatMessageText(msg.text)}</div>`;
    if (msg.type === 'voice') {
      contentHtml = createVoicePlayerHtml(msg);
    } else if (msg.type === 'image') {
      const isSending = msg.status === 'sending';
      const imageUrl = msg.image?.cdnUrl || msg.image?.key || '';
      if (isSending) {
        contentHtml = `
          <div class="image-loader-container sending">
            <div class="image-loader-spinner"></div>
            <img src="${imageUrl}" alt="Sending..." style="opacity: 1;" />
          </div>
        `;
      } else {
        contentHtml = `
          <div class="image-loader-container">
            <div class="image-loader-spinner"></div>
            <img src="${imageUrl}" alt="Image" onclick="window.open(this.src, '_blank')" style="object-fit: contain; width: 100%; height: 100%;" />
          </div>
        `;
      }
    } else if (msg.type === 'recharge') {
      contentHtml = createRechargeCardHtml(msg);
    } else if (msg.type === 'withdraw') {
      contentHtml = createWithdrawCardHtml(msg);
    }

    let invoiceBtnHtml = '';
    const invoiceUrl = msg.invoiceUrl || msg.invoice_url;
    if (invoiceUrl) {
      invoiceBtnHtml = `
        <div style="margin-top: 6px; padding-top: 4px;">
          <a href="${escapeHtmlAttr(invoiceUrl)}" target="_blank" rel="noopener noreferrer" download style="
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            background: #008069;
            color: #ffffff;
            font-size: 0.75rem;
            font-weight: 600;
            border-radius: 6px;
            text-decoration: none;
            box-shadow: 0 1px 3px rgba(0,0,0,0.12);
            transition: background 0.2s ease;
          " onmouseover="this.style.background='#016b57'" onmouseout="this.style.background='#008069'">
            <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
              <polyline points="7 10 12 15 17 10"></polyline>
              <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            Download Invoice
          </a>
        </div>
      `;
    }

    bubble.innerHTML = `
      ${contentHtml}
      ${invoiceBtnHtml}
      <div class="bubble-meta-widget">
        <span>${formattedTime}</span>
        ${tickHtml}
      </div>
    `;

    // Robust handler to stop image loader spinner
    if (msg.type === 'image') {
      const img = bubble.querySelector('img');
      if (img) {
        const isSending = msg.status === 'sending';
        if (isSending) {
          img.style.opacity = '1';
        } else {
          const handleLoad = () => {
            const spinner = img.previousElementSibling;
            if (spinner && spinner.classList.contains('image-loader-spinner')) {
              spinner.remove();
            }
            img.style.opacity = '1';
            
            const src = msg.image?.cdnUrl || '';
            if (src.startsWith('blob:')) {
              URL.revokeObjectURL(src);
            }
          };
          if (img.complete) {
            handleLoad();
          } else {
            img.onload = handleLoad;
            img.onerror = handleLoad;
          }
        }
      }
    }

    if (isNew) {
      if (prepend) {
        bubble.classList.add('prepend-anim-class');
        const loader = document.getElementById('widgetMessagesOlderLoader');
        if (loader && loader.nextSibling) {
          msgEl.insertBefore(bubble, loader.nextSibling);
        } else {
          msgEl.appendChild(bubble);
        }
      } else {
        msgEl.appendChild(bubble);
        msgEl.scrollTop = msgEl.scrollHeight;
      }
    }
  }

  let currentAudio = null;
  let currentAudioBtn = null;

  async function playVoiceNote(btn, key, msgId, duration) {
    if (!key || key === 'undefined') return alert('Audio file key is missing.');

    const playerContainer = document.getElementById(`player-${msgId}`);
    const bars = playerContainer ? playerContainer.querySelectorAll('.waveform-bar') : [];
    const timeSpan = playerContainer ? playerContainer.querySelector('.voice-time') : null;

    if (currentAudio && currentAudioBtn === btn) {
      if (currentAudio.paused) {
        currentAudio.play();
        btn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>`;
      } else {
        currentAudio.pause();
        btn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M8 5v14l11-7z"/></svg>`;
      }
      return;
    }

    if (currentAudio) {
      currentAudio.pause();
      if (currentAudioBtn) {
        currentAudioBtn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M8 5v14l11-7z"/></svg>`;
        const prevPlayer = currentAudioBtn.closest('.voice-player-container');
        if (prevPlayer) {
          prevPlayer.querySelectorAll('.waveform-bar').forEach(b => b.classList.remove('active'));
          const prevDuration = prevPlayer.getAttribute('data-duration') || '0';
          const prevTimeSpan = prevPlayer.querySelector('.voice-time');
          if (prevTimeSpan) prevTimeSpan.textContent = formatTime(parseFloat(prevDuration));
        }
      }
    }

    btn.innerHTML = `<div style="width: 12px; height: 12px; border: 2px solid rgba(0,0,0,0.3); border-top-color: #333; border-radius: 50%; animation: spin 0.7s linear infinite;"></div>`;
    btn.disabled = true;

    try {
      let audioUrl;
      if (key.startsWith('http') || (key.startsWith('/') && !key.startsWith('/uploads/'))) {
        audioUrl = key;
      } else {
        const res = await fetch(getApiUrl(`/api/v1/voice/play-url?key=${encodeURIComponent(key)}`), {
          headers: { Authorization: `Bearer ${currentToken}` }
        });
        if (!res.ok) throw new Error('Failed to get playback URL');
        const data = await res.json();
        audioUrl = data.url;
        if (audioUrl && audioUrl.startsWith('/')) {
          audioUrl = getApiUrl(audioUrl);
        }
      }

      const audio = new Audio(audioUrl);
      currentAudio = audio;
      currentAudioBtn = btn;
      btn.disabled = false;
      btn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>`;

      audio.play().catch(err => {
        console.error('Audio playback error:', err);
        btn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M8 5v14l11-7z"/></svg>`;
        alert('Could not play audio: ' + err.message);
      });

      audio.ontimeupdate = () => {
        if (!audio.duration) return;
        const progress = audio.currentTime / audio.duration;
        const activeCount = Math.floor(progress * bars.length);
        bars.forEach((bar, idx) => {
          if (idx < activeCount) {
            bar.classList.add('active');
          } else {
            bar.classList.remove('active');
          }
        });
        if (timeSpan) {
          timeSpan.textContent = `${formatTime(audio.currentTime)} / ${formatTime(audio.duration)}`;
        }
      };

      audio.onended = () => {
        btn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M8 5v14l11-7z"/></svg>`;
        bars.forEach(b => b.classList.remove('active'));
        if (timeSpan) timeSpan.textContent = formatTime(duration);
        currentAudio = null;
        currentAudioBtn = null;
      };
    } catch (err) {
      console.error('playVoiceNote error:', err);
      btn.innerHTML = `<svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M8 5v14l11-7z"/></svg>`;
      btn.disabled = false;
      alert('Could not load audio: ' + err.message);
    }
  }

  function updateTick(messageId, status) {
    const msgEl = document.getElementById('widgetMessages');
    const bubbles = msgEl.querySelectorAll('.bubble-widget.outgoing');
    bubbles.forEach(bubble => {
      if (!messageId || bubble.dataset.msgId === messageId) {
        const tick = bubble.querySelector('.tick-widget');
        if (tick) {
          if (status === 'read') {
            tick.textContent = '✓✓';
            tick.classList.add('read');
          } else if (status === 'delivered') {
            tick.textContent = '✓✓';
            tick.classList.remove('read');
          } else if (status === 'sent') {
            tick.textContent = '✓';
            tick.classList.remove('read');
          }
        }
      }
    });
  }

  function goBackToConvoList() {
    activeConversation = null;
    document.getElementById('widgetConvoList').style.display = 'block';
    document.getElementById('widgetActiveChat').style.display = 'none';
    document.getElementById('btnWidgetBack').style.display = 'none';
    document.getElementById('widgetHeaderTitleText').textContent = currentUser ? currentUser.name : 'Support Center';
    
    const widgetHeaderAvatar = document.getElementById('widgetHeaderAvatar');
    const widgetHeaderDefaultIcon = document.getElementById('widgetHeaderDefaultIcon');
    if (widgetHeaderAvatar && widgetHeaderDefaultIcon) {
      widgetHeaderAvatar.style.display = 'none';
      widgetHeaderDefaultIcon.style.display = 'flex';
    }

    const presenceIndicator = document.getElementById('presenceIndicator');
    if (presenceIndicator) {
      presenceIndicator.style.display = 'none';
    }
    if (presenceInterval) clearInterval(presenceInterval);
    loadConversations();
  }

  function getWidgetPartner(conv) {
    if (!conv) return { _id: null, recipientId: null, name: 'Chat Partner' };

    const isStaffUser = currentUser?.role === 'agent' || currentUser?.role === 'admin';
    const myIds = [
      currentUser?._id,
      currentUser?.emailId,
      isStaffUser ? currentUser?.agentId : null,
      currentUser?.id
    ].map(id => id ? String(id) : null).filter(Boolean);

    const p1 = conv.participant1Details?._id || conv.participant1Details?.emailId || conv.participant1;
    const p2 = conv.participant2Details?._id || conv.participant2Details?.emailId || conv.participant2;

    const isP1Me = myIds.some(id => String(id) === String(p1) || String(id) === String(conv.participant1));
    const isP2Me = myIds.some(id => String(id) === String(p2) || String(id) === String(conv.participant2));

    let partnerObj = null;
    if (isP1Me && !isP2Me) {
      partnerObj = conv.participant2Details || conv.emailId || conv.participant2;
    } else if (isP2Me && !isP1Me) {
      partnerObj = conv.participant1Details || conv.agentId || conv.participant1;
    } else {
      const isStaff = currentUser?.role === 'agent' || currentUser?.role === 'admin';
      partnerObj = isStaff ? (conv.emailIdDetails || conv.emailId || conv.participant2) : (conv.agentIdDetails || conv.agentId || conv.participant1);
    }

    if (typeof partnerObj === 'string') {
      partnerObj = { _id: partnerObj, emailId: partnerObj, name: partnerObj };
    }

    const recipientId = partnerObj?._id || partnerObj?.emailId || partnerObj?.id || (typeof partnerObj === 'string' ? partnerObj : null);

    return {
      _id: recipientId,
      recipientId: recipientId,
      name: partnerObj?.name || recipientId || 'Chat Partner',
      avatar: partnerObj?.avatar || ''
    };
  }

  function sendWidgetText() {
    const input = document.getElementById('widgetMsgInput');
    const text = input ? input.value.trim() : '';
    if (!text) return;

    if (!activeConversation) {
      console.error('[Widget Frontend] Cannot send message: No active conversation selected.');
      return alert('Please select a contact/conversation first.');
    }

    if (!socket || !socket.connected) {
      console.error('[Widget Frontend] Cannot send message: WebSocket is not connected.', { socket, connected: socket?.connected });
      return alert('WebSocket connection is not active! Please wait or refresh the page.');
    }

    const partnerInfo = getWidgetPartner(activeConversation);
    const recipientId = partnerInfo.recipientId;

    if (!recipientId) {
      console.error('[Widget Frontend] Cannot determine recipientId for active conversation:', activeConversation);
      return alert('Recipient details are missing for this conversation.');
    }

    const conversationId = activeConversation._id || `conv-${currentUser._id}-${recipientId}`;
    const messageId = 'msg-' + Date.now();

    if (activeConversation.isVirtual) {
      activeConversation.isVirtual = false;
      const msgEl = document.getElementById('widgetMessages');
      if (msgEl) msgEl.innerHTML = '';
    }

    const msgObj = {
      _id: messageId,
      conversationId,
      senderId: currentUser._id || currentUser.emailId,
      senderType: currentUser.role,
      type: 'text',
      text,
      status: 'sent',
      createdAt: new Date()
    };

    appendMessageBubble(msgObj);

    const sendPayload = {
      _id: messageId,
      conversationId,
      recipientId,
      type: 'text',
      text
    };
    console.log('[Widget Frontend] Sending message payload:', sendPayload);
    socket.emit('message:send', sendPayload, (err, res) => {
      if (err) {
        console.error('[Widget Frontend] message:send error response:', err);
      } else {
        console.log('[Widget Frontend] message:send response:', res);
      }
    });

    if (input) input.value = '';
  }

  let widgetMediaRecorder = null;
  let widgetAudioChunks = [];
  let widgetRecordingStartTime = null;
  let widgetIsRecording = false;
  let widgetRecordingTimerInterval = null;

  async function sendWidgetVoice() {
    if (widgetIsRecording) {
      stopWidgetRecordingAndSend();
    } else {
      await startWidgetRecording();
    }
  }

  async function startWidgetRecording() {
    if (!socket || !socket.connected) return alert('Establish websocket connection first!');
    if (!activeConversation) return alert('Select active conversation first!');

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      widgetAudioChunks = [];
      widgetMediaRecorder = new MediaRecorder(stream);
      
      widgetMediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          widgetAudioChunks.push(event.data);
        }
      };

      widgetMediaRecorder.onstop = async () => {
        const audioBlob = new Blob(widgetAudioChunks, { type: 'audio/webm' });
        const duration = Math.round((Date.now() - widgetRecordingStartTime) / 1000);
        stream.getTracks().forEach(track => track.stop());
        
        await uploadWidgetAudioBlob(audioBlob, duration);
      };

      widgetRecordingStartTime = Date.now();
      widgetMediaRecorder.start();
      widgetIsRecording = true;
      
      const voiceBtn = document.querySelector('.btn-widget-icon[onclick="sendWidgetVoice()"]');
      if (voiceBtn) {
        voiceBtn.innerHTML = '🟥';
        voiceBtn.style.background = '#ef4444';
        voiceBtn.style.color = '#ffffff';
      }
      const input = document.getElementById('widgetMsgInput');
      input.placeholder = 'Recording...';
      input.disabled = true;

      let elapsed = 0;
      widgetRecordingTimerInterval = setInterval(() => {
        elapsed++;
        input.placeholder = `Recording (${elapsed}s)...`;
      }, 1000);

    } catch (err) {
      console.error('Error starting audio recording:', err);
      alert('Could not access microphone: ' + err.message);
    }
  }

  function stopWidgetRecordingAndSend() {
    if (widgetMediaRecorder && widgetMediaRecorder.state !== 'inactive') {
      widgetMediaRecorder.stop();
    }
    widgetIsRecording = false;
    clearInterval(widgetRecordingTimerInterval);
    
    const voiceBtn = document.querySelector('.btn-widget-icon[onclick="sendWidgetVoice()"]');
    if (voiceBtn) {
      voiceBtn.innerHTML = '<img src="/chat/view/images/mic.svg?v=2" style="width: 20px; height: 20px;" />';
      voiceBtn.style.background = '';
      voiceBtn.style.color = '';
    }
    const input = document.getElementById('widgetMsgInput');
    input.placeholder = 'Type a message...';
    input.disabled = false;
  }

  async function uploadWidgetAudioBlob(audioBlob, duration) {
    const isStaff = currentUser.role === 'agent' || currentUser.role === 'admin';
    const partner = isStaff ? activeConversation.emailId : activeConversation.agentId;
    const recipientId = partner?._id || partner;
    const agentId = isStaff ? currentUser._id : recipientId;
    const emailId = currentUser.role === 'user' ? currentUser._id : recipientId;
    const conversationId = activeConversation ? activeConversation._id : `conv-${agentId}-${emailId}`;
    const messageId = 'msg-voice-' + Date.now();

    const input = document.getElementById('widgetMsgInput');
    input.placeholder = 'Uploading...';
    input.disabled = true;

    // Immediately show the temporary preview bubble with sending status
    const tempMsgObj = {
      _id: messageId,
      conversationId,
      senderId: currentUser._id,
      senderType: currentUser.role,
      type: 'voice',
      audio: { key: 'temp', duration, mimeType: 'audio/webm', cdnUrl: '' },
      status: 'sending',
      createdAt: new Date()
    };

    if (activeConversation.isVirtual) {
      activeConversation.isVirtual = false;
      document.getElementById('widgetMessages').innerHTML = '';
    }

    appendMessageBubble(tempMsgObj);

    try {
      const presignedRes = await fetch(getApiUrl('/api/v1/voice/presigned-url'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${currentToken}`
        },
        body: JSON.stringify({ conversationId, mimeType: 'audio/webm' })
      });
      
      if (!presignedRes.ok) throw new Error('Failed to get upload URL');
      const presignedData = await presignedRes.json();

      let uploadRes;
      let finalCdnUrl = presignedData.cdnUrl;
      let finalFileKey = presignedData.fileKey;

      try {
        const uploadHeaders = {
          'Content-Type': 'audio/webm'
        };
        if (presignedData.metadata) {
          Object.assign(uploadHeaders, presignedData.metadata);
        }
        if (presignedData.uploadUrl.startsWith('/') || presignedData.uploadUrl.includes(window.location.host)) {
          uploadHeaders['Authorization'] = `Bearer ${currentToken}`;
        }
        uploadRes = await fetch(presignedData.uploadUrl, {
          method: 'PUT',
          headers: uploadHeaders,
          body: audioBlob
        });
        if (!uploadRes.ok) throw new Error('S3 Upload failed');
      } catch (s3Err) {
        console.warn('S3 upload failed, falling back to local mock upload:', s3Err);
        const mockKey = `voice-notes/${conversationId}/${currentUser._id || 'anonymous'}/${Date.now()}-${Math.floor(Math.random() * 1000)}.webm`;
        const mockUploadUrl = `/api/v1/voice/upload-mock?key=${mockKey}`;
        
        uploadRes = await fetch(getApiUrl(mockUploadUrl), {
          method: 'PUT',
          headers: {
            'Content-Type': 'audio/webm',
            'Authorization': `Bearer ${currentToken}`
          },
          body: audioBlob
        });
        if (!uploadRes.ok) throw new Error('Local mock upload fallback failed');
        
        finalFileKey = mockKey;
        finalCdnUrl = `/uploads/${mockKey}`;
      }

      const msgObj = {
        _id: messageId,
        conversationId,
        senderId: currentUser._id,
        senderType: currentUser.role,
        type: 'voice',
        audio: { key: finalFileKey, duration, mimeType: 'audio/webm', cdnUrl: finalCdnUrl },
        status: 'sent',
        createdAt: new Date()
      };

      appendMessageBubble(msgObj);

      const sendPayload = {
        _id: messageId,
        conversationId,
        recipientId,
        type: 'voice',
        audio: { key: finalFileKey, duration, mimeType: 'audio/webm', cdnUrl: finalCdnUrl }
      };
      console.log('[Widget Frontend] Sending voice payload:', sendPayload);
      socket.emit('message:send', sendPayload, (err, res) => {
        if (err) {
          console.error('[Widget Frontend] message:send voice error response:', err);
        } else {
          console.log('[Widget Frontend] message:send voice response:', res);
        }
      });

    } catch (err) {
      console.error('Voice note upload error:', err);
      // Remove temporary bubble on failure
      const tempBubble = document.querySelector(`[data-msg-id="${messageId}"]`);
      if (tempBubble) tempBubble.remove();
      alert('Failed to send voice note: ' + err.message);
    } finally {
      input.placeholder = 'Type a message...';
      input.disabled = false;
    }
  }

  function sendWidgetImage() {
    if (!socket || !socket.connected) return alert('Establish websocket connection first!');
    if (!activeConversation) return alert('Select active conversation first!');
    document.getElementById('widgetImageFileInput').click();
  }

  async function uploadWidgetImage(file) {
    if (!file) return;

    const isStaff = currentUser.role === 'agent' || currentUser.role === 'admin';
    const partner = isStaff ? activeConversation.emailId : activeConversation.agentId;
    const recipientId = partner?._id || partner;
    const agentId = isStaff ? currentUser._id : recipientId;
    const emailId = currentUser.role === 'user' ? currentUser._id : recipientId;
    const conversationId = activeConversation ? activeConversation._id : `conv-${agentId}-${emailId}`;
    const messageId = 'msg-image-' + Date.now();

    const input = document.getElementById('widgetMsgInput');
    input.placeholder = 'Uploading image...';
    input.disabled = true;

    const localPreviewUrl = URL.createObjectURL(file);

    // Immediately show the temporary preview bubble with sending status
    const tempMsgObj = {
      _id: messageId,
      conversationId,
      senderId: currentUser._id,
      senderType: currentUser.role,
      type: 'image',
      image: { key: 'temp', mimeType: file.type || 'image/jpeg', cdnUrl: localPreviewUrl },
      status: 'sending',
      createdAt: new Date()
    };

    if (activeConversation.isVirtual) {
      activeConversation.isVirtual = false;
      document.getElementById('widgetMessages').innerHTML = '';
    }

    appendMessageBubble(tempMsgObj);

    try {
      const presignedRes = await fetch(getApiUrl('/api/v1/image/presigned-url'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${currentToken}`
        },
        body: JSON.stringify({ conversationId, mimeType: file.type || 'image/jpeg' })
      });
      
      if (!presignedRes.ok) throw new Error('Failed to get upload URL');
      const presignedData = await presignedRes.json();

      let uploadRes;
      let finalCdnUrl = presignedData.cdnUrl;
      let finalFileKey = presignedData.fileKey;

      try {
        const uploadHeaders = {
          'Content-Type': file.type || 'image/jpeg'
        };
        if (presignedData.metadata) {
          Object.assign(uploadHeaders, presignedData.metadata);
        }
        if (presignedData.uploadUrl.startsWith('/') || presignedData.uploadUrl.includes(window.location.host)) {
          uploadHeaders['Authorization'] = `Bearer ${currentToken}`;
        }
        uploadRes = await fetch(presignedData.uploadUrl, {
          method: 'PUT',
          headers: uploadHeaders,
          body: file
        });
        if (!uploadRes.ok) throw new Error('S3 Upload failed');
      } catch (s3Err) {
        console.warn('S3 upload failed, falling back to local mock upload:', s3Err);
        const extension = file.type ? file.type.split('/')[1] || 'jpeg' : 'jpeg';
        const mockKey = `images/${conversationId}/${currentUser._id || 'anonymous'}/${Date.now()}-${Math.floor(Math.random() * 1000)}.${extension}`;
        const mockUploadUrl = `/api/v1/image/upload-mock?key=${mockKey}`;
        
        uploadRes = await fetch(getApiUrl(mockUploadUrl), {
          method: 'PUT',
          headers: {
            'Content-Type': file.type || 'image/jpeg',
            'Authorization': `Bearer ${currentToken}`
          },
          body: file
        });
        if (!uploadRes.ok) throw new Error('Local mock upload fallback failed');
        
        finalFileKey = mockKey;
        finalCdnUrl = `/uploads/${mockKey}`;
      }

      const msgObj = {
        _id: messageId,
        conversationId,
        senderId: currentUser._id,
        senderType: currentUser.role,
        type: 'image',
        image: { key: finalFileKey, mimeType: file.type || 'image/jpeg', cdnUrl: localPreviewUrl },
        status: 'sent',
        createdAt: new Date()
      };

      appendMessageBubble(msgObj);

      const sendPayload = {
        _id: messageId,
        conversationId,
        recipientId,
        type: 'image',
        image: { key: finalFileKey, mimeType: file.type || 'image/jpeg', cdnUrl: finalCdnUrl }
      };
      console.log('[Widget Frontend] Sending image payload:', sendPayload);
      socket.emit('message:send', sendPayload, (err, res) => {
        if (err) {
          console.error('[Widget Frontend] message:send image error response:', err);
        } else {
          console.log('[Widget Frontend] message:send image response:', res);
        }
      });

    } catch (err) {
      console.error('Image upload error:', err);
      // Remove temporary bubble on failure
      const tempBubble = document.querySelector(`[data-msg-id="${messageId}"]`);
      if (tempBubble) tempBubble.remove();
      alert('Failed to send image: ' + err.message);
    } finally {
      input.placeholder = 'Type a message...';
      input.disabled = false;
      document.getElementById('widgetImageFileInput').value = '';
    }
  }

  function widgetLogout() {
    // 1. Clear LocalStorage and Cookies
    localStorage.removeItem('chat_identity');
    localStorage.removeItem('agent_identity');
    localStorage.removeItem('token');
    document.cookie = "token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie = "chat_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie = "token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/chat;";
    document.cookie = "chat_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/chat;";

    // 2. Disconnect Real-time Socket & Timers
    if (socket) socket.disconnect();
    if (presenceInterval) clearInterval(presenceInterval);

    // 3. Clear In-Memory Caches
    currentToken = '';
    currentUser = null;
    activeConversation = null;
    cachedBooks = [];
    seedData = null;
    messagesNextCursor = null;
    messagesHasMore = false;

    // 4. Sanitize DOM elements
    const msgEl = document.getElementById('widgetMessages');
    if (msgEl) msgEl.innerHTML = '';
    const convoListEl = document.getElementById('widgetConvoList');
    if (convoListEl) convoListEl.innerHTML = '<div style="padding:2rem; text-align:center; color:#64748b; font-size:0.8rem;">Loading active chats...</div>';

    // 5. Redirect to logout endpoint
    window.location.href = '/office/partials/logout';
  }

  function toggleChatDrawer(forceOpen = null) {
    const drawer = document.getElementById('chatDrawer');
    if (forceOpen !== null) {
      if (forceOpen) drawer.classList.add('open');
      else drawer.classList.remove('open');
    } else {
      drawer.classList.toggle('open');
    }

    const isOpen = drawer.classList.contains('open');

    // Toggle floating trigger button visibility so it hides when side popup opens
    const floatingTriggers = document.querySelectorAll('#fbChatWidgetFloatingBtn, button.fab-pulse, button.fixed.bottom-8.right-8, button.fixed.bottom-6.right-6');
    floatingTriggers.forEach(trig => {
      if (isOpen) {
        trig.style.setProperty('display', 'none', 'important');
      } else {
        trig.style.removeProperty('display');
      }
    });

    if (isOpen) {
      document.body.classList.add('chat-drawer-open');
      initializeWidgetConnection();
    } else {
      document.body.classList.remove('chat-drawer-open');
    }
  }

  let cachedBooks = [];
  async function fetchAndCacheBooks() {
    try {
      if (!currentToken) return;
      const res = await fetch(getApiUrl('/api/v1/games/all-books'), {
        headers: { Authorization: `Bearer ${currentToken}` }
      });
      if (res.ok) {
        const data = await res.json();
        if (data && data.success && data.all_books) {
          cachedBooks = data.all_books.map(b => ({
            id: b.id,
            name: b.name,
            is_subscribed: b.is_subscribed === true || String(b.is_subscribed) === 'true' || b.is_subscribed === 1 || String(b.is_subscribed) === '1',
            subscription_stage: b.subscription_stage || b.stage_status || ''
          }));
          console.log('[Widget] Cached books:', cachedBooks);
        }
      }
    } catch (err) {
      console.warn('[Widget] Failed to fetch books:', err);
    }
  }

  async function syncWidgetUserProfile() {
    if (!currentToken) return;
    try {
      const meRes = await fetch(getApiUrl('/api/v1/auth/me'), {
        headers: { Authorization: `Bearer ${currentToken}` }
      });
      if (meRes.ok) {
        const meData = await meRes.json();
        if (meData && meData.user) {
          if (currentUser) {
            currentUser.mob = meData.user.mob || currentUser.mob || '';
            currentUser.avatar = meData.user.avatar || meData.user.img || currentUser.avatar || '';
            currentUser.img = meData.user.img || currentUser.img || '';
            currentUser.name = meData.user.name || currentUser.name;
          }
          const stored = localStorage.getItem('chat_identity');
          if (stored) {
            try {
              const p = JSON.parse(stored);
              p.user = Object.assign(p.user || {}, meData.user);
              localStorage.setItem('chat_identity', JSON.stringify(p));
            } catch (e) {}
          }
          const widgetHeaderTitle = document.getElementById('widgetHeaderTitleText');
          if (widgetHeaderTitle && currentUser && currentUser.name) {
            widgetHeaderTitle.textContent = currentUser.name;
          }
        }
      }
    } catch (e) {
      console.warn('[Widget] Profile sync warning:', e);
    }
  }

  function initializeWidgetConnection() {
    const cached = localStorage.getItem('chat_identity');
    if (cached) {
      const parsed = JSON.parse(cached);
      currentToken = parsed.token;
      currentUser = parsed.user;
      if (currentUser) {
        currentUser._id = currentUser._id || currentUser.emailId;
      }
      currentUser.role = parsed.role;

      // Show Chat Layout
      document.getElementById('drawerChatView').style.display = 'flex';
      const logoutBtn = document.getElementById('btnWidgetLogout');
      if (logoutBtn) logoutBtn.style.display = 'inline-block';
      document.getElementById('widgetHeaderTitleText').textContent = currentUser.name;
      goBackToConvoList();
      connectWebsocket();
      fetchAndCacheBooks();
      syncWidgetUserProfile();
    } else {
      window.location.href = '/chat/view/login.html';
    }
  }

  function resetChatScrollPosition() {
    const activeChat = document.getElementById('widgetActiveChat');
    if (activeChat) activeChat.scrollTop = 0;
    const chatContainer = document.getElementById('drawerChatView');
    if (chatContainer) chatContainer.scrollTop = 0;
    const content = document.querySelector('.widget-content');
    if (content) content.scrollTop = 0;
    const drawer = document.querySelector('.chat-drawer');
    if (drawer) drawer.scrollTop = 0;
  }

  // Quick forms
  async function openQuickForm(type) {
    const overlay = document.getElementById('quickFormOverlay');
    const title = document.getElementById('quickFormTitle');
    const body = overlay.querySelector('.quick-form-body');
    
    resetChatScrollPosition();
    overlay.style.display = 'flex';

    let selectOptionsHtml = '<option value="">Select Game</option>';
    if (cachedBooks && cachedBooks.length > 0) {
      const filteredBooks = cachedBooks.filter(b => b.is_subscribed && (b.subscription_stage || '').toUpperCase() === 'DONE');
      if (filteredBooks.length > 0) {
        selectOptionsHtml = filteredBooks.map(b => `<option value="${b.id}" data-name="${escapeHtml(b.name)}">${escapeHtml(b.name)}</option>`).join('');
      } else {
        selectOptionsHtml = '<option value="">No Subscribed Games Available</option>';
      }
    } else {
      // Fallback/Default options
      const defaultBooks = [
        { id: "324", name: "Lucky Vault", is_subscribed: true, subscription_stage: "DONE" },
        { id: "323", name: "Dice Verse", is_subscribed: true, subscription_stage: "DONE" },
        { id: "322", name: "Jackpot Spin", is_subscribed: true, subscription_stage: "DONE" },
        { id: "321", name: "Gold Rush Pro", is_subscribed: true, subscription_stage: "DONE" },
        { id: "310", name: "Infinity Fortune", is_subscribed: true, subscription_stage: "DONE" },
        { id: "309", name: "Crown Riches", is_subscribed: false, subscription_stage: "NONE" }
      ];
      const filteredDefaults = defaultBooks.filter(b => b.is_subscribed && (b.subscription_stage || '').toUpperCase() === 'DONE');
      selectOptionsHtml = filteredDefaults.map(b => `<option value="${b.id}" data-name="${escapeHtml(b.name)}">${escapeHtml(b.name)}</option>`).join('');
      
      // Async fetch to update select in background
      fetchAndCacheBooks().then(() => {
        const selectEl = document.getElementById(type === 'deposit' ? 'depGame' : 'wdGame');
        if (selectEl && cachedBooks.length > 0) {
          const filteredBooks = cachedBooks.filter(b => b.is_subscribed && (b.subscription_stage || '').toUpperCase() === 'DONE');
          if (filteredBooks.length > 0) {
            selectEl.innerHTML = filteredBooks.map(b => `<option value="${b.id}" data-name="${escapeHtml(b.name)}">${escapeHtml(b.name)}</option>`).join('');
          } else {
            selectEl.innerHTML = '<option value="">No Subscribed Games Available</option>';
          }
        }
      });
    }
    
    if (type === 'deposit') {
      title.innerHTML = '<span style="display:inline-flex; align-items:center; gap:6px;"><img src="/chat/view/images/recharge_icon.svg" alt="Recharge" style="width:16px; height:16px; object-fit:contain;" /> Recharge Account</span>';
      body.innerHTML = `
        <form id="widgetDepositFormStep1" onsubmit="generateWidgetQR(event)" style="display:flex; flex-direction:column; gap:0.75rem;">
          <div class="quick-form-field">
            <label>Select Game</label>
            <select id="depGame" required>
              ${selectOptionsHtml}
            </select>
          </div>
          <div class="quick-form-field">
            <label>Recharge Amount (₹)</label>
            <div style="display: flex; gap: 0.35rem; margin-bottom: 0.35rem;">
              <button type="button" onclick="setQuickAmount(500)" class="btn-amount-pre">₹500</button>
              <button type="button" onclick="setQuickAmount(1000)" class="btn-amount-pre">₹1000</button>
              <button type="button" onclick="setQuickAmount(5000)" class="btn-amount-pre">₹5000</button>
              <button type="button" onclick="setQuickAmount(10000)" class="btn-amount-pre">₹10000</button>
            </div>
            <input type="number" id="depAmount" placeholder="Enter amount" required min="10" />
          </div>
          <button type="submit" class="quick-form-submit-btn">Generate Payment QR</button>
        </form>
      `;
    } else if (type === 'issue') {
      title.innerHTML = '<span style="display:inline-flex; align-items:center; gap:6px;"><img src="/chat/view/images/withdraw_icon.svg" alt="Withdraw" style="width:16px; height:16px; object-fit:contain;" /> Withdraw Funds</span>';
      body.innerHTML = `
        <div class="qr-loader-container" style="padding: 2rem 1rem;">
          <div class="qr-spinner"></div>
          <div style="font-size: 0.85rem; font-weight: 600; color: #64748b; margin-top: 0.5rem;">Checking payment account...</div>
        </div>
      `;

      let payAcc = null;
      try {
        const payRes = await fetch(getApiUrl('/api/v1/withdraw/payment-account'), {
          headers: {
            'Authorization': `Bearer ${currentToken}`
          }
        });
        if (payRes.ok) {
          const payData = await payRes.json();
          if (payData && payData.success && payData.data) {
            payAcc = payData.data;
          }
        }
      } catch (err) {
        console.error('[Widget Frontend] Error fetching payment account:', err);
      }

      // Case 1: No Payment Account Linked
      if (!payAcc) {
        body.innerHTML = `
          <div style="text-align: center; padding: 1.5rem 0.5rem; display: flex; flex-direction: column; gap: 0.85rem; align-items: center;">
            <div style="font-size: 2.2rem; line-height: 1;">⚠️</div>
            <div style="font-size: 0.95rem; font-weight: 700; color: #f59e0b;">No Payment Account Linked</div>
            <p style="font-size: 0.8rem; color: #64748b; margin: 0; line-height: 1.5; max-width: 290px;">
              No payment account details found for your account. Please set up your Bank &amp; UPI payment account details in Profile before requesting a withdrawal.
            </p>
            <a href="profile.php" class="quick-form-submit-btn" style="text-decoration: none; display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 0.55rem 1.25rem; font-size: 0.82rem; margin-top: 0.25rem;">
              <span>Go to Profile / Add Details</span> ➔
            </a>
          </div>
        `;
        return;
      }

      const rawPayImg = payAcc.image_url || payAcc.image || '';
      const refinedPayImgUrl = rawPayImg ? formatAvatarUrl(rawPayImg) : '';

      // Case 2: Approval Pending
      const stageStatus = (payAcc.stage_status || '').toUpperCase();
      if (stageStatus === 'EMPLOYEE-PENDING' || stageStatus === 'PENDING') {
        body.innerHTML = `
          <div style="display: flex; flex-direction: column; gap: 0.85rem; padding: 0.25rem 0;">
            <div style="background: rgba(245, 158, 11, 0.1); border: 1px solid rgba(245, 158, 11, 0.3); border-radius: 10px; padding: 0.85rem; text-align: center;">
              <div style="font-size: 1.5rem; margin-bottom: 0.25rem;">⏳</div>
              <div style="font-size: 0.85rem; font-weight: 700; color: #d97706; text-transform: uppercase; letter-spacing: 0.5px;">Account Approval Pending</div>
              <p style="font-size: 0.75rem; color: #92400e; margin: 0.35rem 0 0 0; line-height: 1.4;">
                You cannot request a withdrawal while your payment account detail approval is pending. Please wait until your details are approved by an administrator.
              </p>
            </div>
            
            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 0.75rem; font-size: 0.75rem; color: #334155;">
              <div style="font-weight: 700; color: #475569; margin-bottom: 0.5rem; text-transform: uppercase; font-size: 0.7rem;">Submitted Payment Details:</div>
              <div style="display: flex; flex-direction: column; gap: 4px;">
                <div><span style="color:#64748b;">Holder:</span> <strong>${escapeHtml(payAcc.account_name || 'N/A')}</strong></div>
                <div><span style="color:#64748b;">Bank:</span> <strong>${escapeHtml(payAcc.bank_name || 'N/A')}</strong></div>
                <div><span style="color:#64748b;">A/C No:</span> <strong>${escapeHtml(payAcc.account_no || 'N/A')}</strong></div>
                <div><span style="color:#64748b;">IFSC:</span> <strong>${escapeHtml(payAcc.ifsc_code || 'N/A')}</strong></div>
                <div><span style="color:#64748b;">UPI ID:</span> <strong>${escapeHtml(payAcc.upi_id || 'N/A')}</strong></div>
              </div>
              ${refinedPayImgUrl ? `
                <div style="margin-top: 6px; text-align: center; border-top: 1px dashed #e2e8f0; padding-top: 4px;">
                  <a href="${escapeHtmlAttr(refinedPayImgUrl)}" target="_blank" style="font-size: 0.7rem; color: #d97706; text-decoration: none; font-weight: 600;">🔍 View Uploaded QR / Passbook Image</a>
                </div>
              ` : ''}
            </div>

            <button type="button" onclick="closeQuickForm()" style="width: 100%; background: #64748b; color: white; border: none; padding: 0.5rem; border-radius: 8px; font-weight: 600; cursor: pointer; font-size: 0.8rem;">Close</button>
          </div>
        `;
        return;
      }

      // Case 3: Approved Payment Account
      body.innerHTML = `
        <form onsubmit="submitIssueForm(event)" style="display:flex; flex-direction:column; gap:0.75rem;">
          <!-- Approved Account Summary Card -->
          <div style="background: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 10px; padding: 0.75rem; font-size: 0.75rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px;">
              <span style="font-weight: 700; color: #0f172a; text-transform: uppercase; font-size: 0.7rem;">✓ Verified Payment Account</span>
              <span style="background: #22c55e; color: white; font-size: 0.65rem; font-weight: 700; padding: 2px 6px; border-radius: 10px;">APPROVED</span>
            </div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 4px 8px; color: #334155; font-size: 0.72rem;">
              <div><span style="color: #64748b;">Holder:</span> <strong>${escapeHtml(payAcc.account_name || 'N/A')}</strong></div>
              <div><span style="color: #64748b;">Bank:</span> <strong>${escapeHtml(payAcc.bank_name || 'N/A')}</strong></div>
              <div><span style="color: #64748b;">A/C No:</span> <strong>${escapeHtml(payAcc.account_no || 'N/A')}</strong></div>
              <div><span style="color: #64748b;">IFSC:</span> <strong>${escapeHtml(payAcc.ifsc_code || 'N/A')}</strong></div>
              <div style="grid-column: span 2;"><span style="color: #64748b;">UPI ID:</span> <strong>${escapeHtml(payAcc.upi_id || 'N/A')}</strong></div>
            </div>
            ${refinedPayImgUrl ? `
              <div style="margin-top: 6px; text-align: center; border-top: 1px dashed #cbd5e1; padding-top: 4px;">
                <a href="${escapeHtmlAttr(refinedPayImgUrl)}" target="_blank" style="font-size: 0.7rem; color: #2563eb; text-decoration: none; font-weight: 600;">🔍 View Linked QR / Passbook Image</a>
              </div>
            ` : ''}
          </div>

          <input type="hidden" id="wdApprovedAccName" value="${escapeHtmlAttr(payAcc.account_name || '')}" />
          <input type="hidden" id="wdApprovedAccNo" value="${escapeHtmlAttr(payAcc.account_no || '')}" />
          <input type="hidden" id="wdApprovedBankName" value="${escapeHtmlAttr(payAcc.bank_name || '')}" />
          <input type="hidden" id="wdApprovedIfsc" value="${escapeHtmlAttr(payAcc.ifsc_code || '')}" />
          <input type="hidden" id="wdApprovedUpi" value="${escapeHtmlAttr(payAcc.upi_id || '')}" />
          <input type="hidden" id="wdApprovedImage" value="${escapeHtmlAttr(payAcc.image || '')}" />
          <input type="hidden" id="wdApprovedImageUrl" value="${escapeHtmlAttr(refinedPayImgUrl)}" />

          <div class="quick-form-field">
            <label>Select Game</label>
            <select id="wdGame" required>
              ${selectOptionsHtml}
            </select>
          </div>
          <div class="quick-form-field">
            <label>Withdrawal Amount (₹)</label>
            <input type="number" id="wdAmount" placeholder="Enter withdrawal amount" required min="1" />
          </div>
          <button id="wdSubmitBtn" type="submit" class="quick-form-submit-btn">Submit Withdrawal Request</button>
        </form>
      `;
    }
  }
  async function generateWidgetQR(e) {
    e.preventDefault();
    const gameSelect = document.getElementById('depGame');
    const bookId = gameSelect.value;
    const selectedOption = gameSelect.options[gameSelect.selectedIndex];
    const gameName = selectedOption ? (selectedOption.getAttribute('data-name') || selectedOption.text) : 'Unknown Book';
    const amount = document.getElementById('depAmount').value;
    
    const overlay = document.getElementById('quickFormOverlay');
    const body = overlay.querySelector('.quick-form-body');
    
    // Show Loading Animation
    body.innerHTML = `
      <div class="qr-loader-container">
        <div class="qr-spinner"></div>
        <div>Generating secure QR code...</div>
      </div>
    `;
    
    try {
      const response = await fetch(getApiUrl('/api/v1/recharge/generate-qr'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${currentToken}`
        },
        body: JSON.stringify({
          userId: currentUser._id,
          bookId: bookId,
          amount: amount
        })
      });
      
      const data = await response.json();
      if (!response.ok || !data.success) {
        throw new Error(data.error || 'Failed to generate QR');
      }

      if (data.qr_available === false) {
        body.innerHTML = `
          <div style="text-align: center; padding: 1.5rem; display: flex; flex-direction: column; gap: 0.75rem; align-items: center;">
            <img src="/chat/view/images/recharge_icon.svg" alt="Recharge" style="width: 36px; height: 36px; object-fit: contain;" />
            <div style="font-size: 0.85rem; font-weight: bold; color: #ef4444; word-break: break-word;">${escapeHtml(data.message || 'Only Cash Transaction Available.')}</div>
            <p style="font-size: 0.75rem; color: #64748b; margin: 0; line-height: 1.4;">Online QR payment is currently disabled for this transaction. Please contact support or your agent for cash deposit options.</p>
            <button type="button" onclick="closeQuickForm()" style="margin-top: 0.5rem; background: #64748b; color: white; border: none; padding: 0.4rem 1.25rem; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 0.8rem;">Close</button>
          </div>
        `;
        return;
      }
      
      // Render Step 2
      body.innerHTML = `
        <form onsubmit="submitDepositForm(event)" style="display:flex; flex-direction:column; gap:0.75rem;">
          <input type="hidden" id="depGame" value="${escapeHtml(gameName)}" />
          <input type="hidden" id="depBookId" value="${escapeHtml(bookId)}" />
          <input type="hidden" id="depAmount" value="${amount}" />
          <input type="hidden" id="depQrId" value="${data.qr_id || ''}" />
          <input type="hidden" id="depRangeId" value="${data.range_id || ''}" />
          <input type="hidden" id="depEmpId" value="${data.emp_id || ''}" />
          
          <div style="text-align: center; margin: 0.25rem 0;">
            <div style="font-size: 0.75rem; color: #64748b; font-weight: bold; margin-bottom: 0.35rem; text-transform: uppercase;">Scan to Pay ₹${amount}</div>
            <img src="${data.qr_url}" alt="Payment QR" style="width: 140px; height: 140px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);" />
          </div>

          <div class="quick-form-field">
            <label>UTR / Transaction ID</label>
            <input type="text" id="depTxId" placeholder="Enter 12-digit UTR/TxID" required pattern="^[a-zA-Z0-9]{12}$" title="UTR/Transaction ID must be exactly 12 alphanumeric characters" />
          </div>

          <div class="quick-form-field">
            <label>Upload Payment Receipt</label>
            <input type="file" id="depProofFile" accept="image/*" required style="font-size: 0.75rem; padding: 0.35rem;" />
          </div>

          <button id="depSubmitBtn" type="submit" class="quick-form-submit-btn">Submit Recharge Request</button>
        </form>
      `;
    } catch (err) {
      console.error(err);
      body.innerHTML = `
        <div style="text-align: center; padding: 1.5rem; display: flex; flex-direction: column; gap: 0.75rem; align-items: center;">
          <div style="font-size: 2rem; color: #ef4444;">⚠️</div>
          <div style="font-size: 0.85rem; font-weight: bold; color: #ef4444; word-break: break-word;">Having Trouble Generating QR</div>
          <p style="font-size: 0.75rem; color: #64748b; margin: 0; line-height: 1.4;">${escapeHtml(err.message || 'Please try again later.')}</p>
          <div style="display: flex; gap: 0.5rem; width: 100%; margin-top: 0.5rem;">
            <button type="button" onclick="openQuickForm('deposit')" style="flex: 1; background: var(--primary); color: white; border: none; padding: 0.5rem; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 0.8rem;">Retry</button>
            <button type="button" onclick="closeQuickForm()" style="flex: 1; background: #64748b; color: white; border: none; padding: 0.5rem; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 0.8rem;">Close</button>
          </div>
        </div>
      `;
    }
  }

  async function ensureWidgetConnectedAndGetConversation() {
    if (!socket || !socket.connected) {
      connectWebsocket();
      await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Connection timed out')), 6000);
        socket.once('connect', () => {
          clearTimeout(timeout);
          resolve();
        });
      });
    }

    if (!activeConversation) {
      const listRes = await fetch(getApiUrl('/api/v1/conversations'), {
        headers: { Authorization: `Bearer ${currentToken}` }
      });
      const listData = await listRes.json();
      const list = listData.conversations || [];

      if (list.length > 0) {
        activeConversation = list[0];
      } else if (currentUser && currentUser.agentId) {
        activeConversation = {
          _id: `conv-${currentUser.agentId}-${currentUser._id}`,
          agentId: currentUser.agentId,
          emailId: currentUser._id,
          isVirtual: true,
          lastMessageAt: new Date(0).toISOString()
        };
      } else {
        throw new Error('No assigned agent found to send recharge request to.');
      }
    }
    return activeConversation;
  }

  async function submitRechargeRequest(game, amount, txId, file, bookId = '324', phpTxnId = null) {
    const conv = await ensureWidgetConnectedAndGetConversation();
    const isStaff = currentUser.role === 'agent' || currentUser.role === 'admin';
    const partner = isStaff ? conv.emailId : conv.agentId;
    const recipientId = partner?._id || partner;
    const conversationId = conv._id;
    const messageId = 'msg-recharge-' + Date.now();

    // 1. Get presigned URL
    const presignedRes = await fetch(getApiUrl('/api/v1/image/presigned-url'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentToken}`
      },
      body: JSON.stringify({ conversationId, mimeType: file.type || 'image/jpeg' })
    });
    
    if (!presignedRes.ok) throw new Error('Failed to get upload URL');
    const presignedData = await presignedRes.json();

    let uploadRes;
    let finalCdnUrl = presignedData.cdnUrl;
    let finalFileKey = presignedData.fileKey;

    try {
      // 2. Upload file
      const uploadHeaders = {
        'Content-Type': file.type || 'image/jpeg'
      };
      if (presignedData.metadata) {
        Object.assign(uploadHeaders, presignedData.metadata);
      }
      if (presignedData.uploadUrl.startsWith('/') || presignedData.uploadUrl.includes(window.location.host)) {
        uploadHeaders['Authorization'] = `Bearer ${currentToken}`;
      }
      uploadRes = await fetch(presignedData.uploadUrl, {
        method: 'PUT',
        headers: uploadHeaders,
        body: file
      });
      if (!uploadRes.ok) throw new Error('S3 Upload failed');
    } catch (s3Err) {
      console.warn('S3 upload failed, falling back to local mock upload:', s3Err);
      const extension = file.type ? file.type.split('/')[1] || 'jpeg' : 'jpeg';
      const mockKey = `images/${conversationId}/${currentUser._id || 'anonymous'}/${Date.now()}-${Math.floor(Math.random() * 1000)}.${extension}`;
      const mockUploadUrl = `/api/v1/image/upload-mock?key=${mockKey}`;
      
      uploadRes = await fetch(mockUploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': file.type || 'image/jpeg',
          'Authorization': `Bearer ${currentToken}`
        },
        body: file
      });
      if (!uploadRes.ok) throw new Error('Local mock upload fallback failed');
      
      finalFileKey = mockKey;
      finalCdnUrl = `/uploads/${mockKey}`;
    }

    const localPreviewUrl = URL.createObjectURL(file);

    // 3. Construct recharge payload
    const rechargeObj = {
      userId: currentUser._id,
      bookId: String(bookId),
      bookName: game,
      amount: Number(amount),
      transactionId: phpTxnId || null,
      utrNo: txId,
      proofImage: finalFileKey
    };

    // Build clean summary text conditionally
    const summaryParts = [];
    if (amount) summaryParts.push(`₹${amount}`);
    if (game) summaryParts.push(`for ${game}`);
    if (phpTxnId) summaryParts.push(`(Txn ID: ${phpTxnId})`);
    if (txId) summaryParts.push(`(UTR: ${txId})`);

    const summaryText = summaryParts.length > 0 ? `💸 Recharge Request: ${summaryParts.join(' ')}` : '💸 Recharge Request';

    const msgObj = {
      _id: messageId,
      conversationId,
      senderId: currentUser._id,
      senderType: currentUser.role,
      type: 'recharge',
      text: summaryText,
      recharge: {
        ...rechargeObj,
        proofImageCdnUrl: localPreviewUrl
      },
      status: 'sent',
      createdAt: new Date()
    };

    if (conv.isVirtual) {
      conv.isVirtual = false;
      const msgEl = document.getElementById('widgetMessages');
      if (msgEl) msgEl.innerHTML = '';
    }

    // 4. Render locally if active convo is this one
    const msgEl = document.getElementById('widgetMessages');
    if (msgEl && activeConversation && activeConversation._id === conversationId) {
      appendMessageBubble(msgObj);
    }

    // 5. Send via websocket
    const sendPayload = {
      _id: messageId,
      conversationId,
      recipientId,
      type: 'recharge',
      text: msgObj.text,
      recharge: rechargeObj
    };
    console.log('[Widget Frontend] Sending recharge payload:', sendPayload);
    socket.emit('message:send', sendPayload, (err, res) => {
      if (err) {
        console.error('[Widget Frontend] message:send recharge error response:', err);
      } else {
        console.log('[Widget Frontend] message:send recharge response:', res);
      }
    });

    return msgObj;
  }

  async function submitDepositForm(e) {
    e.preventDefault();
    const game = document.getElementById('depGame').value;
    const bookId = document.getElementById('depBookId') ? document.getElementById('depBookId').value : '324';
    const amount = document.getElementById('depAmount').value;
    const qrId = document.getElementById('depQrId').value;
    const rangeId = document.getElementById('depRangeId').value;
    const empId = document.getElementById('depEmpId').value;
    const utrVal = document.getElementById('depTxId') ? document.getElementById('depTxId').value.trim() : '';
    const fileInput = document.getElementById('depProofFile');
    const file = fileInput.files[0];
    
    if (!file) return alert('Payment receipt image is required.');
    
    const submitBtn = document.getElementById('depSubmitBtn');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Uploading Receipt & Submitting...';
    
    try {
      const fileToBase64 = (f) => new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(f);
        reader.onload = () => resolve(reader.result);
        reader.onerror = err => reject(err);
      });

      const base64Image = await fileToBase64(file);

      // Submit to recharge submission proxy endpoint
      const submitRes = await fetch(getApiUrl('/api/v1/recharge/submit'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${currentToken}`
        },
        body: JSON.stringify({
          userId: currentUser._id,
          qrId: qrId,
          rangeId: rangeId,
          amount: Number(amount),
          empId: empId,
          bookId: bookId,
          utrNo: utrVal,
          image: base64Image
        })
      });

      if (!submitRes.ok) {
        let errorMsg = 'Failed to submit payment details to the server';
        try {
          const errorData = await submitRes.json();
          errorMsg = errorData.error || errorData.message || errorMsg;
        } catch (e) {
          const rawText = await submitRes.text().catch(() => '');
          if (rawText) errorMsg = rawText.replace(/<[^>]*>/g, '').trim().substring(0, 150);
        }
        throw new Error(errorMsg);
      }

      let submitResult;
      try {
        submitResult = await submitRes.json();
      } catch (e) {
        throw new Error('Invalid response received from server');
      }

      if (submitResult.success === false) {
        throw new Error(submitResult.message || 'Failed to submit payment details to the server');
      }

      // PHP server returns recharge_id / transactionId
      const phpTxnId = submitResult.recharge_id || submitResult.transactionId || submitResult.id || null;
      await submitRechargeRequest(game, amount, utrVal, file, bookId, phpTxnId);
      closeQuickForm();
    } catch (err) {
      console.error(err);
      alert('Failed to submit recharge request: ' + err.message);
      submitBtn.disabled = false;
      submitBtn.textContent = 'Submit Recharge Request';
    }
  }

  function setQuickAmount(amount) {
    const input = document.getElementById('depAmount');
    if (input) input.value = amount;
  }

  function closeQuickForm() {
    const overlay = document.getElementById('quickFormOverlay');
    if (overlay) overlay.style.display = 'none';
    resetChatScrollPosition();
  }

  async function submitIssueForm(e) {
    e.preventDefault();
    const gameSelect = document.getElementById('wdGame');
    const bookId = gameSelect.value;
    const selectedOption = gameSelect.options[gameSelect.selectedIndex];
    const gameName = selectedOption ? (selectedOption.getAttribute('data-name') || selectedOption.text) : 'Unknown Book';
    const amount = document.getElementById('wdAmount').value;

    const accName = document.getElementById('wdApprovedAccName')?.value || '';
    const accNo = document.getElementById('wdApprovedAccNo')?.value || '';
    const bankName = document.getElementById('wdApprovedBankName')?.value || '';
    const ifsc = document.getElementById('wdApprovedIfsc')?.value || '';
    const upi = document.getElementById('wdApprovedUpi')?.value || '';
    const imageName = document.getElementById('wdApprovedImage')?.value || '';
    const imageUrl = document.getElementById('wdApprovedImageUrl')?.value || '';

    const bankDetailsSummary = `A/C Name: ${accName} | Bank: ${bankName} | A/C No: ${accNo} | IFSC: ${ifsc} | UPI: ${upi}`;

    const submitBtn = document.getElementById('wdSubmitBtn');
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.textContent = 'Submitting Withdrawal Request...';
    }
    
    try {
      // 1. Fetch approved image blob so it gets uploaded to Wasabi with standard images/conv-... key
      let imageBlob = null;
      if (imageUrl) {
        try {
          const imgFetch = await fetch(imageUrl);
          if (imgFetch.ok) {
            imageBlob = await imgFetch.blob();
          }
        } catch (imgErr) {
          console.warn('[Widget Frontend] Could not fetch approved image blob for Wasabi upload:', imgErr);
        }
      }

      // 2. Submit to withdrawal submission proxy endpoint
      const submitRes = await fetch(getApiUrl('/api/v1/withdraw/submit'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${currentToken}`
        },
        body: JSON.stringify({
          userId: currentUser._id,
          bookId: bookId,
          amount: Number(amount),
          detail: bankDetailsSummary,
          image: imageName
        })
      });

      if (!submitRes.ok) {
        const errorData = await submitRes.json();
        throw new Error(errorData.error || errorData.message || 'Failed to submit withdrawal details to the server');
      }

      const submitResult = await submitRes.json();
      if (!submitResult.success) {
        throw new Error(submitResult.message || 'Failed to submit withdrawal details to the server');
      }

      // 3. Upload image blob to Wasabi and emit chat message with Wasabi S3 fileKey
      await submitWithdrawRequest(gameName, amount, bankDetailsSummary, imageBlob || imageName, imageUrl, submitResult.withdrawal_id || 'N/A', bookId);
      closeQuickForm();
    } catch (err) {
      console.error(err);
      alert('Failed to submit withdrawal request: ' + err.message);
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Submit Withdrawal Request';
      }
    }
  }

  async function submitWithdrawRequest(game, amount, bankDetails, fileOrImageName, imageUrlOrFile, withdrawalId, bookId = '324') {
    const conv = await ensureWidgetConnectedAndGetConversation();
    const isStaff = currentUser.role === 'agent' || currentUser.role === 'admin';
    const partner = isStaff ? conv.emailId : conv.agentId;
    const recipientId = partner?._id || partner;
    const conversationId = conv._id;
    const messageId = 'msg-withdraw-' + Date.now();

    let finalFileKey = typeof fileOrImageName === 'string' ? fileOrImageName : '';
    let finalCdnUrl = typeof imageUrlOrFile === 'string' ? imageUrlOrFile : '';

    if (fileOrImageName instanceof Blob) {
      const file = fileOrImageName;
      try {
        // 1. Get presigned URL for the QR code image
        const presignedRes = await fetch(getApiUrl('/api/v1/image/presigned-url'), {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${currentToken}`
          },
          body: JSON.stringify({ conversationId, mimeType: file.type || 'image/jpeg' })
        });
        
        if (!presignedRes.ok) throw new Error('Failed to get upload URL');
        const presignedData = await presignedRes.json();
        finalCdnUrl = presignedData.cdnUrl;
        finalFileKey = presignedData.fileKey;

        // 2. Upload file to S3
        const uploadHeaders = {
          'Content-Type': file.type || 'image/jpeg'
        };
        if (presignedData.metadata) {
          Object.assign(uploadHeaders, presignedData.metadata);
        }
        if (presignedData.uploadUrl.startsWith('/') || presignedData.uploadUrl.includes(window.location.host)) {
          uploadHeaders['Authorization'] = `Bearer ${currentToken}`;
        }
        const uploadRes = await fetch(presignedData.uploadUrl, {
          method: 'PUT',
          headers: uploadHeaders,
          body: file
        });
        if (!uploadRes.ok) throw new Error('S3 Upload failed');
      } catch (s3Err) {
        console.warn('S3 upload failed, falling back to local mock upload:', s3Err);
        const extension = file.type ? file.type.split('/')[1] || 'jpeg' : 'jpeg';
        const mockKey = `images/${conversationId}/${currentUser._id || 'anonymous'}/${Date.now()}-${Math.floor(Math.random() * 1000)}.${extension}`;
        
        await fetch(getApiUrl(`/api/v1/image/upload-mock?key=${mockKey}`), {
          method: 'PUT',
          headers: {
            'Content-Type': file.type || 'image/jpeg',
            'Authorization': `Bearer ${currentToken}`
          },
          body: file
        });
        
        finalFileKey = mockKey;
        finalCdnUrl = `/uploads/${mockKey}`;
      }
    }

    // 3. Construct withdraw payload
    const withdrawObj = {
      userId: currentUser._id,
      bookId: String(bookId),
      bookName: game,
      amount: Number(amount),
      bankDetails: bankDetails,
      transactionId: String(withdrawalId),
      proofImage: finalFileKey || undefined
    };

    // Build clean summary text conditionally
    const summaryParts = [];
    if (amount) summaryParts.push(`₹${amount}`);
    if (game && game !== 'Unknown Book') summaryParts.push(`for ${game}`);
    if (withdrawalId && withdrawalId !== 'N/A') summaryParts.push(`(Txn ID: ${withdrawalId})`);

    const summaryText = summaryParts.length > 0 ? `🏦 Withdrawal Request: ${summaryParts.join(' ')}` : '🏦 Withdrawal Request';

    const msgObj = {
      _id: messageId,
      conversationId,
      senderId: currentUser._id,
      senderType: currentUser.role,
      type: 'withdraw',
      text: summaryText,
      withdraw: {
        ...withdrawObj,
        proofImageCdnUrl: finalCdnUrl || undefined
      },
      status: 'sent',
      createdAt: new Date()
    };

    if (conv.isVirtual) {
      conv.isVirtual = false;
      const msgEl = document.getElementById('widgetMessages');
      if (msgEl) msgEl.innerHTML = '';
    }

    // 4. Render locally if active convo is this one
    const msgEl = document.getElementById('widgetMessages');
    if (msgEl && activeConversation && activeConversation._id === conversationId) {
      appendMessageBubble(msgObj);
    }

    // 5. Send via websocket
    const sendPayload = {
      _id: messageId,
      conversationId,
      recipientId,
      type: 'withdraw',
      text: msgObj.text,
      withdraw: withdrawObj
    };
    console.log('[Widget Frontend] Sending withdraw payload:', sendPayload);
    socket.emit('message:send', sendPayload, (err, res) => {
      if (err) {
        console.error('[Widget Frontend] message:send withdraw error response:', err);
      } else {
        console.log('[Widget Frontend] message:send withdraw response:', res);
      }
    });

    return msgObj;
  }


  // Export functions to window
  window.toggleChatDrawer = toggleChatDrawer;
  window.goBackToConvoList = goBackToConvoList;
  window.widgetLogout = widgetLogout;
  window.sendWidgetText = sendWidgetText;
  window.sendWidgetVoice = sendWidgetVoice;
  window.sendWidgetImage = sendWidgetImage;
  window.uploadWidgetImage = uploadWidgetImage;
  window.playVoiceNote = playVoiceNote;
  window.openQuickForm = openQuickForm;
  window.closeQuickForm = closeQuickForm;
  window.setQuickAmount = setQuickAmount;
  window.generateWidgetQR = generateWidgetQR;
  window.submitDepositForm = submitDepositForm;
  window.submitIssueForm = submitIssueForm;
  window.ensureWidgetConnectedAndGetConversation = ensureWidgetConnectedAndGetConversation;
  window.submitRechargeRequest = submitRechargeRequest;

  // 4. Initial connection triggers
  let chatTrigger = document.querySelector('button.fab-pulse') || document.querySelector('button.fixed.bottom-8.right-8') || document.getElementById('fbChatWidgetFloatingBtn');
  if (!chatTrigger) {
    chatTrigger = document.createElement('button');
    chatTrigger.id = 'fbChatWidgetFloatingBtn';
    chatTrigger.innerHTML = `
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
      </svg>
    `;
    chatTrigger.style.cssText = `
      position: fixed !important;
      bottom: 24px !important;
      right: 24px !important;
      width: 60px !important;
      height: 60px !important;
      border-radius: 50% !important;
      background: linear-gradient(135deg, #008069 0%, #25d366 100%) !important;
      color: #ffffff !important;
      border: none !important;
      box-shadow: 0 10px 25px rgba(37, 211, 102, 0.45) !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      cursor: pointer !important;
      z-index: 999999 !important;
      transition: transform 0.25s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.25s ease !important;
    `;
    chatTrigger.onmouseover = function() {
      chatTrigger.style.transform = 'scale(1.1)';
      chatTrigger.style.boxShadow = '0 15px 30px rgba(37, 211, 102, 0.6)';
    };
    chatTrigger.onmouseout = function() {
      chatTrigger.style.transform = 'scale(1)';
      chatTrigger.style.boxShadow = '0 10px 25px rgba(37, 211, 102, 0.45)';
    };
    document.body.appendChild(chatTrigger);
  }

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

    // Restore previously saved position if available
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

  if (chatTrigger) {
    chatTrigger.addEventListener('click', (e) => {
      e.preventDefault();
      window.toggleChatDrawer();
    });
    makeChatWidgetMovable(chatTrigger);
  }

  document.querySelectorAll('#fbChatWidgetFloatingBtn, button.fab-pulse, button.fixed.bottom-8.right-8, button.fixed.bottom-6.right-6').forEach(trig => {
    makeChatWidgetMovable(trig);
  });

  // Auto connect if logged in
  function getCookieVal(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
  }
  function parseJwtPayload(token) {
    try {
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
          return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join(''));
      return JSON.parse(jsonPayload);
    } catch (e) { return null; }
  }

  const cookieToken = getCookieVal('token') || getCookieVal('chat_token');
  let cached = localStorage.getItem('chat_identity');
  let parsedCached = null;
  try {
    if (cached) parsedCached = JSON.parse(cached);
  } catch (e) {}

  if (!cookieToken) {
    localStorage.removeItem('chat_identity');
    parsedCached = null;
  } else if (cookieToken && (!parsedCached || parsedCached.token !== cookieToken)) {
    const payload = parseJwtPayload(cookieToken);
    if (payload) {
      const userObj = {
        _id: payload.emailId || payload.id || 'user',
        emailId: payload.emailId || payload.id,
        name: payload.name || 'User',
        role: payload.role || 'user',
        agentId: payload.agentId || null
      };
      const identityObj = { token: cookieToken, user: userObj, role: payload.role || 'user' };
      localStorage.setItem('chat_identity', JSON.stringify(identityObj));
      parsedCached = identityObj;
    }
  }

  if (parsedCached) {
    currentToken = parsedCached.token;
    currentUser = parsedCached.user;
    if (currentUser) {
      currentUser._id = currentUser._id || currentUser.emailId;
      currentUser.role = parsedCached.role;
    }
  }

})();
