<?php 
include 'partials/_header.php';

$msg='';
if(ISSET($_POST['mem_upd_pass'])){
    $old_pass = $_POST["old_pass"];
    
    $new_pass = $_POST["new_pass"];
    $old_pass_give = $_POST["old_pass_give"];
  
    $id = $_POST["id"];
  
    if($old_pass == $old_pass_give){
      $qry= mysqli_query($conn, "UPDATE `users` set `password` = '".$new_pass."' WHERE `id` = '".$id."' ") or die(mysqli_error());    
      if($qry){
          $_SESSION['swl_type'] = "success";
          $_SESSION['head'] = "Successfull!";
          $_SESSION['text'] = "Old Password Changed!";
              if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.''.$routey.'";</script>';
                exit;
              }
          }
    }
    else{
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error Occurred !";
        $_SESSION['text'] = "Old Password Did not Match!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.''.$routey.'";</script>';
            exit;
        }  
    }  
}
?>

    <style>
        /* DreamHub Dark Neon Password Update Page (1:1 UI Kit Match) */
        .update-pass-wrapper {
            max-width: 680px !important;
            margin: 20px auto 40px auto !important;
            padding: 0 16px !important;
        }

        /* Glassmorphism Outer Card Container */
        .dh-pass-card {
            background: linear-gradient(180deg, #071B31 0%, #04111F 100%) !important;
            border: 1px solid #135FA8 !important;
            border-radius: 28px !important;
            padding: 28px 24px !important;
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4), 0 0 24px rgba(23, 200, 255, 0.12) !important;
            position: relative !important;
        }

        /* Card Top Header Section */
        .dh-pass-header {
            display: flex !important;
            align-items: center !important;
            justify-content: space-between !important;
            flex-wrap: nowrap !important;
            gap: 16px !important;
            margin-bottom: 24px !important;
        }

        .dh-pass-header-left {
            display: flex !important;
            align-items: center !important;
            gap: 14px !important;
        }

        .dh-pass-header-icon {
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

        .dh-pass-header-title {
            font-size: 22px !important;
            font-weight: 700 !important;
            color: #F7FAFF !important;
            line-height: 1.2 !important;
            margin: 0 !important;
        }

        .dh-pass-header-sub {
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

        /* Form Input Field Rows (Mockup 1:1 Layout) */
        .dh-input-row {
            display: flex !important;
            align-items: flex-end !important;
            gap: 14px !important;
            margin-bottom: 18px !important;
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
            padding: 0 42px 0 16px !important;
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

        .dh-eye-toggle-btn {
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

        .dh-eye-toggle-btn:hover {
            color: #17C8FF !important;
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
            .dh-pass-header {
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

    <!-- Update Password Section -->
    <div class="update-pass-wrapper">
        <div class="dh-pass-card">
            
            <!-- Card Header Section -->
            <div class="dh-pass-header">
                <div class="dh-pass-header-left">
                    <div class="dh-pass-header-icon">
                        <i class="bi bi-shield-lock-fill"></i>
                    </div>
                    <div>
                        <h3 class="dh-pass-header-title">Update Your Password</h3>
                        <div class="dh-pass-header-sub">Ensure your account security by updating your password.</div>
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

            <form class="profile-form" action="<?php echo $m_url; ?><?php echo $routey;?>" onsubmit="return verifyPassword()" method="post">
                <input type="hidden" name="old_pass" value="<?php echo htmlspecialchars($user_dls["password"] ?? ''); ?>">
                <input type="hidden" name="id" value="<?php echo htmlspecialchars($user_dls["id"] ?? ''); ?>">

                <!-- 1. OLD PASSWORD -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-lock-fill"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">OLD PASSWORD <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="password" id="old_pass_give" name="old_pass_give" class="dh-input-control" placeholder="Enter Old Password" required>
                            <i class="bi bi-eye-slash dh-eye-toggle-btn" onclick="togglePassVisibility('old_pass_give', this)"></i>
                        </div>
                    </div>
                </div>

                <!-- 2. NEW PASSWORD -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-key-fill"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">NEW PASSWORD <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="password" id="pass" class="dh-input-control" placeholder="Enter New Password" required>
                            <i class="bi bi-eye-slash dh-eye-toggle-btn" onclick="togglePassVisibility('pass', this)"></i>
                        </div>
                    </div>
                </div>

                <!-- 3. CONFIRM PASSWORD -->
                <div class="dh-input-row">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-shield-check"></i>
                    </div>
                    <div class="dh-input-field-wrap">
                        <label class="dh-input-label">CONFIRM PASSWORD <span class="dh-asterisk">*</span></label>
                        <div class="dh-input-control-wrap">
                            <input type="password" id="confirmpass" name="new_pass" class="dh-input-control" placeholder="Confirm New Password" required>
                            <i class="bi bi-eye-slash dh-eye-toggle-btn" onclick="togglePassVisibility('confirmpass', this)"></i>
                        </div>
                    </div>
                </div>

                <!-- Submit Button -->
                <button type="submit" name="mem_upd_pass" class="dh-btn-submit">
                    <i class="bi bi-check-circle-fill" style="font-size: 18px;"></i>
                    <span>Save Changes</span>
                </button>
            </form>

            <!-- Bottom Info Banner -->
            <div class="dh-info-banner">
                <div class="dh-info-icon-circle">
                    <i class="bi bi-info-lg"></i>
                </div>
                <div>
                    <div class="dh-info-text-title">Password Security Reminder</div>
                    <div class="dh-info-text-sub">Use a strong password with letters, numbers, and special characters for safety.</div>
                </div>
            </div>

        </div>
    </div>
    <!-- /Update Password Section -->

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

<script>
    function togglePassVisibility(inputId, iconEl) {
        const input = document.getElementById(inputId);
        if (input) {
            if (input.type === 'password') {
                input.type = 'text';
                iconEl.classList.remove('bi-eye-slash');
                iconEl.classList.add('bi-eye');
            } else {
                input.type = 'password';
                iconEl.classList.remove('bi-eye');
                iconEl.classList.add('bi-eye-slash');
            }
        }
    }

    function verifyPassword() {
        var password = document.getElementById("pass").value;
        var confirmPassword = document.getElementById("confirmpass").value;
        
        if (password == "") {
            swal({
                title: "Error!",
                text: "The password field is empty.",
                icon: "error",
                button: "Ok Done!",
                showConfirmButton: false,
                timer: 5000
            });
            return false;
        }
        else if (password == confirmPassword) {
            return true;
        } else {
            swal({
                title: "Error!",
                text: "Please make sure your passwords match.",
                icon: "error",
                button: "Ok Done!",
                showConfirmButton: false,
                timer: 5000
            });
            return false;
        }
    }
</script>
<?php include 'partials/_footer.php'; ?>
