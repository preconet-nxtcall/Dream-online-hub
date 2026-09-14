<?php
if (session_status() === PHP_SESSION_NONE) session_start();

if (!isset($conn) || !isset($m_url)) {
    require_once file_exists(__DIR__ . "/../office/partials/_dbconnect.php") 
        ? __DIR__ . "/../office/partials/_dbconnect.php" 
        : "office/partials/_dbconnect.php";
}

if (empty($_SESSION['uloggedin']) || empty($_SESSION['user_id'])) {
    $target = (!empty($m_url) && isset($_SERVER['HTTP_HOST']) && strpos($m_url, $_SERVER['HTTP_HOST']) !== false) ? $m_url : 'index.php';
    if (!headers_sent()) header("Location: " . $target);
    echo '<meta http-equiv="refresh" content="0;url=' . $target . '"><script>location.replace("' . $target . '");</script>';
    exit;
}
$qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error());
$site_dls = mysqli_fetch_array($qrydisplay20); 

if(ISSET($_SESSION['user_id'])){
    $uid = $_SESSION['user_id'];
    $qrydisplayd1 = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$uid'") or die(mysqli_error());
    $user_dls = mysqli_fetch_array($qrydisplayd1);
}

$reqx = $_SERVER['REQUEST_URI'];
$routerx=str_replace($m_folder,'',$reqx);

$routey=ltrim($routerx, '/');
$var_value4 = explode("/",$routey,2);

if(ISSET($_POST['add_contact'])){
    $name = addslashes($_POST["name"]);
    $phone = $_POST["phone"];
    $email = $_POST["email"];
    $sub = addslashes($_POST["sub"]);
    $msg = addslashes($_POST["msg"]);
    $show_status = "PENDING";
    $user_id = $_SESSION['user_id'];
    $qrydisplayd1 = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$user_id'") or die(mysqli_error());
    $user_dls = mysqli_fetch_array($qrydisplayd1);
    $emp_id = $user_dls['agency_id'];

    $reqx = $_SERVER['REQUEST_URI'];
    $routerx=str_replace($m_folder,'',$reqx);
    $routey=ltrim($routerx, '/');
    
    $qry = "INSERT INTO `contact`(`name`, `user_id`, `emp_id`, `phone`, `email`, `sub`, `msg`, `read_status`, `date`) VALUES ('".$name."','".$user_id."','".$emp_id."','".$phone."','".$email."','".$sub."','".$msg."','".$show_status."','".$date."')";
    $query = mysqli_query($conn,$qry);
    if($query){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "We Will Call You Soon !";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.''.$routey.'"</script>';
            exit;
        }
    }
}

