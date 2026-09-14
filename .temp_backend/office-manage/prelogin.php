<?php
// Pre-Login Guide Landing Page Template for FairBiz / Office-Manage
if (!isset($conn) || !isset($m_url)) {
    require_once file_exists(__DIR__ . "/../office/partials/_dbconnect.php") 
        ? __DIR__ . "/../office/partials/_dbconnect.php" 
        : "office/partials/_dbconnect.php";
}
if (!isset($site_dls) && isset($conn)) {
    $qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error($conn));
    $site_dls = mysqli_fetch_array($qrydisplay20);
}

$site_title = !empty($site_dls['heading']) ? $site_dls['heading'] : 'DreamHub';
$meta_desc = !empty($site_dls['meta']) ? $site_dls['meta'] : ($site_title . ' - Dream Online Hub');

$logo_file = !empty($site_dls['white_logo']) ? $site_dls['white_logo'] : (!empty($site_dls['logo']) ? $site_dls['logo'] : '');
$db_logo_url = !empty($logo_file) ? $m_url . ADD_PHOTO_SITE_PATH . $logo_file : '';

$favicon_file = !empty($site_dls['fevicon']) ? $site_dls['fevicon'] : '';
$favicon_url = !empty($favicon_file) ? $m_url . ADD_PHOTO_SITE_PATH . $favicon_file : '';

