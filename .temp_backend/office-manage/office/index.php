<?php
include 'partials/_dbconnect.php';
if(isset($_SESSION['u_id']) && $_SESSION['loggedin'] == true){
    header("location: admin_dashboard");
    exit;   
}

$qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error($conn));
$site_dls = mysqli_fetch_array($qrydisplay20); 

if(ISSET($_POST['login']) || (ISSET($_POST['uname']) && ISSET($_POST['pass']))){
	$username1 = $_POST["uname"];
	$password = $_POST["pass"];
	$sql = "Select * from users where password ='".$password."' AND ( mob = '".$username1."' OR email ='".$username1."' ) AND type != 'USER' AND show_status = 'ACTIVE'";
	$qrydisplay = mysqli_query($conn, $sql);
	$num = mysqli_num_rows($qrydisplay);
	if ($num == 1){
      	while($row=mysqli_fetch_assoc($qrydisplay)){
			$type= $row['type'];
			$ch_id = $row['id'];
			$login = true;
			if (session_status() === PHP_SESSION_NONE) {
				session_start();
			}
			$_SESSION['loggedin'] = true;
			$_SESSION['u_type'] = $type;
			$_SESSION['u_id'] = $ch_id;

			// Sync user/agent to Node MongoDB upon PHP login
			if (function_exists('sync_user_to_node_mongo')) {
				sync_user_to_node_mongo($row);
			}

			// Generate JWT token cookie for seamless chat SSO
			if (function_exists('generate_chat_jwt')) {
				$chat_role = ($type === 'ADMIN') ? 'admin' : 'agent';
				$user_email = !empty($row['email']) ? $row['email'] : (!empty($row['mob']) ? $row['mob'] : $ch_id);
				$agent_unq_id = ($type === 'ADMIN') ? ($ch_id == 1 ? 'ADMIN-1' : 'ADMIN-' . $ch_id) : 'AGENCY-' . $ch_id;

				$chat_jwt = generate_chat_jwt([
					'emailId' => $user_email,
					'name'    => $row['name'] ?? $user_email,
					'role'    => $chat_role,
					'agentId' => $agent_unq_id,
					'id'      => $ch_id
				]);
				setcookie('token', $chat_jwt, time() + (7 * 24 * 60 * 60), '/');
				setcookie('chat_token', $chat_jwt, time() + (7 * 24 * 60 * 60), '/');
			}

			header("location: admin_dashboard");
      	}
    }
    else{
		$_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Authentication Failed";
        $_SESSION['text'] = "Invalid username/mobile or password. Please verify and try again.";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    }
}

$site_name = !empty($site_dls['heading']) ? htmlspecialchars($site_dls['heading']) : 'Portal Administration';
$favicon_url = !empty($site_dls['fevicon']) ? $m_url.ADD_PHOTO_SITE_PATH.$site_dls['fevicon'] : 'assets/img/favicon.png';
$logo_url = !empty($site_dls['logo']) ? $m_url.ADD_PHOTO_SITE_PATH.$site_dls['logo'] : 'assets/img/main-log.png';
$white_logo_url = !empty($site_dls['white_logo']) ? $m_url.ADD_PHOTO_SITE_PATH.$site_dls['white_logo'] : $logo_url;
$whatsapp_num = !empty($site_dls['whatsapp']) ? preg_replace('/[^0-9]/', '', $site_dls['whatsapp']) : '';