$theme_mode = !empty($site_dls['theme_mode']) ? $site_dls['theme_mode'] : 'dark';
$theme_primary = !empty($site_dls['theme_primary']) ? $site_dls['theme_primary'] : '#8b5cf6';
$theme_secondary = !empty($site_dls['theme_secondary']) ? $site_dls['theme_secondary'] : '#6366f1';
$theme_bg = !empty($site_dls['theme_bg']) ? $site_dls['theme_bg'] : ($theme_mode === 'light' ? '#f8fafc' : '#0b071e');
$theme_card = !empty($site_dls['theme_card']) ? $site_dls['theme_card'] : ($theme_mode === 'light' ? '#ffffff' : '#161333');
$theme_text = !empty($site_dls['theme_text']) ? $site_dls['theme_text'] : ($theme_mode === 'light' ? '#0f172a' : '#f8fafc');
?>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US" data-theme-mode="<?php echo $theme_mode; ?>">
<head>
    <meta charset="utf-8">
    <title><?php echo $site_dls['heading'];?></title>
    <meta name="author" content="<?php echo $site_dls['heading'];?>">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <meta name="description" content="<?php echo $site_dls['meta'];?>">
    <!-- font -->
    <link rel="stylesheet" href="<?php echo $m_url; ?>assets/fonts/fonts.css">
    <!-- Icons -->
    <link rel="stylesheet" href="<?php echo $m_url; ?>assets/fonts/font-icons.css">
    <link rel="stylesheet" href="<?php echo $m_url; ?>assets/css/bootstrap.min.css">
    <link rel="stylesheet" href="<?php echo $m_url; ?>assets/css/swiper-bundle.min.css">
    <link rel="stylesheet" href="<?php echo $m_url; ?>assets/css/animate.css">
    <link rel="stylesheet" type="text/css" href="<?php echo $m_url; ?>assets/css/styles.css" />
    <link rel="stylesheet" type="text/css" href="<?php echo $m_url; ?>assets/css/theme.css" />
    <!-- Favicon and Touch Icons  -->
    <link rel="shortcut icon" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['fevicon']; ?>">
    <link rel="apple-touch-icon-precomposed" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['fevicon']; ?>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.13.1/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/sweetalert/1.1.3/sweetalert.min.css" integrity="sha512-gOQQLjHRpD3/SEOtalVq50iDn4opLVup2TF8c4QPI3/NmUPNZOk2FG0ihi8oCU/qYEsw4P6nuEZT2lAG0UNYaw==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    <script src="https://unpkg.com/sweetalert/dist/sweetalert.min.js"></script>

    <!-- Dynamic Admin Theme Variables -->
    <style id="dynamic-theme-vars">
        :root {
            --theme-mode: <?php echo $theme_mode; ?>;
            --theme-primary: <?php echo $theme_primary; ?>;
            --theme-secondary: <?php echo $theme_secondary; ?>;
            --theme-bg: <?php echo $theme_bg; ?>;
            --theme-card: <?php echo $theme_card; ?>;
            --theme-text: <?php echo $theme_text; ?>;
            --theme-primary-gradient: linear-gradient(135deg, <?php echo $theme_secondary; ?> 0%, <?php echo $theme_primary; ?> 100%);
            --theme-border: <?php echo ($theme_mode === 'light') ? 'rgba(0, 0, 0, 0.08)' : $theme_primary . '38'; ?>;
            --theme-glow: <?php echo $theme_primary . '44'; ?>;
            --theme-glow-strong: <?php echo $theme_primary . '88'; ?>;
        }

        body, #wrapper {
            background-color: var(--theme-bg) !important;
            background-image: <?php echo ($theme_mode === 'light') 
                ? 'radial-gradient(circle at 20% 10%, ' . $theme_primary . '18 0%, transparent 40%), radial-gradient(circle at 80% 50%, ' . $theme_secondary . '12 0%, transparent 45%), radial-gradient(circle at 50% 90%, ' . $theme_primary . '0d 0%, transparent 40%) !important;'
                : 'radial-gradient(circle at 20% 10%, ' . $theme_primary . '1f 0%, transparent 40%), radial-gradient(circle at 80% 50%, ' . $theme_secondary . '18 0%, transparent 45%), radial-gradient(circle at 50% 90%, ' . $theme_primary . '14 0%, transparent 40%) !important;'; ?>
            background-attachment: fixed !important;
            color: var(--theme-text) !important;
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif !important;
        }

        /* Global Custom SweetAlert Styling */
        .sweet-overlay, .swal-overlay {
            background-color: <?php echo ($theme_mode === 'light') ? 'rgba(15, 23, 42, 0.45)' : 'rgba(5, 3, 15, 0.75)'; ?> !important;
            backdrop-filter: blur(8px) !important;
            -webkit-backdrop-filter: blur(8px) !important;
        }

        .sweet-alert, .swal-modal {
            background: var(--theme-card) !important;
            backdrop-filter: blur(20px) !important;
            -webkit-backdrop-filter: blur(20px) !important;
            border: 1px solid var(--theme-border) !important;
            border-radius: 18px !important;
            box-shadow: var(--theme-shadow) !important;
            width: 320px !important;
            max-width: 88vw !important;
            padding: 20px 16px !important;
            position: fixed !important;
            top: 50% !important;
            left: 50% !important;
            transform: translate(-50%, -50%) !important;
            margin: 0 !important;
            z-index: 99999 !important;
        }

        .sweet-alert h2, .swal-title {
            color: var(--theme-text) !important;
            font-size: 17px !important;
            font-weight: 700 !important;
            margin: 10px 0 6px 0 !important;
            padding: 0 !important;
            line-height: 1.3 !important;
        }

        .sweet-alert p, .swal-text {
            color: var(--theme-text-muted) !important;
            font-size: 13px !important;
            font-weight: 400 !important;
            line-height: 1.5 !important;
            margin: 4px 0 14px 0 !important;
            text-align: center !important;
        }

        .sweet-alert .sa-icon, .swal-icon {
            transform: scale(0.65) !important;
            margin: 0 auto 2px auto !important;
        }

        .sweet-alert button, .swal-button {
            background: var(--theme-primary-gradient) !important;
            color: #ffffff !important;
            font-size: 13px !important;
            font-weight: 600 !important;
            border-radius: 10px !important;
            padding: 8px 24px !important;
            border: none !important;
            box-shadow: 0 4px 15px var(--theme-glow) !important;
            outline: none !important;
        }

        .sweet-alert button:hover, .swal-button:hover {
            box-shadow: 0 6px 20px var(--theme-glow-strong) !important;
            filter: brightness(1.08);
        }

        .sweet-alert button.cancel, .swal-button--cancel {
            background: var(--theme-surface) !important;
            color: var(--theme-text-muted) !important;
            box-shadow: none !important;
            border: 1px solid var(--theme-border) !important;
        }

        .sweet-alert button.cancel:hover, .swal-button--cancel:hover {
            background: var(--theme-border) !important;
            color: var(--theme-text) !important;
        }

        /* --- SweetAlert Icon Transparent Background & Explicit Styling --- */
        .sweet-alert .sa-icon,
        .swal-icon {
            transform: scale(0.65) !important;
            margin: 0 auto 2px auto !important;
            background-color: transparent !important;
            background: transparent !important;
        }

        .sweet-alert .sa-icon::before,
        .sweet-alert .sa-icon::after,
        .sweet-alert .sa-icon .sa-fix,
        .swal-icon::before,
        .swal-icon::after,
        .swal-icon--success::before,
        .swal-icon--success::after,
        .swal-icon--success__hide-corners,
        .swal-icon--success__ring {
            background-color: transparent !important;
            background: transparent !important;
        }

        /* --- SUCCESS ICON --- */
        .sweet-alert .sa-icon.sa-success,
        .swal-icon--success {
            border-color: #10b981 !important;
        }
        .sweet-alert .sa-icon.sa-success .sa-placeholder {
            border: 4px solid rgba(16, 185, 129, 0.3) !important;
            border-radius: 50% !important;
            background: transparent !important;
        }
        .sweet-alert .sa-icon.sa-success .sa-line,
        .swal-icon--success__line {
            background-color: #10b981 !important;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
        }

        /* --- ERROR ICON --- */
        .sweet-alert .sa-icon.sa-error,
        .swal-icon--error {
            border-color: #ef4444 !important;
        }
        .sweet-alert .sa-icon.sa-error .sa-line,
        .swal-icon--error__line {
            background-color: #ef4444 !important;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
        }

        /* --- WARNING ICON --- */
        .sweet-alert .sa-icon.sa-warning,
        .swal-icon--warning {
            border-color: #f97316 !important;
        }
        .sweet-alert .sa-icon.sa-warning .sa-body,
        .swal-icon--warning__body {
            width: 5px !important;
            height: 29px !important;
            border-radius: 2px !important;
            margin-left: -2px !important;
            background-color: #f97316 !important;
            position: absolute !important;
            left: 50% !important;
            top: 10px !important;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
        }
        .sweet-alert .sa-icon.sa-warning .sa-dot,
        .swal-icon--warning__dot {
            width: 7px !important;
            height: 7px !important;
            border-radius: 50% !important;
            margin-left: -3px !important;
            background-color: #f97316 !important;
            position: absolute !important;
            left: 50% !important;
            bottom: 10px !important;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
        }

        /* --- INFO ICON --- */
        .sweet-alert .sa-icon.sa-info,
        .swal-icon--info {
            border-color: #3b82f6 !important;
        }
        .sweet-alert .sa-icon.sa-info::before,
        .sweet-alert .sa-icon.sa-info::after,
        .swal-icon--info::before,
        .swal-icon--info::after {
            background-color: #3b82f6 !important;
            display: block !important;
            visibility: visible !important;
            opacity: 1 !important;
        }

        .game-header-glass {
            background: var(--theme-header-bg) !important;
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--theme-border) !important;
            border-radius: 18px !important;
            margin: 15px auto !important;
            max-width: 1240px;
            box-shadow: var(--theme-shadow) !important;
            padding: 10px 20px !important;
        }

        #header {
            background: transparent !important;
            box-shadow: none !important;
            border: none !important;
        }

        .logo-header img {
            max-height: 38px;
            width: auto;
            object-fit: contain;
        }

        .header-icon-btn {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: var(--theme-surface);
            border: 1px solid var(--theme-border);
            color: var(--theme-text) !important;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            text-decoration: none;
            transition: all 0.2s ease;
        }

        .header-icon-btn:hover {
            background: var(--theme-border);
            color: var(--theme-primary) !important;
            transform: translateY(-1px);
        }

        .header-menu-btn {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            background: var(--theme-surface);
            border: 1px solid var(--theme-border);
            color: var(--theme-text) !important;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            text-decoration: none;
            transition: all 0.2s ease;
        }

        .header-menu-btn:hover {
            background: var(--theme-border);
            color: var(--theme-primary) !important;
        }

        /* DreamHub Side Navigation Drawer (1:1 Mockup Design) */
        .offcanvas-backdrop,
        .offcanvas-backdrop.show {
            z-index: 10400 !important;
            background-color: rgba(0, 0, 0, 0.7) !important;
        }

        .offcanvas.canvas-mb,
        #mobileMenu,
        #mobileMenu.offcanvas-start {
            width: 320px !important;
            max-width: 85vw !important;
            background: linear-gradient(180deg, #091C35 0%, #041120 100%) !important;
            backdrop-filter: blur(24px) !important;
            -webkit-backdrop-filter: blur(24px) !important;
            border-top-right-radius: 28px !important;
            border-bottom-right-radius: 28px !important;
            border-right: 1px solid rgba(255, 255, 255, 0.08) !important;
            border-top: none !important;
            border-left: none !important;
            border-bottom: none !important;
            box-shadow: 14px 0 45px rgba(0, 0, 0, 0.65) !important;
            padding: 24px 20px 24px 20px !important;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            z-index: 10500 !important;
            pointer-events: auto !important;
        }

        .dh-sidenav-header {
            position: relative;
            padding-top: 4px;
            padding-bottom: 20px;
        }

        .dh-btn-close-drawer {
            position: absolute;
            top: -4px;
            right: -4px;
            background: transparent;
            border: none;
            color: #FFFFFF;
            font-size: 22px;
            cursor: pointer;
            padding: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: opacity 0.2s ease;
            opacity: 0.9;
            z-index: 10510 !important;
        }

        .dh-btn-close-drawer:hover {
            opacity: 1;
            color: #17C8FF;
        }

        .dh-user-profile-box {
            display: flex;
            align-items: center;
            gap: 14px;
            padding-right: 30px;
        }

        .dh-user-avatar-wrap {
            width: 62px;
            height: 62px;
            border-radius: 50%;
            border: 2px solid #17C8FF;
            box-shadow: 0 0 22px rgba(23, 200, 255, 0.6), 0 0 10px rgba(23, 200, 255, 0.4);
            object-fit: cover;
            background: #0B2440;
            flex-shrink: 0;
        }

        .dh-user-info {
            display: flex;
            flex-direction: column;
            gap: 2px;
            overflow: hidden;
        }

        .dh-user-name {
            font-size: 18px;
            font-weight: 700;
            color: #FFFFFF;
            letter-spacing: -0.2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .dh-user-email {
            font-size: 13px;
            color: #9FB8D9;
            font-weight: 400;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .dh-user-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(17, 50, 90, 0.5);
            border: 1px solid rgba(23, 200, 255, 0.3);
            border-radius: 999px;
            padding: 3px 10px;
            font-size: 11px;
            font-weight: 600;
            color: #17C8FF;
            margin-top: 4px;
            width: fit-content;
        }

        /* Menu Items Stack */
        .dh-sidenav-menu {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-top: 10px;
            flex: 1;
            overflow-y: auto;
            padding-right: 2px;
            scrollbar-width: none;
        }

        .dh-sidenav-menu::-webkit-scrollbar {
            display: none;
        }

        .dh-nav-btn {
            width: 100%;
            min-height: 52px;
            border-radius: 16px;
            padding: 8px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            text-decoration: none !important;
            transition: all 0.25s ease;
            background: rgba(11, 36, 64, 0.65);
            border: 1px solid #1A3F66;
            color: #FFFFFF !important;
            pointer-events: auto !important;
            cursor: pointer !important;
            position: relative !important;
            z-index: 10510 !important;
        }

        .dh-nav-btn * {
            pointer-events: none !important;
        }

        .dh-nav-btn:hover {
            border-color: #17C8FF;
            transform: translateX(3px);
            box-shadow: 0 4px 16px rgba(23, 200, 255, 0.25);
        }

        .dh-nav-btn.active {
            background: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%) !important;
            border-color: transparent !important;
            color: #FFFFFF !important;
            box-shadow: 0 8px 24px rgba(8, 123, 255, 0.45) !important;
        }

        .dh-nav-left {
            display: flex;
            align-items: center;
            gap: 12px;
            overflow: hidden;
        }

        .dh-nav-icon-box {
            width: 38px;
            height: 38px;
            border-radius: 12px;
            background: rgba(23, 200, 255, 0.1);
            color: #FFFFFF !important;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            flex-shrink: 0;
            transition: all 0.25s ease;
        }

        .dh-nav-btn.active .dh-nav-icon-box {
            background: rgba(255, 255, 255, 0.22);
            color: #FFFFFF !important;
        }

        .dh-nav-text-group {
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        .dh-nav-title-row {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .dh-nav-title {
            font-size: 15px;
            font-weight: 600;
            color: #FFFFFF !important;
            line-height: 1.2;
        }

        .dh-nav-subtext {
            font-size: 11px;
            color: #6E88A8;
            line-height: 1.2;
            margin-top: 2px;
        }

        .dh-nav-btn.active .dh-nav-subtext {
            color: rgba(255, 255, 255, 0.85);
        }

        .dh-badge-new {
            background: #FF355D;
            color: #FFFFFF;
            font-size: 9px;
            font-weight: 800;
            padding: 2px 6px;
            border-radius: 999px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-left: 4px;
        }

        .dh-nav-arrow {
            font-size: 14px;
            color: #FFFFFF !important;
            opacity: 0.9;
            transition: transform 0.25s ease;
        }

        .dh-nav-btn:hover .dh-nav-arrow {
            transform: translateX(2px);
        }

        /* Bottom Section / Separator & Signout */
        .dh-sidenav-bottom {
            padding-top: 16px;
            border-top: 1px solid rgba(255, 255, 255, 0.08);
            margin-top: 16px;
        }

        .dh-btn-signout {
            width: 100%;
            height: 50px;
            border-radius: 999px;
            background: rgba(11, 36, 64, 0.6);
            border: 1px solid #1A3F66;
            color: #FFFFFF !important;
            font-size: 15px;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            text-decoration: none !important;
            cursor: pointer;
            transition: all 0.25s ease;
            position: relative !important;
            z-index: 10510 !important;
            pointer-events: auto !important;
        }

        .dh-btn-signout * {
            pointer-events: none !important;
        }

        .dh-btn-signout:hover {
            border-color: #FF355D;
            color: #FF355D !important;
            background: rgba(255, 53, 93, 0.12);
            box-shadow: 0 0 18px rgba(255, 53, 93, 0.25);
        }
    </style>

</head>

<body class="preload-wrapper">

    <!-- preload -->
    <div class="preload preload-container">
        <div class="preload-logo">
            <div class="spinner"></div>
        </div>
    </div>
    <!-- /preload -->
    <div id="wrapper">

        <!-- Header -->
        <header id="header" class="header-default">
            <div class="container-fluid px-1">
                <div class="game-header-glass">
                    <div class="row align-items-center">
                        <div class="col-3 col-md-4">
                            <a href="#mobileMenu" data-bs-toggle="offcanvas" aria-controls="offcanvasLeft" class="header-menu-btn">
                                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                    <line x1="3" y1="12" x2="21" y2="12"></line>
                                    <line x1="3" y1="6" x2="21" y2="6"></line>
                                    <line x1="3" y1="18" x2="21" y2="18"></line>
                                </svg>
                            </a>
                        </div>
                        <div class="col-6 col-md-4 text-center">
                            <a href="<?php echo $m_url; ?>home.php" class="logo-header d-inline-block">
                                <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['white_logo']; ?>" alt="logo" class="logo">
                            </a>
                        </div>

                        <div class="col-3 col-md-4 text-end">
                            <a href="<?php echo $m_url;?>profile.php" class="header-icon-btn">
                                <i class="icon icon-account" style="font-size: 18px;"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </header>
        <!-- /Header -->

        <!-- DreamHub Offcanvas Side Navigation Drawer -->
        <div class="offcanvas offcanvas-start canvas-mb" id="mobileMenu" tabindex="-1" aria-hidden="true">
            <div style="display: flex; flex-direction: column; height: 100%; justify-content: space-between;">
                <div>
                    <!-- Top Profile Header -->
                    <div class="dh-sidenav-header">
                        <button type="button" class="dh-btn-close-drawer" data-bs-dismiss="offcanvas" aria-label="Close">
                            <i class="bi bi-x-lg"></i>
                        </button>
                        <div class="dh-user-profile-box">
                            <img src="<?php if(!empty($user_dls['img'])) { echo $m_url.ADD_PHOTO_SITE_PATH.$user_dls['img']; } else { echo $m_url.'assets/images/logo/user.png'; } ?>" alt="User Avatar" class="dh-user-avatar-wrap">
                            <div class="dh-user-info">
                                <div class="dh-user-name"><?php echo htmlspecialchars($user_dls['name'] ?? 'Final Test'); ?></div>
                                <div class="dh-user-email"><?php echo htmlspecialchars($user_dls['email'] ?? 'finaltest1@gmail.com'); ?></div>
                                <div>
                                    <span class="dh-user-badge">
                                        <i class="bi bi-shield-check"></i> User Account
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Menu Navigation Links -->
                    <div class="dh-sidenav-menu">
                        <!-- 1. Home -->
                        <a href="<?php echo $m_url;?>home.php" class="dh-nav-btn <?php if($routerx=='/' || $routerx=='/home' || $routerx=='/home.php'){ echo 'active'; }?>">
                            <div class="dh-nav-left">
                                <div class="dh-nav-icon-box"><i class="bi bi-house-door-fill"></i></div>
                                <span class="dh-nav-title">Home</span>
                            </div>
                            <i class="bi bi-chevron-right dh-nav-arrow"></i>
                        </a>

                        <!-- 2. Recharge -->
                        <a href="<?php echo $m_url;?>recharge.php" class="dh-nav-btn <?php if($routerx=='/recharge' || $routerx=='/recharge.php'){ echo 'active'; }?>">
                            <div class="dh-nav-left">
                                <div class="dh-nav-icon-box"><i class="bi bi-lightning-charge-fill"></i></div>
                                <span class="dh-nav-title">Recharge</span>
                            </div>
                            <i class="bi bi-chevron-right dh-nav-arrow"></i>
                        </a>

                        <!-- 3. Withdraw -->
                        <a href="<?php echo $m_url;?>withdraw.php" class="dh-nav-btn <?php if($routerx=='/withdraw' || $routerx=='/withdraw.php'){ echo 'active'; }?>">
                            <div class="dh-nav-left">
                                <div class="dh-nav-icon-box"><i class="bi bi-wallet2"></i></div>
                                <span class="dh-nav-title">Withdraw</span>
                            </div>
                            <i class="bi bi-chevron-right dh-nav-arrow"></i>
                        </a>

                        <!-- 4. Recharge Records -->
                        <a href="<?php echo $m_url;?>records.php" class="dh-nav-btn <?php if($routerx=='/records' || $routerx=='/records.php'){ echo 'active'; }?>">
                            <div class="dh-nav-left">
                                <div class="dh-nav-icon-box"><i class="bi bi-file-earmark-text-fill"></i></div>
                                <span class="dh-nav-title">Recharge Records</span>
                            </div>
                            <i class="bi bi-chevron-right dh-nav-arrow"></i>
                        </a>

                        <!-- 5. Profile -->
                        <a href="<?php echo $m_url;?>profile.php" class="dh-nav-btn <?php if($routerx=='/profile' || $routerx=='/profile.php'){ echo 'active'; }?>">
                            <div class="dh-nav-left">
                                <div class="dh-nav-icon-box"><i class="bi bi-person-fill"></i></div>
                                <span class="dh-nav-title">Profile</span>
                            </div>
                            <i class="bi bi-chevron-right dh-nav-arrow"></i>
                        </a>

                        <!-- 6. Change Password -->
                        <a href="<?php echo $m_url;?>update-password.php" class="dh-nav-btn <?php if($routerx=='/update-password' || $routerx=='/update-password.php'){ echo 'active'; }?>">
                            <div class="dh-nav-left">
                                <div class="dh-nav-icon-box"><i class="bi bi-lock-fill"></i></div>
                                <span class="dh-nav-title">Change Password</span>
                            </div>
                            <i class="bi bi-chevron-right dh-nav-arrow"></i>
                        </a>

                    </div>
                </div>

                <!-- Bottom Sign Out Section -->
                <div class="dh-sidenav-bottom">
                    <a href="javascript:void(0)" class="dh-btn-signout logout_btn_ajax">
                        <i class="bi bi-box-arrow-left" style="font-size: 18px;"></i>
                        <span>Sign out</span>
                    </a>
                </div>
            </div>
        </div>
        <!-- /mobile menu -->

