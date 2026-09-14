<?php 
include 'partials/_header.php';
$msg='';
if(ISSET($_POST['upd_acdls'])){
    $name = addslashes($_POST["name"]);
    $mob = addslashes($_POST["mob"]);
    $email = addslashes($_POST["email"]);
    $old_img = addslashes($_POST["old_img"]);
    $id = $user_dls["id"];
  
    $type = "USER";
    $res1=mysqli_query($conn,"select * from users where id<>$id and ( mob='$mob' or email='$email' ) ");
    $check=mysqli_num_rows($res1);
    if($check>0){
        $msg="1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "This Account already exist!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.''.$routey.'";</script>';
            exit;
        }
    }
    else{
        $msg='';
    }

    if($msg == ''){
        $img_new1 = $old_img;
        if(isset($_FILES['image']) && $_FILES['image']['name']!=''){
            $img1 = $_FILES["image"]['name'];
            if (($_FILES['image']['size'] > 1048576) || ( $_FILES['image']['type']!='image/png' && $_FILES['image']['type']!='image/jpg' && $_FILES['image']['type']!='image/jpeg' && $_FILES['image']['type']!='image/webp' && $_FILES['image']['type']!='image/avif')){
                $_SESSION['swl_type'] = "error";
                $_SESSION['head'] = "Error !";
                $_SESSION['text'] = "Select Jpg/png/webp/avif Under 1Mb!";
                if(ISSET($_SESSION['swl_type'])){
                    echo '<script language="javascript">location.href="'.$m_url.''.$routey.'";</script>';
                    exit;
                }
            }
            else{
                $img_new1=$date_ts.'_User_Image.'.pathinfo($img1, PATHINFO_EXTENSION);
                move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
            }
        }

        $qry = mysqli_query($conn, "UPDATE `users` set `name` = '".$name."', `mob` = '".$mob."', `email` = '".$email."', `img` = '".$img_new1."' WHERE `id` = '".$id."' ") or die(mysqli_error($conn));    
        if($qry){
            if(!empty($img_new1) && !empty($old_img) && $img_new1 != $old_img){
                if(file_exists(ADD_PHOTO_SERVER_PATH.$old_img)){
                    @unlink(ADD_PHOTO_SERVER_PATH.$old_img);
                }
            }
        }

        // Process payment account details if posted
        if(isset($_POST['account_name'])){
            $chk_pending_qry = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$id' ORDER BY id DESC LIMIT 1");
            $chk_pending_row = mysqli_fetch_array($chk_pending_qry);
            $is_currently_pending = isset($chk_pending_row['stage_status']) && $chk_pending_row['stage_status'] === 'EMPLOYEE-PENDING';

            if(!$is_currently_pending){
                $account_name = addslashes($_POST["account_name"]);
                $account_no   = addslashes($_POST["account_no"]);
                $ifsc_code    = addslashes($_POST["ifsc_code"]);
                $bank_name    = addslashes($_POST["bank_name"]);
                $upi_id       = addslashes($_POST["upi_id"]);
                $old_pay_img  = isset($_POST["old_pay_img"]) ? addslashes($_POST["old_pay_img"]) : '';
                $stage_status = "EMPLOYEE-PENDING";
                $read_status  = "PENDING";

                $pay_img_new = $old_pay_img;
                if(isset($_FILES["payment_image"]) && $_FILES['payment_image']['name'] != ''){
                    if (($_FILES['payment_image']['size'] <= 5242880) && ( $_FILES['payment_image']['type']=='image/png' || $_FILES['payment_image']['type']=='image/jpg' || $_FILES['payment_image']['type']=='image/jpeg' || $_FILES['payment_image']['type']=='image/webp' || $_FILES['payment_image']['type']=='image/avif' || $_FILES['payment_image']['type']=='application/pdf')){
                        $pay_img_new = $date_ts.'_Payment_Acc_Image.'.pathinfo($_FILES['payment_image']['name'], PATHINFO_EXTENSION);
                        move_uploaded_file($_FILES['payment_image']['tmp_name'], ADD_PHOTO_SERVER_PATH.$pay_img_new);
                        if(!empty($old_pay_img) && $pay_img_new != $old_pay_img && file_exists(ADD_PHOTO_SERVER_PATH.$old_pay_img)){
                            @unlink(ADD_PHOTO_SERVER_PATH.$old_pay_img);
                        }
                    }
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

                $res_check = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$id'");
                if(mysqli_num_rows($res_check) > 0){
                    mysqli_query($conn, "UPDATE `user_payment_accounts` SET 
                        `account_name` = '".$account_name."',
                        `account_no`   = '".$account_no."',
                        `ifsc_code`    = '".$ifsc_code."',
                        `bank_name`    = '".$bank_name."',
                        `upi_id`       = '".$upi_id."',
                        `image`        = '".$pay_img_new."',
                        `stage_status` = '".$stage_status."',
                        `read_status`  = '".$read_status."',
                        `date_ts`      = '".$date_ts."'
                        WHERE `user_id` = '".$id."' ") or die(mysqli_error($conn));
                } else {
                    mysqli_query($conn, "INSERT INTO `user_payment_accounts`(`user_id`, `account_name`, `account_no`, `ifsc_code`, `bank_name`, `upi_id`, `image`, `stage_status`, `read_status`, `date_ts`) VALUES ('".$id."', '".$account_name."', '".$account_no."', '".$ifsc_code."', '".$bank_name."', '".$upi_id."', '".$pay_img_new."', '".$stage_status."', '".$read_status."', '".$date_ts."')") or die(mysqli_error($conn));
                }
            }
        }

        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successful!";
        $_SESSION['text'] = "Profile & Account Details Updated!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.''.$routey.'";</script>';
            exit;
        }
    }
}

