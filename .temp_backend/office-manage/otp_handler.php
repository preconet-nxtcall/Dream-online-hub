<?php
require_once __DIR__ . "/office/partials/_dbconnect.php";

header('Content-Type: application/json');

// Auto-create otps table if not exists
if (isset($conn) && $conn) {
    @mysqli_query($conn, "CREATE TABLE IF NOT EXISTS `otps` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `phone` varchar(20) NOT NULL,
      `otp` varchar(10) NOT NULL,
      `date_ts` varchar(50) NOT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
}

$action = $_POST['action'] ?? $_GET['action'] ?? '';

if ($action === 'send_otp') {
    $phone = isset($_POST['phone']) ? trim(addslashes($_POST['phone'])) : '';
    if (strlen($phone) !== 10 || !ctype_digit($phone)) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid 10-digit phone number.']);
        exit;
    }

    // Generate random 6-digit OTP
    $otp = sprintf("%06d", mt_rand(100000, 999999));
    $date_ts = date("Y-m-d H:i:s");

    // Insert into otps table: INSERT INTO `otps`(`phone`, `otp`, `date_ts`)
    $insertQry = "INSERT INTO `otps`(`phone`, `otp`, `date_ts`) VALUES ('$phone', '$otp', '$date_ts')";
    $insertRes = mysqli_query($conn, $insertQry);

    if (!$insertRes) {
        echo json_encode(['status' => 'error', 'message' => 'Database insertion failed: ' . mysqli_error($conn)]);
        exit;
    }

    // Retrieve API Key, Sender ID, Site Name from site_stng or environment
    $apitxt_key = getenv('APITXT_API_KEY') ?: '';
    $sms_sender = '';
    $site_heading = 'FairBiz';

    $site_query = mysqli_query($conn, "SELECT * FROM `site_stng` LIMIT 1");
    if ($site_query && $site_row = mysqli_fetch_assoc($site_query)) {
        if (!empty($site_row['sms_key'])) {
            $apitxt_key = trim($site_row['sms_key']);
        } elseif (!empty($site_row['pay_key'])) {
            $apitxt_key = trim($site_row['pay_key']);
        }
        if (!empty($site_row['sms_sender'])) {
            $sms_sender = trim($site_row['sms_sender']);
        }
        if (!empty($site_row['heading'])) {
            $site_heading = trim($site_row['heading']);
        }
    }

    // CUSTOMIZABLE OTP SMS MESSAGE (Edit this text anytime!)
    $otp_message = "Your verification OTP for " . $site_heading . " is " . $otp . ". Do not share this OTP with anyone.";

    $api_response_msg = '';
    $api_sent = false;

    // Format mobile parameter (adding 91 prefix for Indian mobile numbers if 10-digit)
    $mobile_param = (strlen($phone) === 10 && substr($phone, 0, 2) !== '91') ? ('91' . $phone) : $phone;

    if (!empty($apitxt_key)) {
        // Construct URL according to APITxT API specification
        $api_url = "https://apitxt.com/api/sendOTP?authkey=" . urlencode($apitxt_key) . "&mobile=" . urlencode($mobile_param) . "&otp=" . urlencode($otp) . "&message=" . urlencode($otp_message);
        if (!empty($sms_sender)) {
            $api_url .= "&sender=" . urlencode($sms_sender);
        }

        if (function_exists('curl_init')) {
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $api_url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            $response = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curl_err = curl_error($ch);
            curl_close($ch);

            if ($response) {
                $api_res_json = json_decode($response, true);
                if ($api_res_json && (
                    (isset($api_res_json['status']) && (strtolower((string)$api_res_json['status']) === 'success' || $api_res_json['status'] == 200 || $api_res_json['status'] === true)) ||
                    (isset($api_res_json['type']) && strtolower((string)$api_res_json['type']) === 'success')
                )) {
                    $api_sent = true;
                } else {
                    $api_response_msg = isset($api_res_json['message']) ? $api_res_json['message'] : (is_string($response) ? substr(strip_tags($response), 0, 200) : 'API response error');
                }
            } else {
                $api_response_msg = 'cURL Error: ' . ($curl_err ?: 'No response from APITxT gateway');
            }
        } else {
            $api_response_msg = 'cURL PHP extension is not enabled.';
        }
    } else {
        $api_response_msg = 'SMS API Key is missing or empty in site_stng (sms_key / pay_key).';
    }

    $response_data = [
        'status'  => 'success',
        'message' => 'OTP Send your phone!',
        'otp'     => $otp, // Saved in otps database table
    ];

    if (!$api_sent && !empty($api_response_msg)) {
        $response_data['api_notice'] = $api_response_msg;
    }

    echo json_encode($response_data);
    exit;
}

if ($action === 'verify_otp') {
    $phone = isset($_POST['phone']) ? trim(addslashes($_POST['phone'])) : '';
    $otp = isset($_POST['otp']) ? trim(addslashes($_POST['otp'])) : '';

    if (empty($phone) || empty($otp)) {
        echo json_encode(['status' => 'error', 'message' => 'Phone number and OTP are required.']);
        exit;
    }

    // Check latest OTP in otps database table for given phone number
    $checkQry = mysqli_query($conn, "SELECT * FROM `otps` WHERE `phone` = '$phone' AND `otp` = '$otp' ORDER BY `id` DESC LIMIT 1");

    if ($checkQry && mysqli_num_rows($checkQry) > 0) {
        echo json_encode(['status' => 'success', 'message' => 'OTP verified successfully!']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Invalid OTP. Please check and try again.']);
    }
    exit;
}

echo json_encode(['status' => 'error', 'message' => 'Invalid action requested.']);
exit;
