<?php 
if(!ISSET($m_url)){
    require "office/partials/_dbconnect.php";
}
$qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error());
$site_dls = mysqli_fetch_array($qrydisplay20); 

$reqx = $_SERVER['REQUEST_URI'];
$m_folder_clean = isset($m_folder) ? $m_folder : '';
$routerx = !empty($m_folder_clean) ? str_replace($m_folder_clean, '', $reqx) : $reqx;

$routey = ltrim($routerx, '/');
$var_value4 = explode("/", $routey, 2);
$page_name = strtolower(explode('?', $var_value4[0] ?? '')[0]);

// If user is already logged in, redirect directly to user dashboard (home)
if(isset($_SESSION['user_id']) && !empty($_SESSION['uloggedin'])){
    if (!headers_sent()) {
        header("Location: " . $m_url . "home");
    }
    echo '<script language="javascript">location.href="'.$m_url.'home";</script>';
    exit;   
}

// 1. Root route '/' -> Render Coming Soon landing page
if ($page_name === '') {
    require __DIR__ . "/partials/coming_soon.php";
    exit;
}

// 1b. Pre-login guide route '/prelogin' -> Render Pre-login guide page
if (in_array($page_name, ['prelogin', 'prelogin.php', 'guide', 'guide.php'], true) || (isset($is_prelogin_page) && $is_prelogin_page === true)) {
    require __DIR__ . "/partials/prelogin.php";
    exit;
}

// 2. Login & Registration routes / Form actions -> Render Login Page
$is_login_request = (isset($is_login_page) && $is_login_page === true) || 
                    in_array($page_name, ['login', 'login.php'], true) ||
                    isset($_POST['login']) || isset($_POST['signup']) || isset($_POST['resetpass']);

if ($is_login_request) {
    require __DIR__ . "/login.php";
    exit;
}

http_response_code(404);
require __DIR__ . "/partials/404.php";
exit;