$user_id_curr = isset($user_dls['id']) ? $user_dls['id'] : 0;

$qry_pay_dls = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$user_id_curr' ORDER BY id DESC LIMIT 1");
$pay_acc_dls = mysqli_fetch_array($qry_pay_dls);
$is_pay_pending = isset($pay_acc_dls['stage_status']) && $pay_acc_dls['stage_status'] === 'EMPLOYEE-PENDING';
?>

<style>
    /* DreamHub Dark Neon Profile System (Strict Mockup Match) */
    .profile-page-wrapper {
        max-width: 680px !important;
        margin: 20px auto 20px auto !important;
        padding: 0 16px !important;
    }

    /* Glassmorphism Card Container */
    .dh-profile-card {
        background: linear-gradient(180deg, #071B31 0%, #04111F 100%) !important;
        border: 1px solid #135FA8 !important;
        border-radius: 24px !important;
        padding: 26px 22px !important;
        box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4), 0 0 24px rgba(23, 200, 255, 0.12) !important;
    }

    /* Header Section */
    .dh-profile-header {
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        margin-bottom: 24px !important;
        flex-wrap: wrap !important;
        gap: 16px !important;
    }

    .dh-profile-title-group h2 {
        font-size: 24px !important;
        font-weight: 700 !important;
        color: #F7FAFF !important;
        margin: 0 !important;
        line-height: 1.2 !important;
    }

    .dh-profile-title-group p {
        font-size: 13px !important;
        color: #9FB8D9 !important;
        margin: 4px 0 0 0 !important;
    }

    .dh-user-avatar-block {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
    }

    .dh-avatar-ring-container {
        position: relative !important;
        width: 68px !important;
        height: 68px !important;
        border-radius: 50% !important;
        border: 2px solid #17C8FF !important;
        box-shadow: 0 0 20px rgba(23, 200, 255, 0.5) !important;
        background: #0B2440 !important;
        flex-shrink: 0 !important;
    }

    .dh-avatar-img {
        width: 100% !important;
        height: 100% !important;
        border-radius: 50% !important;
        object-fit: cover !important;
    }

    .dh-avatar-cam-btn {
        position: absolute !important;
        bottom: -2px !important;
        right: -2px !important;
        width: 26px !important;
        height: 26px !important;
        border-radius: 50% !important;
        background: #087BFF !important;
        border: 2px solid #04111F !important;
        color: #FFFFFF !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 12px !important;
        cursor: pointer !important;
        box-shadow: 0 0 10px rgba(8, 123, 255, 0.6) !important;
        transition: transform 0.2s ease !important;
    }

    .dh-avatar-cam-btn:hover {
        transform: scale(1.1) !important;
    }

    .dh-user-meta-name {
        font-size: 16px !important;
        font-weight: 700 !important;
        color: #F7FAFF !important;
        text-transform: uppercase !important;
        line-height: 1.2 !important;
    }

    .dh-user-meta-badge {
        display: inline-block !important;
        margin-top: 4px !important;
        background: rgba(11, 36, 64, 0.8) !important;
        border: 1px solid #1A3F66 !important;
        color: #9FB8D9 !important;
        font-size: 11px !important;
        font-weight: 600 !important;
        padding: 2px 10px !important;
        border-radius: 999px !important;
    }

    /* Section Banner Header */
    .dh-section-banner {
        background: rgba(11, 36, 64, 0.6) !important;
        border: 1px solid #1A3F66 !important;
        border-radius: 16px !important;
        padding: 12px 16px !important;
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
        margin-bottom: 18px !important;
    }

    .dh-section-icon-box {
        width: 40px !important;
        height: 40px !important;
        border-radius: 12px !important;
        background: rgba(8, 123, 255, 0.15) !important;
        border: 1px solid rgba(23, 200, 255, 0.3) !important;
        color: #17C8FF !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 18px !important;
        flex-shrink: 0 !important;
    }

    .dh-section-banner-title {
        font-size: 16px !important;
        font-weight: 700 !important;
        color: #F7FAFF !important;
        line-height: 1.2 !important;
    }

    .dh-section-banner-sub {
        font-size: 12px !important;
        color: #9FB8D9 !important;
        line-height: 1.2 !important;
        margin-top: 2px !important;
    }

    /* Form Field Rows Exact Proportions */
    .dh-field-row {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
        margin-bottom: 14px !important;
    }

    .dh-field-icon-box {
        width: 44px !important;
        height: 44px !important;
        min-width: 44px !important;
        border-radius: 12px !important;
        background: rgba(11, 36, 64, 0.8) !important;
        border: 1px solid #1A3F66 !important;
        color: #17C8FF !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 18px !important;
        flex-shrink: 0 !important;
    }

    .dh-field-label {
        width: 150px !important;
        min-width: 150px !important;
        flex-shrink: 0 !important;
        font-size: 13px !important;
        font-weight: 500 !important;
        color: #9FB8D9 !important;
        margin: 0 !important;
        line-height: 1.3 !important;
    }

    .dh-asterisk {
        color: #17C8FF !important;
        margin-left: 2px !important;
        font-weight: 600 !important;
    }

    .dh-field-input-wrap {
        flex: 1 !important;
        position: relative !important;
        display: flex !important;
        align-items: center !important;
    }

    .dh-field-input {
        width: 100% !important;
        height: 46px !important;
        background: #0B2440 !important;
        border: 1px solid #1A3F66 !important;
        border-radius: 12px !important;
        color: #F7FAFF !important;
        font-size: 14px !important;
        font-weight: 500 !important;
        padding: 0 16px !important;
        outline: none !important;
        box-shadow: none !important;
        transition: all 0.2s ease !important;
    }

    .dh-field-input::placeholder {
        color: #6E88A8 !important;
        opacity: 0.8 !important;
    }

    .dh-field-input:focus {
        border-color: #17C8FF !important;
        box-shadow: 0 0 14px rgba(23, 200, 255, 0.3) !important;
        background: #0D2D50 !important;
    }

    .dh-field-input[readonly],
    .dh-field-input:disabled {
        opacity: 0.75 !important;
        cursor: not-allowed !important;
        background: rgba(11, 36, 64, 0.5) !important;
        color: #6E88A8 !important;
    }

    .dh-field-input-copy-btn {
        position: absolute !important;
        right: 14px !important;
        top: 50% !important;
        transform: translateY(-50%) !important;
        color: #6E88A8 !important;
        cursor: pointer !important;
        font-size: 16px !important;
        transition: color 0.2s ease !important;
        z-index: 2 !important;
    }

    .dh-field-input-copy-btn:hover {
        color: #17C8FF !important;
    }

    /* QR Code / Passbook Image Section Layout */
    .dh-upload-zone-wrapper {
        margin-top: 16px !important;
        margin-bottom: 20px !important;
    }

    .dh-upload-dotted-box {
        flex: 1 !important;
        border: 1.5px dashed #135FA8 !important;
        border-radius: 14px !important;
        background: rgba(11, 36, 64, 0.5) !important;
        padding: 12px 18px !important;
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        gap: 16px !important;
        transition: border-color 0.2s ease !important;
    }

    .dh-upload-dotted-box:hover {
        border-color: #17C8FF !important;
    }

    .dh-upload-left-content {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
    }

    .dh-upload-cloud-icon {
        font-size: 28px !important;
        color: #17C8FF !important;
    }

    .dh-upload-text-title {
        font-size: 14px !important;
        font-weight: 600 !important;
        color: #F7FAFF !important;
    }

    .dh-upload-text-sub {
        font-size: 11px !important;
        color: #6E88A8 !important;
        margin-top: 2px !important;
    }

    .dh-upload-trigger-btn {
        background: linear-gradient(90deg, #17C8FF 0%, #087BFF 100%) !important;
        color: #FFFFFF !important;
        border: none !important;
        border-radius: 10px !important;
        padding: 8px 18px !important;
        font-size: 13px !important;
        font-weight: 600 !important;
        display: flex !important;
        align-items: center !important;
        gap: 6px !important;
        cursor: pointer !important;
        box-shadow: 0 4px 15px rgba(8, 123, 255, 0.3) !important;
        transition: transform 0.2s ease !important;
        white-space: nowrap !important;
    }

    .dh-upload-trigger-btn:hover {
        transform: translateY(-1px) !important;
        box-shadow: 0 6px 20px rgba(8, 123, 255, 0.5) !important;
    }

    /* Save Changes Button */
    .dh-btn-save-primary {
        width: 100% !important;
        height: 52px !important;
        border-radius: 999px !important;
        background: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%) !important;
        color: #FFFFFF !important;
        border: none !important;
        font-size: 16px !important;
        font-weight: 700 !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        gap: 10px !important;
        cursor: pointer !important;
        box-shadow: 0 10px 30px rgba(8, 123, 255, 0.45) !important;
        transition: all 0.25s ease !important;
        margin-top: 14px !important;
    }

    .dh-btn-save-primary:hover {
        transform: translateY(-2px) !important;
        box-shadow: 0 14px 35px rgba(23, 200, 255, 0.5) !important;
        filter: brightness(1.08) !important;
    }

    /* Mobile Responsive */
    @media (max-width: 576px) {
        .dh-field-row {
            flex-wrap: wrap !important;
            gap: 6px !important;
        }
        .dh-field-label {
            width: 100% !important;
            min-width: 100% !important;
        }
        .dh-field-icon-box {
            display: none !important;
        }
        .dh-profile-header {
            flex-direction: column !important;
            align-items: flex-start !important;
        }
    }
