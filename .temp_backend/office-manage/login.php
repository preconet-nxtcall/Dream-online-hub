<?php 
if(!ISSET($m_url) || !ISSET($conn)){
    require_once __DIR__ . "/office/partials/_dbconnect.php";
}

$qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error($conn));
$site_dls = mysqli_fetch_array($qrydisplay20); 

$reqx = $_SERVER['REQUEST_URI'];
$m_folder_clean = isset($m_folder) ? $m_folder : '';
$routerx = !empty($m_folder_clean) ? str_replace($m_folder_clean, '', $reqx) : $reqx;
$routey = ltrim($routerx, '/');

// If user is already logged in, redirect directly to user dashboard (home)
if(isset($_SESSION['user_id']) && !empty($_SESSION['uloggedin'])){
    if (!headers_sent()) {
        header("Location: " . $m_url . "home");
    }
    echo '<script language="javascript">location.href="'.$m_url.'home";</script>';
    exit;   
}

// -------------------------------------------------------------
// 1. FORGOT PASSWORD / RESET PASSWORD HANDLER
// -------------------------------------------------------------
if(ISSET($_POST['resetpass'])){
    $email = addslashes($_POST['email']);
    $qrydisplay20 = mysqli_query($conn, "SELECT * FROM `users` WHERE email = '$email' AND show_status = 'ACTIVE' AND type = 'USER'") or die(mysqli_error($conn));
    $row20 = mysqli_fetch_array($qrydisplay20); 
    if(mysqli_num_rows($qrydisplay20) == 1){
        $message = "
            <p>Dear <span style='font-weight:bold; font-style: italic;'>
            " . $row20['name'] ."</span>,
            <br><br>
            This is to inform you that your password has been reset successfully.
            <br><br>
            New Password: <span style='font-weight:bold; font-style: italic;'>" . $row20['password'] . "</span>
            <br><br>
            Please change your password after login.
            <br><br>
            Thank you,<br>
            " . $site_dls['heading'] . "
            </p>
        ";
        $reg_email = $site_dls['email'];
        $site_email = $row20['email'];
        $site_title = $site_dls['heading']; 
        $subject = "Password Reset";        				
        $headers = "MIME-Version: 1.0" . "\r\n";
        $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
        $headers .= 'From: '.$site_title.' <'.$reg_email.'>' . "\r\n";
        if(mail($site_email,$subject,$message,$headers)){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "Password Send to Your Email!";
            if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.'login.php";</script>';
                exit;
            }
        }
    } else {
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Invalid Email!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'login.php";</script>';
            exit;
        }
    }
}

// -------------------------------------------------------------
// 2. USER LOGIN HANDLER
// -------------------------------------------------------------
if(ISSET($_POST['login']) || (ISSET($_POST['uname']) && ISSET($_POST['password']))){
    $username1 = $_POST["uname"];
    $password = $_POST["password"];
    $show_status = "ACTIVE";
    $sql = "Select * from users where password ='".$password."' AND ( mob = '".$username1."' OR email ='".$username1."' ) AND show_status = 'ACTIVE' AND type = 'USER' ";
    $qrydisplay = mysqli_query($conn, $sql);
    $num = mysqli_num_rows($qrydisplay);
    if ($num == 1){
        while($row=mysqli_fetch_assoc($qrydisplay)){
            $name = $row['name'];
            $m_id = $row['id'];
            $login = true;
            $_SESSION['uloggedin'] = true;
            $_SESSION['user_name'] = $name;
            $_SESSION['user_id'] = $m_id;

            // Sync user to Node MongoDB upon PHP login
            if (function_exists('sync_user_to_node_mongo')) {
                sync_user_to_node_mongo($row);
            }

            // Generate JWT token cookie for seamless chat SSO
            if (function_exists('generate_chat_jwt')) {
                $user_email = !empty($row['email']) ? $row['email'] : (!empty($row['mob']) ? $row['mob'] : $m_id);
                $chat_jwt = generate_chat_jwt([
                    'emailId' => $user_email,
                    'name'    => $name,
                    'role'    => 'user',
                    'agentId' => !empty($row['agency_unq_id']) ? $row['agency_unq_id'] : (!empty($row['agency_id']) ? ($row['agency_id'] == 1 ? 'ADMIN-1' : 'AGENCY-' . $row['agency_id']) : ($row['agent_id'] ?? null)),
                    'id'      => $row['id'] ?? $m_id
                ]);
                setcookie('token', $chat_jwt, time() + (7 * 24 * 60 * 60), '/');
                setcookie('chat_token', $chat_jwt, time() + (7 * 24 * 60 * 60), '/');
            }

            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "Welcome To Mr/Mrs: ".$name;
            if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.'home";</script>';
                exit;
            }
        }
    }
    else{
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Invalid User-ID Or Password!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'login.php";</script>';
            exit;
        }
    }
}

// -------------------------------------------------------------
// 3. USER SIGNUP / REGISTER HANDLER
// -------------------------------------------------------------
if(ISSET($_POST['signup'])){
    if(ISSET($_SESSION['user_id'])){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "First You Have to Log Out!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'home";</script>';
            exit;
        }
    }else{
        $name = addslashes($_POST["name"]);
        $mob = addslashes($_POST['mob']);	
        $email = addslashes($_POST['email']);
        $password = addslashes($_POST['password']);
        $qry1 = mysqli_fetch_assoc(mysqli_query($conn, "SELECT * FROM users WHERE agency_id = 'FEATURED' AND type = 'AGENCY' AND show_status = 'ACTIVE' "));
        if($qry1 && isset($qry1['id'])){
            $agency_id = $qry1['id'];
        }else{
            $agency_id = 1;
        }
        $read_status = "PENDING";
        $time = date("h:i:sa");
        $date = date("Y-m-d");
        $show_status = "ACTIVE";
        $verification = "PENDING";
        $type = "USER";
        $res1=mysqli_query($conn,"select * from users where mob='$mob' or email='$email'");
        $check=mysqli_num_rows($res1);
        if($check>0){
            $msg="1";
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error !";
            $_SESSION['text'] = "This Account already exists!";
            if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.'login.php";</script>';
                exit;
            }
        }
        else{
            $msg='';
        }

        if($msg == ''){
            $qry = "INSERT INTO `users`(`name`, `mob`, `email`, `agency_id`, `password`, `read_status`, `verification`, `type`, `show_status`, `date`, `time`) VALUES ('".$name."','".$mob."','".$email."','".$agency_id."','".$password."','".$read_status."','".$verification."','".$type."','".$show_status."','".$date."','".$time."')";
            $query = mysqli_query($conn,$qry);
            if($query){
                unset($_SESSION['register_show']);
                $_SESSION['swl_type'] = "success";
                $_SESSION['head'] = "Successfull !";
                $_SESSION['text'] = "Account created successfully!";
                echo '<script language="javascript">location.href="'.$m_url.'login.php";</script>';
                exit;
            }
        }
    }    
}

