<?php
mysqli_report(MYSQLI_REPORT_OFF);

$server = getenv('DB_HOST') ?: "localhost";
$username = getenv('DB_USER') ?: "root";
$password = getenv('DB_PASS') !== false ? getenv('DB_PASS') : "";
$database = getenv('DB_NAME') ?: "gamecrm";

// Try connecting to primary database (gamecrm)
$conn = @mysqli_connect($server, $username, $password, $database);

if (!$conn) {
    // When database gamecrm is not found, fallback to fairbiz database
    $database = "fairbiz";
    $conn = @mysqli_connect($server, $username, $password, $database);
    if (!$conn) {
        die("Error: " . mysqli_connect_error());
    }
}

$is_https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') 
    || (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443)
    || (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strtolower($_SERVER['HTTP_X_FORWARDED_PROTO']) === 'https');
$http_protocol = $is_https ? "https://" : "http://";
$http_host = $_SERVER['HTTP_X_FORWARDED_HOST'] ?? $_SERVER['HTTP_HOST'] ?? 'localhost';
if ($http_host === 'office-manage' || strpos($http_host, 'office-manage') !== false) {
    $http_host = $_SERVER['HTTP_X_FORWARDED_HOST'] ?? 'fairbizcrm.com';
}

// Dynamically determine root relative folder
$doc_root = rtrim(str_replace('\\', '/', $_SERVER['DOCUMENT_ROOT'] ?? ''), '/');
$current_dir = rtrim(str_replace('\\', '/', dirname(__DIR__, 2)), '/');
$sub_folder = '';
if ($doc_root && strpos($current_dir, $doc_root) === 0) {
    $sub_folder = trim(substr($current_dir, strlen($doc_root)), '/');
}

$m_folder = $sub_folder ? $sub_folder . '/' : '';
$m_url = $http_protocol . $http_host . '/' . ($m_folder ? $m_folder : '');

date_default_timezone_set("Asia/Calcutta");
$date = date("Y-m-d");
$time = date("H:i:s");
$date_ts = time();

define('SERVER_PATH', rtrim($current_dir, '/') . '/');
define('SITE_PATH', $m_url);

define('ADD_EDITOR_SERVER_PATH', SERVER_PATH . 'uploads/ckeditor/');
define('ADD_EDITOR_SITE_PATH', 'uploads/ckeditor/');

define('ADD_PHOTO_SERVER_PATH', SERVER_PATH . 'uploads/photos/');
define('ADD_PHOTO_SITE_PATH', 'uploads/photos/');

define('ADD_VIDEO_SERVER_PATH', SERVER_PATH . 'uploads/videos/');
define('ADD_VIDEO_SITE_PATH', 'uploads/videos/');

define('ADD_DOCUMENT_SERVER_PATH', SERVER_PATH . 'uploads/documents/');
define('ADD_DOCUMENT_SITE_PATH', 'uploads/documents/');

define('ADD_MUSIC_SERVER_PATH', SERVER_PATH . 'uploads/musics/');
define('ADD_MUSIC_SITE_PATH', 'uploads/musics/');

// Auto-create upload directories and set writable permissions
foreach ([ADD_EDITOR_SERVER_PATH, ADD_PHOTO_SERVER_PATH, ADD_VIDEO_SERVER_PATH, ADD_DOCUMENT_SERVER_PATH, ADD_MUSIC_SERVER_PATH] as $upload_dir) {
    if (!file_exists($upload_dir)) {
        @mkdir($upload_dir, 0777, true);
    }
    if (file_exists($upload_dir) && !is_writable($upload_dir)) {
        @chmod($upload_dir, 0777);
    }
}

// Auto-migrate site_stng dynamic theme columns if not present
if (isset($conn) && $conn) {
    static $theme_cols_checked = false;
    if (!$theme_cols_checked) {
        $theme_cols_checked = true;
        $check_theme_cols = @mysqli_query($conn, "SHOW COLUMNS FROM `site_stng` LIKE 'theme_mode'");
        if ($check_theme_cols && mysqli_num_rows($check_theme_cols) == 0) {
            @mysqli_query($conn, "ALTER TABLE `site_stng` 
                ADD COLUMN `theme_mode` varchar(10) NOT NULL DEFAULT 'dark',
                ADD COLUMN `theme_primary` varchar(20) NOT NULL DEFAULT '#8b5cf6',
                ADD COLUMN `theme_secondary` varchar(20) NOT NULL DEFAULT '#6366f1',
                ADD COLUMN `theme_bg` varchar(20) NOT NULL DEFAULT '#0b071e',
                ADD COLUMN `theme_card` varchar(20) NOT NULL DEFAULT '#161333',
                ADD COLUMN `theme_text` varchar(20) NOT NULL DEFAULT '#f8fafc'");
        }
    }
}

try {
	$pdo = new PDO("mysql:host={$server};dbname={$database}", $username, $password);
} catch(PDOException $ex) {
    error_log("Connection error :" . $ex->getMessage());
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!function_exists('generate_chat_jwt')) {
    function generate_chat_jwt($payload, $secret = null) {
        if (!$secret) {
            $secret = getenv('JWT_SECRET') ?: 'super-secret-jwt-key-agent-chat-2026';
        }
        $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        
        if (!isset($payload['exp'])) {
            $payload['exp'] = time() + (7 * 24 * 60 * 60); // 7 days default
        }
        $payload_json = json_encode($payload);
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload_json));
        
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        
        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }
}

if (!function_exists('sync_user_to_node_mongo')) {
    function sync_user_to_node_mongo($user_data) {
        try {
            $node_api_url = getenv('NODE_API_URL') ?: 'http://localhost:3000/api/auth/sync-user';

            $agency_unq_id = $user_data['agency_unq_id'] ?? null;
            if (empty($agency_unq_id) && !empty($user_data['agency_id'])) {
                $agency_unq_id = ($user_data['agency_id'] == 1 || $user_data['agency_id'] == '1') ? 'ADMIN-1' : 'AGENCY-' . $user_data['agency_id'];
            }

            $payload = json_encode([
                'id'            => $user_data['id'] ?? null,
                'email'         => $user_data['email'] ?? null,
                'mob'           => $user_data['mob'] ?? null,
                'name'          => $user_data['name'] ?? null,
                'agency_id'     => $user_data['agency_id'] ?? null,
                'agency_unq_id' => $agency_unq_id,
                'type'          => $user_data['type'] ?? 'USER',
                'show_status'   => $user_data['show_status'] ?? 'ACTIVE',
                'img'           => $user_data['img'] ?? null
            ]);

            if (function_exists('curl_init')) {
                $ch = curl_init($node_api_url);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
                curl_setopt($ch, CURLOPT_HTTPHEADER, [
                    'Content-Type: application/json',
                    'Content-Length: ' . strlen($payload)
                ]);
                curl_setopt($ch, CURLOPT_CONNECTTIMEOUT_MS, 500);
                curl_setopt($ch, CURLOPT_TIMEOUT, 1);
                $response = curl_exec($ch);
                curl_close($ch);
                return $response;
            } else {
                $opts = [
                    'http' => [
                        'method'  => 'POST',
                        'header'  => "Content-Type: application/json\r\n" .
                                     "Content-Length: " . strlen($payload) . "\r\n",
                        'content' => $payload,
                        'timeout' => 1
                    ]
                ];
                $context = stream_context_create($opts);
                return @file_get_contents($node_api_url, false, $context);
            }
        } catch (Exception $e) {
            error_log('[sync_user_to_node_mongo] Error: ' . $e->getMessage());
            return false;
        }
    }
}
?>