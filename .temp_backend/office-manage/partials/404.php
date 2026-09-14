<?php 
if (!isset($conn) || !isset($m_url)) {
    require_once file_exists(__DIR__ . "/../office/partials/_dbconnect.php") 
        ? __DIR__ . "/../office/partials/_dbconnect.php" 
        : "office/partials/_dbconnect.php";
}
if (!isset($site_dls) && isset($conn)) {
    $qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error($conn));
    $site_dls = mysqli_fetch_array($qrydisplay20);
}
$site_title = isset($site_dls['heading']) ? $site_dls['heading'] : 'FairBiz CRM';
$favicon_path = isset($site_dls['fevicon']) ? $m_url . "uploads/site/" . $site_dls['fevicon'] : '';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>404 - Page Not Found | <?php echo htmlspecialchars($site_title); ?></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/font/bootstrap-icons.min.css">
    
    <?php if (!empty($favicon_path)): ?>
    <link rel="shortcut icon" href="<?php echo $favicon_path; ?>">
    <?php endif; ?>

    <style>
        :root {
            --bg-deep: #070913;
            --bg-card: rgba(18, 24, 43, 0.75);
            --border-card: rgba(255, 255, 255, 0.12);
            --primary: #00a884;
            --primary-glow: rgba(0, 168, 132, 0.35);
            --accent: #6366f1;
            --accent-glow: rgba(99, 102, 241, 0.35);
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
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
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
            padding: 1.5rem;
        }

        /* Ambient Lighting Background Effects */
        .ambient-glow-1 {
            position: absolute;
            top: 15%;
            left: 25%;
            width: 450px;
            height: 450px;
            background: radial-gradient(circle, var(--primary-glow) 0%, rgba(7, 9, 19, 0) 70%);
            border-radius: 50%;
            filter: blur(80px);
            pointer-events: none;
            animation: pulseGlow 8s infinite alternate ease-in-out;
        }

        .ambient-glow-2 {
            position: absolute;
            bottom: 15%;
            right: 25%;
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, var(--accent-glow) 0%, rgba(7, 9, 19, 0) 70%);
            border-radius: 50%;
            filter: blur(90px);
            pointer-events: none;
            animation: pulseGlow 10s infinite alternate ease-in-out;
        }

        @keyframes pulseGlow {
            0% { transform: scale(1) translateY(0); opacity: 0.6; }
            100% { transform: scale(1.15) translateY(-25px); opacity: 1; }
        }

        /* Error Card Wrapper */
        .error-card {
            position: relative;
            z-index: 10;
            background: var(--bg-card);
            border: 1px solid var(--border-card);
            border-radius: 24px;
            padding: 3.5rem 2.5rem;
            max-width: 540px;
            width: 100%;
            text-align: center;
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            animation: cardFloat 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }

        @keyframes cardFloat {
            from { opacity: 0; transform: translateY(20px) scale(0.96); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }

        /* Icon & Number Badge */
        .icon-badge-wrapper {
            position: relative;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1.5rem;
        }

        .icon-circle {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, rgba(0, 168, 132, 0.15) 0%, rgba(99, 102, 241, 0.15) 100%);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 22px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #00e6a8;
            font-size: 2.25rem;
            box-shadow: 0 10px 30px rgba(0, 168, 132, 0.2);
            animation: iconFloat 4s ease-in-out infinite alternate;
        }

        @keyframes iconFloat {
            0% { transform: translateY(0) rotate(0deg); }
            100% { transform: translateY(-8px) rotate(3deg); }
        }

        .code-pill {
            position: absolute;
            bottom: -8px;
            right: -12px;
            background: linear-gradient(135deg, var(--primary) 0%, #008069 100%);
            color: #ffffff;
            font-family: var(--font-heading);
            font-weight: 800;
            font-size: 0.75rem;
            padding: 0.25rem 0.65rem;
            border-radius: 50px;
            border: 2px solid var(--bg-deep);
            box-shadow: 0 4px 12px var(--primary-glow);
        }

        .error-title {
            font-family: var(--font-heading);
            font-size: clamp(1.75rem, 4vw, 2.25rem);
            font-weight: 800;
            margin-bottom: 0.75rem;
            background: linear-gradient(180deg, #ffffff 0%, #cbd5e1 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: -0.02em;
        }

        .error-subtitle {
            font-size: 0.95rem;
            color: var(--text-muted);
            line-height: 1.6;
            margin-bottom: 2.25rem;
        }

        /* Action Buttons */
        .btn-group {
            display: flex;
            gap: 1rem;
            justify-content: center;
            flex-wrap: wrap;
        }

        .btn-action {
            padding: 0.85rem 1.65rem;
            border-radius: 12px;
            font-weight: 700;
            font-size: 0.95rem;
            text-decoration: none;
            transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            cursor: pointer;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary) 0%, #008069 100%);
            color: #ffffff;
            box-shadow: 0 8px 25px var(--primary-glow);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 12px 30px var(--primary-glow);
            filter: brightness(1.1);
        }

        .btn-secondary {
            background: rgba(255, 255, 255, 0.05);
            color: var(--text-main);
            border: 1px solid var(--border-card);
        }

        .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.1);
            border-color: rgba(255, 255, 255, 0.25);
            transform: translateY(-2px);
        }

        .quick-links {
            margin-top: 2rem;
            padding-top: 1.5rem;
            border-top: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            justify-content: center;
            gap: 1.5rem;
            font-size: 0.825rem;
        }

        .quick-links a {
            color: var(--text-muted);
            text-decoration: none;
            transition: color 0.2s;
        }

        .quick-links a:hover {
            color: var(--primary);
        }
    </style>
</head>
<body>

    <div class="ambient-glow-1"></div>
    <div class="ambient-glow-2"></div>

    <div class="error-card">
        <div class="icon-badge-wrapper">
            <div class="icon-circle">
                <i class="bi bi-compass-fill"></i>
            </div>
            <span class="code-pill">404</span>
        </div>

        <h1 class="error-title">Page Not Found</h1>
        <p class="error-subtitle">
            The page or resource you are looking for doesn't exist, has been moved, or is temporarily unavailable.
        </p>

        <div class="btn-group">
            <a href="<?php echo $m_url;?>" class="btn-action btn-primary">
                <i class="bi bi-box-arrow-in-right"></i> Return to User Login
            </a>
            <a href="<?php echo $m_url;?>office/" class="btn-action btn-secondary">
                <i class="bi bi-house-door-fill"></i> Return to Staff Login
            </a>
        </div>

        <div class="quick-links">
            <a href="<?php echo $m_url;?>"><i class="bi bi-shield-lock"></i> Homepage </a>
            <a href="javascript:history.back()"><i class="bi bi-arrow-left"></i> Go Back</a>
        </div>
    </div>

</body>
</html>