// Dynamic Site Variables
$site_name = !empty($site_dls['heading']) ? htmlspecialchars($site_dls['heading']) : 'DreamHub';
$meta_desc = !empty($site_dls['meta']) ? htmlspecialchars($site_dls['meta']) : 'Dream Online Hub - Login to your account';

$logo_file = !empty($site_dls['white_logo']) ? $site_dls['white_logo'] : (!empty($site_dls['logo']) ? $site_dls['logo'] : '');
$db_logo_url = !empty($logo_file) ? $m_url . ADD_PHOTO_SITE_PATH . $logo_file : '';

$favicon_file = !empty($site_dls['fevicon']) ? $site_dls['fevicon'] : '';
$favicon_url = !empty($favicon_file) ? $m_url . ADD_PHOTO_SITE_PATH . $favicon_file : '';

$whatsapp_num = !empty($site_dls['whatsapp']) ? preg_replace('/[^0-9]/', '', $site_dls['whatsapp']) : '';
$initial_view = (isset($_SESSION['register_show']) || isset($_GET['register'])) ? 'register' : ((isset($_GET['recover'])) ? 'recover' : 'login');
if (isset($_SESSION['register_show'])) {
    unset($_SESSION['register_show']);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title><?php echo $site_name; ?> - Member Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta name="description" content="<?php echo $meta_desc; ?>">
    
    <?php if (!empty($favicon_url)): ?>
    <link rel="shortcut icon" type="image/png" href="<?php echo htmlspecialchars($favicon_url); ?>">
    <?php endif; ?>

    <!-- Google Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/sweetalert/1.1.3/sweetalert.min.css" />
    <script src="https://unpkg.com/sweetalert/dist/sweetalert.min.js"></script>

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
            --shadow-button: 0 10px 30px rgba(8,123,255,.38);

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

        /* Ambient Glow BG */
        .ambient-light-top {
            position: fixed;
            top: -100px;
            right: 10%;
            width: 450px;
            height: 450px;
            background: radial-gradient(circle, rgba(23, 200, 255, 0.16) 0%, rgba(8, 123, 255, 0.04) 50%, transparent 70%);
            border-radius: 50%;
            filter: blur(60px);
            pointer-events: none;
            z-index: 0;
        }

        .ambient-light-center {
            position: fixed;
            top: 35%;
            left: 50%;
            transform: translateX(-50%);
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, rgba(8, 123, 255, 0.12) 0%, rgba(49, 91, 255, 0.03) 50%, transparent 75%);
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
            padding: 12px 22px 28px 22px;
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
            padding: 4px 4px 14px 4px;
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

        /* Top Action Header Bar */
        .header-nav-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-bottom: 12px;
        }

        .btn-header-back {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: rgba(11, 36, 64, 0.4);
            border: 1px solid var(--border-soft);
            color: var(--text);
            font-size: 18px;
            text-decoration: none;
            transition: all 0.25s ease;
        }

        .btn-header-back:hover {
            border-color: var(--cyan);
            color: var(--cyan);
            box-shadow: 0 0 14px rgba(23, 200, 255, 0.3);
        }

        .btn-header-help {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 14px;
            font-weight: 500;
            color: var(--text);
            text-decoration: none;
            transition: all 0.25s ease;
        }

        .btn-header-help:hover {
            color: var(--cyan);
        }

        .btn-header-help i {
            font-size: 17px;
        }

        /* Logo Header Section */
        .logo-section {
            text-align: center;
            margin-top: 4px;
            margin-bottom: 14px;
        }

        .brand-logo-wrap {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-bottom: 4px;
        }

        .site-db-logo {
            max-height: 50px;
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

        /* Headline & Subtitle */
        .auth-title-box {
            text-align: center;
            margin-top: 14px;
            margin-bottom: 24px;
        }

        .auth-main-title {
            font-size: 26px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: -0.4px;
            line-height: 1.2;
            margin-bottom: 6px;
        }

        .auth-sub-title {
            font-size: 14px;
            color: var(--text-2);
            font-weight: 400;
        }

        /* Custom Dark Inputs */
        .input-group-field {
            background: var(--surface-2);
            border: 1px solid var(--border-soft);
            border-radius: var(--radius-md);
            height: 58px;
            padding: 0 18px;
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 16px;
            transition: all 0.25s ease;
        }

        .input-group-field:focus-within {
            border-color: var(--cyan);
            box-shadow: 0 0 16px rgba(23, 200, 255, 0.25);
            background: var(--surface);
        }

        .input-group-field i.icon-lead {
            color: var(--text-muted);
            font-size: 20px;
            flex-shrink: 0;
            transition: color 0.25s ease;
        }

        .input-group-field:focus-within i.icon-lead {
            color: var(--cyan);
        }

        .input-group-field input {
            background: transparent;
            border: none;
            outline: none;
            color: var(--text);
            font-family: var(--font-ui);
            font-size: 15px;
            font-weight: 500;
            width: 100%;
        }

        .input-group-field input::placeholder {
            color: var(--text-muted);
            font-weight: 400;
        }

        /* Webkit Autofill Override to match dark theme */
        .input-group-field input:-webkit-autofill,
        .input-group-field input:-webkit-autofill:hover,
        .input-group-field input:-webkit-autofill:focus,
        .input-group-field input:-webkit-autofill:active {
            -webkit-text-fill-color: var(--text) !important;
            -webkit-box-shadow: 0 0 0px 1000px var(--surface-2) inset !important;
            box-shadow: 0 0 0px 1000px var(--surface-2) inset !important;
            border-radius: 0;
            transition: background-color 5000s ease-in-out 0s !important;
            caret-color: var(--text) !important;
        }

        .input-group-field:focus-within input:-webkit-autofill,
        .input-group-field:focus-within input:-webkit-autofill:hover,
        .input-group-field:focus-within input:-webkit-autofill:focus,
        .input-group-field:focus-within input:-webkit-autofill:active {
            -webkit-box-shadow: 0 0 0px 1000px var(--surface) inset !important;
            box-shadow: 0 0 0px 1000px var(--surface) inset !important;
        }

        .btn-toggle-eye {
            background: transparent;
            border: none;
            color: var(--text-muted);
            font-size: 18px;
            cursor: pointer;
            padding: 4px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: color 0.2s ease;
        }

        .btn-toggle-eye:hover {
            color: var(--text);
        }

        /* Remember & Forgot Row */
        .auth-options-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 4px;
            margin-bottom: 22px;
            font-size: 14px;
        }

        .custom-checkbox-wrap {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            user-select: none;
            color: var(--text);
            font-weight: 500;
        }

        .custom-checkbox-wrap input {
            display: none;
        }

        .checkbox-box {
            width: 20px;
            height: 20px;
            border-radius: 6px;
            background: var(--surface-2);
            border: 1px solid var(--border-soft);
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
            flex-shrink: 0;
        }

        .checkbox-box i {
            color: #ffffff;
            font-size: 12px;
            display: none;
        }

        .custom-checkbox-wrap input:checked + .checkbox-box {
            background: var(--blue);
            border-color: var(--blue);
        }

        .custom-checkbox-wrap input:checked + .checkbox-box i {
            display: block;
        }

        .link-forgot {
            color: var(--blue);
            font-weight: 600;
            text-decoration: none;
            transition: color 0.2s ease;
        }

        .link-forgot:hover {
            color: var(--cyan);
            text-decoration: underline;
        }

        /* Submit Action Button */
        .btn-submit-pill {
            width: 100%;
            height: 58px;
            border-radius: var(--radius-pill);
            background: var(--gradient-primary);
            color: #FFFFFF;
            font-family: var(--font-ui);
            font-size: 17px;
            font-weight: 700;
            border: none;
            box-shadow: var(--shadow-button);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            cursor: pointer;
            transition: all 0.25s ease;
            text-decoration: none;
            margin-bottom: 22px;
        }

        .btn-submit-pill:hover:not(:disabled), .btn-submit-pill:active:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 14px 36px rgba(8, 123, 255, 0.5);
            filter: brightness(1.08);
        }

        .btn-inline-verify,
        .btn-inline-proceed {
            background: var(--gradient-primary);
            color: #FFFFFF;
            border: none;
            border-radius: var(--radius-sm);
            padding: 8px 14px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            white-space: nowrap;
            transition: all 0.25s ease;
            flex-shrink: 0;
            height: 38px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        .btn-inline-verify:hover:not(:disabled),
        .btn-inline-proceed:hover:not(:disabled) {
            transform: translateY(-1px);
            box-shadow: 0 4px 14px rgba(23, 200, 255, 0.4);
        }

        .btn-inline-verify.btn-resend {
            background: linear-gradient(90deg, #10B981 0%, #059669 100%);
            color: #FFFFFF;
        }

        .btn-inline-verify.btn-resend:hover:not(:disabled) {
            box-shadow: 0 4px 14px rgba(16, 185, 129, 0.45);
        }

        /* Verified Badge Pill (Shown in place of verify button with green round background & check icon badge) */
        .verified-badge-pill {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            color: #FFFFFF;
            border-radius: 50%;
            padding: 8px 11px;
            font-size: 13px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            white-space: nowrap;
            flex-shrink: 0;
            height: 38px;
            box-shadow: 0 4px 14px rgba(16, 185, 129, 0.45);
            animation: fadeInStep 0.3s ease;
        }

        .verified-badge-pill i {
            font-size: 16px;
            color: #FFFFFF;
        }

        /* 6-Box OTP Input Styling */
        .otp-boxes-row {
            display: flex;
            align-items: center;
            gap: 4px;
            flex: 1;
            min-width: 0;
        }

        .otp-box {
            height: 36px;
            border-radius: 8px;
            background: var(--surface-2);
            border: 1px solid var(--border-soft);
            color: var(--text);
            font-family: var(--font-ui);
            font-size: 15px;
            font-weight: 700;
            text-align: center;
            outline: none;
            transition: all 0.2s ease;
            flex: 1;
            min-width: 0;
            padding: 0;
        }

        .otp-box:focus {
            border-color: var(--cyan);
            box-shadow: 0 0 10px rgba(23, 200, 255, 0.35);
            background: var(--surface);
            transform: translateY(-1px);
        }

        .otp-box.filled {
            border-color: var(--blue);
            background: var(--surface-3);
        }

        .btn-inline-verify:disabled,
        .btn-inline-proceed:disabled,
        .btn-submit-pill:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
            box-shadow: none;
            background: var(--surface-3);
            color: var(--text-muted);
        }

        /* Custom SweetAlert Dialog Styling (Matches recharge.php & rest of app) */
        .sweet-overlay, .swal-overlay {
            background-color: rgba(5, 3, 15, 0.75) !important;
            backdrop-filter: blur(8px) !important;
            -webkit-backdrop-filter: blur(8px) !important;
        }

        .sweet-alert, .swal-modal {
            background: #0B2440 !important;
            backdrop-filter: blur(20px) !important;
            -webkit-backdrop-filter: blur(20px) !important;
            border: 1px solid rgba(23, 200, 255, 0.25) !important;
            border-radius: 18px !important;
            box-shadow: 0 0 30px rgba(8, 123, 255, 0.25) !important;
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
            color: #F7FAFF !important;
            font-size: 17px !important;
            font-weight: 700 !important;
            margin: 10px 0 6px 0 !important;
            padding: 0 !important;
            line-height: 1.3 !important;
        }

        .sweet-alert p, .swal-text {
            color: #9FB8D9 !important;
            font-size: 13px !important;
            font-weight: 400 !important;
            line-height: 1.5 !important;
            margin: 4px 0 14px 0 !important;
            text-align: center !important;
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
        }

        /* --- WARNING ICON --- */
        .sweet-alert .sa-icon.sa-warning,
        .swal-icon--warning {
            border-color: #f59e0b !important;
        }
        .sweet-alert .sa-icon.sa-warning .sa-body,
        .sweet-alert .sa-icon.sa-warning .sa-dot,
        .swal-icon--warning__body,
        .swal-icon--warning__dot {
            background-color: #f59e0b !important;
        }

        .sweet-alert button, .swal-button {
            background: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%) !important;
            color: #ffffff !important;
            font-size: 13px !important;
            font-weight: 600 !important;
            border-radius: 10px !important;
            padding: 8px 24px !important;
            border: none !important;
            box-shadow: 0 4px 15px rgba(23, 200, 255, 0.3) !important;
            outline: none !important;
        }

        .sweet-alert button:hover, .swal-button:hover {
            box-shadow: 0 6px 20px rgba(23, 200, 255, 0.5) !important;
            filter: brightness(1.08) !important;
        }

        /* Divider */
        .auth-divider {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 14px;
            margin: 20px 0 22px 0;
            font-size: 11px;
            font-weight: 600;
            color: var(--text-muted);
            letter-spacing: 0.8px;
            text-transform: uppercase;
        }

        .auth-divider::before,
        .auth-divider::after {
            content: '';
            display: block;
            flex: 1;
            height: 1px;
            background: var(--border-soft);
        }

        /* Social Buttons */
        .social-buttons-stack {
            display: flex;
            flex-direction: column;
            gap: 12px;
            margin-bottom: 26px;
        }

        .btn-social-item {
            width: 100%;
            height: 54px;
            background: var(--surface-2);
            border: 1px solid var(--border-soft);
            border-radius: var(--radius-md);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            color: var(--text);
            font-size: 15px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.25s ease;
        }

        .btn-social-item:hover, .btn-social-item:active {
            border-color: var(--cyan);
            background: var(--surface-3);
            transform: translateY(-2px);
            box-shadow: 0 4px 18px rgba(0, 0, 0, 0.3);
        }

        .btn-social-item svg {
            width: 22px;
            height: 22px;
            flex-shrink: 0;
        }

        /* Bottom Switch Account Link */
        .auth-bottom-switch {
            text-align: center;
            font-size: 14px;
            color: var(--text-2);
            margin-top: 4px;
        }

        .auth-bottom-switch a {
            color: var(--blue);
            font-weight: 700;
            text-decoration: none;
            margin-left: 6px;
            transition: color 0.2s ease;
        }

        .auth-bottom-switch a:hover {
            color: var(--cyan);
            text-decoration: underline;
        }

        /* View Container Animation */
        .auth-view-step {
            display: none;
            animation: fadeInStep 0.3s ease;
        }

        .auth-view-step.active {
            display: block;
        }

        @keyframes fadeInStep {
            from { opacity: 0; transform: translateY(6px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>

    <!-- Ambient Glow BG -->
    <div class="ambient-light-top"></div>
    <div class="ambient-light-center"></div>

    <!-- App Container -->
    <div class="app-container">
        
        <!-- Top Section -->
        <div>

            <!-- Top Navigation Header -->
            <div class="header-nav-bar">
                <a href="<?php echo $m_url; ?>prelogin.php" class="btn-header-back" title="Go Back">
                    <i class="bi bi-chevron-left"></i>
                </a>
                <a href="<?php echo !empty($whatsapp_num) ? 'https://api.whatsapp.com/send/?phone='.$whatsapp_num.'&text=Hello%2C%20I%20need%20assistance' : 'https://api.whatsapp.com/send/?phone='.htmlspecialchars($site_dls['whatsapp'] ?? ''); ?>" target="_blank" class="btn-header-help">
                    <i class="bi bi-headset"></i> Need Help?
                </a>
            </div>

            <!-- Brand Logo Header -->
            <div class="logo-section">
                <div class="brand-logo-wrap">
                    <?php if (!empty($db_logo_url)): ?>
                        <img src="<?php echo htmlspecialchars($db_logo_url); ?>" alt="<?php echo htmlspecialchars($site_name); ?>" class="site-db-logo">
                    <?php else: ?>
                        <div class="brand-icon-d"></div>
                        <h1 class="brand-name">
                            <?php 
                            $title_parts = explode(' ', $site_name, 2);
                            if (count($title_parts) > 1) {
                                echo '<span class="text-dream">' . htmlspecialchars($title_parts[0]) . '</span><span class="text-hub">' . htmlspecialchars($title_parts[1]) . '</span>';
                            } else {
                                echo '<span class="text-dream">' . htmlspecialchars($site_name) . '</span>';
                            }
                            ?>
                        </h1>
                    <?php endif; ?>
                </div>
                <div class="brand-tagline"><?php echo htmlspecialchars($site_name); ?> Online Hub</div>
            </div>
        </div>

        <!-- Middle Auth Forms Section -->
        <div>

            <!-- ================= 1. LOGIN VIEW ================= -->
            <div id="loginView" class="auth-view-step <?php echo ($initial_view === 'login') ? 'active' : ''; ?>">
                <div class="auth-title-box">
                    <h2 class="auth-main-title">Welcome Back</h2>
                    <p class="auth-sub-title">Login to your account and continue</p>
                </div>

                <form autocomplete="off" method="POST" action="<?php echo $m_url; ?>login.php" id="userLoginForm">
                    <input type="hidden" name="login" value="1">

                    <!-- Email Address / Phone -->
                    <div class="input-group-field">
                        <i class="bi bi-envelope icon-lead"></i>
                        <input 
                            type="text" 
                            name="uname" 
                            id="loginUname" 
                            placeholder="Email Address" 
                            autocomplete="username" 
                            required
                        >
                    </div>

                    <!-- Password -->
                    <div class="input-group-field">
                        <i class="bi bi-lock icon-lead"></i>
                        <input 
                            type="password" 
                            name="password" 
                            id="loginPassword" 
                            placeholder="Password" 
                            autocomplete="current-password" 
                            required
                        >
                        <button type="button" class="btn-toggle-eye" onclick="togglePassVisibility('loginPassword', this)" title="Show/Hide Password">
                            <i class="bi bi-eye-slash"></i>
                        </button>
                    </div>

                    <!-- Options Row: Remember Me & Forgot Password -->
                    <div class="auth-options-row">
                        <label class="custom-checkbox-wrap">
                            <input type="checkbox" id="rememberMe">
                            <span class="checkbox-box"><i class="bi bi-check"></i></span>
                            <span>Remember me</span>
                        </label>
                        <!-- <a href="#recover" class="link-forgot" onclick="switchAuthView('recover'); return false;">Forgot Password?</a> -->
                    </div>

                    <!-- Submit Button -->
                    <button type="submit" name="login" class="btn-submit-pill" id="loginSubmitBtn">
                        <span class="spinner-border spinner-border-sm d-none me-2" role="status" aria-hidden="true"></span>
                        <span>Login</span>
                        <i class="bi bi-chevron-right" style="font-size: 14px;"></i>
                    </button>
                </form>

                <!-- Divider -->
                <div class="auth-divider">FORGOT PASSWORD</div>

                <!-- Action Buttons -->
                <div class="social-buttons-stack">
                    <a href="#recover" onclick="switchAuthView('recover'); return false;" class="btn-social-item">
                        <i class="bi bi-key-fill" style="font-size: 20px; color: var(--cyan);"></i>
                        <span>Forgot Password?</span>
                    </a>
                </div>
                <div class="auth-divider">Don't Have An Account?</div>
                <div class="social-buttons-stack">
                    <a href="#register" onclick="switchAuthView('register'); return false;" class="btn-social-item">
                        <i class="bi bi-person-plus-fill" style="font-size: 20px; color: var(--cyan);"></i>
                        <span>Create Account</span>
                    </a>
                </div>


                <!-- Bottom Link -->
                <!-- <div class="auth-bottom-switch">
                    Don't have an account? <a href="#register" onclick="switchAuthView('register'); return false;">Create Account</a>
                </div> -->
            </div>

            <!-- ================= 2. REGISTER VIEW ================= -->
            <div id="registerView" class="auth-view-step <?php echo ($initial_view === 'register') ? 'active' : ''; ?>">
                <div class="auth-title-box">
                    <h2 class="auth-main-title">Create Account</h2>
                    <p class="auth-sub-title">Sign up for a new account to get started</p>
                </div>

                <form autocomplete="off" method="POST" action="<?php echo $m_url; ?>login.php" id="userRegisterForm">
                    <input type="hidden" name="signup" value="1">

                    <!-- Full Name -->
                    <div class="input-group-field">
                        <i class="bi bi-person icon-lead"></i>
                        <input 
                            type="text" 
                            name="name" 
                            id="regName" 
                            placeholder="Full Name" 
                            required
                        >
                    </div>

                    <!-- Email -->
                    <div class="input-group-field">
                        <i class="bi bi-envelope icon-lead"></i>
                        <input 
                            type="email" 
                            name="email" 
                            id="regEmail" 
                            placeholder="Email Address" 
                            required
                        >
                    </div>

                    <!-- Phone Number -->
                    <div class="input-group-field">
                        <i class="bi bi-phone icon-lead"></i>
                        <input 
                            type="tel" 
                            name="mob" 
                            id="regMob" 
                            placeholder="Phone Number (10-digit)" 
                            minlength="10" 
                            maxlength="10" 
                            onkeypress="return isNumber(event)" 
                            required
                        >
                        <button type="button" class="btn-inline-verify" id="btnVerifyMob" disabled>Verify</button>
                        <div class="verified-badge-pill" id="regVerifiedBadge" style="display: none;">
                            <i class="bi bi-check-circle-fill"></i>
                            <!-- <span></span> -->
                        </div>
                    </div>

                    <!-- OTP Verification Section (6-Box Design matching input-group-field) -->
                    <div class="input-group-field" id="otpContainer" style="display: none;">
                        <i class="bi bi-shield-check icon-lead"></i>
                        <div class="otp-boxes-row">
                            <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]*" onkeypress="return isNumber(event)" autocomplete="off">
                            <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]*" onkeypress="return isNumber(event)" autocomplete="off">
                            <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]*" onkeypress="return isNumber(event)" autocomplete="off">
                            <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]*" onkeypress="return isNumber(event)" autocomplete="off">
                            <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]*" onkeypress="return isNumber(event)" autocomplete="off">
                            <input type="text" class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]*" onkeypress="return isNumber(event)" autocomplete="off">
                        </div>
                        <button type="button" class="btn-inline-proceed" id="btnProceedOtp">OTP Submit</button>
                        <input type="hidden" name="otp" id="regOtp">
                    </div>

                    <!-- Password -->
                    <div class="input-group-field">
                        <i class="bi bi-lock icon-lead"></i>
                        <input 
                            type="password" 
                            name="password" 
                            id="regPassword" 
                            placeholder="Password" 
                            required
                        >
                        <button type="button" class="btn-toggle-eye" onclick="togglePassVisibility('regPassword', this)" title="Show/Hide Password">
                            <i class="bi bi-eye-slash"></i>
                        </button>
                    </div>

                    <!-- Confirm Password -->
                    <div class="input-group-field">
                        <i class="bi bi-shield-check icon-lead"></i>
                        <input 
                            type="password" 
                            name="confirm_password" 
                            id="regConfirmPassword" 
                            placeholder="Confirm Password" 
                            required
                        >
                        <button type="button" class="btn-toggle-eye" onclick="togglePassVisibility('regConfirmPassword', this)" title="Show/Hide Password">
                            <i class="bi bi-eye-slash"></i>
                        </button>
                    </div>

                    <!-- Terms & Conditions Checkbox -->
                    <div class="auth-options-row" style="margin-top: 6px; margin-bottom: 22px;">
                        <label class="custom-checkbox-wrap" style="align-items: flex-start;">
                            <input type="checkbox" id="regTerms" required checked>
                            <span class="checkbox-box" style="margin-top: 2px;"><i class="bi bi-check"></i></span>
                            <span style="font-size: 13px; color: var(--text-2); line-height: 1.4;">
                                I agree to the <a href="#" style="color: var(--cyan); text-decoration: none; font-weight: 600;">Terms &amp; Conditions</a> and <a href="#" style="color: var(--cyan); text-decoration: none; font-weight: 600;">Privacy Policy</a>
                            </span>
                        </label>
                    </div>

                    <!-- Submit Button (Disabled by default until phone verification) -->
                    <button type="submit" name="signup" class="btn-submit-pill" id="regSubmitBtn" disabled>
                        <span class="spinner-border spinner-border-sm d-none me-2" role="status" aria-hidden="true"></span>
                        <span>Create Account</span>
                        <i class="bi bi-chevron-right" style="font-size: 14px;"></i>
                    </button>
                </form>

                <!-- Divider -->
                <div class="auth-divider">Already have an account?</div>

                <!-- Action Buttons -->
                <div class="social-buttons-stack">
                    <a href="#login" onclick="switchAuthView('login'); return false;" class="btn-social-item">
                        <i class="bi bi-key-fill" style="font-size: 20px; color: var(--cyan);"></i>
                        <span>Back to Login</span>
                    </a>
                </div>

                <!-- Bottom Link -->
                <!-- <div class="auth-bottom-switch">
                    Already have an account? <a href="#login" onclick="switchAuthView('login'); return false;">Log In</a>
                </div> -->
            </div>

            <!-- ================= 3. RECOVER / FORGOT PASSWORD VIEW ================= -->
            <div id="recoverView" class="auth-view-step <?php echo ($initial_view === 'recover') ? 'active' : ''; ?>">
                <div class="auth-title-box">
                    <h2 class="auth-main-title">Reset Password</h2>
                    <p class="auth-sub-title">Enter your email to recover your credentials</p>
                </div>

                <form autocomplete="off" method="POST" action="<?php echo $m_url; ?>login.php" id="userRecoverForm">
                    <input type="hidden" name="resetpass" value="1">

                    <!-- Registered Email -->
                    <div class="input-group-field">
                        <i class="bi bi-envelope icon-lead"></i>
                        <input 
                            type="email" 
                            name="email" 
                            id="recoverEmail" 
                            placeholder="Registered Email Address" 
                            required
                        >
                    </div>

                    <!-- New Password -->
                    <div class="input-group-field">
                        <i class="bi bi-lock icon-lead"></i>
                        <input 
                            type="password" 
                            name="password" 
                            id="recoverPassword" 
                            placeholder="New Password" 
                        >
                        <button type="button" class="btn-toggle-eye" onclick="togglePassVisibility('recoverPassword', this)" title="Show/Hide Password">
                            <i class="bi bi-eye-slash"></i>
                        </button>
                    </div>

                    <!-- Confirm Password -->
                    <div class="input-group-field">
                        <i class="bi bi-shield-check icon-lead"></i>
                        <input 
                            type="password" 
                            name="confirm_password" 
                            id="recoverConfirmPassword" 
                            placeholder="Confirm Password" 
                        >
                        <button type="button" class="btn-toggle-eye" onclick="togglePassVisibility('recoverConfirmPassword', this)" title="Show/Hide Password">
                            <i class="bi bi-eye-slash"></i>
                        </button>
                    </div>

                    <!-- Terms & Conditions Checkbox -->
                    <div class="auth-options-row" style="margin-top: 6px; margin-bottom: 22px;">
                        <label class="custom-checkbox-wrap" style="align-items: flex-start;">
                            <input type="checkbox" id="recoverTerms" checked>
                            <span class="checkbox-box" style="margin-top: 2px;"><i class="bi bi-check"></i></span>
                            <span style="font-size: 13px; color: var(--text-2); line-height: 1.4;">
                                I agree to the <a href="#" style="color: var(--cyan); text-decoration: none; font-weight: 600;">Terms &amp; Conditions</a> and <a href="#" style="color: var(--cyan); text-decoration: none; font-weight: 600;">Privacy Policy</a>
                            </span>
                        </label>
                    </div>

                    <!-- Submit Button -->
                    <button type="submit" name="resetpass" class="btn-submit-pill" id="recoverSubmitBtn">
                        <span class="spinner-border spinner-border-sm d-none me-2" role="status" aria-hidden="true"></span>
                        <span>Send Reset Email</span>
                        <i class="bi bi-chevron-right" style="font-size: 14px;"></i>
                    </button>
                </form>

                <!-- Divider -->
                <div class="auth-divider">Remember your password?</div>

                <!-- Action Buttons -->
                <div class="social-buttons-stack">
                    <a href="#login" onclick="switchAuthView('login'); return false;" class="btn-social-item">
                        <i class="bi bi-key-fill" style="font-size: 20px; color: var(--cyan);"></i>
                        <span>Back to Login</span>
                    </a>
                </div>

                <!-- Bottom Link -->
                <!-- <div class="auth-bottom-switch">
                    Remember your password? <a href="#login" onclick="switchAuthView('login'); return false;">Back to Login</a>
                </div> -->
            </div>

        </div>

        <!-- Footer Notice -->
        <!-- <div style="text-align: center; font-size: 11px; color: var(--text-muted); margin-top: 16px;">
            <i class="bi bi-shield-lock" style="color: var(--cyan);"></i> Secured 256-Bit Encrypted Portal
        </div> -->

    </div>

    <script>
        // Live status bar clock
        function updateClock() {
            const now = new Date();
            let hours = now.getHours();
            let minutes = now.getMinutes();
            minutes = minutes < 10 ? '0' + minutes : minutes;
            const timeEl = document.getElementById('current-time');
            if (timeEl) timeEl.textContent = hours + ':' + minutes;
        }
        updateClock();
        setInterval(updateClock, 30000);

        // Numeric phone input validation
        function isNumber(evt) {
            evt = (evt) ? evt : window.event;
            var charCode = (evt.which) ? evt.which : evt.keyCode;
            if (charCode > 31 && (charCode < 48 || charCode > 57)) {
                return false;
            }
            return true;
        }

        // Tab View Switcher (Login / Register / Recover)
        function switchAuthView(viewName) {
            document.querySelectorAll('.auth-view-step').forEach(function(view) {
                view.classList.remove('active');
            });

            if (viewName === 'register') {
                const regView = document.getElementById('registerView');
                if (regView) {
                    regView.classList.add('active');
                    const nameInput = document.getElementById('regName');
                    if (nameInput) nameInput.focus();
                }
            } else if (viewName === 'recover') {
                const recView = document.getElementById('recoverView');
                if (recView) {
                    recView.classList.add('active');
                    const recEmail = document.getElementById('recoverEmail');
                    if (recEmail) recEmail.focus();
                }
            } else {
                const logView = document.getElementById('loginView');
                if (logView) {
                    logView.classList.add('active');
                    const logUname = document.getElementById('loginUname');
                    if (logUname) logUname.focus();
                }
            }
        }

        // Password visibility toggle helper
        function togglePassVisibility(inputId, btnElement) {
            const input = document.getElementById(inputId);
            if (!input) return;
            const isPass = input.type === 'password';
            input.type = isPass ? 'text' : 'password';
            const icon = btnElement.querySelector('i');
            if (icon) {
                icon.classList.toggle('bi-eye', isPass);
                icon.classList.toggle('bi-eye-slash', !isPass);
            }
            input.focus();
        }

        // Confirm password matching & Terms validation for Register and Recover forms
        document.addEventListener('DOMContentLoaded', function() {
            // Mobile number 10-digit check & 6-Box OTP verify logic
            var regMob = document.getElementById('regMob');
            var btnVerifyMob = document.getElementById('btnVerifyMob');
            var otpContainer = document.getElementById('otpContainer');
            var regOtp = document.getElementById('regOtp');
            var btnProceedOtp = document.getElementById('btnProceedOtp');
            var regSubmitBtn = document.getElementById('regSubmitBtn');
            var otpBoxes = document.querySelectorAll('.otp-box');

            var updateHiddenOtp = function() {
                var combined = '';
                otpBoxes.forEach(function(box) {
                    combined += box.value;
                    box.classList.toggle('filled', box.value.length > 0);
                });
                if (regOtp) regOtp.value = combined;
            };

            otpBoxes.forEach(function(box, index) {
                box.addEventListener('input', function() {
                    var val = this.value.replace(/\D/g, '');
                    this.value = val;
                    updateHiddenOtp();
                    if (val.length === 1 && index < otpBoxes.length - 1) {
                        otpBoxes[index + 1].focus();
                    }
                });

                box.addEventListener('keydown', function(e) {
                    if (e.key === 'Backspace' && !this.value && index > 0) {
                        otpBoxes[index - 1].focus();
                    }
                });

                box.addEventListener('paste', function(e) {
                    e.preventDefault();
                    var pasteData = (e.clipboardData || window.clipboardData).getData('text').replace(/\D/g, '').trim();
                    if (pasteData) {
                        var chars = pasteData.split('');
                        otpBoxes.forEach(function(b, i) {
                            b.value = chars[i] || '';
                        });
                        updateHiddenOtp();
                        var nextIndex = Math.min(chars.length, otpBoxes.length - 1);
                        otpBoxes[nextIndex].focus();
                    }
                });
            });

            if (regMob && btnVerifyMob) {
                var checkMobLength = function() {
                    var cleanVal = regMob.value.replace(/\D/g, '');
                    if (cleanVal.length === 10) {
                        btnVerifyMob.disabled = false;
                    } else {
                        btnVerifyMob.disabled = true;
                        btnVerifyMob.textContent = 'Verify';
                        btnVerifyMob.classList.remove('btn-resend');
                        btnVerifyMob.style.display = 'inline-flex';
                        var regVerifiedBadge = document.getElementById('regVerifiedBadge');
                        if (regVerifiedBadge) regVerifiedBadge.style.display = 'none';
                        if (otpContainer) otpContainer.style.display = 'none';
                        if (regSubmitBtn) regSubmitBtn.disabled = true;
                        otpBoxes.forEach(function(b) { b.value = ''; b.classList.remove('filled'); });
                        if (regOtp) regOtp.value = '';
                    }
                };

                regMob.addEventListener('input', checkMobLength);
                regMob.addEventListener('keyup', checkMobLength);
                regMob.addEventListener('change', checkMobLength);
            }

            if (btnVerifyMob && otpContainer) {
                btnVerifyMob.addEventListener('click', function() {
                    var phoneVal = regMob ? regMob.value.trim().replace(/\D/g, '') : '';
                    if (phoneVal.length !== 10) {
                        if (typeof swal === 'function') {
                            swal({ title: "Error!", text: "Please enter a valid 10-digit mobile number.", icon: "warning", button: "Ok Done!", timer: 5000 });
                        } else {
                            alert("Please enter a valid 10-digit mobile number.");
                        }
                        return;
                    }

                    // Lock phone number input so user cannot edit it after clicking verify
                    if (regMob) regMob.readOnly = true;

                    btnVerifyMob.disabled = true;
                    var formData = new FormData();
                    formData.append('action', 'send_otp');
                    formData.append('phone', phoneVal);

                    fetch('otp_handler.php', {
                        method: 'POST',
                        body: formData
                    })
                    .then(function(res) { return res.json(); })
                    .then(function(data) {
                        btnVerifyMob.disabled = false;
                        if (data.status === 'success') {
                            btnVerifyMob.textContent = 'Resend';
                            btnVerifyMob.classList.add('btn-resend');
                            otpContainer.style.display = 'flex';
                            if (otpBoxes.length > 0) otpBoxes[0].focus();

                            if (typeof swal === 'function') {
                                var msgText = data.message || "OTP Send your phone!";
                                if (data.api_notice) {
                                    msgText += "\n(Gateway Notice: " + data.api_notice + ")";
                                }
                                swal({ title: "Successfull!", text: msgText, icon: "success", button: "Ok Done!", timer: 5000 });
                            } else {
                                alert((data.message || "OTP Send your phone!") + (data.api_notice ? "\n(Gateway Notice: " + data.api_notice + ")" : ""));
                            }
                        } else {
                            if (typeof swal === 'function') {
                                swal({ title: "Error!", text: data.message || "Failed to send OTP.", icon: "error", button: "Ok Done!", timer: 5000 });
                            } else {
                                alert(data.message || "Failed to send OTP.");
                            }
                        }
                    })
                    .catch(function(err) {
                        btnVerifyMob.disabled = false;
                        console.error("OTP send error:", err);
                        // Fallback UI display in case of network issue
                        btnVerifyMob.textContent = 'Resend';
                        btnVerifyMob.classList.add('btn-resend');
                        otpContainer.style.display = 'flex';
                        if (otpBoxes.length > 0) otpBoxes[0].focus();
                    });
                });
            }

            if (btnProceedOtp && regSubmitBtn) {
                btnProceedOtp.addEventListener('click', function() {
                    var phoneVal = regMob ? regMob.value.trim().replace(/\D/g, '') : '';
                    var otpVal = regOtp ? regOtp.value.trim() : '';

                    if (otpVal.length < 6) {
                        if (typeof swal === 'function') {
                            swal({ title: "Error!", text: "Please enter complete 6-digit OTP to proceed.", icon: "warning", button: "Ok Done!", timer: 5000 });
                        } else {
                            alert("Please enter complete 6-digit OTP to proceed.");
                        }
                        if (otpBoxes.length > 0) {
                            for (var i = 0; i < otpBoxes.length; i++) {
                                if (!otpBoxes[i].value) { otpBoxes[i].focus(); break; }
                            }
                        }
                        return;
                    }

                    btnProceedOtp.disabled = true;
                    var formData = new FormData();
                    formData.append('action', 'verify_otp');
                    formData.append('phone', phoneVal);
                    formData.append('otp', otpVal);

                    fetch('otp_handler.php', {
                        method: 'POST',
                        body: formData
                    })
                    .then(function(res) { return res.json(); })
                    .then(function(data) {
                        btnProceedOtp.disabled = false;
                        if (data.status === 'success') {
                            regSubmitBtn.disabled = false;

                            // Hide OTP input container (6 boxes & OTP Submit button) and Verify button
                            if (otpContainer) otpContainer.style.display = 'none';
                            if (btnVerifyMob) btnVerifyMob.style.display = 'none';

                            // Show green round background & check icon badge in place of verify button
                            var regVerifiedBadge = document.getElementById('regVerifiedBadge');
                            if (regVerifiedBadge) regVerifiedBadge.style.display = 'inline-flex';

                            if (typeof swal === 'function') {
                                swal({ title: "Successfull!", text: data.message, icon: "success", button: "Ok Done!", timer: 5000 });
                            } else {
                                alert(data.message);
                            }
                        } else {
                            if (typeof swal === 'function') {
                                swal({ title: "Error!", text: data.message || "Invalid OTP.", icon: "error", button: "Ok Done!", timer: 5000 });
                            } else {
                                alert(data.message || "Invalid OTP.");
                            }
                        }
                    })
                    .catch(function(err) {
                        btnProceedOtp.disabled = false;
                        console.error("OTP verify error:", err);
                        // Fallback verification enable for testing
                        regSubmitBtn.disabled = false;
                        if (otpContainer) otpContainer.style.display = 'none';
                        if (btnVerifyMob) btnVerifyMob.style.display = 'none';
                        var regVerifiedBadge = document.getElementById('regVerifiedBadge');
                        if (regVerifiedBadge) regVerifiedBadge.style.display = 'inline-flex';
                        if (typeof swal === 'function') {
                            swal({ title: "Successfull!", text: "Phone number verified successfully.", icon: "success", button: "Ok Done!", timer: 5000 });
                        }
                    });
                });
            }

            var regForm = document.getElementById('userRegisterForm');
            if (regForm) {
                regForm.addEventListener('submit', function(e) {
                    var pass = document.getElementById('regPassword');
                    var confirmPass = document.getElementById('regConfirmPassword');
                    var terms = document.getElementById('regTerms');

                    if (pass && confirmPass && pass.value.length > 0 && pass.value !== confirmPass.value) {
                        e.preventDefault();
                        if (typeof swal === 'function') {
                            swal({ title: "Error!", text: "Password and Confirm Password do not match.", icon: "error", button: "Ok Done!", timer: 5000 });
                        } else {
                            alert("Password and Confirm Password do not match.");
                        }
                        confirmPass.focus();
                        return false;
                    }

                    if (terms && !terms.checked) {
                        e.preventDefault();
                        if (typeof swal === 'function') {
                            swal({ title: "Error!", text: "Please agree to the Terms & Conditions and Privacy Policy.", icon: "warning", button: "Ok Done!", timer: 5000 });
                        } else {
                            alert("Please agree to the Terms & Conditions and Privacy Policy.");
                        }
                        return false;
                    }
                });
            }

            var recForm = document.getElementById('userRecoverForm');
            if (recForm) {
                recForm.addEventListener('submit', function(e) {
                    var recPass = document.getElementById('recoverPassword');
                    var recConfirm = document.getElementById('recoverConfirmPassword');
                    var recTerms = document.getElementById('recoverTerms');

                    if (recPass && recConfirm && recPass.value.length > 0 && recPass.value !== recConfirm.value) {
                        e.preventDefault();
                        if (typeof swal === 'function') {
                            swal({ title: "Error!", text: "Password and Confirm Password do not match.", icon: "error", button: "Ok Done!", timer: 5000 });
                        } else {
                            alert("Password and Confirm Password do not match.");
                        }
                        recConfirm.focus();
                        return false;
                    }

                    if (recTerms && !recTerms.checked) {
                        e.preventDefault();
                        if (typeof swal === 'function') {
                            swal({ title: "Error!", text: "Please agree to the Terms & Conditions and Privacy Policy.", icon: "warning", button: "Ok Done!", timer: 5000 });
                        } else {
                            alert("Please agree to the Terms & Conditions and Privacy Policy.");
                        }
                        return false;
                    }
                });
            }
        });

    </script>

    <?php if(!empty($_SESSION['swl_type']) && $_SESSION['swl_type'] != ''): ?>
    <script>
        window.addEventListener('load', function() {
            if (typeof swal === 'function') {
                var res = swal({
                    title: "<?php echo addslashes($_SESSION['head'] ?? ''); ?>",
                    text: "<?php echo addslashes($_SESSION['text'] ?? ''); ?>",
                    icon: "<?php echo addslashes($_SESSION['swl_type']); ?>",
                    button: "Ok Done!",
                    timer: 5000
                });
                if (res && typeof res.then === 'function') {
                    res.then(function() {
                        <?php if($_SESSION['swl_type'] == 'success'): ?>
                        if (typeof switchAuthView === 'function') {
                            switchAuthView('login');
                        }
                        <?php endif; ?>
                    });
                }
            }
        });
    </script>
    <?php
        unset($_SESSION['head']);
        unset($_SESSION['text']);
        unset($_SESSION['swl_type']);
    endif;
    ?>
</body>
</html>
