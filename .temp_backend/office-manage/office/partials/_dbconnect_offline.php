<?php
$server = "localhost";
$username = "root";
$password = "";
$database = "fairbiz";

$conn = mysqli_connect($server, $username, $password, $database);
if (!$conn){
    die("Error". mysqli_connect_error());
}
$m_url='http://localhost/fairbiz/';
$m_folder='fairbiz/';

date_default_timezone_set("Asia/Calcutta");
$date = date("Y-m-d");
$time = date("h:i:sa");
$date_ts = time();

define('SERVER_PATH',$_SERVER['DOCUMENT_ROOT'].'/fairbiz/');
define('SITE_PATH','http://localhost/fairbiz/');

define('ADD_EDITOR_SERVER_PATH',SERVER_PATH.'uploads/ckeditor/');
define('ADD_EDITOR_SITE_PATH','uploads/ckeditor/');

define('ADD_PHOTO_SERVER_PATH',SERVER_PATH.'uploads/photos/');
define('ADD_PHOTO_SITE_PATH','uploads/photos/');

define('ADD_VIDEO_SERVER_PATH',SERVER_PATH.'uploads/videos/');
define('ADD_VIDEO_SITE_PATH','uploads/videos/');

define('ADD_DOCUMENT_SERVER_PATH',SERVER_PATH.'uploads/documents/');
define('ADD_DOCUMENT_SITE_PATH','uploads/documents/');

define('ADD_MUSIC_SERVER_PATH',SERVER_PATH.'uploads/musics/');
define('ADD_MUSIC_SITE_PATH','uploads/musics/');

try {
	$pdo = new PDO("mysql:host={$server};dbname={$database}", $username, $password);
} catch(PDOException $ex) {
    echo "Connection error :" . $ex->getMessage();
}
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
$_SESSION['app_on'] = "OFFLINE";
?>