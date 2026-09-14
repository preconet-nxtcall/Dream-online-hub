<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($conn) || !isset($m_url)) {
    if (file_exists(__DIR__ . "/../../office/partials/_dbconnect.php")) {
        require_once __DIR__ . "/../../office/partials/_dbconnect.php";
    } elseif (file_exists("../office/partials/_dbconnect.php")) {
        require_once "../office/partials/_dbconnect.php";
    }
}

$_SESSION = array();

if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

session_destroy();

$target = (isset($m_url) && !empty($m_url)) ? $m_url : '../index';
header("Location: " . $target);
exit();
?>