</style>

<div class="profile-page-wrapper">
    <div class="dh-profile-card">
        
        <!-- Header with Avatar & User Details -->
        <div class="dh-profile-header">
            <div class="dh-profile-title-group">
                <h2>My Profile</h2>
                <p>Manage your information and payment details securely.</p>
            </div>
            
            <div class="dh-user-avatar-block">
                <div class="dh-avatar-ring-container">
                    <img src="<?php if(ISSET($user_dls['img']) && $user_dls['img'] != '') { echo $m_url.ADD_PHOTO_SITE_PATH.$user_dls['img']; } else { echo $m_url.'assets/images/logo/user.png'; } ?>" alt="Profile Avatar" id="profileImagePreview" class="dh-avatar-img">
                    <button type="button" id="editImageBtn" class="dh-avatar-cam-btn" title="Change Photo">
                        <i class="bi bi-camera-fill"></i>
                    </button>
                </div>
                <div>
                    <div class="dh-user-meta-name"><?php echo htmlspecialchars($user_dls['name'] ?? 'FINAL TEST'); ?></div>
                    <span class="dh-user-meta-badge">User Account</span>
                </div>
            </div>
        </div>

        <!-- Combined Profile Form -->
        <form action="<?php echo $m_url; ?><?php echo $routey;?>" method="post" enctype="multipart/form-data">
            <input type="file" id="hiddenFileInput" accept="image/*" name="image" style="display:none;">
            <input type="hidden" name="old_img" value="<?php echo htmlspecialchars($user_dls['img'] ?? ''); ?>">

            <!-- 1. Personal Information Section -->
            <div class="dh-section-banner">
                <div class="dh-section-icon-box">
                    <i class="bi bi-person-fill"></i>
                </div>
                <div>
                    <div class="dh-section-banner-title">Personal Information</div>
                    <div class="dh-section-banner-sub">Keep your details up to date.</div>
                </div>
            </div>

            <!-- Full Name -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-person"></i>
                </div>
                <div class="dh-field-label">Full Name <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="name" class="dh-field-input" value="<?php echo htmlspecialchars($user_dls['name'] ?? ''); ?>" placeholder="Final Test" required>
                </div>
            </div>

            <!-- Email Address -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-envelope"></i>
                </div>
                <div class="dh-field-label">Email Address <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="email" name="email" class="dh-field-input" value="<?php echo htmlspecialchars($user_dls['email'] ?? ''); ?>" placeholder="finaltest1@gmail.com" required>
                </div>
            </div>

            <!-- Phone Number -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-telephone"></i>
                </div>
                <div class="dh-field-label">Phone Number <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="mob" class="dh-field-input" value="<?php echo htmlspecialchars($user_dls['mob'] ?? ''); ?>" placeholder="8910882266" required>
                </div>
            </div>

            <!-- Agency Name -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-people"></i>
                </div>
                <div class="dh-field-label">Agency Name</div>
                <div class="dh-field-input-wrap">
                    <input type="text" class="dh-field-input" style="padding-right: 36px !important;" value="<?php 
                        $agenid = $user_dls['agency_id'] ?? 1;
                        if($agenid == 1 || empty($agenid)){
                            echo "No Agency Assigned!";
                        } else {
                            $qryagendls = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$agenid' ") or die(mysqli_error($conn));
                            $agendls = mysqli_fetch_array($qryagendls);
                            echo htmlspecialchars($agendls['name'] ?? 'No Agency Assigned!');
                        }
                    ?>" readonly>
                    <i class="bi bi-chevron-down" style="position: absolute; right: 14px; top: 50%; transform: translateY(-50%); color: #6E88A8; font-size: 14px; pointer-events: none;"></i>
                </div>
            </div>


            <!-- 2. Payment Account Details Section -->
            <div class="dh-section-banner" style="margin-top: 28px !important;">
                <div class="dh-section-icon-box">
                    <i class="bi bi-bank"></i>
                </div>
                <div>
                    <div class="dh-section-banner-title">Payment Account Details</div>
                    <div class="dh-section-banner-sub">Add your withdrawal account details.</div>
                </div>
            </div>

            <input type="hidden" name="old_pay_img" value="<?php echo htmlspecialchars($pay_acc_dls['image'] ?? ''); ?>">

            <!-- Account Holder Name -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-person"></i>
                </div>
                <div class="dh-field-label">Account Holder Name <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="account_name" class="dh-field-input" value="<?php echo htmlspecialchars($pay_acc_dls['account_name'] ?? ''); ?>" placeholder="Rahul" required <?php if($is_pay_pending){ echo 'disabled'; } ?>>
                </div>
            </div>

            <!-- Account Number -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-credit-card"></i>
                </div>
                <div class="dh-field-label">Account Number <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="account_no" class="dh-field-input" value="<?php echo htmlspecialchars($pay_acc_dls['account_no'] ?? ''); ?>" placeholder="89108829900" required <?php if($is_pay_pending){ echo 'disabled'; } ?>>
                </div>
            </div>

            <!-- Bank Name -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-bank"></i>
                </div>
                <div class="dh-field-label">Bank Name <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="bank_name" class="dh-field-input" value="<?php echo htmlspecialchars($pay_acc_dls['bank_name'] ?? ''); ?>" placeholder="Axis" required <?php if($is_pay_pending){ echo 'disabled'; } ?>>
                </div>
            </div>

            <!-- IFSC Code -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-qr-code"></i>
                </div>
                <div class="dh-field-label">IFSC Code <span class="dh-asterisk">*</span></div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="ifsc_code" id="ifscCodeInput" class="dh-field-input" style="padding-right: 42px !important;" value="<?php echo htmlspecialchars($pay_acc_dls['ifsc_code'] ?? ''); ?>" placeholder="UTIN000013" required <?php if($is_pay_pending){ echo 'disabled'; } ?>>
                    <i class="bi bi-copy dh-field-input-copy-btn" id="copyIfscBtn" title="Copy IFSC Code"></i>
                </div>
            </div>

            <!-- UPI ID -->
            <div class="dh-field-row">
                <div class="dh-field-icon-box">
                    <i class="bi bi-send"></i>
                </div>
                <div class="dh-field-label">UPI ID</div>
                <div class="dh-field-input-wrap">
                    <input type="text" name="upi_id" id="upiIdInput" class="dh-field-input" style="padding-right: 42px !important;" value="<?php echo htmlspecialchars($pay_acc_dls['upi_id'] ?? ''); ?>" placeholder="Enter UPI ID (e.g. name@upi)" <?php if($is_pay_pending){ echo 'disabled'; } ?>>
                    <i class="bi bi-copy dh-field-input-copy-btn" id="copyUpiBtn" title="Copy UPI ID"></i>
                </div>
            </div>

            <!-- QR Code / Passbook Image Dotted Upload Zone -->
            <div class="dh-upload-zone-wrapper">
                <div class="dh-field-row" style="align-items: flex-start !important;">
                    <div class="dh-field-icon-box" style="margin-top: 4px !important;">
                        <i class="bi bi-image"></i>
                    </div>
                    <div class="dh-field-label" style="padding-top: 12px !important;">
                        QR Code / Passbook Image
                    </div>
                    <div class="dh-field-input-wrap">
                        <div class="dh-upload-dotted-box">
                            <div class="dh-upload-left-content">
                                <i class="bi bi-cloud-arrow-up dh-upload-cloud-icon"></i>
                                <div>
                                    <div class="dh-upload-text-title" id="selectedFileName">Choose File</div>
                                    <div class="dh-upload-text-sub">JPG, PNG or PDF (Max 5MB)</div>
                                </div>
                            </div>
                            <button type="button" id="triggerPayUploadBtn" class="dh-upload-trigger-btn" <?php if($is_pay_pending){ echo 'disabled style="opacity: 0.6; cursor: not-allowed;"'; } ?>>
                                <i class="bi bi-upload"></i>
                                <span>Choose File</span>
                            </button>
                        </div>
                        <input type="file" name="payment_image" id="paymentFileInput" accept="image/*" style="display:none;" <?php if($is_pay_pending){ echo 'disabled'; } ?>>
                    </div>
                </div>
                
                <?php if(isset($pay_acc_dls['image']) && $pay_acc_dls['image'] != ''){ ?>
                    <div class="mt-2 text-end">
                        <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$pay_acc_dls['image']; ?>" alt="Payment QR" id="paymentImgPrev" style="max-height: 70px; border-radius: 10px; border: 1px solid #1A3F66;">
                    </div>
                <?php } ?>
            </div>

            <?php if($is_pay_pending){ ?>
                <div class="alert alert-danger mt-3 mb-3 text-center" style="border-radius: 14px; font-weight: 600; font-size: 13px; background: rgba(255, 53, 93, 0.15); border: 1px solid #FF355D; color: #FF355D;" role="alert">
                    <i class="bi bi-exclamation-triangle-fill" style="margin-right: 5px;"></i> You cannot update payment account details while approval is pending.
                </div>
            <?php } ?>

            <!-- Primary Submit Button -->
            <button type="submit" name="upd_acdls" class="dh-btn-save-primary">
                <i class="bi bi-hdd-fill" style="font-size: 18px;"></i>
                <span>Save Changes</span>
            </button>
        </form>

    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Avatar Upload Triggers
        const editBtn   = document.getElementById('editImageBtn');
        const fileInput = document.getElementById('hiddenFileInput');
        const imgPrev   = document.getElementById('profileImagePreview');

        if (editBtn && fileInput) {
            editBtn.addEventListener('click', function() { fileInput.click(); });
        }

        if (fileInput && imgPrev) {
            fileInput.addEventListener('change', function(e) {
                if (e.target.files && e.target.files[0]) {
                    const reader = new FileReader();
                    reader.onload = function(ev) { imgPrev.src = ev.target.result; };
                    reader.readAsDataURL(e.target.files[0]);
                }
            });
        }

        // Payment Image Upload Triggers
        const triggerPayBtn = document.getElementById('triggerPayUploadBtn');
        const payFileInput  = document.getElementById('paymentFileInput');
        const fileNameDisplay = document.getElementById('selectedFileName');

        if (triggerPayBtn && payFileInput) {
            triggerPayBtn.addEventListener('click', function() { payFileInput.click(); });
        }

        if (payFileInput) {
            payFileInput.addEventListener('change', function(e) {
                if (e.target.files && e.target.files[0]) {
                    if (fileNameDisplay) {
                        fileNameDisplay.textContent = e.target.files[0].name;
                    }
                }
            });
        }

        // Copy Clipboard Helpers
        function copyText(inputId) {
            const el = document.getElementById(inputId);
            if (el && el.value.trim() !== '') {
                navigator.clipboard.writeText(el.value).then(function() {
                    if (typeof swal === 'function') {
                        swal({ title: "Copied!", text: el.value + " copied to clipboard.", icon: "success", timer: 1500, buttons: false });
                    }
                });
            }
        }

        const copyIfsc = document.getElementById('copyIfscBtn');
        if (copyIfsc) {
            copyIfsc.addEventListener('click', function() { copyText('ifscCodeInput'); });
        }

        const copyUpi = document.getElementById('copyUpiBtn');
        if (copyUpi) {
            copyUpi.addEventListener('click', function() { copyText('upiIdInput'); });
        }
    });
</script>

<?php
    if(!empty($_SESSION['swl_type']) && $_SESSION['swl_type'] != ''){
?>
    <script>
        window.addEventListener('load',function(){
            swal({
                title: "<?php echo $_SESSION['head']; ?>",
                text: "<?php echo $_SESSION['text']; ?>",
                icon: "<?php echo $_SESSION['swl_type']; ?>",
                button: "Ok Done!",
                showConfirmButton: false,
                timer: 5000
            }).then(function(){
                location.reload();
            });
        });
    </script>
<?php
    unset($_SESSION['head']);
    unset($_SESSION['text']);
    unset($_SESSION['swl_type']);
}
?>

<?php include 'partials/_footer.php'; ?>
