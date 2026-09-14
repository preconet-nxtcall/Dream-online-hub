<?php
// Coming Soon Landing Page Template for FairBiz CRM
if (!isset($conn) || !isset($m_url)) {
    require_once file_exists(__DIR__ . "/../office/partials/_dbconnect.php") 
        ? __DIR__ . "/../office/partials/_dbconnect.php" 
        : "office/partials/_dbconnect.php";
}
if (!isset($site_dls) && isset($conn)) {
    $qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error($conn));
    $site_dls = mysqli_fetch_array($qrydisplay20);
}

$site_title = !empty($site_dls['heading']) ? $site_dls['heading'] : 'FairBiz CRM';
$meta_desc = !empty($site_dls['meta']) ? $site_dls['meta'] : ($site_title . ' - Coming Soon');
$logo_path = !empty($site_dls['white_logo']) ? $m_url . ADD_PHOTO_SITE_PATH . $site_dls['white_logo'] : '';
$favicon_path = !empty($site_dls['fevicon']) ? $m_url . ADD_PHOTO_SITE_PATH . $site_dls['fevicon'] : '';

$theme_mode = !empty($site_dls['theme_mode']) ? $site_dls['theme_mode'] : 'dark';
$theme_primary = !empty($site_dls['theme_primary']) ? $site_dls['theme_primary'] : '#8b5cf6';
$theme_secondary = !empty($site_dls['theme_secondary']) ? $site_dls['theme_secondary'] : '#6366f1';
$theme_bg = !empty($site_dls['theme_bg']) ? $site_dls['theme_bg'] : ($theme_mode === 'light' ? '#f8fafc' : '#070913');
$theme_card = !empty($site_dls['theme_card']) ? $site_dls['theme_card'] : ($theme_mode === 'light' ? '#ffffff' : 'rgba(18, 24, 43, 0.7)');
$theme_text = !empty($site_dls['theme_text']) ? $site_dls['theme_text'] : ($theme_mode === 'light' ? '#0f172a' : '#f8fafc');