$login_url = isset($m_url) ? $m_url . 'login' : 'login.php';
$hero_img_path = isset($m_url) ? $m_url . 'assets/images/hero_cards.jpg' : 'assets/images/hero_cards.jpg';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title><?php echo htmlspecialchars($site_title); ?> - Pre-Login Guide</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="description" content="<?php echo htmlspecialchars($meta_desc); ?>">
    
    <!-- Google Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/font/bootstrap-icons.min.css">
    
    <?php if (!empty($favicon_url)): ?>
    <link rel="shortcut icon" type="image/png" href="<?php echo htmlspecialchars($favicon_url); ?>">
    <?php endif; ?>

    <style>
        :root {
            --bg: #04111F;
            --bg-deep: #020B16;
            --surface: #071B31;
            --surface-2: #0B2440;
            --surface-3: #102D4F;
            --border: #135FA8;
            --border-soft: #1A3F66;
            --text: #F7FAFF;
            --text-2: #9FB8D9;
            --text-muted: #6E88A8;
            --cyan: #17C8FF;
            --blue: #087BFF;
            --indigo: #315BFF;
            --purple: #6C46FF;
            --success: #25E38A;
            --warning: #FFB020;
            --danger: #FF355D;
            --info: #48B9FF;

            --gradient-primary: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%);
            --gradient-secondary: linear-gradient(90deg, #087BFF 0%, #6C46FF 100%);
            --gradient-panel: linear-gradient(180deg, #0B2440 0%, #06182C 100%);
            --gradient-page: radial-gradient(circle at 70% 5%, rgba(23,200,255,.14), transparent 32%), linear-gradient(180deg, #04111F 0%, #020B16 100%);

            --radius-sm: 12px;
            --radius-md: 16px;
            --radius-lg: 22px;
            --radius-xl: 28px;
            --radius-pill: 999px;

            --shadow-card: 0 12px 40px rgba(0,0,0,.28);
            --shadow-glow: 0 0 24px rgba(23,200,255,.28);
            --shadow-button: 0 10px 30px rgba(8,123,255,.32);

            --font-ui: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            background: var(--gradient-page);
            background-color: var(--bg);
            color: var(--text);
            font-family: var(--font-ui);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            overflow-x: hidden;
            position: relative;
        }

        /* Ambient Glow Background Effects */
        .ambient-light-top {
            position: fixed;
            top: -100px;
            right: 10%;
            width: 450px;
            height: 450px;
            background: radial-gradient(circle, rgba(23, 200, 255, 0.18) 0%, rgba(8, 123, 255, 0.05) 50%, transparent 70%);
            border-radius: 50%;
            filter: blur(60px);
            pointer-events: none;
            z-index: 0;
        }

        .ambient-light-center {
            position: fixed;
            top: 30%;
            left: 50%;
            transform: translateX(-50%);
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, rgba(8, 123, 255, 0.15) 0%, rgba(49, 91, 255, 0.04) 50%, transparent 75%);
            border-radius: 50%;
            filter: blur(80px);
            pointer-events: none;
            z-index: 0;
        }

        /* Mobile Device Frame Container */
        .app-container {
            width: 100%;
            max-width: 440px;
            min-height: 100vh;
            background: var(--gradient-page);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            position: relative;
            z-index: 1;
            padding: 12px 20px 24px 20px;
            box-shadow: 0 0 60px rgba(0, 0, 0, 0.6);
        }

        @media (min-width: 481px) {
            body {
                padding: 20px 0;
            }
            .app-container {
                min-height: 880px;
                max-height: 940px;
                border-radius: 40px;
                border: 1px solid var(--border-soft);
                overflow-y: auto;
                scrollbar-width: none;
            }
            .app-container::-webkit-scrollbar {
                display: none;
            }
        }

        /* Top Mobile Status Bar */
        .status-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 4px 6px 12px 6px;
            font-size: 14px;
            font-weight: 600;
            color: var(--text);
            letter-spacing: -0.2px;
        }

        .status-bar .status-icons {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
        }

        /* Top Action Header */
        .header-action {
            display: flex;
            justify-content: flex-end;
            align-items: center;
            padding-bottom: 8px;
        }

        .btn-skip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 18px;
            background: rgba(11, 36, 64, 0.4);
            border: 1px solid var(--border-soft);
            border-radius: var(--radius-pill);
            color: var(--text);
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .btn-skip:hover, .btn-skip:active {
            border-color: var(--cyan);
            color: var(--cyan);
            box-shadow: 0 0 16px rgba(23, 200, 255, 0.3);
            transform: translateY(-1px);
        }

        /* Logo Header Section */
        .logo-section {
            text-align: center;
            margin-top: 4px;
            margin-bottom: 12px;
        }

        .brand-logo-wrap {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-bottom: 4px;
        }

        .site-db-logo {
            max-height: 52px;
            width: auto;
            max-width: 240px;
            object-fit: contain;
            filter: drop-shadow(0 4px 16px rgba(23, 200, 255, 0.35));
        }

        .brand-icon-d {
            width: 44px;
            height: 44px;
            background: var(--gradient-primary);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: var(--shadow-glow);
            clip-path: polygon(0 0, 100% 0, 100% 75%, 75% 100%, 0 100%);
            position: relative;
        }

        .brand-icon-d::before {
            content: 'D';
            font-family: var(--font-ui);
            font-weight: 900;
            font-size: 26px;
            color: #04111F;
            font-style: italic;
        }

        .brand-name {
            font-size: 34px;
            font-weight: 800;
            letter-spacing: -0.8px;
            line-height: 1;
        }

        .brand-name .text-dream {
            color: var(--text);
        }

        .brand-name .text-hub {
            background: var(--gradient-primary);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-tagline {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            font-size: 13px;
            font-weight: 500;
            color: var(--text-2);
            letter-spacing: 0.3px;
            margin-top: 2px;
        }

        .brand-tagline::before,
        .brand-tagline::after {
            content: '';
            display: block;
            width: 42px;
            height: 1px;
            background: linear-gradient(90deg, transparent, var(--border), transparent);
        }

        .sub-bullet-features {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-top: 14px;
            font-size: 14px;
            font-weight: 500;
            color: var(--text);
        }

        .sub-bullet-features .dot {
            color: var(--cyan);
            font-size: 10px;
            text-shadow: 0 0 8px var(--cyan);
        }

        /* Hero Cards Graphic Container */
        .hero-cards-section {
            position: relative;
            width: 100%;
            margin: 12px 0 8px 0;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .hero-cards-wrapper {
            position: relative;
            width: 100%;
            max-width: 360px;
            border-radius: var(--radius-lg);
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 4px;
            animation: floatHero 6s ease-in-out infinite alternate;
        }

        @keyframes floatHero {
            0% { transform: translateY(0px); }
            100% { transform: translateY(-8px); }
        }

        .hero-cards-img {
            width: 100%;
            height: auto;
            max-height: 240px;
            object-fit: cover;
            object-position: center;
            border-radius: var(--radius-md);
            box-shadow: 0 16px 36px rgba(0, 0, 0, 0.45);
            display: block;
        }

        /* Main Headline & Subtitle */
        .hero-text-content {
            text-align: center;
            margin-top: 8px;
            margin-bottom: 12px;
        }

        .hero-headline {
            font-size: 24px;
            font-weight: 800;
            color: var(--text);
            line-height: 1.25;
            letter-spacing: -0.4px;
        }

        .hero-subbullets {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            margin-top: 8px;
            font-size: 14px;
            font-weight: 500;
            color: var(--text-2);
        }

        .hero-subbullets .dot {
            color: var(--blue);
            font-size: 8px;
        }

        /* Slide Pagination Dots */
        .pagination-dots {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            margin: 12px 0 16px 0;
        }

        .dot-item {
            height: 6px;
            border-radius: var(--radius-pill);
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .dot-item.active {
            width: 26px;
            background: var(--gradient-primary);
            box-shadow: var(--shadow-glow);
        }

        .dot-item.inactive {
            width: 6px;
            background: var(--surface-3);
            border: 1px solid var(--border-soft);
        }

        .dot-item.inactive:hover {
            background: var(--text-muted);
        }

        /* Download App Panel Card */
        .download-panel-card {
            background: var(--gradient-panel);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            padding: 18px 16px;
            text-align: center;
            box-shadow: var(--shadow-card);
            backdrop-filter: blur(14px);
            margin-bottom: 18px;
            position: relative;
            overflow: hidden;
        }

        .download-panel-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 1px;
            background: linear-gradient(90deg, transparent, rgba(23, 200, 255, 0.4), transparent);
        }

        .download-title {
            font-size: 17px;
            font-weight: 700;
            color: var(--text);
            margin-bottom: 3px;
        }

        .download-subtitle {
            font-size: 12px;
            color: var(--text-2);
            margin-bottom: 14px;
            font-weight: 400;
        }

        .store-buttons-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }

        .store-btn {
            display: flex;
            align-items: center;
            gap: 8px;
            background: var(--bg);
            border: 1px solid var(--border-soft);
            border-radius: var(--radius-sm);
            padding: 8px 10px;
            text-decoration: none;
            color: var(--text);
            transition: all 0.25s ease;
        }

        .store-btn:hover, .store-btn:active {
            border-color: var(--cyan);
            background: var(--surface);
            box-shadow: 0 4px 18px rgba(8, 123, 255, 0.2);
            transform: translateY(-2px);
        }

        .store-btn svg {
            width: 24px;
            height: 24px;
            flex-shrink: 0;
        }

        .store-btn-text {
            display: flex;
            flex-direction: column;
            text-align: left;
            line-height: 1.1;
        }

        .store-btn-text .sub {
            font-size: 9px;
            color: var(--text-2);
            text-transform: uppercase;
            letter-spacing: 0.2px;
            font-weight: 500;
        }

        .store-btn-text .main {
            font-size: 13px;
            font-weight: 700;
            color: var(--text);
            margin-top: 1px;
            white-space: nowrap;
        }

        /* Bottom Feature Navigation Icons */
        .bottom-features-nav {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 8px;
            padding-top: 4px;
        }

        .feature-nav-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            text-decoration: none;
            color: var(--text-2);
            transition: all 0.2s ease;
            cursor: pointer;
        }

        .feature-nav-item:hover {
            color: var(--text);
        }

        .feature-nav-item .icon-box {
            width: 38px;
            height: 38px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--cyan);
            font-size: 22px;
            margin-bottom: 4px;
            transition: all 0.25s ease;
        }

        .feature-nav-item:hover .icon-box {
            transform: translateY(-2px);
            filter: drop-shadow(0 0 10px var(--cyan));
        }

        .feature-nav-item .label {
            font-size: 11px;
            font-weight: 500;
            color: var(--text-2);
            line-height: 1.25;
        }
    </style>
