<?php
ob_start();
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight CORS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Include database connection
require_once file_exists(__DIR__ . '/office/partials/_dbconnect.php') 
    ? __DIR__ . '/office/partials/_dbconnect.php' 
    : (file_exists(__DIR__ . '/ptadmin/partials/_dbconnect.php') ? __DIR__ . '/ptadmin/partials/_dbconnect.php' : 'office/partials/_dbconnect.php');

// Get posted JSON data
$data = json_decode(file_get_contents("php://input"));

// Determine the action. If no action is provided but login credentials are, default to 'login'
$action = !empty($data->action) ? $data->action : (!empty($_POST['action']) ? $_POST['action'] : '');
if(empty($action) && (!empty($data->email) || !empty($data->mob) || !empty($data->userId)) && !empty($data->password)){
    $action = 'login';
}

if ($action === 'login') {
    // Get the login identifier (could be email, mob, or userId from the chat-assistant)
    $login_id = '';
    if (!empty($data->email)) $login_id = $data->email;
    elseif (!empty($data->mob)) $login_id = $data->mob;
    elseif (!empty($data->userId)) $login_id = $data->userId;
    
    if (!empty($login_id) && !empty($data->password)) {
        $login_id = mysqli_real_escape_string($conn, $login_id);
        $password = mysqli_real_escape_string($conn, $data->password);
        
        // Check user in database (Matching email OR mob)
        $query = "SELECT id, name, email, mob, type, show_status, img FROM users WHERE (email = '$login_id' OR mob = '$login_id') AND password = '$password' AND type != 'EMPLOYEE' LIMIT 1";
        $result = mysqli_query($conn, $query);
        
        if (mysqli_num_rows($result) > 0) {
            $user = mysqli_fetch_assoc($result);
            
            // Ensure account is active
            if ($user['show_status'] === 'ACTIVE') {
                http_response_code(200);
                echo json_encode([
                    "success" => true,
                    "message" => "Login successful",
                    "user" => [
                        "id" => $user['id'],
                        "name" => $user['name'],
                        "email" => $user['email'],
                        "phone" => $user['mob'],
                        "role" => $user['type'],
                        "avatar" => (!empty($user['img'])) ? $m_url.ADD_PHOTO_SITE_PATH.$user['img'] : null
                    ]
                ]);
            } else {
                http_response_code(403);
                echo json_encode([
                    "success" => false,
                    "message" => "Account is suspended or inactive."
                ]);
            }
        } else {
            http_response_code(401);
            echo json_encode([
                "success" => false,
                "message" => "Invalid email/mobile or password."
            ]);
        }
    } else {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Incomplete data. Please provide email/mobile and password."
        ]);
    }
} elseif ($action === 'read_users' || $action === 'read_agency_users') {
    // Secure Read (SELECT) - Fetch all users, agency users, or a specific user by ID
    $id = !empty($data->id) ? (int)$data->id : null;
    $agency_id = !empty($data->agency_id) ? trim($data->agency_id) : null;
    
    if ($id) {
        $stmt = $conn->prepare("SELECT id, name, email, mob, agency_id, agency_unq_id, type, show_status FROM users WHERE id = ?");
        $stmt->bind_param("i", $id);
    } elseif ($agency_id && $action === 'read_agency_users') {
        $stmt = $conn->prepare("SELECT id, name, email, mob, agency_id, agency_unq_id, type, show_status FROM users WHERE (agency_id = ? OR agency_unq_id = ?) AND (type IS NULL OR type = '' OR type = 'USER')");
        $stmt->bind_param("ss", $agency_id, $agency_id);
    } else {
        $stmt = $conn->prepare("SELECT id, name, email, mob, agency_id, agency_unq_id, type, show_status FROM users");
    }
    
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $users = [];
        while ($row = $result->fetch_assoc()) {
            if (empty($row['agency_unq_id']) && !empty($row['agency_id'])) {
                $row['agency_unq_id'] = ($row['agency_id'] == 1 || $row['agency_id'] == '1') ? 'ADMIN-1' : 'AGENCY-' . $row['agency_id'];
            }
            $users[] = $row;
        }
        
        http_response_code(200);
        echo json_encode(["success" => true, "data" => $users]);
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database error."]);
    }
    $stmt->close();

} elseif ($action === 'create_user') {
    // Secure Create (INSERT)
    $name = !empty($data->name) ? trim($data->name) : '';
    $email = !empty($data->email) ? trim($data->email) : '';
    $mob = !empty($data->mob) ? trim($data->mob) : '';
    $password = !empty($data->password) ? $data->password : '';
    
    if ($name && $email && $password) {
        // Warning: In a real app, ALWAYS hash passwords (e.g., password_hash). 
        // This example uses plain text to match your existing login query logic.
        $qry1 = mysqli_fetch_assoc(mysqli_query($conn, "SELECT * FROM users WHERE agency_id = 'FEATURED' AND type = 'AGENCY' AND show_status = 'ACTIVE' "));
        if($qry1['id']){
            $agency_id = $qry1['id'];
        }else{
            $agency_id = 1;
        }
        $stmt = $conn->prepare("INSERT INTO users (name, email, mob, password, type, show_status, agency_id) VALUES (?, ?, ?, ?, 'USER', 'ACTIVE', ?)");
        $stmt->bind_param("ssssi", $name, $email, $mob, $password, $agency_id);
        
        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["success" => true, "message" => "User created successfully.", "id" => $conn->insert_id]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Failed to create user."]);
        }
        $stmt->close();
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Name, email, and password are required."]);
    }

} elseif ($action === 'update_user') {
    // Secure Update (UPDATE)
    $id = !empty($data->id) ? (int)$data->id : 0;
    $name = !empty($data->name) ? trim($data->name) : null;
    
    if ($id && $name !== null) {
        $stmt = $conn->prepare("UPDATE users SET name = ? WHERE id = ?");
        $stmt->bind_param("si", $name, $id);
        
        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["success" => true, "message" => "User updated successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Failed to update user."]);
        }
        $stmt->close();
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "User ID and new name are required."]);
    }

} elseif ($action === 'delete_user') {
    // Secure Delete (DELETE)
    $id = !empty($data->id) ? (int)$data->id : 0;
    
    if ($id) {
        $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["success" => true, "message" => "User deleted successfully."]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Failed to delete user."]);
        }
        $stmt->close();
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "User ID is required."]);
    }

} elseif ($action === 'get_by_agency_id') {
    // Fetch full row details for a given agency_id
    $agency_id = !empty($data->agency_id) ? $data->agency_id : null;
    
    if ($agency_id !== null) {
        // Query to match either the internal agency_id column or the string-based agency_unq_id if it exists
        $stmt = $conn->prepare("SELECT * FROM users WHERE agency_id = ? OR id = ? OR agency_unq_id = ?");
        $stmt->bind_param("sis", $agency_id, $agency_id, $agency_id);
        
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            $data_rows = [];
            while ($row = $result->fetch_assoc()) {
                // Ensure password isn't leaked out for security
                unset($row['password']);
                if (empty($row['agency_unq_id']) && !empty($row['agency_id'])) {
                    $row['agency_unq_id'] = ($row['agency_id'] == 1 || $row['agency_id'] == '1') ? 'ADMIN-1' : 'AGENCY-' . $row['agency_id'];
                }
                $data_rows[] = $row;
            }
            
            http_response_code(200);
            echo json_encode(["success" => true, "data" => $data_rows]);
        } else {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Database error."]);
        }
        $stmt->close();
    } else {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "agency_id is required."]);
    }

} elseif ($action === 'get_qr_code') {
    // -------------------------------------------------------
    // GET QR CODE
    // Input  : book_id, agency_id, amount, user_id (optional/recommended)
    // Output : qr_image_url, qr_id, range_id
    // Logic  :
    //  1. Check if user_id & book_id are subscribed in `subscription` table.
    //     If not subscribed -> return 200 with success = false.
    //  2. Find price range for given amount.
    //  3. Check agency recharge limit. If limit >= amount -> search agency QR.
    //  4. If agency QR not found -> fall back to Admin (emp_id = 1) QR.
    // -------------------------------------------------------

    $book_id   = !empty($data->book_id)   ? (int)$data->book_id   : (!empty($_POST['book_id']) ? (int)$_POST['book_id'] : 0);
    $agency_id = !empty($data->agency_id) ? (int)$data->agency_id : (!empty($_POST['agency_id']) ? (int)$_POST['agency_id'] : 0);
    $amount    = !empty($data->amount)    ? (float)$data->amount  : (!empty($_POST['amount']) ? (float)$_POST['amount'] : 0);
    $user_id   = !empty($data->user_id)   ? (int)$data->user_id   : (!empty($_POST['user_id']) ? (int)$_POST['user_id'] : 0);

    if (!$book_id || !$agency_id || !$amount) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "book_id, agency_id, and amount are required."
        ]);
        exit;
    }

    // Step 0 — Check if book is subscribed by user (if user_id provided)
    if (!empty($user_id)) {
        $done = "DONE";
        $stmt_sub = $conn->prepare(
            "SELECT * FROM `subscription` WHERE user_id = ? AND book_id = ? AND stage_status = ? LIMIT 1"
        );
        $stmt_sub->bind_param("ii", $user_id, $book_id, $done);
        $stmt_sub->execute();
        $res_sub = $stmt_sub->get_result();

        if ($res_sub->num_rows === 0) {
            http_response_code(200);
            echo json_encode([
                "success" => false,
                "message" => "This book is not subscribed by user."
            ]);
            $stmt_sub->close();
            exit;
        }
        $stmt_sub->close();
    }

    // Step 1 — Find the matching price range for the given amount
    $stmt_range = $conn->prepare(
        "SELECT * FROM `pricerange`
         WHERE CAST(price_start AS UNSIGNED) <= ?
           AND CAST(price_end   AS UNSIGNED) >= ?
           AND show_status = 'ACTIVE'
         LIMIT 1"
    );
    $stmt_range->bind_param("dd", $amount, $amount);
    $stmt_range->execute();
    $result_range = $stmt_range->get_result();

    if ($result_range->num_rows === 0) {
        // No price range matched — only cash available
        http_response_code(200);
        echo json_encode([
            "success"       => true,
            "qr_available"  => false,
            "message"       => "Only Cash Transaction Available.",
            "qr_image_url"  => null,
            "qr_id"         => null,
            "range_id"      => null
        ]);
        $stmt_range->close();
        exit;
    }

    $row_range = $result_range->fetch_assoc();
    $range_id  = (int)$row_range['id'];
    $stmt_range->close();

    // Step 2 — Check agency recharge limit from agency_cash_book
    $stmt_acb = $conn->prepare(
        "SELECT recharge_limit_live FROM `agency_cash_book` WHERE agency_id = ? LIMIT 1"
    );
    $stmt_acb->bind_param("i", $agency_id);
    $stmt_acb->execute();
    $result_acb = $stmt_acb->get_result();
    $agency_recharge_limit = 0;
    if ($result_acb->num_rows > 0) {
        $row_acb = $result_acb->fetch_assoc();
        $agency_recharge_limit = (float)$row_acb['recharge_limit_live'];
    }
    $stmt_acb->close();

    // Step 3 — Decide initial agency ID for QR lookup
    $qr_agency_id = ($agency_recharge_limit > $amount) ? $agency_id : 1;

    // Step 4 — Fetch active QR for resolved agency + range
    $stmt_qr = $conn->prepare(
        "SELECT * FROM `qrcode`
         WHERE range_id   = ?
           AND emp_id     = ?
           AND show_status = 'ACTIVE'
         LIMIT 1"
    );
    $stmt_qr->bind_param("ii", $range_id, $qr_agency_id);
    $stmt_qr->execute();
    $result_qr = $stmt_qr->get_result();

    // Step 4b — Fallback to Admin (emp_id = 1) if agency's specific QR code is not found
    if ($result_qr->num_rows === 0 && $qr_agency_id != 1) {
        $stmt_qr->close();
        $qr_agency_id = 1;
        $stmt_qr = $conn->prepare(
            "SELECT * FROM `qrcode`
             WHERE range_id   = ?
               AND emp_id     = 1
               AND show_status = 'ACTIVE'
             LIMIT 1"
        );
        $stmt_qr->bind_param("i", $range_id);
        $stmt_qr->execute();
        $result_qr = $stmt_qr->get_result();
    }

    if ($result_qr->num_rows === 0) {
        // No QR found even after Admin fallback — only cash available
        http_response_code(200);
        echo json_encode([
            "success"      => true,
            "qr_available" => false,
            "message"      => "Only Cash Transaction Available.",
            "qr_image_url" => null,
            "qr_id"        => null,
            "range_id"     => $range_id
        ]);
        $stmt_qr->close();
        exit;
    }

    $row_qr = $result_qr->fetch_assoc();
    $stmt_qr->close();

    // Step 4c — Fetch Bank Details from features table using bank_id from qrcode
    $bank_name   = null;
    $bank_detail = null;
    $bank_id     = isset($row_qr['bank_id']) ? (int)$row_qr['bank_id'] : 0;

    if ($bank_id > 0) {
        $stmt_bank = $conn->prepare("SELECT `name`, `detail` FROM `features` WHERE `id` = ? LIMIT 1");
        $stmt_bank->bind_param("i", $bank_id);
        $stmt_bank->execute();
        $res_bank = $stmt_bank->get_result();
        if ($res_bank && $res_bank->num_rows > 0) {
            $row_bank   = $res_bank->fetch_assoc();
            $bank_name   = $row_bank['name'];
            $bank_detail = $row_bank['detail'];
        }
        $stmt_bank->close();
    }

    // Step 5 — Build and return the JSON response
    http_response_code(200);
    echo json_encode([
        "success"      => true,
        "qr_available" => true,
        "message"      => "QR code found.",
        "qr_image_url" => $m_url . ADD_PHOTO_SITE_PATH . $row_qr['image'],
        "qr_id"        => (int)$row_qr['id'],
        "range_id"     => $range_id,
        "emp_id"       => $qr_agency_id,
        "bank_id"      => $bank_id,
        "bank_name"    => $bank_name,
        "bank_detail"  => $bank_detail
    ]);

} elseif ($action === 'recharge_by_user') {
    // -------------------------------------------------------
    // RECHARGE BY USER
    // Input  : user_id, qr_id, range_id, amount, emp_id, book_id, transection_id, image (file or base64)
    // Output : success (true/false), message, recharge_id
    // Logic  : Mirrors recharge.php form submit logic.
    // -------------------------------------------------------

    $raw_user_id     = !empty($data->user_id) ? trim($data->user_id) : (!empty($_POST['user_id']) ? trim($_POST['user_id']) : '');
    $user_id        = is_numeric($raw_user_id) ? (int)$raw_user_id : 0;
    $qr_id          = !empty($data->qr_id) ? (int)$data->qr_id : (!empty($_POST['qr_id']) ? (int)$_POST['qr_id'] : 0);
    $range_id       = !empty($data->range_id) ? (int)$data->range_id : (!empty($_POST['range_id']) ? (int)$_POST['range_id'] : 0);
    $amount         = !empty($data->amount) ? (float)$data->amount : (!empty($_POST['amount']) ? (float)$_POST['amount'] : 0);
    $emp_id         = !empty($data->emp_id) ? (int)$data->emp_id : (!empty($_POST['emp_id']) ? (int)$_POST['emp_id'] : 0);
    $book_id        = !empty($data->book_id) ? (int)$data->book_id : (!empty($_POST['book_id']) ? (int)$_POST['book_id'] : 0);
    $transection_id = !empty($data->transection_id) ? trim($data->transection_id) : (!empty($data->transaction_id) ? trim($data->transaction_id) : (!empty($_POST['transection_id']) ? trim($_POST['transection_id']) : (!empty($_POST['transaction_id']) ? trim($_POST['transaction_id']) : '')));

    // Resolve user_id & emp_id from DB if passed as email or non-numeric string
    if ((!$user_id || !$emp_id) && !empty($raw_user_id)) {
        $safe_raw_user = mysqli_real_escape_string($conn, $raw_user_id);
        $qryusr_lookup = mysqli_query($conn, "SELECT id, agency_id FROM `users` WHERE id = '$safe_raw_user' OR email = '$safe_raw_user' OR mob = '$safe_raw_user' LIMIT 1");
        if ($qryusr_lookup && mysqli_num_rows($qryusr_lookup) > 0) {
            $rowusr_lookup = mysqli_fetch_assoc($qryusr_lookup);
            if (!$user_id) $user_id = (int)$rowusr_lookup['id'];
            if (!$emp_id && !empty($rowusr_lookup['agency_id'])) {
                $emp_id = (int)$rowusr_lookup['agency_id'];
            }
        }
    }

    if (!$emp_id) {
        $emp_id = 1; // Default to Admin
    }

    $qrsendr=mysqli_query($conn,"SELECT * FROM `recharge` WHERE `user_id` = '$user_id' AND (`stage_status` = 'AGENCY-PENDING' OR `stage_status` = 'AGENCY-DONE' OR `stage_status` = 'EMPLOYEE-PENDING') ") or die(mysqli_error());
	$rsendr=mysqli_num_rows($qrsendr);
    if($rsendr > 0){
        $return_array = array(
            "success" => false,
            "message" => "1 Recharge Already Processing!",
        );
        echo json_encode($return_array);
        exit;
    }

    if (!$user_id || !$amount || !$book_id || empty($transection_id)) {
        if (ob_get_length()) ob_clean();
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "user_id, amount, book_id, and transection_id are required."
        ]);
        exit;
    }

    // Fetch QR code & bank info with safety checks
    $bank_id = 0;
    $bank_name = '';
    $bank_slag = '';
    $bank_details = '';

    if (!empty($qr_id)) {
        $qryqrdls = mysqli_query($conn, "SELECT * FROM `qrcode` WHERE `id` = '$qr_id'");
        if ($qryqrdls && mysqli_num_rows($qryqrdls) > 0) {
            $rqrdls = mysqli_fetch_array($qryqrdls);
            $bank_id = isset($rqrdls['bank_id']) ? (int)$rqrdls['bank_id'] : 0;
        }
    }

    if ($bank_id > 0) {
        $qrybndls = mysqli_query($conn, "SELECT * FROM `features` WHERE `id` = '$bank_id'");
        if ($qrybndls && mysqli_num_rows($qrybndls) > 0) {
            $rbndls = mysqli_fetch_array($qrybndls);
            if ($rbndls) {
                $bank_name = isset($rbndls['name']) ? addslashes($rbndls['name']) : '';
                $bank_slag = isset($rbndls['slag']) ? addslashes($rbndls['slag']) : '';
                $bank_details = isset($rbndls['detail']) ? addslashes($rbndls['detail']) : '';
            }
        }
    }

    // Fetch subscription ID
    $qryprcrange = mysqli_query($conn, "SELECT * FROM `subscription` WHERE `user_id` = '$user_id' AND `book_id` = '$book_id' LIMIT 1");
    $subscription_id = 0;
    if ($qryprcrange && mysqli_num_rows($qryprcrange) > 0) {
        $rmprcrange = mysqli_fetch_array($qryprcrange);
        $subscription_id = $rmprcrange['id'];
    }

    // Ensure uploads/photos directory exists
    if (!file_exists(ADD_PHOTO_SERVER_PATH)) {
        @mkdir(ADD_PHOTO_SERVER_PATH, 0777, true);
    }

    // Process image (file upload or base64)
    $img_new1 = '';
    if (!empty($_FILES['image']['name'])) {
        $img1 = $_FILES['image']['name'];
        $ext = pathinfo($img1, PATHINFO_EXTENSION);
        $img_new1 = $date_ts . '_Recharge_Image.' . $ext;
        @move_uploaded_file($_FILES['image']['tmp_name'], ADD_PHOTO_SERVER_PATH . $img_new1);
    } elseif (!empty($data->image_base64) || !empty($data->image)) {
        $base64_str = !empty($data->image_base64) ? $data->image_base64 : $data->image;
        if (preg_match('/^data:image\/(\w+);base64,/', $base64_str, $type)) {
            $base64_str = substr($base64_str, strpos($base64_str, ',') + 1);
            $ext = strtolower($type[1]);
        } else {
            $ext = 'png';
        }
        $base64_str = str_replace(' ', '+', $base64_str);
        $data_img = @base64_decode($base64_str);
        if ($data_img !== false) {
            $img_new1 = $date_ts . '_Recharge_Image.' . $ext;
            @file_put_contents(ADD_PHOTO_SERVER_PATH . $img_new1, $data_img);
        }
    }

    $stage_status = "AGENCY-PENDING";
    $employee_read_status = "PENDING";
    $agency_read_status = "PENDING";
    $transection_id_safe = addslashes($transection_id);

    $qryins = mysqli_query($conn, "INSERT INTO `recharge`(
        `user_id`, `qr_id`, `range_id`, `amount`, `stage_status`, 
        `emp_id`, `book_id`, `subscription_id`, `transection_id`, 
        `bank_id`, `bank_name`, `bank_slag`, `bank_details`, 
        `remark`, `employee_remark`, `image`, `invoice`, 
        `employee_read_status`, `agency_read_status`, `date_ts`
    ) VALUES (
        '$user_id', '$qr_id', '$range_id', '$amount', '$stage_status', 
        '$emp_id', '$book_id', '$subscription_id', '$transection_id_safe', 
        '$bank_id', '$bank_name', '$bank_slag', '$bank_details', 
        '', '', '$img_new1', '', 
        '$employee_read_status', '$agency_read_status', '$date_ts'
    )");

    if ($qryins) {
        $recharge_id = mysqli_insert_id($conn);
        @mysqli_query($conn, "UPDATE `agency_cash_book` SET `recharge_limit_live` = `recharge_limit_live` - '$amount', `rs_inhand_expected` = `rs_inhand_expected` + '$amount' WHERE `agency_id` = '$emp_id'");
        
        if (ob_get_length()) ob_clean();
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Recharge Submitted Successfully!",
            "recharge_id" => $recharge_id
        ]);
    } else {
        if (ob_get_length()) ob_clean();
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Failed to submit recharge request."
        ]);
    }

} elseif ($action === 'recharge_records') {
    // -------------------------------------------------------
    // RECHARGE RECORDS
    // Input  : user_id (optional, omit to get all), status_type (optional: 'pending', 'successful', 'rejected', 'all')
    // Output : success (true/false), data (array of recharge records), categorized (object with pending, successful, rejected lists)
    // Logic  : Mirrors records.php queries and structure.
    // -------------------------------------------------------

    $user_id     = !empty($data->user_id)     ? (int)$data->user_id     : (!empty($_POST['user_id'])     ? (int)$_POST['user_id']     : 0);
    $status_type = !empty($data->status_type) ? trim($data->status_type) : (!empty($_POST['status_type']) ? trim($_POST['status_type']) : 'all');

    $where_clauses = [];
    if ($user_id > 0) {
        $where_clauses[] = "user_id = '$user_id'";
    }

    if ($status_type === 'pending') {
        $where_clauses[] = "(stage_status = 'AGENCY-PENDING' OR stage_status = 'AGENCY-DONE' OR stage_status = 'EMPLOYEE-PENDING')";
    } elseif ($status_type === 'successful' || $status_type === 'done') {
        $where_clauses[] = "stage_status = 'EMPLOYEE-DONE'";
    } elseif ($status_type === 'rejected') {
        $where_clauses[] = "(stage_status = 'AGENCY-REJECT' OR stage_status = 'EMPLOYEE-REJECT')";
    }

    $where_sql = count($where_clauses) > 0 ? "WHERE " . implode(" AND ", $where_clauses) : "";

    $query = "SELECT * FROM `recharge` $where_sql ORDER BY ABS(id) DESC";
    $result = mysqli_query($conn, $query);

    if ($result) {
        $all_records = [];
        $pending_records = [];
        $successful_records = [];
        $rejected_records = [];

        while ($row = mysqli_fetch_assoc($result)) {
            // Fetch book name
            $book_id = $row['book_id'];
            $book_name = "";
            if (!empty($book_id)) {
                $qry_bk = mysqli_query($conn, "SELECT name FROM `features` WHERE id = '$book_id' LIMIT 1");
                if ($res_bk = mysqli_fetch_assoc($qry_bk)) {
                    $book_name = $res_bk['name'];
                }
            }
            $row['book_name'] = $book_name;

            // Image & Invoice URLs
            $row['image_url'] = !empty($row['image']) ? $m_url . ADD_PHOTO_SITE_PATH . $row['image'] : null;
            $row['invoice_url'] = !empty($row['invoice']) ? $m_url . ADD_DOCUMENT_SITE_PATH . $row['invoice'] : null;
            $row['formatted_date'] = is_numeric($row['date_ts']) ? date('m/d/Y H:i:s a', (int)$row['date_ts']) : $row['date_ts'];

            // Status label categorization matching records.php
            $stage = $row['stage_status'];
            if ($stage === 'EMPLOYEE-DONE') {
                $row['status_category'] = 'SUCCESSFUL';
                $successful_records[] = $row;
            } elseif ($stage === 'AGENCY-REJECT' || $stage === 'EMPLOYEE-REJECT') {
                $row['status_category'] = 'REJECTED';
                $rejected_records[] = $row;
            } else {
                $row['status_category'] = 'PENDING';
                $pending_records[] = $row;
            }

            $all_records[] = $row;
        }

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Recharge records retrieved successfully.",
            "total_records" => count($all_records),
            "data" => $all_records,
            "categorized" => [
                "pending" => $pending_records,
                "successful" => $successful_records,
                "rejected" => $rejected_records
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database query failed."]);
    }

} elseif ($action === 'user_withdraw') {
    // -------------------------------------------------------
    // USER WITHDRAW
    // Input  : user_id, book_id, amount, agency_id (optional), deatil / detail (optional), image (file or base64, optional), user_ac_holder_name (optional), user_ac_number (optional), user_bank_name (optional), user_bank_ifsc (optional), user_upi_id (optional)
    // Output : success (true/false), message, withdrawal_id
    // Logic  : Mirrors withdraw.php submission logic.
    // -------------------------------------------------------

    $user_id   = !empty($data->user_id) ? (int)$data->user_id : (!empty($_POST['user_id']) ? (int)$_POST['user_id'] : 0);
    $book_id   = !empty($data->book_id) ? (int)$data->book_id : (!empty($_POST['book_id']) ? (int)$_POST['book_id'] : 0);
    $amount    = !empty($data->amount)  ? (float)$data->amount : (!empty($_POST['amount']) ? (float)$_POST['amount'] : 0);
    $agency_id = !empty($data->agency_id) ? (int)$data->agency_id : (!empty($_POST['agency_id']) ? (int)$_POST['agency_id'] : 0);
    $deatil    = !empty($data->deatil) ? trim($data->deatil) : (!empty($data->detail) ? trim($data->detail) : (!empty($_POST['deatil']) ? trim($_POST['deatil']) : (!empty($_POST['detail']) ? trim($_POST['detail']) : '')));

    if (!$user_id || !$book_id || !$amount) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "user_id, book_id, and amount are required."
        ]);
        exit;
    }

    // Check payment account details for this user
    $chk_pay_qry = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$user_id' ORDER BY id DESC LIMIT 1");
    $chk_pay_row = ($chk_pay_qry && mysqli_num_rows($chk_pay_qry) > 0) ? mysqli_fetch_assoc($chk_pay_qry) : null;

    if (empty($chk_pay_row)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Please set up your Payment Account Details in Profile first!"
        ]);
        exit;
    }

    if (isset($chk_pay_row['stage_status']) && $chk_pay_row['stage_status'] === 'EMPLOYEE-PENDING') {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "You cannot request a withdrawal while your payment account detail approval is pending."
        ]);
        exit;
    }

    // If agency_id is not provided, fetch agency_id from users table
    if (!$agency_id) {
        $qryusr = mysqli_query($conn, "SELECT agency_id FROM `users` WHERE id = '$user_id' LIMIT 1");
        if ($qryusr && mysqli_num_rows($qryusr) > 0) {
            $rowusr = mysqli_fetch_assoc($qryusr);
            $agency_id = (int)$rowusr['agency_id'];
        }
    }

    // Check if withdrawal already exists for this user in pending state
    $qrycheck = mysqli_query($conn, "SELECT id FROM `withdrawal` WHERE `user_id` = '$user_id' AND (`stage_status` = 'EMPLOYEE-PENDING' OR `stage_status` = 'EMPLOYEE-PASS' OR `stage_status` = 'AGENCY-PENDING') LIMIT 1");
    if ($qrycheck && mysqli_num_rows($qrycheck) > 0) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Withdrawal Already Exists!"
        ]);
        exit;
    }

    // Process image (file upload, base64, or fallback to user_payment_accounts image)
    $img_new1 = '';
    if (!empty($_FILES['image']['name'])) {
        $img1 = $_FILES['image']['name'];
        $ext = pathinfo($img1, PATHINFO_EXTENSION);
        $img_new1 = $date_ts . '_Withdraw_QR_Image.' . $ext;
        move_uploaded_file($_FILES['image']['tmp_name'], ADD_PHOTO_SERVER_PATH . $img_new1);
    } elseif (!empty($data->image_base64) || (!empty($data->image) && strpos($data->image, 'data:image') === 0)) {
        $base64_str = !empty($data->image_base64) ? $data->image_base64 : $data->image;
        if (preg_match('/^data:image\/(\w+);base64,/', $base64_str, $type)) {
            $base64_str = substr($base64_str, strpos($base64_str, ',') + 1);
            $ext = strtolower($type[1]);
        } else {
            $ext = 'png';
        }
        $base64_str = str_replace(' ', '+', $base64_str);
        $data_img = base64_decode($base64_str);
        $img_new1 = $date_ts . '_Withdraw_QR_Image.' . $ext;
        file_put_contents(ADD_PHOTO_SERVER_PATH . $img_new1, $data_img);
    }

    if (empty($img_new1) && !empty($chk_pay_row['image'])) {
        $img_new1 = addslashes($chk_pay_row['image']);
    }

    // User Payment Account details to store in withdrawal record
    $user_ac_holder_name = !empty($data->user_ac_holder_name) ? addslashes($data->user_ac_holder_name) : (!empty($_POST['user_ac_holder_name']) ? addslashes($_POST['user_ac_holder_name']) : addslashes($chk_pay_row['account_name'] ?? ''));
    $user_ac_number      = !empty($data->user_ac_number) ? addslashes($data->user_ac_number) : (!empty($_POST['user_ac_number']) ? addslashes($_POST['user_ac_number']) : addslashes($chk_pay_row['account_no'] ?? ''));
    $user_bank_name      = !empty($data->user_bank_name) ? addslashes($data->user_bank_name) : (!empty($_POST['user_bank_name']) ? addslashes($_POST['user_bank_name']) : addslashes($chk_pay_row['bank_name'] ?? ''));
    $user_bank_ifsc      = !empty($data->user_bank_ifsc) ? addslashes($data->user_bank_ifsc) : (!empty($_POST['user_bank_ifsc']) ? addslashes($_POST['user_bank_ifsc']) : addslashes($chk_pay_row['ifsc_code'] ?? ''));
    $user_upi_id         = !empty($data->user_upi_id) ? addslashes($data->user_upi_id) : (!empty($_POST['user_upi_id']) ? addslashes($_POST['user_upi_id']) : addslashes($chk_pay_row['upi_id'] ?? ''));

    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_ac_holder_name` varchar(255) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_ac_number` varchar(100) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_bank_name` varchar(255) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_bank_ifsc` varchar(50) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_upi_id` varchar(100) DEFAULT NULL");

    $stage_status = "EMPLOYEE-PENDING";
    $employee_read_status = "PENDING";
    $agency_read_status = "PENDING";
    $deatil_safe = addslashes($deatil);

    $qryins = mysqli_query($conn, "INSERT INTO `withdrawal`(
        `user_id`, `book_id`, `amount`, `transaction_id`, `agency_id`, 
        `stage_status`, `employee_read_status`, `agency_read_status`, 
        `bank_id`, `bank_name`, `bank_slag`, `emp_agency_image`, 
        `image`, `deatil`, `user_ac_holder_name`, `user_ac_number`, `user_bank_name`, `user_bank_ifsc`, `user_upi_id`, `remark`, `date_ts`
    ) VALUES (
        '$user_id', '$book_id', '$amount', '', '$agency_id', 
        '$stage_status', '$employee_read_status', '$agency_read_status', 
        '', '', '', '', 
        '$img_new1', '$deatil_safe', '$user_ac_holder_name', '$user_ac_number', '$user_bank_name', '$user_bank_ifsc', '$user_upi_id', '', '$date_ts'
    )");

    if ($qryins) {
        $withdrawal_id = mysqli_insert_id($conn);
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Withdrawal Request Submitted!",
            "withdrawal_id" => $withdrawal_id
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Withdrawal Request Not Submitted!"
        ]);
    }

} elseif ($action === 'withdraw_records') {
    // -------------------------------------------------------
    // WITHDRAW RECORDS
    // Input  : user_id (optional, omit to get all), status_type (optional: 'pending', 'successful', 'rejected', 'all')
    // Output : success (true/false), data (array of withdrawal records), categorized (pending, successful, rejected)
    // -------------------------------------------------------

    $user_id     = !empty($data->user_id)     ? (int)$data->user_id     : (!empty($_POST['user_id'])     ? (int)$_POST['user_id']     : 0);
    $status_type = !empty($data->status_type) ? trim($data->status_type) : (!empty($_POST['status_type']) ? trim($_POST['status_type']) : 'all');

    $where_clauses = [];
    if ($user_id > 0) {
        $where_clauses[] = "user_id = '$user_id'";
    }

    if ($status_type === 'pending') {
        $where_clauses[] = "(stage_status = 'EMPLOYEE-PENDING' OR stage_status = 'EMPLOYEE-PASS' OR stage_status = 'AGENCY-PENDING')";
    } elseif ($status_type === 'successful' || $status_type === 'done') {
        $where_clauses[] = "(stage_status = 'EMPLOYEE-DONE' OR stage_status = 'AGENCY-DONE')";
    } elseif ($status_type === 'rejected') {
        $where_clauses[] = "(stage_status = 'AGENCY-REJECT' OR stage_status = 'EMPLOYEE-REJECT')";
    }

    $where_sql = count($where_clauses) > 0 ? "WHERE " . implode(" AND ", $where_clauses) : "";

    $query = "SELECT * FROM `withdrawal` $where_sql ORDER BY ABS(id) DESC";
    $result = mysqli_query($conn, $query);

    if ($result) {
        $all_records = [];
        $pending_records = [];
        $successful_records = [];
        $rejected_records = [];

        while ($row = mysqli_fetch_assoc($result)) {
            $book_id = $row['book_id'];
            $book_name = "";
            if (!empty($book_id)) {
                $qry_bk = mysqli_query($conn, "SELECT name FROM `features` WHERE id = '$book_id' LIMIT 1");
                if ($res_bk = mysqli_fetch_assoc($qry_bk)) {
                    $book_name = $res_bk['name'];
                }
            }
            $row['book_name'] = $book_name;
            $row['image_url'] = !empty($row['image']) ? $m_url . ADD_PHOTO_SITE_PATH . $row['image'] : null;
            $row['emp_agency_image_url'] = !empty($row['emp_agency_image']) ? $m_url . ADD_PHOTO_SITE_PATH . $row['emp_agency_image'] : null;
            $row['formatted_date'] = is_numeric($row['date_ts']) ? date('m/d/Y H:i:s a', (int)$row['date_ts']) : $row['date_ts'];

            $stage = $row['stage_status'];
            if ($stage === 'EMPLOYEE-DONE' || $stage === 'AGENCY-DONE') {
                $row['status_category'] = 'SUCCESSFUL';
                $successful_records[] = $row;
            } elseif ($stage === 'AGENCY-REJECT' || $stage === 'EMPLOYEE-REJECT') {
                $row['status_category'] = 'REJECTED';
                $rejected_records[] = $row;
            } else {
                $row['status_category'] = 'PENDING';
                $pending_records[] = $row;
            }

            $all_records[] = $row;
        }

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Withdrawal records retrieved successfully.",
            "total_records" => count($all_records),
            "data" => $all_records,
            "categorized" => [
                "pending" => $pending_records,
                "successful" => $successful_records,
                "rejected" => $rejected_records
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database query failed."]);
    }

} elseif ($action === 'all_books') {
    // -------------------------------------------------------
    // ALL BOOKS
    // Input  : user_id (optional/recommended, to check subscription status)
    // Output : success (true/false), all_books, subscribed_books, non_subscribed_books
    // -------------------------------------------------------

    $user_id = !empty($data->user_id) ? (int)$data->user_id : (!empty($_POST['user_id']) ? (int)$_POST['user_id'] : 0);

    // Fetch user's active subscriptions if user_id is provided
    $user_subs = [];
    if ($user_id > 0) {
        $qrys = mysqli_query($conn, "SELECT * FROM `subscription` WHERE user_id = '$user_id'");
        if ($qrys) {
            while ($sub_row = mysqli_fetch_assoc($qrys)) {
                $user_subs[$sub_row['book_id']] = $sub_row;
            }
        }
    }

    $qrybooks = mysqli_query($conn, "SELECT * FROM `features` WHERE type = 'BOOK' AND show_status = 'ACTIVE' ORDER BY ABS(id) DESC");

    if ($qrybooks) {
        $all_books = [];
        $subscribed_books = [];
        $non_subscribed_books = [];

        while ($book = mysqli_fetch_assoc($qrybooks)) {
            $book_id = $book['id'];
            $book['image_url'] = !empty($book['image']) ? $m_url . ADD_PHOTO_SITE_PATH . $book['image'] : null;
            $book['website_link'] = isset($book['detail']) ? $book['detail'] : '';

            if (isset($user_subs[$book_id])) {
                $sub_info = $user_subs[$book_id];
                $book['is_subscribed'] = true;
                $book['subscription_id'] = (int)$sub_info['id'];
                $book['username'] = !empty($sub_info['username']) ? $sub_info['username'] : '';
                $book['password'] = !empty($sub_info['password']) ? $sub_info['password'] : '';
                $book['subscription_stage'] = $sub_info['stage_status'];
                $book['subscription_read_status'] = $sub_info['read_status'];
                
                $subscribed_books[] = $book;
            } else {
                $book['is_subscribed'] = false;
                $book['subscription_id'] = null;
                $book['username'] = '';
                $book['password'] = '';
                $book['subscription_stage'] = null;
                $book['subscription_read_status'] = null;

                $non_subscribed_books[] = $book;
            }

            $all_books[] = $book;
        }

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Books retrieved successfully.",
            "total_books" => count($all_books),
            "total_subscribed" => count($subscribed_books),
            "total_non_subscribed" => count($non_subscribed_books),
            "all_books" => $all_books,
            "subscribed_books" => $subscribed_books,
            "non_subscribed_books" => $non_subscribed_books
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database query failed."]);
    }

} elseif ($action === 'click_on_book') {
    // -------------------------------------------------------
    // CLICK ON BOOK
    // Input  : user_id (required), book_id (required)
    // Output : 
    //  - If ALREADY Subscribed: returns website link, username, password, & subscription details.
    //  - If NON-Subscribed: instantly creates a subscription request and returns success.
    // -------------------------------------------------------

    $user_id = !empty($data->user_id) ? (int)$data->user_id : (!empty($_POST['user_id']) ? (int)$_POST['user_id'] : 0);
    $book_id = !empty($data->book_id) ? (int)$data->book_id : (!empty($_POST['book_id']) ? (int)$_POST['book_id'] : 0);

    if (!$user_id || !$book_id) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "user_id and book_id are required."
        ]);
        exit;
    }

    // Verify book exists in features table
    $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$book_id' AND type = 'BOOK' AND show_status = 'ACTIVE' LIMIT 1");
    if (!$qrybook || mysqli_num_rows($qrybook) == 0) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Book not found or inactive."
        ]);
        exit;
    }
    $book_details = mysqli_fetch_assoc($qrybook);
    $book_details['image_url'] = !empty($book_details['image']) ? $m_url . ADD_PHOTO_SITE_PATH . $book_details['image'] : null;

    // Check if subscription exists for user & book
    $qrys = mysqli_query($conn, "SELECT * FROM `subscription` WHERE book_id = '$book_id' AND user_id = '$user_id' LIMIT 1");

    if ($qrys && mysqli_num_rows($qrys) > 0) {
        // --- CASE 1: ALREADY SUBSCRIBED ---
        $sub_data = mysqli_fetch_assoc($qrys);
        
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "is_subscribed" => true,
            "already_subscribed" => true,
            "message" => "Book is subscribed.",
            "data" => [
                "subscription_id"   => (int)$sub_data['id'],
                "book_id"           => (int)$book_details['id'],
                "book_name"         => $book_details['name'],
                "website_link"      => isset($book_details['detail']) ? $book_details['detail'] : '',
                "image_url"         => $book_details['image_url'],
                "username"          => !empty($sub_data['username']) ? $sub_data['username'] : null,
                "password"          => !empty($sub_data['password']) ? $sub_data['password'] : null,
                "has_credentials"   => (!empty($sub_data['username']) && !empty($sub_data['password'])),
                "stage_status"      => $sub_data['stage_status'],
                "read_status"       => $sub_data['read_status']
            ]
        ]);
    } else {
        // --- CASE 2: NON-SUBSCRIBED -> INSTANT SUBSCRIBE REQUEST ---
        $qryusrdetls = mysqli_query($conn, "SELECT agency_id FROM `users` WHERE id = '$user_id' LIMIT 1");
        $agency_id = 1;
        $user_under = "ADMIN";

        if ($qryusrdetls && mysqli_num_rows($qryusrdetls) > 0) {
            $rmusrdetls = mysqli_fetch_assoc($qryusrdetls);
            $agency_id = (int)$rmusrdetls['agency_id'];
            $user_under = ($agency_id == 1) ? "ADMIN" : "AGENCY";
        }

        $read_status = "PENDING";
        $stage_status = "PENDING";
        $show_status = "ACTIVE";

        $qryins = mysqli_query($conn, "INSERT INTO `subscription`(
            `user_id`, `book_id`, `emp_id`, `stage_status`, 
            `read_status`, `show_status`, `user_under`, `date_ts`
        ) VALUES (
            '$user_id', '$book_id', '$agency_id', '$stage_status', 
            '$read_status', '$show_status', '$user_under', '$date_ts'
        )");

        if ($qryins) {
            $new_sub_id = mysqli_insert_id($conn);
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "is_subscribed" => false,
                "request_submitted" => true,
                "message" => "Subscribe request sent successfully!",
                "data" => [
                    "subscription_id"   => $new_sub_id,
                    "book_id"           => (int)$book_details['id'],
                    "book_name"         => $book_details['name'],
                    "website_link"      => isset($book_details['detail']) ? $book_details['detail'] : '',
                    "image_url"         => $book_details['image_url'],
                    "username"          => null,
                    "password"          => null,
                    "has_credentials"   => false,
                    "stage_status"      => "PENDING",
                    "read_status"       => "PENDING"
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                "success" => false,
                "message" => "Failed to send subscribe request."
            ]);
        }
    }

} elseif ($action === 'send_enquiry') {
    // -------------------------------------------------------
    // SEND ENQUIRY / CONTACT US
    // Input  : name, email, phone / mob, sub / subject, msg / message, user_id (optional), emp_id / agency_id (optional)
    // Output : success (true/false), message, enquiry_id
    // Reference: _footer.php & _header.php contact form insertion
    // -------------------------------------------------------

    $user_id   = !empty($data->user_id) ? (int)$data->user_id : (!empty($_POST['user_id']) ? (int)$_POST['user_id'] : 0);
    $emp_id    = !empty($data->emp_id) ? (int)$data->emp_id : (!empty($data->agency_id) ? (int)$data->agency_id : (!empty($_POST['emp_id']) ? (int)$_POST['emp_id'] : (!empty($_POST['agency_id']) ? (int)$_POST['agency_id'] : 0)));

    $name  = !empty($data->name) ? trim($data->name) : (!empty($_POST['name']) ? trim($_POST['name']) : '');
    $email = !empty($data->email) ? trim($data->email) : (!empty($_POST['email']) ? trim($_POST['email']) : '');
    $phone = !empty($data->phone) ? trim($data->phone) : (!empty($data->mob) ? trim($data->mob) : (!empty($_POST['phone']) ? trim($_POST['phone']) : (!empty($_POST['mob']) ? trim($_POST['mob']) : '')));
    $sub   = !empty($data->sub) ? trim($data->sub) : (!empty($data->subject) ? trim($data->subject) : (!empty($_POST['sub']) ? trim($_POST['sub']) : (!empty($_POST['subject']) ? trim($_POST['subject']) : '')));
    $msg   = !empty($data->msg) ? trim($data->msg) : (!empty($data->message) ? trim($data->message) : (!empty($_POST['msg']) ? trim($_POST['msg']) : (!empty($_POST['message']) ? trim($_POST['message']) : '')));

    // If user_id is provided, populate missing agency_id and user contact details if empty
    if ($user_id > 0) {
        $qry_usr = mysqli_query($conn, "SELECT name, email, mob, agency_id FROM `users` WHERE id = '$user_id' LIMIT 1");
        if ($qry_usr && mysqli_num_rows($qry_usr) > 0) {
            $user_row = mysqli_fetch_assoc($qry_usr);
            if (empty($emp_id)) {
                $emp_id = (int)$user_row['agency_id'];
            }
            if (empty($name) && !empty($user_row['name'])) {
                $name = $user_row['name'];
            }
            if (empty($email) && !empty($user_row['email'])) {
                $email = $user_row['email'];
            }
            if (empty($phone) && !empty($user_row['mob'])) {
                $phone = $user_row['mob'];
            }
        }
    }

    // Default emp_id to 1 (Admin) if still 0 or empty
    if (empty($emp_id)) {
        $emp_id = 1;
    }

    if (empty($name) || (empty($email) && empty($phone)) || empty($sub) || empty($msg)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Name, contact (email/phone), subject, and message are required."
        ]);
        exit;
    }

    $read_status = "PENDING";
    $enq_date = !empty($date) ? $date : date("Y-m-d");

    $stmt = $conn->prepare("INSERT INTO `contact` (`name`, `user_id`, `emp_id`, `phone`, `email`, `sub`, `msg`, `read_status`, `date`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("siissssss", $name, $user_id, $emp_id, $phone, $email, $sub, $msg, $read_status, $enq_date);

    if ($stmt->execute()) {
        $enquiry_id = $conn->insert_id;
        $stmt->close();
        http_response_code(201);
        echo json_encode([
            "success" => true,
            "message" => "Enquiry submitted successfully!",
            "enquiry_id" => (int)$enquiry_id
        ]);
    } else {
        $stmt->close();
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Failed to submit enquiry."
        ]);
    }

} elseif ($action === 'get_payment_account' || $action === 'read_payment_account') {
    // -------------------------------------------------------
    // GET USER PAYMENT ACCOUNT DETAILS
    // Input  : user_id
    // Output : success (true/false), data (object with account details)
    // -------------------------------------------------------

    $user_id = !empty($data->user_id) ? (int)$data->user_id : (!empty($_POST['user_id']) ? (int)$_POST['user_id'] : 0);

    if (!$user_id) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "user_id is required."
        ]);
        exit;
    }

    $qry_pay_dls = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$user_id' ORDER BY id DESC LIMIT 1");
    if ($qry_pay_dls && mysqli_num_rows($qry_pay_dls) > 0) {
        $pay_acc_dls = mysqli_fetch_assoc($qry_pay_dls);
        $pay_acc_dls['image_url'] = !empty($pay_acc_dls['image']) ? $m_url . ADD_PHOTO_SITE_PATH . $pay_acc_dls['image'] : null;
        
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "data" => $pay_acc_dls
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "No payment account details found for this user.",
            "data" => null
        ]);
    }

} elseif ($action === 'update_payment_account' || $action === 'user_payment_account' || $action === 'save_payment_account') {
    // -------------------------------------------------------
    // UPDATE USER PAYMENT ACCOUNT DETAILS
    // Input  : user_id, account_name, account_no, ifsc_code, bank_name, upi_id, old_pay_img, image/payment_image (file or base64)
    // Output : success (true/false), message, data
    // -------------------------------------------------------

    $user_id      = !empty($data->user_id)      ? (int)$data->user_id      : (!empty($_POST['user_id'])      ? (int)$_POST['user_id']      : 0);
    $account_name = !empty($data->account_name) ? trim($data->account_name) : (!empty($_POST['account_name']) ? trim($_POST['account_name']) : '');
    $account_no   = !empty($data->account_no)   ? trim($data->account_no)   : (!empty($_POST['account_no'])   ? trim($_POST['account_no'])   : '');
    $ifsc_code    = !empty($data->ifsc_code)    ? trim($data->ifsc_code)    : (!empty($_POST['ifsc_code'])    ? trim($_POST['ifsc_code'])    : '');
    $bank_name    = !empty($data->bank_name)    ? trim($data->bank_name)    : (!empty($_POST['bank_name'])    ? trim($_POST['bank_name'])    : '');
    $upi_id       = !empty($data->upi_id)       ? trim($data->upi_id)       : (!empty($_POST['upi_id'])       ? trim($_POST['upi_id'])       : '');
    $old_pay_img  = !empty($data->old_pay_img)  ? trim($data->old_pay_img)  : (!empty($_POST['old_pay_img'])  ? trim($_POST['old_pay_img'])  : '');

    if (!$user_id) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "user_id is required."
        ]);
        exit;
    }

    @mysqli_query($conn, "CREATE TABLE IF NOT EXISTS `user_payment_accounts` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `user_id` int(11) NOT NULL,
      `account_name` varchar(255) DEFAULT NULL,
      `account_no` varchar(100) DEFAULT NULL,
      `ifsc_code` varchar(50) DEFAULT NULL,
      `bank_name` varchar(255) DEFAULT NULL,
      `upi_id` varchar(100) DEFAULT NULL,
      `image` varchar(255) DEFAULT NULL,
      `stage_status` varchar(50) DEFAULT '1',
      `read_status` varchar(50) DEFAULT '1',
      `date_ts` varchar(100) DEFAULT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    // Check if stage_status is EMPLOYEE-PENDING
    $chk_pending = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$user_id' ORDER BY id DESC LIMIT 1");
    $existing_row = mysqli_fetch_assoc($chk_pending);
    if (isset($existing_row['stage_status']) && $existing_row['stage_status'] === 'EMPLOYEE-PENDING') {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "You cannot update your payment account detail while approval is pending."
        ]);
        exit;
    }

    if (empty($old_pay_img) && isset($existing_row['image'])) {
        $old_pay_img = $existing_row['image'];
    }

    // Handle Image Upload (File or Base64)
    $pay_img_new = $old_pay_img;
    if (!empty($_FILES['payment_image']['name']) || !empty($_FILES['image']['name'])) {
        $file_obj = !empty($_FILES['payment_image']['name']) ? $_FILES['payment_image'] : $_FILES['image'];
        $ext = pathinfo($file_obj['name'], PATHINFO_EXTENSION);
        $pay_img_new = $date_ts . '_Payment_Acc_Image.' . $ext;
        move_uploaded_file($file_obj['tmp_name'], ADD_PHOTO_SERVER_PATH . $pay_img_new);
    } elseif (!empty($data->image_base64) || (!empty($data->image) && strpos($data->image, 'data:image') === 0)) {
        $base64_str = !empty($data->image_base64) ? $data->image_base64 : $data->image;
        if (preg_match('/^data:image\/(\w+);base64,/', $base64_str, $type)) {
            $base64_str = substr($base64_str, strpos($base64_str, ',') + 1);
            $ext = strtolower($type[1]);
        } else {
            $ext = 'png';
        }
        $base64_str = str_replace(' ', '+', $base64_str);
        $data_img = base64_decode($base64_str);
        $pay_img_new = $date_ts . '_Payment_Acc_Image.' . $ext;
        file_put_contents(ADD_PHOTO_SERVER_PATH . $pay_img_new, $data_img);
    }

    $stage_status = "EMPLOYEE-PENDING";
    $read_status  = "PENDING";

    $account_name_safe = addslashes($account_name);
    $account_no_safe   = addslashes($account_no);
    $ifsc_code_safe    = addslashes($ifsc_code);
    $bank_name_safe    = addslashes($bank_name);
    $upi_id_safe       = addslashes($upi_id);
    $pay_img_safe      = addslashes($pay_img_new);

    if ($existing_row) {
        $qry_acc = mysqli_query($conn, "UPDATE `user_payment_accounts` SET 
            `account_name` = '".$account_name_safe."',
            `account_no`   = '".$account_no_safe."',
            `ifsc_code`    = '".$ifsc_code_safe."',
            `bank_name`    = '".$bank_name_safe."',
            `upi_id`       = '".$upi_id_safe."',
            `image`        = '".$pay_img_safe."',
            `stage_status` = '".$stage_status."',
            `read_status`  = '".$read_status."',
            `date_ts`      = '".$date_ts."'
            WHERE `user_id` = '".$user_id."' ");
    } else {
        $qry_acc = mysqli_query($conn, "INSERT INTO `user_payment_accounts`(
            `user_id`, `account_name`, `account_no`, `ifsc_code`, `bank_name`, `upi_id`, `image`, `stage_status`, `read_status`, `date_ts`
        ) VALUES (
            '".$user_id."', '".$account_name_safe."', '".$account_no_safe."', '".$ifsc_code_safe."', '".$bank_name_safe."', '".$upi_id_safe."', '".$pay_img_safe."', '".$stage_status."', '".$read_status."', '".$date_ts."'
        )");
    }

    if ($qry_acc) {
        if (!empty($pay_img_new) && !empty($old_pay_img) && $pay_img_new != $old_pay_img) {
            if (file_exists(ADD_PHOTO_SERVER_PATH . $old_pay_img)) {
                @unlink(ADD_PHOTO_SERVER_PATH . $old_pay_img);
            }
        }

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Payment Account Details Updated Successfully!",
            "data" => [
                "user_id"      => $user_id,
                "account_name" => $account_name,
                "account_no"   => $account_no,
                "ifsc_code"    => $ifsc_code,
                "bank_name"    => $bank_name,
                "upi_id"       => $upi_id,
                "image"        => $pay_img_new,
                "image_url"    => !empty($pay_img_new) ? $m_url . ADD_PHOTO_SITE_PATH . $pay_img_new : null,
                "stage_status" => $stage_status,
                "read_status"  => $read_status,
                "date_ts"      => $date_ts
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Failed to update payment account details."
        ]);
    }

} elseif ($action === 'send_otp') {
    // -------------------------------------------------------
    // SEND OTP (FOR PHONE VERIFICATION)
    // Input  : phone / mob / mobile
    // Output : success (true/false), status ('success'/'error'), message, otp, phone
    // -------------------------------------------------------

    if (isset($conn) && $conn) {
        @mysqli_query($conn, "CREATE TABLE IF NOT EXISTS `otps` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `phone` varchar(20) NOT NULL,
          `otp` varchar(10) NOT NULL,
          `date_ts` varchar(50) NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    }

    $raw_phone = !empty($data->phone) ? $data->phone : (!empty($data->mob) ? $data->mob : (!empty($data->mobile) ? $data->mobile : (!empty($_POST['phone']) ? $_POST['phone'] : (!empty($_POST['mob']) ? $_POST['mob'] : (!empty($_POST['mobile']) ? $_POST['mobile'] : '')))));
    $phone = preg_replace('/\D/', '', trim((string)$raw_phone));

    if (strlen($phone) !== 10 || !ctype_digit($phone)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'status'  => 'error',
            'message' => 'Invalid 10-digit phone number.'
        ]);
        exit;
    }

    // Generate random 6-digit OTP
    $otp = sprintf("%06d", mt_rand(100000, 999999));
    $date_ts_str = date("Y-m-d H:i:s");

    // Insert into otps table
    $insertQry = "INSERT INTO `otps`(`phone`, `otp`, `date_ts`) VALUES ('$phone', '$otp', '$date_ts_str')";
    $insertRes = mysqli_query($conn, $insertQry);

    if (!$insertRes) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'status'  => 'error',
            'message' => 'Database insertion failed: ' . mysqli_error($conn)
        ]);
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

    // OTP SMS Message
    $otp_message = "Your verification OTP for " . $site_heading . " is " . $otp . ". Do not share this OTP with anyone.";
    $api_response_msg = '';
    $api_sent = false;

    // Format mobile parameter (adding 91 prefix for Indian mobile numbers if 10-digit)
    $mobile_param = (strlen($phone) === 10 && substr($phone, 0, 2) !== '91') ? ('91' . $phone) : $phone;

    if (!empty($apitxt_key)) {
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
        'success' => true,
        'status'  => 'success',
        'message' => 'OTP Send your phone!',
        'otp'     => $otp,
        'phone'   => $phone
    ];

    if (!$api_sent && !empty($api_response_msg)) {
        $response_data['api_notice'] = $api_response_msg;
    }

    http_response_code(200);
    echo json_encode($response_data);
    exit;

} elseif ($action === 'verify_otp') {
    // -------------------------------------------------------
    // VERIFY OTP
    // Input  : phone / mob / mobile, otp
    // Output : success (true/false), status ('success'/'error'), message
    // -------------------------------------------------------

    $raw_phone = !empty($data->phone) ? $data->phone : (!empty($data->mob) ? $data->mob : (!empty($data->mobile) ? $data->mobile : (!empty($_POST['phone']) ? $_POST['phone'] : (!empty($_POST['mob']) ? $_POST['mob'] : (!empty($_POST['mobile']) ? $_POST['mobile'] : '')))));
    $phone = preg_replace('/\D/', '', trim((string)$raw_phone));
    $otp = !empty($data->otp) ? trim((string)$data->otp) : (!empty($_POST['otp']) ? trim((string)$_POST['otp']) : '');

    if (empty($phone) || empty($otp)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'status'  => 'error',
            'message' => 'Phone number and OTP are required.'
        ]);
        exit;
    }

    $safe_phone = mysqli_real_escape_string($conn, $phone);
    $safe_otp   = mysqli_real_escape_string($conn, $otp);

    // Check latest OTP in otps database table for given phone number
    $checkQry = mysqli_query($conn, "SELECT * FROM `otps` WHERE `phone` = '$safe_phone' AND `otp` = '$safe_otp' ORDER BY `id` DESC LIMIT 1");

    if ($checkQry && mysqli_num_rows($checkQry) > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'status'  => 'success',
            'message' => 'OTP verified successfully!'
        ]);
    } else {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'status'  => 'error',
            'message' => 'Invalid OTP. Please check and try again.'
        ]);
    }
    exit;

} else {
    // Fallback for unknown actions
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Action not found or invalid request."
    ]);
}
// API USAGE FOR CHAT-ASSISTANT:
// URL: http://localhost/gamecrm/api.php (Replace 'localhost' with your live domain)
//
// --- Endpoints (POST with JSON payload) ---
// 1. Login: { "action": "login", "email": "user_email_or_mobile", "password": "user_password" }
// 2. Read Users: { "action": "read_users", "id": 1 } (id is optional, omit to get all)
// 3. Create User: { "action": "create_user", "name": "Jane", "email": "jane@test.com", "password": "123", "mob": "9876543210" }
// 4. Update User: { "action": "update_user", "id": 1, "name": "Jane Doe" }
// 5. Delete User: { "action": "delete_user", "id": 1 }
// 6. Get by Agency: { "action": "get_by_agency_id", "agency_id": "1" } (Works with numeric id or 'AGENCY-XX')
// 7. Get QR Code:   { "action": "get_qr_code", "book_id": 324, "agency_id": 23, "amount": 300 }
// 8. Recharge by User: { "action": "recharge_by_user", "user_id": 22, "qr_id": 3, "range_id": 1, "amount": 90, "emp_id": 1, "book_id": 324, "transection_id": "TXN123456", "image": "data:image/png;base64,..." }
// 9. Recharge Records: { "action": "recharge_records", "user_id": 22, "status_type": "all" } (status_type options: "pending", "successful", "rejected", "all")
// 10. User Withdraw: { "action": "user_withdraw", "user_id": 22, "book_id": 324, "amount": 100, "deatil": "Bank Acc details", "image": "data:image/png;base64,..." }
// 11. Withdraw Records: { "action": "withdraw_records", "user_id": 22, "status_type": "all" } (status_type options: "pending", "successful", "rejected", "all")
// 12. All Books: { "action": "all_books", "user_id": 22 }
// 13. Click On Book: { "action": "click_on_book", "user_id": 22, "book_id": 324 }
// 14. Send Enquiry: { "action": "send_enquiry", "name": "John Doe", "email": "john@example.com", "phone": "9876543210", "sub": "General Query", "msg": "Hello...", "user_id": 22 }
// 15. Get Payment Account: { "action": "get_payment_account", "user_id": 22 }
// 16. Update Payment Account: { "action": "update_payment_account", "user_id": 22, "account_name": "John Doe", "account_no": "123456789", "ifsc_code": "IFSC0001", "bank_name": "SBI", "upi_id": "john@upi", "image": "data:image/png;base64,..." }
// 17. Send OTP: { "action": "send_otp", "phone": "9876543210" }
// 18. Verify OTP: { "action": "verify_otp", "phone": "9876543210", "otp": "123456" }
//
// Note: Only non-'USER' roles (e.g. AGENCY) can login via the login action.
//
// Expected Responses:
// 200/201 OK: { "success": true, "message": "...", "data": [...] }
// 400 Bad Request: { "success": false, "message": "Incomplete data / Missing fields." }
// 401 Unauthorized: { "success": false, "message": "Invalid credentials." }
// 403 Forbidden: { "success": false, "message": "Account is suspended or inactive." }
// 404 Not Found: { "success": false, "message": "Action not found or invalid request." }
// 500 Server Error: { "success": false, "message": "Database/Execution error." }
//
// send_otp Response:
// { "success": true, "status": "success", "message": "OTP Send your phone!", "otp": "123456", "phone": "9876543210" }
//
// verify_otp Response:
// { "success": true, "status": "success", "message": "OTP verified successfully!" }
//
?>
