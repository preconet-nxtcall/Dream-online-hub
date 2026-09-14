<?php 
include 'partials/_header.php';

if(isset($_POST['withdraw_request'])){
    $user_id = $user_dls['id'];
    $chk_pay_qry = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$user_id' ORDER BY id DESC LIMIT 1");
    $chk_pay_row = mysqli_fetch_array($chk_pay_qry);

    if(empty($chk_pay_row)){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Please set up your Payment Account Details in Profile first!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'withdraw";</script>';
            exit;
        }
    }

    if(isset($chk_pay_row['stage_status']) && $chk_pay_row['stage_status'] === 'EMPLOYEE-PENDING'){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "You cannot request a withdrawal while your payment account detail approval is pending.";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'withdraw";</script>';
            exit;
        }
    }

    $agency_id = $user_dls['agency_id'];
    $amount = $_POST['amount'];
    $stage_status = "EMPLOYEE-PENDING";
    $employee_read_status = "PENDING";
    $agency_read_status = "PENDING";
    $book_id = $_POST['book_id'];
	$qrycheck=mysqli_query($conn,"SELECT * FROM `withdrawal` WHERE `user_id` = '$user_id' AND (`stage_status` = 'EMPLOYEE-PENDING' OR `stage_status` = 'EMPLOYEE-PASS' OR `stage_status` = 'AGENCY-PENDING')") or die(mysqli_error());
	$rmcheck=mysqli_fetch_array($qrycheck);
    if(ISSET($rmcheck)){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Withdrawal Already Exists!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'withdraw";</script>';
            exit;
        }
    }

    $user_ac_holder_name = isset($_POST['user_ac_holder_name']) ? addslashes($_POST['user_ac_holder_name']) : addslashes($chk_pay_row['account_name'] ?? '');
    $user_ac_number      = isset($_POST['user_ac_number']) ? addslashes($_POST['user_ac_number']) : addslashes($chk_pay_row['account_no'] ?? '');
    $user_bank_name      = isset($_POST['user_bank_name']) ? addslashes($_POST['user_bank_name']) : addslashes($chk_pay_row['bank_name'] ?? '');
    $user_bank_ifsc      = isset($_POST['user_bank_ifsc']) ? addslashes($_POST['user_bank_ifsc']) : addslashes($chk_pay_row['ifsc_code'] ?? '');
    $user_upi_id         = isset($_POST['user_upi_id']) ? addslashes($_POST['user_upi_id']) : addslashes($chk_pay_row['upi_id'] ?? '');
    $img_new1            = isset($_POST['user_pay_image']) ? addslashes($_POST['user_pay_image']) : addslashes($chk_pay_row['image'] ?? '');
    $deatil              = isset($_POST['deatil']) ? addslashes($_POST['deatil']) : '';

    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_ac_holder_name` varchar(255) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_ac_number` varchar(100) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_bank_name` varchar(255) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_bank_ifsc` varchar(50) DEFAULT NULL");
    @mysqli_query($conn, "ALTER TABLE `withdrawal` ADD COLUMN `user_upi_id` varchar(100) DEFAULT NULL");

    $qryins = mysqli_query($conn,"INSERT INTO `withdrawal`(`user_id`, `book_id`, `amount`, `agency_id`, `stage_status`, `employee_read_status`, `agency_read_status`, `image`, `deatil`, `user_ac_holder_name`, `user_ac_number`, `user_bank_name`, `user_bank_ifsc`, `user_upi_id`, `date_ts`) VALUES ('$user_id', '$book_id', '$amount', '$agency_id', '$stage_status', '$employee_read_status', '$agency_read_status', '$img_new1', '$deatil', '$user_ac_holder_name', '$user_ac_number', '$user_bank_name', '$user_bank_ifsc', '$user_upi_id', '$date_ts')") or die(mysqli_error($conn));
    if($qryins){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull!";
        $_SESSION['text'] = "Withdrawal Request Submitted!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'withdraw";</script>';
            exit;
        }
    }else{
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error!";
        $_SESSION['text'] = "Withdrawal Request Not Submitted!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'withdraw";</script>';
            exit;
        }
    }
}
?>

    <style>
        /* DreamHub Dark Neon Withdrawal Page (1:1 Mockup Match) */
        .withdraw-page-wrapper {
            max-width: 680px !important;
            margin: 20px auto 40px auto !important;
            padding: 0 16px !important;
        }

        /* Glassmorphism Outer Card Container */
        .dh-withdraw-card {
            background: linear-gradient(180deg, #071B31 0%, #04111F 100%) !important;
            border: 1px solid #135FA8 !important;
            border-radius: 28px !important;
            padding: 28px 24px !important;
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4), 0 0 24px rgba(23, 200, 255, 0.12) !important;
            position: relative !important;
        }

        /* Card Top Header Section */
        .dh-withdraw-header {
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            flex-wrap: nowrap !important;
            gap: 16px !important;
            margin-bottom: 24px !important;
        }

        .dh-withdraw-header-left {
            display: flex !important;
            align-items: center !important;
            gap: 14px !important;
        }

        .dh-withdraw-header-icon {
            width: 48px !important;
            height: 48px !important;
            border-radius: 14px !important;
            background: rgba(8, 123, 255, 0.15) !important;
            border: 1px solid rgba(23, 200, 255, 0.3) !important;
            color: #17C8FF !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-size: 22px !important;
            flex-shrink: 0 !important;
            box-shadow: 0 0 15px rgba(23, 200, 255, 0.2) !important;
        }

        .dh-withdraw-header-title {
            font-size: 22px !important;
            font-weight: 700 !important;
            color: #F7FAFF !important;
            line-height: 1.2 !important;
            margin: 0 !important;
        }

        .dh-withdraw-header-sub {
            font-size: 13px !important;
            color: #9FB8D9 !important;
            margin-top: 3px !important;
            line-height: 1.3 !important;
        }

        /* Safe & Secure Badge */
        .dh-safe-badge {
            background: rgba(11, 36, 64, 0.7) !important;
            border: 1px solid rgba(23, 200, 255, 0.2) !important;
            border-radius: 14px !important;
            padding: 8px 14px !important;
            display: flex !important;
            align-items: center !important;
            gap: 10px !important;
            flex-shrink: 0 !important;
        }

        .dh-safe-shield-icon {
            width: 32px !important;
            height: 32px !important;
            border-radius: 8px !important;
            background: #087BFF !important;
            color: #FFFFFF !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-size: 16px !important;
            box-shadow: 0 0 10px rgba(8, 123, 255, 0.5) !important;
        }

        .dh-safe-title {
            font-size: 12px !important;
            font-weight: 700 !important;
            color: #F7FAFF !important;
            line-height: 1.2 !important;
        }

        .dh-safe-sub {
            font-size: 10px !important;
            color: #9FB8D9 !important;
            line-height: 1.2 !important;
        }

        /* Warning Alert Banner (Amber) */
        .dh-warning-banner {
            background: rgba(255, 176, 32, 0.08) !important;
            border: 1px solid #FFB020 !important;
            border-radius: 16px !important;
            padding: 14px 18px !important;
            display: flex !important;
            align-items: center !important;
            gap: 14px !important;
            margin-bottom: 20px !important;
        }

        .dh-warning-icon {
            font-size: 26px !important;
            color: #FFB020 !important;
            flex-shrink: 0 !important;
        }

        .dh-warning-text {
            color: #FFB020 !important;
            font-size: 13px !important;
            font-weight: 600 !important;
            line-height: 1.4 !important;
        }

        /* Input Field Rows (Mockup 1:1 Layout) */
        .dh-input-row {
            display: flex !important;
            align-items: flex-end !important;
            gap: 14px !important;
            margin-bottom: 16px !important;
        }

        .dh-input-icon-box {
            width: 46px !important;
            height: 46px !important;
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

        .dh-input-field-wrap {
            flex: 1 !important;
            min-width: 0 !important;
        }

        .dh-input-label {
            font-size: 11px !important;
            font-weight: 700 !important;
            color: #9FB8D9 !important;
            letter-spacing: 0.5px !important;
            text-transform: uppercase !important;
            margin-bottom: 6px !important;
            display: block !important;
        }

        .dh-asterisk {
            color: #17C8FF !important;
            font-weight: 700 !important;
            margin-left: 2px !important;
        }

        .dh-input-control-wrap {
            position: relative !important;
            width: 100% !important;
        }

        .dh-input-control {
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

        .dh-input-control::placeholder {
            color: #6E88A8 !important;
            opacity: 0.8 !important;
        }

        .dh-input-control:focus {
            border-color: #17C8FF !important;
            box-shadow: 0 0 14px rgba(23, 200, 255, 0.3) !important;
            background: #0D2D50 !important;
        }

        .dh-input-control[readonly],
        .dh-input-control:disabled {
            opacity: 0.75 !important;
            cursor: not-allowed !important;
            background: rgba(11, 36, 64, 0.5) !important;
            color: #6E88A8 !important;
        }

        /* Select Dropdown Styling */
        select.dh-input-control {
            appearance: none !important;
            -webkit-appearance: none !important;
            -moz-appearance: none !important;
            padding-right: 40px !important;
            cursor: pointer !important;
        }

        select.dh-input-control option {
            background-color: #071B31 !important;
            color: #F7FAFF !important;
            padding: 10px !important;
        }

        .dh-select-chevron {
            position: absolute !important;
            right: 14px !important;
            top: 50% !important;
            transform: translateY(-50%) !important;
            color: #17C8FF !important;
            font-size: 14px !important;
            pointer-events: none !important;
        }

        /* Submit Button (Gradient Pill) */
        .dh-btn-submit {
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
            margin-top: 24px !important;
            margin-bottom: 20px !important;
        }

        .dh-btn-submit:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 14px 35px rgba(23, 200, 255, 0.5) !important;
            filter: brightness(1.08) !important;
        }

        .dh-btn-submit:disabled {
            opacity: 0.6 !important;
            cursor: not-allowed !important;
            transform: none !important;
            box-shadow: none !important;
        }

        /* Bottom Info Banner */
        .dh-info-banner {
            background: rgba(11, 36, 64, 0.6) !important;
            border: 1px solid rgba(23, 200, 255, 0.2) !important;
            border-radius: 16px !important;
            padding: 14px 18px !important;
            display: flex !important;
            align-items: center !important;
            gap: 14px !important;
        }

        .dh-info-icon-circle {
            width: 36px !important;
            height: 36px !important;
            border-radius: 50% !important;
            background: #17C8FF !important;
            color: #04111F !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-size: 20px !important;
            flex-shrink: 0 !important;
            box-shadow: 0 0 12px rgba(23, 200, 255, 0.4) !important;
        }

        .dh-info-text-title {
            font-size: 13px !important;
            font-weight: 600 !important;
            color: #F7FAFF !important;
            line-height: 1.3 !important;
        }

        .dh-info-text-sub {
            font-size: 11px !important;
            color: #9FB8D9 !important;
            margin-top: 2px !important;
            line-height: 1.3 !important;
        }

        /* Mobile Responsive Adjustments */
        @media (max-width: 576px) {
            .dh-withdraw-header {
                flex-direction: column !important;
                align-items: flex-start !important;
            }
            .dh-safe-badge {
                width: 100% !important;
                justify-content: flex-start !important;
            }
            .dh-input-row {
                flex-wrap: wrap !important;
                gap: 6px !important;
            }
            .dh-input-icon-box {
                display: none !important;
            }
        }
    </style>

    <!-- Withdraw Page Container -->
    <?php
    $user_id_curr = isset($user_dls['id']) ? $user_dls['id'] : 0;
    $qry_pay_acc = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `user_id` = '$user_id_curr' ORDER BY id DESC LIMIT 1");
    $pay_acc_dls = mysqli_fetch_array($qry_pay_acc);
    $is_pay_pending = isset($pay_acc_dls['stage_status']) && $pay_acc_dls['stage_status'] === 'EMPLOYEE-PENDING';
    $is_pay_empty = empty($pay_acc_dls);

    $qry_with_check = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE `user_id` = '$user_id_curr' AND (`stage_status` = 'EMPLOYEE-PENDING' OR `stage_status` = 'EMPLOYEE-PASS' OR `stage_status` = 'AGENCY-PENDING')");
    $is_withdraw_exists = (mysqli_num_rows($qry_with_check) > 0);

    $is_withdraw_disabled = $is_pay_empty || $is_pay_pending || $is_withdraw_exists;
    ?>
    <div class="withdraw-page-wrapper">
        <div class="dh-withdraw-card">
            
            <!-- Card Header Section -->
            <div class="dh-withdraw-header">
                <div class="dh-withdraw-header-left">
                    <div class="dh-withdraw-header-icon">
                        <i class="bi bi-bank"></i>
                    </div>
                    <div>
                        <h3 class="dh-withdraw-header-title">Withdraw Now</h3>
                        <div class="dh-withdraw-header-sub">Withdraw your winnings securely to your bank account.</div>
                    </div>
                </div>

                <div class="dh-safe-badge">
                    <div class="dh-safe-shield-icon">
                        <i class="bi bi-shield-check"></i>
                    </div>
                    <div>
                        <div class="dh-safe-title">Safe &amp; Secure</div>
                        <div class="dh-safe-sub">Your data is protected</div>
                    </div>
                </div>
            </div>

            <!-- Amber Warning Alert (If payment account empty) -->
            <?php if($is_pay_empty){ ?>
                <div class="dh-warning-banner">
                    <i class="bi bi-exclamation-triangle-fill dh-warning-icon"></i>
                    <div class="dh-warning-text">
                        Please set up your Payment Account Details in Profile before requesting a withdrawal!
                    </div>
                </div>
            <?php } ?>

            <form class="form-checkout" action="<?php echo $m_url; ?><?php echo $routey;?>" method="post">
                <input type="hidden" name="user_pay_image" value="<?php echo htmlspecialchars($pay_acc_dls['image'] ?? ''); ?>">

                <!-- 1. ACCOUNT HOLDER NAME -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-person"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">ACCOUNT HOLDER NAME <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="text" name="user_ac_holder_name" value="<?php echo htmlspecialchars($pay_acc_dls['account_name'] ?? ''); ?>" readonly class="dh-input-control">
                        </div>
                    </div>
                </div>

                <!-- 2. ACCOUNT NUMBER -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-credit-card-2-front"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">ACCOUNT NUMBER <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="text" name="user_ac_number" value="<?php echo htmlspecialchars($pay_acc_dls['account_no'] ?? ''); ?>" readonly class="dh-input-control">
                        </div>
                    </div>
                </div>

                <!-- 3. BANK NAME -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-bank"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">BANK NAME <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="text" name="user_bank_name" value="<?php echo htmlspecialchars($pay_acc_dls['bank_name'] ?? ''); ?>" readonly class="dh-input-control">
                        </div>
                    </div>
                </div>

                <!-- 4. IFSC CODE -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-grid-3x3-gap-fill"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">IFSC CODE <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="text" name="user_bank_ifsc" value="<?php echo htmlspecialchars($pay_acc_dls['ifsc_code'] ?? ''); ?>" readonly class="dh-input-control">
                        </div>
                    </div>
                </div>

                <!-- 5. UPI ID -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-send-fill"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">UPI ID <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="text" name="user_upi_id" value="<?php echo htmlspecialchars($pay_acc_dls['upi_id'] ?? ''); ?>" placeholder="Enter UPI ID (optional)" readonly class="dh-input-control">
                        </div>
                    </div>
                </div>

                <!-- 6. SELECT BOOK -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-book"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">SELECT BOOK <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <select class="dh-input-control" id="book_id" name="book_id" required <?php if($is_withdraw_disabled){ echo 'disabled'; } ?>>
                                <option value="">Select Book</option>
                                <?php
                                    $qryusrdetls=mysqli_query($conn,"SELECT * FROM `subscription` WHERE stage_status='DONE' and user_id='$user_dls[id]' order by abs(id) desc") or die(mysqli_error());
                                    while($rmusrdetls=mysqli_fetch_array($qryusrdetls)){
                                        $book_id = $rmusrdetls['book_id'];
                                        $qrybook = mysqli_query($conn,"SELECT * FROM `features` WHERE `id` = '$book_id'") or die(mysqli_error());
                                        $rmbook = mysqli_fetch_array($qrybook);
                                ?>
                                <option value="<?php echo $book_id; ?>"><?php echo $rmbook['name']; ?></option>
                                <?php } ?>
                            </select>
                            <i class="bi bi-chevron-down dh-select-chevron"></i>
                        </div>
                    </div>
                </div>

                <!-- 7. WITHDRAW AMOUNT -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-wallet2"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">WITHDRAW AMOUNT <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="text" name="amount" id="amount" placeholder="Enter Amount" oninput="this.value = this.value.replace(/[^0-9]/g, '');" class="dh-input-control" required <?php if($is_withdraw_disabled){ echo 'disabled'; } ?>>
                        </div>
                    </div>
                </div>

                <!-- Submit Withdrawal Button -->
                <button type="submit" name="withdraw_request" class="dh-btn-submit" <?php if($is_withdraw_disabled){ echo 'disabled'; } ?>>
                    <span>Submit Withdrawal</span>
                    <i class="bi bi-arrow-right" style="font-size: 18px;"></i>
                </button>

                <!-- Status Alerts if disabled -->
                <?php if($is_pay_pending){ ?>
                    <div class="alert alert-danger mb-4 text-center" style="border-radius: 14px; font-weight: 600; font-size: 13px; background: rgba(255, 53, 93, 0.15); border: 1px solid #FF355D; color: #FF355D;" role="alert">
                        <i class="bi bi-exclamation-triangle-fill" style="margin-right: 5px;"></i> You cannot request a withdrawal while your payment account detail approval is pending.
                    </div>
                <?php } else if($is_withdraw_exists){ ?>
                    <div class="alert alert-danger mb-4 text-center" style="border-radius: 14px; font-weight: 600; font-size: 13px; background: rgba(255, 53, 93, 0.15); border: 1px solid #FF355D; color: #FF355D;" role="alert">
                        <i class="bi bi-exclamation-triangle-fill" style="margin-right: 5px;"></i> You cannot request a withdrawal because a withdrawal request already exists!
                    </div>
                <?php } ?>

            </form>

            <!-- Bottom Info Banner -->
            <div class="dh-info-banner">
                <div class="dh-info-icon-circle">
                    <i class="bi bi-info-lg"></i>
                </div>
                <div>
                    <div class="dh-info-text-title">Your request will be verified and processed shortly.</div>
                    <div class="dh-info-text-sub">Make sure all details are correct to avoid delays.</div>
                </div>
            </div>

        </div>
    </div>
    <!-- /Recharge -->

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