$theme_mode = !empty($site_dls['theme_mode']) ? $site_dls['theme_mode'] : 'dark';
$theme_primary = !empty($site_dls['theme_primary']) ? $site_dls['theme_primary'] : '#2563eb';
$theme_secondary = !empty($site_dls['theme_secondary']) ? $site_dls['theme_secondary'] : '#1d4ed8';
$theme_bg = !empty($site_dls['theme_bg']) ? $site_dls['theme_bg'] : ($theme_mode === 'light' ? '#f8fafc' : '#0b071e');
$theme_card = !empty($site_dls['theme_card']) ? $site_dls['theme_card'] : ($theme_mode === 'light' ? '#ffffff' : '#161333');
$theme_text = !empty($site_dls['theme_text']) ? $site_dls['theme_text'] : ($theme_mode === 'light' ? '#0f172a' : '#f8fafc');
?>
<!DOCTYPE html>
<html lang="en" data-theme-mode="<?php echo $theme_mode; ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
    <title><?php echo $site_name; ?> &mdash; Secure Login</title>
    <link rel="shortcut icon" type="image/png" href="<?php echo $favicon_url; ?>">

    <!-- Google Fonts: Plus Jakarta Sans -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Bootstrap 5 & Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">

    <style>
        :root {
            --primary: <?php echo $theme_primary; ?>;
            --primary-dark: <?php echo $theme_secondary; ?>;
            --primary-darker: <?php echo $theme_secondary; ?>;
            --primary-light: <?php echo $theme_primary . '20'; ?>;
            --accent-cyan: <?php echo $theme_secondary; ?>;
            --slate-900: <?php echo ($theme_mode === 'light') ? '#0f172a' : '#f8fafc'; ?>;
            --slate-800: <?php echo ($theme_mode === 'light') ? '#1e293b' : '#f1f5f9'; ?>;
            --slate-700: <?php echo ($theme_mode === 'light') ? '#334155' : '#cbd5e1'; ?>;
            --slate-600: <?php echo ($theme_mode === 'light') ? '#475569' : '#94a3b8'; ?>;
            --slate-500: #64748b;
            --slate-400: #94a3b8;
            --slate-200: <?php echo ($theme_mode === 'light') ? '#e2e8f0' : 'rgba(255, 255, 255, 0.12)'; ?>;
            --slate-100: <?php echo ($theme_mode === 'light') ? '#f1f5f9' : 'rgba(255, 255, 255, 0.06)'; ?>;
            --slate-50: <?php echo ($theme_mode === 'light') ? '#f8fafc' : '#0b071e'; ?>;
            --card-border: <?php echo ($theme_mode === 'light') ? '#e2e8f0' : 'rgba(255, 255, 255, 0.1)'; ?>;
            --font-main: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }

        *, *::before, *::after {
            box-sizing: border-box;
        }

        html, body {
            width: 100%;
            min-height: 100%;
            margin: 0;
            padding: 0;
            font-family: var(--font-main);
            background-color: var(--slate-50);
            color: var(--slate-900);
            -webkit-font-smoothing: antialiased;
        }

        /* Preloader */
        #preloader {
            position: fixed;
            inset: 0;
            background: #ffffff;
            z-index: 99999;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: opacity 0.4s ease, visibility 0.4s ease;
        }

        #preloader.fade-out {
            opacity: 0;
            visibility: hidden;
            pointer-events: none;
        }

        .preloader-spinner {
            width: 44px;
            height: 44px;
            border: 3px solid var(--slate-200);
            border-top-color: var(--primary);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Layout Container */
        .login-layout {
            display: flex;
            min-height: 100vh;
            min-height: 100dvh;
            width: 100%;
            overflow-x: hidden;
        }

        /* Left Branding Showcase (Desktop) */
        .brand-panel {
            flex: 1 1 50%;
            background: linear-gradient(135deg, #09122c 0%, #10214d 45%, #1d4ed8 100%);
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            align-items: center;
            padding: 56px 48px;
            color: #ffffff;
            z-index: 1;
        }

        /* Ambient Animated Mesh Spheres */
        .mesh-sphere {
            position: absolute;
            border-radius: 50%;
            filter: blur(80px);
            opacity: 0.55;
            pointer-events: none;
            z-index: 0;
            animation: floatGlow 18s ease-in-out infinite alternate;
        }

        .mesh-sphere-1 {
            width: 420px;
            height: 420px;
            background: #2563eb;
            top: -60px;
            left: -60px;
        }

        .mesh-sphere-2 {
            width: 380px;
            height: 380px;
            background: #06b6d4;
            bottom: -50px;
            right: -50px;
            animation-duration: 22s;
            animation-delay: -6s;
        }

        .mesh-sphere-3 {
            width: 300px;
            height: 300px;
            background: #4f46e5;
            top: 40%;
            left: 50%;
            animation-duration: 16s;
            animation-delay: -9s;
        }

        @keyframes floatGlow {
            0% { transform: translate(0, 0) scale(1); }
            50% { transform: translate(45px, 35px) scale(1.12); }
            100% { transform: translate(-35px, 55px) scale(0.95); }
        }

        .brand-content {
            position: relative;
            z-index: 2;
            width: 100%;
            max-width: 540px;
            margin: auto 0;
        }

        .brand-header-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 36px;
            width: 100%;
        }

        .brand-logo-container {
            display: flex;
            align-items: center;
        }

        .brand-logo-img {
            max-height: 48px;
            max-width: 180px;
            width: auto;
            object-fit: contain;
            filter: drop-shadow(0 4px 14px rgba(0, 0, 0, 0.25));
            border-radius: 10px;
        }

        .brand-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 7px 16px;
            font-size: 0.78rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            background: rgba(37, 99, 235, 0.25);
            border: 1px solid rgba(147, 197, 253, 0.35);
            border-radius: 9999px;
            color: #93c5fd;
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            white-space: nowrap;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .brand-title {
            font-size: 2.35rem;
            font-weight: 800;
            line-height: 1.2;
            margin-bottom: 16px;
            letter-spacing: -0.02em;
            color: #ffffff;
        }

        .brand-title .text-gradient {
            background: linear-gradient(135deg, #60a5fa, #38bdf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-desc {
            font-size: 1.05rem;
            line-height: 1.6;
            color: #cbd5e1;
            margin-bottom: 36px;
        }

        /* Features List */
        .feature-grid {
            display: flex;
            flex-direction: column;
            gap: 16px;
            margin-bottom: 24px;
        }

        .feature-card {
            display: flex;
            align-items: flex-start;
            gap: 14px;
            padding: 14px 18px;
            background: rgba(255, 255, 255, 0.06);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 12px;
            transition: all 0.3s ease;
        }

        .feature-card:hover {
            background: rgba(255, 255, 255, 0.1);
            transform: translateX(4px);
            border-color: rgba(255, 255, 255, 0.18);
        }

        .feature-icon-box {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 38px;
            height: 38px;
            border-radius: 10px;
            background: rgba(37, 99, 235, 0.35);
            color: #60a5fa;
            font-size: 1.15rem;
            flex-shrink: 0;
        }

        .feature-text h6 {
            margin: 0 0 2px 0;
            font-size: 0.92rem;
            font-weight: 700;
            color: #ffffff;
        }

        .feature-text p {
            margin: 0;
            font-size: 0.8rem;
            color: #94a3b8;
            line-height: 1.4;
        }

        /* Brand Footer */
        .brand-footer {
            position: relative;
            z-index: 2;
            width: 100%;
            max-width: 540px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 0.8rem;
            color: #94a3b8;
            padding-top: 24px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }

        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 7px;
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: #22c55e;
            box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.3);
            animation: pulseDot 2s infinite;
        }

        @keyframes pulseDot {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.2); opacity: 0.7; }
        }

        /* Right Auth Panel */
        .auth-panel {
            flex: 1 1 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 40px 24px;
            background: var(--slate-50);
            position: relative;
        }

        /* Decorative background subtle glow on right */
        .auth-panel::before {
            content: '';
            position: absolute;
            top: 0;
            right: 0;
            width: 320px;
            height: 320px;
            background: radial-gradient(circle, var(--primary-light) 0%, transparent 70%);
            pointer-events: none;
        }

        .auth-card {
            width: 100%;
            max-width: 440px;
            background: <?php echo ($theme_mode === 'light') ? '#ffffff' : '#161333'; ?>;
            border-radius: 22px;
            padding: 40px 36px;
            border: 1px solid var(--card-border);
            box-shadow: <?php echo ($theme_mode === 'light') ? '0 20px 40px -15px rgba(15, 23, 42, 0.06), 0 0 1px 1px rgba(15, 23, 42, 0.02)' : '0 20px 50px rgba(0, 0, 0, 0.4), 0 0 1px 1px rgba(255, 255, 255, 0.05)'; ?>;
            position: relative;
            z-index: 2;
        }

        /* Mobile Logo Display */
        .mobile-brand-header {
            display: none;
            text-align: center;
            margin-bottom: 24px;
        }

        .mobile-brand-logo {
            max-height: 48px;
            width: auto;
            object-fit: contain;
            margin-bottom: 8px;
        }

        .portal-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            color: var(--primary);
            background: var(--primary-light);
            padding: 5px 12px;
            border-radius: 9999px;
            margin-bottom: 12px;
        }

        .auth-header {
            margin-bottom: 28px;
        }

        .auth-header h2 {
            font-size: 1.7rem;
            font-weight: 800;
            color: var(--slate-900);
            margin: 0 0 6px 0;
            letter-spacing: -0.02em;
        }

        .auth-header p {
            font-size: 0.9rem;
            color: var(--slate-500);
            margin: 0;
        }

        /* Modern Input Styles */
        .form-group-custom {
            margin-bottom: 20px;
        }

        .form-group-custom label {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--slate-700);
            margin-bottom: 8px;
        }

        .form-group-custom label i {
            color: var(--primary);
            font-size: 0.95rem;
        }

        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-wrapper .input-icon-left {
            position: absolute;
            left: 16px;
            color: var(--slate-400);
            font-size: 1.1rem;
            pointer-events: none;
            transition: color 0.25s ease;
        }

        .form-control-custom {
            width: 100%;
            height: 50px;
            padding: 12px 46px 12px 46px;
            font-size: 0.94rem;
            font-weight: 500;
            color: var(--slate-900);
            background-color: <?php echo ($theme_mode === 'light') ? '#ffffff' : 'rgba(255, 255, 255, 0.05)'; ?>;
            border: 1.5px solid var(--slate-200);
            border-radius: 12px;
            transition: all 0.25s ease;
        }

        .form-control-custom::placeholder {
            color: var(--slate-400);
            opacity: 0.75;
        }

        .form-control-custom:focus {
            outline: none;
            border-color: var(--primary);
            background-color: <?php echo ($theme_mode === 'light') ? '#ffffff' : 'rgba(255, 255, 255, 0.08)'; ?>;
            box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.18);
        }

        .form-control-custom:focus + .input-icon-left,
        .input-wrapper:focus-within .input-icon-left {
            color: var(--primary);
        }

        /* Password toggle button */
        .toggle-password-btn {
            position: absolute;
            right: 14px;
            background: none;
            border: none;
            color: var(--slate-400);
            font-size: 1.15rem;
            cursor: pointer;
            padding: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 6px;
            transition: color 0.2s ease;
        }

        .toggle-password-btn:hover {
            color: var(--slate-700);
        }

        /* Clean Autofill style */
        input:-webkit-autofill,
        input:-webkit-autofill:hover,
        input:-webkit-autofill:focus,
        input:-webkit-autofill:active {
            -webkit-box-shadow: 0 0 0 1000px <?php echo ($theme_mode === 'light') ? '#ffffff' : '#191538'; ?> inset !important;
            box-shadow: 0 0 0 1000px <?php echo ($theme_mode === 'light') ? '#ffffff' : '#191538'; ?> inset !important;
            -webkit-text-fill-color: var(--slate-900) !important;
            transition: background-color 5000s ease-in-out 0s;
        }

        /* Dual Action Buttons */
        .action-buttons-group {
            display: grid;
            grid-template-columns: 1.5fr 1fr;
            gap: 12px;
            margin-top: 26px;
            margin-bottom: 22px;
        }

        .btn-modern {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            height: 48px;
            border-radius: 12px;
            font-size: 0.95rem;
            font-weight: 600;
            padding: 0 18px;
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            border: none;
            cursor: pointer;
            text-decoration: none;
            white-space: nowrap;
        }

        .btn-signin {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: #ffffff;
            box-shadow: 0 8px 20px -4px rgba(37, 99, 235, 0.38);
        }

        .btn-signin:hover {
            background: linear-gradient(135deg, #1d4ed8 0%, #1e40af 100%);
            color: #ffffff;
            box-shadow: 0 12px 24px -4px rgba(37, 99, 235, 0.5);
            transform: translateY(-2px);
        }

        .btn-signin:active {
            transform: translateY(0);
            box-shadow: 0 4px 12px -2px rgba(37, 99, 235, 0.4);
        }

        .btn-signin.disabled, .btn-signin:disabled {
            opacity: 0.75;
            cursor: not-allowed;
            transform: none !important;
        }

        .btn-reset-modern {
            background: var(--slate-100);
            color: var(--slate-700);
            border: 1px solid var(--slate-200);
        }

        .btn-reset-modern:hover {
            background: <?php echo ($theme_mode === 'light') ? '#e2e8f0' : 'rgba(255, 255, 255, 0.12)'; ?>;
            color: var(--slate-900);
            transform: translateY(-2px);
        }

        .btn-reset-modern:active {
            transform: translateY(0);
        }

        /* WhatsApp Support Link Card */
        .whatsapp-support-card {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 16px;
            background: <?php echo ($theme_mode === 'light') ? '#f0fdf4' : 'rgba(34, 197, 94, 0.1)'; ?>;
            border: 1px solid <?php echo ($theme_mode === 'light') ? '#bbf7d0' : 'rgba(34, 197, 94, 0.25)'; ?>;
            border-radius: 12px;
            color: <?php echo ($theme_mode === 'light') ? '#15803d' : '#4ade80'; ?>;
            text-decoration: none;
            transition: all 0.25s ease;
            font-size: 0.85rem;
        }

        .whatsapp-support-card:hover {
            background: <?php echo ($theme_mode === 'light') ? '#dcfce7' : 'rgba(34, 197, 94, 0.18)'; ?>;
            border-color: <?php echo ($theme_mode === 'light') ? '#86efac' : 'rgba(34, 197, 94, 0.4)'; ?>;
            color: <?php echo ($theme_mode === 'light') ? '#166534' : '#86efac'; ?>;
            transform: translateY(-1px);
        }

        .whatsapp-icon-circle {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: #22c55e;
            color: #ffffff;
            font-size: 1.1rem;
            flex-shrink: 0;
        }

        .whatsapp-text {
            display: flex;
            flex-direction: column;
            line-height: 1.3;
        }

        .whatsapp-text strong {
            font-weight: 700;
        }

        .whatsapp-arrow {
            margin-left: auto;
            color: #22c55e;
            font-size: 0.95rem;
            transition: transform 0.2s ease;
        }

        .whatsapp-support-card:hover .whatsapp-arrow {
            transform: translateX(3px);
        }

        /* Footer Info */
        .auth-footer-info {
            text-align: center;
            margin-top: 24px;
            font-size: 0.78rem;
            color: var(--slate-400);
        }

        .auth-footer-info i {
            color: #10b981;
        }

        /* Responsive Breakpoints */
        @media (max-width: 991.98px) {
            .brand-panel {
                display: none;
            }

            .auth-panel {
                flex: 1 1 100%;
                padding: 24px 16px;
                align-items: center;
            }

            .auth-card {
                padding: 32px 24px;
                border-radius: 20px;
                box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.08);
            }

            .mobile-brand-header {
                display: block;
            }
        }

        @media (max-width: 480px) {
            .auth-card {
                padding: 26px 18px;
            }

            .action-buttons-group {
                grid-template-columns: 1fr;
            }

            .btn-modern {
                height: 46px;
                font-size: 0.92rem;
            }

            .auth-header h2 {
                font-size: 1.45rem;
            }
        }
    </style>