</head>
<body>

    <!-- Ambient Glow BG -->
    <div class="ambient-light-top"></div>
    <div class="ambient-light-center"></div>

    <!-- App Container -->
    <div class="app-container">
        
        <!-- Top Status Bar -->
        <div>

            <!-- Top Header Action -->
            <div class="header-action">
                <a href="<?php echo $login_url; ?>" class="btn-skip">
                    Skip <i class="bi bi-chevron-right" style="font-size: 11px;"></i>
                </a>
            </div>

            <!-- Brand Logo & Sub-header -->
            <div class="logo-section">
                <div class="brand-logo-wrap">
                    <?php if (!empty($db_logo_url)): ?>
                        <img src="<?php echo htmlspecialchars($db_logo_url); ?>" alt="<?php echo htmlspecialchars($site_title); ?>" class="site-db-logo">
                    <?php else: ?>
                        <div class="brand-icon-d"></div>
                        <h1 class="brand-name">
                            <?php 
                            $title_parts = explode(' ', $site_title, 2);
                            if (count($title_parts) > 1) {
                                echo '<span class="text-dream">' . htmlspecialchars($title_parts[0]) . '</span><span class="text-hub">' . htmlspecialchars($title_parts[1]) . '</span>';
                            } else {
                                echo '<span class="text-dream">' . htmlspecialchars($site_title) . '</span>';
                            }
                            ?>
                        </h1>
                    <?php endif; ?>
                </div>
                <div class="brand-tagline"><?php echo htmlspecialchars($site_title); ?> Online Hub</div>
                <div class="sub-bullet-features">
                    <span class="dot">•</span>
                    <span>Recharge</span>
                    <span class="dot">•</span>
                    <span>Withdraw</span>
                    <span class="dot">•</span>
                    <span>UPI</span>
                    <span class="dot">•</span>
                </div>
            </div>
        </div>

        <!-- Middle Hero Visual Section -->
        <div>
            <div class="hero-cards-section">
                <div class="hero-cards-wrapper">
                    <img src="<?php echo $hero_img_path; ?>" alt="<?php echo htmlspecialchars($site_title); ?> Gaming Hub" class="hero-cards-img">
                </div>
            </div>

            <!-- Headline & Dynamic Slide Text -->
            <div class="hero-text-content">
                <h2 class="hero-headline" id="slide-title">Your Trusted Online Hub</h2>
                <div class="hero-subbullets" id="slide-subbullets">
                    <span>Fast</span>
                    <span class="dot">•</span>
                    <span>Secure</span>
                    <span class="dot">•</span>
                    <span>Reliable</span>
                </div>
            </div>

            <!-- Pagination Dots -->
            <div class="pagination-dots">
                <div class="dot-item active" onclick="switchSlide(0)"></div>
                <div class="dot-item inactive" onclick="switchSlide(1)"></div>
                <div class="dot-item inactive" onclick="switchSlide(2)"></div>
                <div class="dot-item inactive" onclick="switchSlide(3)"></div>
            </div>
        </div>

        <!-- Bottom Download Panel & Feature Navigation -->
        <div>
            <!-- Download Panel -->
            <div class="download-panel-card">
                <div class="download-title">Download Our App</div>
                <div class="download-subtitle">Get the best experience on your device</div>
                
                <div class="store-buttons-grid">
                    <!-- App Store Button -->
                    <a href="<?php echo $login_url; ?>" class="store-btn">
                        <svg viewBox="0 0 384 512" fill="currentColor">
                            <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.7 26.2 2 52.2-14.7 69.5-34.1z"/>
                        </svg>
                        <div class="store-btn-text">
                            <span class="sub">Download on the</span>
                            <span class="main">App Store</span>
                        </div>
                    </a>

                    <!-- Google Play Button -->
                    <a href="<?php echo $login_url; ?>" class="store-btn">
                        <svg viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1z" fill="#EA4335"/>
                            <path d="M47 38.6C41.9 44.1 39 52.6 39 63.8v384.4c0 11.2 2.9 19.7 8 25.2l12.7 12.7L280.9 265 59.7 25.9 47 38.6z" fill="#4285F4"/>
                            <path d="M325.3 277.7l60.1 60.1L104.6 499l220.7-221.3z" fill="#34A853"/>
                            <path d="M466 235.8l-80.6-46.4-60.1 60.1 60.1 60.1 80.7-46.4c16.1-9.2 26.9-27.4 0-27.4z" fill="#FBBC04"/>
                        </svg>
                        <div class="store-btn-text">
                            <span class="sub">GET IT ON</span>
                            <span class="main">Google Play</span>
                        </div>
                    </a>
                </div>
            </div>

            <!-- Bottom Feature Navigation Bar -->
            <div class="bottom-features-nav">
                <a href="<?php echo $login_url; ?>" class="feature-nav-item">
                    <div class="icon-box">
                        <i class="bi bi-shield-check"></i>
                    </div>
                    <div class="label">Secure<br>Transactions</div>
                </a>
                <a href="<?php echo $login_url; ?>" class="feature-nav-item">
                    <div class="icon-box">
                        <i class="bi bi-lightning-charge"></i>
                    </div>
                    <div class="label">Instant<br>Access</div>
                </a>
                <a href="<?php echo $login_url; ?>" class="feature-nav-item">
                    <div class="icon-box">
                        <i class="bi bi-headset"></i>
                    </div>
                    <div class="label">24/7<br>Support</div>
                </a>
            </div>
        </div>

    </div>

    <script>
        // Update live status bar time
        function updateClock() {
            const now = new Date();
            let hours = now.getHours();
            let minutes = now.getMinutes();
            minutes = minutes < 10 ? '0' + minutes : minutes;
            document.getElementById('current-time').textContent = hours + ':' + minutes;
        }
        updateClock();
        setInterval(updateClock, 30000);

        // Slide carousel content
        const slides = [
            {
                title: "Your Trusted<br>Online Gaming Hub",
                bullets: ["Fast", "Secure", "Reliable"]
            },
            {
                title: "Instant Recharge<br>& Deposit Bonus",
                bullets: ["Automated", "Instant", "Bonus Rewards"]
            },
            {
                title: "Fast Cashouts<br>& 24/7 Withdrawals",
                bullets: ["Zero Fees", "Direct Bank", "Fast Approval"]
            },
            {
                title: "24/7 Support<br>& Dedicated VIP Help",
                bullets: ["Live Chat", "Instant Help", "VIP Rewards"]
            }
        ];

        let currentSlide = 0;

        function switchSlide(index) {
            currentSlide = index;
            const titleEl = document.getElementById('slide-title');
            const bulletsEl = document.getElementById('slide-subbullets');
            const dots = document.querySelectorAll('.dot-item');

            dots.forEach((dot, idx) => {
                if (idx === index) {
                    dot.className = 'dot-item active';
                } else {
                    dot.className = 'dot-item inactive';
                }
            });

            titleEl.style.opacity = '0';
            bulletsEl.style.opacity = '0';

            setTimeout(() => {
                titleEl.innerHTML = slides[index].title;
                bulletsEl.innerHTML = slides[index].bullets
                    .map((item, i) => `<span>${item}</span>${i < slides[index].bullets.length - 1 ? ' <span class="dot">•</span> ' : ''}`)
                    .join('');
                titleEl.style.opacity = '1';
                bulletsEl.style.opacity = '1';
            }, 180);
        }

        // Auto slide change every 5 seconds
        setInterval(() => {
            let nextIndex = (currentSlide + 1) % slides.length;
            switchSlide(nextIndex);
        }, 5000);
    </script>
</body>
</html>