$prelogin_url = !empty($m_url) ? rtrim($m_url, '/') . '/prelogin' : '/prelogin';
$office_url = !empty($m_url) ? rtrim($m_url, '/') . '/office/' : '/office/';
$chat_url = !empty($m_url) ? rtrim($m_url, '/') . '/chat/' : '/chat/';
?>
<!DOCTYPE html>
<html lang="en" data-theme-mode="<?php echo $theme_mode; ?>">
<head>
    <meta charset="utf-8">
    <title><?php echo htmlspecialchars($site_title); ?> - Coming Soon</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="<?php echo htmlspecialchars($meta_desc); ?>">
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/font/bootstrap-icons.min.css">
    
    <?php if (!empty($favicon_path)): ?>
    <link rel="shortcut icon" href="<?php echo $favicon_path; ?>">
    <?php endif; ?>

    <style>
        :root {
            --bg-deep: <?php echo $theme_bg; ?>;
            --bg-card: <?php echo $theme_card; ?>;
            --border-card: <?php echo ($theme_mode === 'light') ? 'rgba(0, 0, 0, 0.08)' : $theme_primary . '33'; ?>;
            --primary: <?php echo $theme_primary; ?>;
            --primary-glow: <?php echo $theme_primary . '55'; ?>;
            --accent: <?php echo $theme_secondary; ?>;
            --accent-glow: <?php echo $theme_secondary . '55'; ?>;
            --text-main: <?php echo $theme_text; ?>;
            --text-muted: <?php echo ($theme_mode === 'light') ? '#64748b' : '#94a3b8'; ?>;
            --font-heading: 'Outfit', sans-serif;
            --font-body: 'Plus Jakarta Sans', sans-serif;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-deep);
            color: var(--text-main);
            font-family: var(--font-body);
            min-height: 100vh;
            overflow-x: hidden;
            display: flex;
            flex-direction: column;
            position: relative;
        }

        /* Ambient Lighting Background Effects */
        .ambient-glow-1 {
            position: absolute;
            top: -10%;
            left: 20%;
            width: 550px;
            height: 550px;
            background: radial-gradient(circle, var(--primary-glow) 0%, rgba(7, 9, 19, 0) 70%);
            border-radius: 50%;
            filter: blur(80px);
            z-index: 0;
            pointer-events: none;
            animation: pulseGlow 8s infinite alternate ease-in-out;
        }

        .ambient-glow-2 {
            position: absolute;
            bottom: 10%;
            right: 15%;
            width: 600px;
            height: 600px;
            background: radial-gradient(circle, var(--accent-glow) 0%, rgba(7, 9, 19, 0) 70%);
            border-radius: 50%;
            filter: blur(90px);
            z-index: 0;
            pointer-events: none;
            animation: pulseGlow 10s infinite alternate ease-in-out;
        }

        @keyframes pulseGlow {
            0% { transform: scale(1) translateY(0); opacity: 0.7; }
            100% { transform: scale(1.15) translateY(-30px); opacity: 1; }
        }

        /* Navigation Header */
        header {
            position: relative;
            z-index: 10;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1.5rem 3rem;
            max-width: 1300px;
            width: 100%;
            margin: 0 auto;
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            font-family: var(--font-heading);
            font-weight: 800;
            font-size: 1.5rem;
            color: var(--text-main);
            text-decoration: none;
            letter-spacing: -0.02em;
        }

        .brand-logo-img {
            max-height: 44px;
            max-width: 220px;
            width: auto;
            height: auto;
            object-fit: contain;
            display: inline-block;
        }

        .logo-icon {
            width: 42px;
            height: 42px;
            background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
            font-size: 1.3rem;
            box-shadow: 0 4px 20px var(--primary-glow);
        }

        .header-nav-actions {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        .nav-btn {
            padding: 0.65rem 1.35rem;
            border-radius: 10px;
            font-weight: 600;
            font-size: 0.9rem;
            text-decoration: none;
            transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .nav-btn-secondary {
            background: <?php echo ($theme_mode === 'light') ? '#ffffff' : 'rgba(255, 255, 255, 0.05)'; ?>;
            color: var(--text-main);
            border: 1px solid var(--border-card);
            box-shadow: <?php echo ($theme_mode === 'light') ? '0 2px 8px rgba(0,0,0,0.04)' : 'none'; ?>;
        }

        .nav-btn-secondary:hover {
            background: rgba(255, 255, 255, 0.1);
            border-color: var(--primary);
            transform: translateY(-2px);
        }

        .nav-btn-primary {
            background: linear-gradient(135deg, var(--accent) 0%, var(--primary) 100%);
            color: #ffffff;
            box-shadow: 0 4px 15px var(--primary-glow);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .nav-btn-primary:hover {
            box-shadow: 0 8px 25px var(--primary-glow);
            transform: translateY(-2px);
            filter: brightness(1.1);
        }

        /* Main Hero Section */
        main {
            position: relative;
            z-index: 1;
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 3rem 1.5rem;
            max-width: 1100px;
            margin: 0 auto;
            width: 100%;
        }

        .badge-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.4rem 1.1rem;
            background: <?php echo $theme_primary . '18'; ?>;
            border: 1px solid <?php echo $theme_primary . '44'; ?>;
            border-radius: 50px;
            color: var(--primary);
            font-size: 0.825rem;
            font-weight: 700;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            margin-bottom: 1.75rem;
            box-shadow: 0 0 20px <?php echo $theme_primary . '22'; ?>;
        }

        .badge-dot {
            width: 8px;
            height: 8px;
            background-color: var(--primary);
            border-radius: 50%;
            box-shadow: 0 0 8px var(--primary);
            animation: pulseDot 1.5s infinite;
        }

        @keyframes pulseDot {
            0% { opacity: 0.4; }
            50% { opacity: 1; }
            100% { opacity: 0.4; }
        }

        .hero-title {
            font-family: var(--font-heading);
            font-size: clamp(2.5rem, 6vw, 4.5rem);
            font-weight: 800;
            line-height: 1.1;
            letter-spacing: -0.03em;
            margin-bottom: 1.25rem;
            color: var(--text-main);
            background: <?php echo ($theme_mode === 'light') ? 'linear-gradient(180deg, var(--text-main) 0%, rgba(15, 23, 42, 0.75) 100%)' : 'linear-gradient(180deg, #ffffff 0%, #cbd5e1 100%)'; ?>;
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero-title span {
            background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .hero-subtitle {
            font-size: clamp(1rem, 2vw, 1.25rem);
            color: var(--text-muted);
            max-width: 720px;
            line-height: 1.6;
            margin-bottom: 2.5rem;
            font-weight: 400;
        }

        .cta-group {
            display: flex;
            gap: 1.25rem;
            align-items: center;
            justify-content: center;
            flex-wrap: wrap;
            margin-bottom: 4rem;
        }

        .cta-btn-main {
            padding: 1rem 2.25rem;
            border-radius: 12px;
            font-weight: 700;
            font-size: 1.05rem;
            text-decoration: none;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 0.65rem;
            background: linear-gradient(135deg, var(--accent) 0%, var(--primary) 100%);
            color: #ffffff;
            box-shadow: 0 10px 30px var(--primary-glow);
            border: 1px solid rgba(255, 255, 255, 0.25);
        }

        .cta-btn-main:hover {
            transform: translateY(-3px);
            box-shadow: 0 15px 40px var(--primary-glow);
            filter: brightness(1.08);
        }

        .cta-btn-sub {
            padding: 1rem 2.25rem;
            border-radius: 12px;
            font-weight: 600;
            font-size: 1.05rem;
            text-decoration: none;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 0.65rem;
            background: <?php echo ($theme_mode === 'light') ? '#ffffff' : 'rgba(255, 255, 255, 0.04)'; ?>;
            color: var(--text-main);
            border: 1px solid var(--border-card);
            backdrop-filter: blur(10px);
            box-shadow: <?php echo ($theme_mode === 'light') ? '0 4px 15px rgba(0,0,0,0.04)' : 'none'; ?>;
        }

        .cta-btn-sub:hover {
            background: rgba(255, 255, 255, 0.08);
            border-color: var(--primary);
            transform: translateY(-3px);
        }

        /* Feature Cards Grid */
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 1.5rem;
            width: 100%;
            text-align: left;
        }

        .feature-card {
            background: var(--bg-card);
            border: 1px solid var(--border-card);
            border-radius: 18px;
            padding: 1.75rem 1.5rem;
            backdrop-filter: blur(16px);
            box-shadow: <?php echo ($theme_mode === 'light') ? '0 4px 20px rgba(0, 0, 0, 0.04)' : '0 4px 20px rgba(0, 0, 0, 0.3)'; ?>;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: flex;
            flex-direction: column;
            gap: 0.85rem;
        }

        .feature-card:hover {
            border-color: var(--primary);
            transform: translateY(-5px);
            box-shadow: <?php echo ($theme_mode === 'light') ? '0 12px 30px rgba(0, 0, 0, 0.08)' : '0 15px 35px rgba(0, 0, 0, 0.4)'; ?>;
        }

        .card-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            background: <?php echo ($theme_mode === 'light') ? 'rgba(0, 0, 0, 0.04)' : 'rgba(255, 255, 255, 0.05)'; ?>;
            border: 1px solid var(--border-card);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary);
            font-size: 1.4rem;
        }

        .card-title {
            font-family: var(--font-heading);
            font-weight: 700;
            font-size: 1.15rem;
            color: var(--text-main);
        }

        .card-desc {
            font-size: 0.875rem;
            color: var(--text-muted);
            line-height: 1.5;
        }

        /* Footer */
        footer {
            position: relative;
            z-index: 10;
            border-top: 1px solid rgba(255, 255, 255, 0.06);
            padding: 2rem 3rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1300px;
            width: 100%;
            margin: 0 auto;
            flex-wrap: wrap;
            gap: 1rem;
        }

        .footer-text {
            font-size: 0.875rem;
            color: var(--text-muted);
        }

        .footer-links {
            display: flex;
            gap: 1.5rem;
        }

        .footer-links a {
            color: var(--text-muted);
            text-decoration: none;
            font-size: 0.875rem;
            transition: color 0.2s;
        }

        .footer-links a:hover {
            color: var(--primary);
        }

        @media (max-width: 768px) {
            header {
                padding: 1.25rem 1.5rem;
            }
            .header-nav-actions .nav-btn-secondary {
                display: none;
            }
            main {
                padding: 2.5rem 1.25rem;
            }
            .cta-group {
                flex-direction: column;
                width: 100%;
            }
            .cta-btn-main, .cta-btn-sub {
                width: 100%;
                justify-content: center;
            }
            footer {
                padding: 1.5rem;
                flex-direction: column;
                text-align: center;
            }
        }
    </style>
</head>
<body>

    <!-- Ambient Glow Effects -->
    <div class="ambient-glow-1"></div>
    <div class="ambient-glow-2"></div>

    <!-- Header Navigation -->
    <header>
        <a href="/" class="brand-logo">
            <?php if (!empty($logo_path)): ?>
                <img src="<?php echo htmlspecialchars($logo_path); ?>" alt="<?php echo htmlspecialchars($site_title); ?>" class="brand-logo-img">
            <?php else: ?>
                <div class="logo-icon">
                    <i class="bi bi-rocket-takeoff-fill"></i>
                </div>
            <?php endif; ?>
            <span class="brand-name"><?php echo htmlspecialchars($site_title); ?></span>
        </a>
        <div class="header-nav-actions">
            <a href="<?php echo $office_url; ?>" class="nav-btn nav-btn-secondary">
                <i class="bi bi-shield-lock-fill"></i> Staff Login
            </a>
            <a href="<?php echo $prelogin_url; ?>" class="nav-btn nav-btn-primary">
                <i class="bi bi-speedometer2"></i> User Dashboard
            </a>
        </div>
    </header>

    <!-- Hero Content -->
    <main>
        <div class="badge-pill">
            <span class="badge-dot"></span>
            <span>Platform Launch In Progress</span>
        </div>

        <h1 class="hero-title">
            Something Extraordinary Is <span>Coming Soon</span>
        </h1>

        <p class="hero-subtitle">
            We are engineering a high-performance CRM and live management hub for seamless support, instant transactions, and real-time operations.
        </p>

        <div class="cta-group">
            <a href="<?php echo $prelogin_url; ?>" class="cta-btn-main">
                <i class="bi bi-layout-sidebar-inset"></i> Open User Dashboard
            </a>
            <a href="<?php echo $office_url; ?>" class="cta-btn-sub">
                <i class="bi bi-person-badge"></i> Staff & Admin Portal
            </a>
        </div>

        <!-- Features Grid -->
        <div class="features-grid">
            <div class="feature-card">
                <div class="card-icon">
                    <i class="bi bi-chat-square-text-fill"></i>
                </div>
                <h3 class="card-title">Live Chat Support</h3>
                <p class="card-desc">Real-time WebSocket communication for instantaneous customer assistance.</p>
            </div>

            <div class="feature-card">
                <div class="card-icon">
                    <i class="bi bi-wallet2"></i>
                </div>
                <h3 class="card-title">Instant Accounting</h3>
                <p class="card-desc">Automated recharge & withdrawal request management with proof verification.</p>
            </div>

            <div class="feature-card">
                <div class="card-icon">
                    <i class="bi bi-shield-check"></i>
                </div>
                <h3 class="card-title">Enterprise Security</h3>
                <p class="card-desc">JWT authentication, role-based access control, and encrypted data streams.</p>
            </div>

            <div class="feature-card">
                <div class="card-icon">
                    <i class="bi bi-cpu-fill"></i>
                </div>
                <h3 class="card-title">Real-Time Insights</h3>
                <p class="card-desc">Live operational monitoring, user tracking, and administrative controls.</p>
            </div>
        </div>
    </main>

    <!-- Footer -->
    <footer>
        <div class="footer-text">
            &copy; <?php echo date('Y'); ?> <?php echo htmlspecialchars($site_title); ?>. All rights reserved.
        </div>
        <div class="footer-links">
            <a href="<?php echo $prelogin_url; ?>">Dashboard</a>
            <a href="<?php echo $office_url; ?>">Staff Portal</a>
            <a href="<?php echo $chat_url; ?>">Chat Interface</a>
        </div>
    </footer>

</body>
</html>