</head>

<body>
    <!-- Preloader -->
    <div id="preloader">
        <div class="preloader-spinner"></div>
    </div>

    <!-- Login Layout -->
    <div class="login-layout">

        <!-- Left Showcase Panel (Desktop) -->
        <div class="brand-panel">
            <!-- Animated Background Glow Spheres -->
            <div class="mesh-sphere mesh-sphere-1"></div>
            <div class="mesh-sphere mesh-sphere-2"></div>
            <div class="mesh-sphere mesh-sphere-3"></div>

            <div class="brand-content">
                <!-- Brand Logo & Console Badge on Same Row (Opposite Sides) -->
                <div class="brand-header-row">
                    <div class="brand-logo-container">
                        <img src="<?php echo $white_logo_url; ?>" alt="<?php echo $site_name; ?>" class="brand-logo-img" onerror="this.src='assets/img/main-log.png'">
                    </div>
                    <div class="brand-badge">
                        <i class="bi bi-shield-check"></i> Management Console
                    </div>
                </div>

                <h1 class="brand-title">
                    Unified Command for <span class="text-gradient"><?php echo $site_name; ?></span>
                </h1>

                <p class="brand-desc">
                    Secure central portal providing real-time financial tracking, agency ledger settlements, and authoritative access control.
                </p>

                <!-- Feature Highlights -->
                <div class="feature-grid">
                    <div class="feature-card">
                        <div class="feature-icon-box">
                            <i class="bi bi-shield-lock-fill"></i>
                        </div>
                        <div class="feature-text">
                            <h6>Enterprise Role-Based Access</h6>
                            <p>Rigorous multi-tier authorization for Admins and Agencies.</p>
                        </div>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon-box">
                            <i class="bi bi-graph-up-arrow"></i>
                        </div>
                        <div class="feature-text">
                            <h6>Real-Time Ledgers & Analytics</h6>
                            <p>Instantaneous tracking of deposits, recharges, and settlements.</p>
                        </div>
                    </div>

                    <div class="feature-card">
                        <div class="feature-icon-box">
                            <i class="bi bi-chat-square-text-fill"></i>
                        </div>
                        <div class="feature-text">
                            <h6>Unified Communication Gateway</h6>
                            <p>Integrated SSO chat and support ticketing system.</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Showcase Bottom Footer -->
            <div class="brand-footer">
                <div class="status-pill">
                    <span class="status-dot"></span>
                    <span>System Operational &bull; 99.9% Uptime</span>
                </div>
                <span>v2.6 Enterprise Edition</span>
            </div>
        </div>

        <!-- Right Auth Panel (Mobile & Desktop) -->
        <div class="auth-panel">
            <div class="auth-card">

                <!-- Mobile Logo Header (Visible only on mobile/tablet) -->
                <div class="mobile-brand-header">
                    <img src="<?php echo $logo_url; ?>" alt="<?php echo $site_name; ?>" class="mobile-brand-logo" onerror="this.src='assets/img/main-log.png'">
                </div>

                <div class="auth-header">
                    <div class="portal-badge">
                        <i class="bi bi-shield-lock-fill"></i> Secure Sign In
                    </div>
                    <h2>Welcome Back</h2>
                    <p>Enter your authorized credentials to access your console.</p>
                </div>

                <!-- Login Form -->
                <form autocomplete="off" method="post" action="index" id="adminLoginForm">
                    <input type="hidden" name="login" value="1">

                    <!-- Username / Mobile / Email -->
                    <div class="form-group-custom">
                        <label for="unameInput">
                            <i class="bi bi-person-fill"></i> Username / Mobile / Email
                        </label>
                        <div class="input-wrapper">
                            <i class="bi bi-person input-icon-left"></i>
                            <input 
                                type="text" 
                                class="form-control-custom" 
                                name="uname" 
                                id="unameInput" 
                                placeholder="Enter your username or mobile" 
                                autocomplete="username" 
                                required
                            >
                        </div>
                    </div>

                    <!-- Password -->
                    <div class="form-group-custom">
                        <label for="passInput">
                            <i class="bi bi-lock-fill"></i> Password
                        </label>
                        <div class="input-wrapper">
                            <i class="bi bi-key input-icon-left"></i>
                            <input 
                                type="password" 
                                class="form-control-custom" 
                                name="pass" 
                                id="passInput" 
                                placeholder="••••••••" 
                                autocomplete="current-password" 
                                required
                            >
                            <button type="button" class="toggle-password-btn" id="togglePasswordBtn" title="Show or hide password" aria-label="Toggle password visibility">
                                <i class="bi bi-eye-slash" id="toggleEyeIcon"></i>
                            </button>
                        </div>
                    </div>

                    <!-- Dual Action Buttons (Sign In + Reset) -->
                    <div class="action-buttons-group">
                        <button type="submit" name="login" class="btn-modern btn-signin" id="submitBtn">
                            <span class="spinner-border spinner-border-sm d-none" id="submitSpinner" role="status" aria-hidden="true"></span>
                            <i class="bi bi-box-arrow-in-right" id="submitIcon"></i>
                            <span id="submitBtnText">Sign In</span>
                        </button>
                        
                        <button type="reset" class="btn-modern btn-reset-modern" id="resetBtn" title="Clear input fields">
                            <i class="bi bi-arrow-counterclockwise"></i>
                            <span>Reset</span>
                        </button>
                    </div>

                    <!-- WhatsApp Support Help Link -->
                    <?php if(!empty($whatsapp_num)): ?>
                    <a href="https://api.whatsapp.com/send/?phone=<?php echo $whatsapp_num; ?>&text=Hello%2C%20I%20need%20help%20with%20logging%20into%20the%20Admin%20Portal" target="_blank" class="whatsapp-support-card" rel="noopener noreferrer">
                        <div class="whatsapp-icon-circle">
                            <i class="bi bi-whatsapp"></i>
                        </div>
                        <div class="whatsapp-text">
                            <span>Having Trouble Logging In?</span>
                            <strong>Get Instant WhatsApp Support</strong>
                        </div>
                        <i class="bi bi-arrow-right whatsapp-arrow"></i>
                    </a>
                    <?php else: ?>
                    <a href="https://api.whatsapp.com/send/?phone=<?php echo htmlspecialchars($site_dls['whatsapp'] ?? ''); ?>" target="_blank" class="whatsapp-support-card" rel="noopener noreferrer">
                        <div class="whatsapp-icon-circle">
                            <i class="bi bi-whatsapp"></i>
                        </div>
                        <div class="whatsapp-text">
                            <span>Having Trouble Logging In?</span>
                            <strong>Get Instant Support</strong>
                        </div>
                        <i class="bi bi-arrow-right whatsapp-arrow"></i>
                    </a>
                    <?php endif; ?>

                    <!-- End-to-End Encryption Notice -->
                    <div class="auth-footer-info">
                        <i class="bi bi-shield-check"></i> 256-Bit TLS End-to-End Encrypted Session
                    </div>

                </form>

            </div>
        </div>

    </div>

    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        // Preloader fadeout
        window.addEventListener('load', function() {
            const preloader = document.getElementById('preloader');
            if (preloader) {
                preloader.classList.add('fade-out');
                setTimeout(() => {
                    preloader.style.display = 'none';
                }, 400);
            }
        });

        // Password visibility toggle
        const toggleBtn = document.getElementById('togglePasswordBtn');
        const passInput = document.getElementById('passInput');
        const toggleEyeIcon = document.getElementById('toggleEyeIcon');

        if (toggleBtn && passInput && toggleEyeIcon) {
            toggleBtn.addEventListener('click', function() {
                const isPassword = passInput.type === 'password';
                passInput.type = isPassword ? 'text' : 'password';
                toggleEyeIcon.classList.toggle('bi-eye', isPassword);
                toggleEyeIcon.classList.toggle('bi-eye-slash', !isPassword);
                passInput.focus();
            });
        }

        // Form Submission & Reset state handling
        const loginForm = document.getElementById('adminLoginForm');
        const submitBtn = document.getElementById('submitBtn');
        const submitBtnText = document.getElementById('submitBtnText');
        const submitSpinner = document.getElementById('submitSpinner');
        const submitIcon = document.getElementById('submitIcon');
        const resetBtn = document.getElementById('resetBtn');

        if (loginForm && submitBtn) {
            loginForm.addEventListener('submit', function(e) {
                if (!loginForm.checkValidity()) {
                    return;
                }

                // Show spinner and visual feedback
                if (submitSpinner) submitSpinner.classList.remove('d-none');
                if (submitIcon) submitIcon.classList.add('d-none');
                if (submitBtnText) submitBtnText.textContent = 'Signing in...';
                submitBtn.classList.add('disabled');
                submitBtn.style.pointerEvents = 'none';

                // Delay disabling so the browser includes all form parameters in the POST payload
                setTimeout(() => {
                    submitBtn.disabled = true;
                }, 100);
            });
        }

        if (resetBtn && submitBtn) {
            resetBtn.addEventListener('click', function() {
                setTimeout(() => {
                    submitBtn.disabled = false;
                    submitBtn.style.pointerEvents = '';
                    submitBtn.classList.remove('disabled');
                    if (submitSpinner) submitSpinner.classList.add('d-none');
                    if (submitIcon) submitIcon.classList.remove('d-none');
                    if (submitBtnText) submitBtnText.textContent = 'Sign In';
                    document.getElementById('unameInput').focus();
                }, 50);
            });
        }
    </script>

    <!-- Toast Container -->
    <div id="toastContainer" class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 99999;"></div>

    <script>
        function showToast(type = "info", title = "", message = "", duration = 4000) {
            const iconMap = {
                success: 'bi-check-circle-fill',
                error: 'bi-exclamation-octagon-fill',
                warning: 'bi-exclamation-triangle-fill',
                info: 'bi-info-circle-fill'
            };

            const colorMap = {
                success: 'text-bg-success',
                error: 'text-bg-danger',
                warning: 'text-bg-warning',
                info: 'text-bg-primary'
            };

            const toastId = 'toast-' + Date.now();
            const icon = iconMap[type] || iconMap['info'];
            const color = colorMap[type] || colorMap['info'];

            const toastHTML = `
                <div id="${toastId}" class="toast align-items-center ${color} border-0 shadow-lg" role="alert" aria-live="assertive" aria-atomic="true">
                    <div class="d-flex">
                        <div class="toast-body d-flex align-items-start gap-2">
                            <i class="bi ${icon} fs-5 mt-1"></i>
                            <div>
                                <strong class="d-block">${title}</strong>
                                ${message ? '<small style="opacity: 0.95;">' + message + '</small>' : ''}
                            </div>
                        </div>
                        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
                    </div>
                </div>
            `;
            
            const toastContainer = document.getElementById('toastContainer');
            if (toastContainer) {
                toastContainer.insertAdjacentHTML('beforeend', toastHTML);
                const toastElement = document.getElementById(toastId);
                const toast = new bootstrap.Toast(toastElement, { delay: duration });
                toast.show();
                toastElement.addEventListener('hidden.bs.toast', () => {
                    toastElement.remove();
                });
            }
        }
    </script>

    <?php
        if(!empty($_SESSION['swl_type']) && $_SESSION['swl_type'] != ''){
            $head = isset($_SESSION['head']) ? $_SESSION['head'] : '';
            $text = isset($_SESSION['text']) ? $_SESSION['text'] : '';
            $type = $_SESSION['swl_type'];
            
            echo "<script>showToast('" . addslashes($type) . "', '" . addslashes($head) . "', '" . addslashes($text) . "');</script>";
            
            unset($_SESSION['head']);
            unset($_SESSION['text']);
            unset($_SESSION['swl_type']);
        }
    ?>
</body>
</html>
