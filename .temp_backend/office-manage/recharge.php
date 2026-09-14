<?php 
include 'partials/_header.php';

if(isset($_POST['add_recharge'])){
    $user_id = $user_dls['id'];
    $qr_id = $_POST['qr_id'];
    $qryqrdls = mysqli_query($conn, "SELECT * FROM `qrcode` WHERE `id` = '$qr_id'") or die(mysqli_error($conn));
    $rqrdls = mysqli_fetch_array($qryqrdls);
    $bank_id = $rqrdls['bank_id'];
    $qrybndls = mysqli_query($conn, "SELECT * FROM `features` WHERE `id` = '$bank_id'") or die(mysqli_error($conn));
    $rbndls = mysqli_fetch_array($qrybndls);
    $bank_name = $rbndls['name'];
    $bank_slag = $rbndls['slag'];
    $bank_details = $rbndls['detail'];

    $range_id = $_POST['range_id'];
    $amount = $_POST['amount'];
    $stage_status = "AGENCY-PENDING";
    $employee_read_status = "PENDING";
    $agency_read_status = "PENDING";
    $emp_id = $_POST['emp_id'];
    $book_id = $_POST['book_id'];
	$qryprcrange=mysqli_query($conn,"SELECT * FROM `subscription` WHERE `user_id` = '$user_id' AND `book_id` = '$book_id'") or die(mysqli_error($conn));
	$rmprcrange=mysqli_fetch_array($qryprcrange);

    $qrsendr=mysqli_query($conn,"SELECT * FROM `recharge` WHERE `user_id` = '$user_id' AND (`stage_status` = 'AGENCY-PENDING' OR `stage_status` = 'AGENCY-DONE' OR `stage_status` = 'EMPLOYEE-PENDING') ") or die(mysqli_error($conn));
	$rsendr=mysqli_num_rows($qrsendr);
    if($rsendr > 0){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error!";
        $_SESSION['text'] = "1 Recharge Already Processing!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'recharge";</script>';
            exit;
        }
    }

    $subscription_id = $rmprcrange['id'];
    $transection_id = $_POST['transection_id'];

    $img1 = $_FILES["image"]['name'];
    if($_FILES['image']['name']!=''){
        if (($_FILES['image']['size'] > 1048576) || ( $_FILES['image']['type']!='image/png' && $_FILES['image']['type']!='image/jpg' && $_FILES['image']['type']!='image/jpeg' && $_FILES['image']['type']!='image/webp' && $_FILES['image']['type']!='image/avif')){
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error !";
            $_SESSION['text'] = "Select Jpg/png/webp/avif Under 1Mb!";
            if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.'recharge";</script>';
                exit;
            }
        }
        else{
            $img_new1=$date_ts.'_Recharge_Image.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
        }
    }
    else{
        $img_new1= $old_img;
    }

    $qryins = mysqli_query($conn,"INSERT INTO `recharge`(`user_id`, `qr_id`, `range_id`, `amount`, `stage_status`, `emp_id`, `book_id`, `subscription_id`, `transection_id`, `bank_id`, `bank_name`, `bank_slag`, `bank_details`, `image`, `employee_read_status`, `agency_read_status`, `date_ts`) VALUES ('$user_id', '$qr_id', '$range_id', '$amount', '$stage_status', '$emp_id', '$book_id', '$subscription_id', '$transection_id', '$bank_id', '$bank_name', '$bank_slag', '$bank_details', '$img_new1', '$employee_read_status', '$agency_read_status', '$date_ts')") or die(mysqli_error($conn));
    if($qryins){
        $qryupd = mysqli_query($conn,"UPDATE `agency_cash_book` SET `recharge_limit_live` = `recharge_limit_live` - '".$amount."' , `rs_inhand_expected` = `rs_inhand_expected` + '".$amount."' WHERE `agency_id` = '".$emp_id."'") or die(mysqli_error($conn));
        if($qryupd){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull!";
            $_SESSION['text'] = "Recharge Submitted!";
            if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.'recharge";</script>';
                exit;
            }
        } else {
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error!";
            $_SESSION['text'] = "Recharge Not Submitted!";
            if(ISSET($_SESSION['swl_type'])){
                echo '<script language="javascript">location.href="'.$m_url.'recharge";</script>';
                exit;
            }
        }
    }else{
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error!";
        $_SESSION['text'] = "Recharge Not Submitted!";
        if(ISSET($_SESSION['swl_type'])){
            echo '<script language="javascript">location.href="'.$m_url.'recharge";</script>';
            exit;
        }
    }
}
?>

<style>
    /* DreamHub Dark Neon Recharge System (Strict Mockup Match) */
    .recharge-page-wrapper {
        max-width: 680px !important;
        margin: 20px auto 100px auto !important;
        padding: 0 16px !important;
    }

    /* Main Glass Card with Exact Outer Glow & Border Radius */
    .dh-recharge-card {
        background: linear-gradient(180deg, #071B31 0%, #04111F 100%) !important;
        border: 1px solid rgba(23, 200, 255, 0.25) !important;
        border-radius: 28px !important;
        padding: 26px 22px !important;
        box-shadow: 0 0 30px rgba(8, 123, 255, 0.18), 0 12px 40px rgba(0, 0, 0, 0.5) !important;
    }

    /* Top Header Row - Strictly Same Row */
    .dh-recharge-header {
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        margin-bottom: 24px !important;
        flex-wrap: nowrap !important;
        gap: 12px !important;
    }

    .dh-recharge-header-left {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
        overflow: hidden !important;
    }

    .dh-recharge-icon-box {
        width: 48px !important;
        height: 48px !important;
        border-radius: 14px !important;
        background: rgba(8, 123, 255, 0.2) !important;
        border: 1px solid rgba(23, 200, 255, 0.35) !important;
        color: #17C8FF !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 22px !important;
        flex-shrink: 0 !important;
        box-shadow: 0 0 16px rgba(23, 200, 255, 0.2) !important;
    }

    .dh-recharge-title-group h2 {
        font-size: 20px !important;
        font-weight: 700 !important;
        color: #F7FAFF !important;
        margin: 0 !important;
        line-height: 1.2 !important;
        white-space: nowrap !important;
    }

    .dh-recharge-title-group p {
        font-size: 12px !important;
        color: #9FB8D9 !important;
        margin: 3px 0 0 0 !important;
        line-height: 1.2 !important;
    }

    .dh-secure-badge {
        background: rgba(11, 36, 64, 0.8) !important;
        border: 1px solid rgba(23, 200, 255, 0.25) !important;
        border-radius: 14px !important;
        padding: 8px 12px !important;
        display: flex !important;
        align-items: center !important;
        gap: 8px !important;
        flex-shrink: 0 !important;
    }

    .dh-secure-badge i {
        color: #087BFF !important;
        font-size: 20px !important;
    }

    .dh-secure-badge-text {
        display: flex !important;
        flex-direction: column !important;
        font-size: 11px !important;
        font-weight: 600 !important;
        color: #9FB8D9 !important;
        line-height: 1.2 !important;
    }

    /* Field Group Stack */
    .dh-field-group {
        margin-bottom: 20px !important;
    }

    .dh-field-label-top {
        font-size: 11px !important;
        font-weight: 700 !important;
        color: #9FB8D9 !important;
        text-transform: uppercase !important;
        letter-spacing: 0.5px !important;
        margin-bottom: 8px !important;
        display: block !important;
    }

    .dh-asterisk {
        color: #17C8FF !important;
        margin-left: 2px !important;
    }

    /* Exact Input Container Box with Left Icon Divider */
    .dh-input-container {
        position: relative !important;
        display: flex !important;
        align-items: center !important;
        width: 100% !important;
        height: 52px !important;
        background: rgba(11, 36, 64, 0.7) !important;
        border: 1px solid rgba(23, 200, 255, 0.22) !important;
        border-radius: 16px !important;
        overflow: hidden !important;
        transition: all 0.25s ease !important;
    }

    .dh-input-container:focus-within {
        border-color: #17C8FF !important;
        box-shadow: 0 0 16px rgba(23, 200, 255, 0.3) !important;
        background: rgba(13, 45, 80, 0.8) !important;
    }

    .dh-input-icon-box {
        width: 48px !important;
        height: 100% !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        color: #17C8FF !important;
        font-size: 18px !important;
        border-right: 1px solid rgba(255, 255, 255, 0.08) !important;
        flex-shrink: 0 !important;
    }

    .dh-input-element, .dh-select-element {
        flex: 1 !important;
        height: 100% !important;
        background: transparent !important;
        border: none !important;
        outline: none !important;
        color: #F7FAFF !important;
        font-size: 14px !important;
        font-weight: 500 !important;
        padding: 0 14px !important;
        box-shadow: none !important;
        appearance: none !important;
        -webkit-appearance: none !important;
    }

    .dh-select-element option {
        background-color: #071B31 !important;
        color: #F7FAFF !important;
    }

    .dh-input-element::placeholder {
        color: #6E88A8 !important;
        opacity: 0.8 !important;
    }

    .dh-input-right-icon {
        position: absolute !important;
        right: 16px !important;
        color: #17C8FF !important;
        font-size: 14px !important;
        pointer-events: none !important;
    }

    /* Quick Amount Buttons Always Visible inside Amount Input Box */
    .dh-quick-amounts {
        display: flex !important;
        align-items: center !important;
        gap: 4px !important;
        padding-right: 8px !important;
        flex-shrink: 0 !important;
    }

    .dh-quick-btn {
        background: rgba(8, 123, 255, 0.15) !important;
        border: 1px solid rgba(23, 200, 255, 0.25) !important;
        color: #F7FAFF !important;
        border-radius: 999px !important;
        padding: 4px 8px !important;
        font-size: 11px !important;
        font-weight: 600 !important;
        cursor: pointer !important;
        transition: all 0.2s ease !important;
        white-space: nowrap !important;
    }

    .dh-quick-btn:hover {
        border-color: #17C8FF !important;
        color: #17C8FF !important;
        background: rgba(23, 200, 255, 0.25) !important;
    }

    /* Screenshot Upload Dotted Zone */
    .dh-upload-dotted-zone {
        border: 1.5px dashed #135FA8 !important;
        border-radius: 16px !important;
        background: rgba(11, 36, 64, 0.5) !important;
        padding: 16px 20px !important;
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        gap: 16px !important;
        transition: border-color 0.2s ease !important;
    }

    .dh-upload-dotted-zone:hover {
        border-color: #17C8FF !important;
    }

    .dh-upload-left-group {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
    }

    .dh-upload-cloud-icon {
        font-size: 32px !important;
        color: #17C8FF !important;
    }

    .dh-upload-title {
        font-size: 15px !important;
        font-weight: 600 !important;
        color: #F7FAFF !important;
    }

    .dh-upload-sub {
        font-size: 12px !important;
        color: #6E88A8 !important;
        margin-top: 2px !important;
    }

    .dh-upload-btn-gradient {
        background: linear-gradient(90deg, #17C8FF 0%, #087BFF 100%) !important;
        color: #FFFFFF !important;
        border: none !important;
        border-radius: 12px !important;
        padding: 10px 20px !important;
        font-size: 13px !important;
        font-weight: 600 !important;
        display: flex !important;
        align-items: center !important;
        gap: 8px !important;
        cursor: pointer !important;
        box-shadow: 0 4px 15px rgba(8, 123, 255, 0.3) !important;
        transition: transform 0.2s ease !important;
        white-space: nowrap !important;
    }

    .dh-upload-btn-gradient:hover {
        transform: translateY(-1px) !important;
        box-shadow: 0 6px 20px rgba(8, 123, 255, 0.5) !important;
    }

    /* Info Verification Alert Box */
    .dh-info-alert-box {
        background: rgba(8, 123, 255, 0.08) !important;
        border: 1px solid rgba(8, 123, 255, 0.25) !important;
        border-radius: 14px !important;
        padding: 12px 16px !important;
        display: flex !important;
        align-items: center !important;
        gap: 12px !important;
        margin-bottom: 24px !important;
    }

    .dh-info-alert-icon {
        color: #17C8FF !important;
        font-size: 22px !important;
        flex-shrink: 0 !important;
    }

    .dh-info-alert-title {
        font-size: 13px !important;
        font-weight: 600 !important;
        color: #F7FAFF !important;
        line-height: 1.3 !important;
    }

    .dh-info-alert-sub {
        font-size: 12px !important;
        color: #9FB8D9 !important;
        line-height: 1.3 !important;
        margin-top: 2px !important;
    }

    /* Primary Recharge Button */
    .dh-btn-recharge-now {
        width: 100% !important;
        height: 54px !important;
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
    }

    .dh-btn-recharge-now:hover {
        transform: translateY(-2px) !important;
        box-shadow: 0 14px 35px rgba(23, 200, 255, 0.5) !important;
        filter: brightness(1.08) !important;
    }
</style>

<div class="recharge-page-wrapper">
    <div class="dh-recharge-card">
        
        <!-- Header - Strictly Same Row -->
        <div class="dh-recharge-header">
            <div class="dh-recharge-header-left">
                <div class="dh-recharge-icon-box">
                    <i class="bi bi-lightning-charge-fill"></i>
                </div>
                <div class="dh-recharge-title-group">
                    <h2>Recharge Now</h2>
                    <p>Add balance to your account and enjoy uninterrupted gaming.</p>
                </div>
            </div>
            
            <div class="dh-secure-badge">
                <i class="bi bi-shield-check"></i>
                <div class="dh-secure-badge-text">
                    <span>Secure</span>
                    <span>Payments</span>
                </div>
            </div>
        </div>

        <form action="<?php echo $m_url; ?><?php echo $routey;?>" method="post" enctype="multipart/form-data">
            
            <!-- 1. Select Book Field -->
            <div class="dh-field-group">
                <label class="dh-field-label-top">SELECT BOOK <span class="dh-asterisk">*</span></label>
                <div class="dh-input-container">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-book"></i>
                    </div>
                    <select class="dh-select-element" id="book_id" name="book_id" required>
                        <option value="">Select Book</option>
                        <?php
                            $qryusrdetls=mysqli_query($conn,"SELECT * FROM `subscription` WHERE stage_status='DONE' and user_id='$user_dls[id]' order by abs(id) desc") or die(mysqli_error($conn));
                            while($rmusrdetls=mysqli_fetch_array($qryusrdetls)){
                                $book_id = $rmusrdetls['book_id'];
                                $qrybook = mysqli_query($conn,"SELECT * FROM `features` WHERE `id` = '$book_id'") or die(mysqli_error($conn));
                                $rmbook = mysqli_fetch_array($qrybook);
                        ?>
                        <option value="<?php echo $book_id; ?>"><?php echo htmlspecialchars($rmbook['name']); ?></option>
                        <?php } ?>
                    </select>
                    <i class="bi bi-chevron-down dh-input-right-icon"></i>
                </div>
            </div>

            <!-- 2. Recharge Amount Field -->
            <div class="dh-field-group">
                <label class="dh-field-label-top">RECHARGE AMOUNT <span class="dh-asterisk">*</span></label>
                <div class="dh-input-container">
                    <div class="dh-input-icon-box" style="font-weight: 700;">₹</div>
                    <input type="text" name="amount" id="price_amount_id" onkeyup="show_qr_code(this.value);" placeholder="Enter Amount" oninput="this.value = this.value.replace(/[^0-9]/g, '');" class="dh-input-element" required>
                    
                    <div class="dh-quick-amounts">
                        <span class="dh-quick-btn" onclick="addQuickAmount(100)">+100</span>
                        <span class="dh-quick-btn" onclick="addQuickAmount(500)">+500</span>
                        <span class="dh-quick-btn" onclick="addQuickAmount(1000)">+1,000</span>
                        <span class="dh-quick-btn" onclick="addQuickAmount(5000)">+5,000</span>
                    </div>
                </div>
            </div>

            <!-- QR Code Render Box (AJAX output) -->
            <div class="mb-3 text-center" id="qr_code_box"></div>

            <!-- 3. Transaction ID Field -->
            <div class="dh-field-group">
                <label class="dh-field-label-top">TRANSACTION ID <span class="dh-asterisk">*</span></label>
                <div class="dh-input-container">
                    <div class="dh-input-icon-box">
                        <i class="bi bi-card-text"></i>
                    </div>
                    <input type="text" name="transection_id" id="transection_id" placeholder="Enter Transaction ID" oninput="this.value = this.value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();" class="dh-input-element" required>
                </div>
            </div>

            <!-- 4. Upload Screenshot Field -->
            <div class="dh-field-group">
                <label class="dh-field-label-top">UPLOAD SCREENSHOT <span class="dh-asterisk">*</span></label>
                <div class="dh-upload-dotted-zone">
                    <div class="dh-upload-left-group">
                        <i class="bi bi-cloud-arrow-up dh-upload-cloud-icon"></i>
                        <div>
                            <div class="dh-upload-title" id="rechargeFileName">Choose Screenshot File</div>
                            <div class="dh-upload-sub">JPG, PNG or PDF (Max 5MB)</div>
                        </div>
                    </div>
                    <button type="button" class="dh-upload-btn-gradient" onclick="document.getElementById('image').click();">
                        <i class="bi bi-upload"></i>
                        <span>Choose File</span>
                    </button>
                    <input type="file" name="image" id="image" required accept="image/*" style="display: none;" onchange="
                        const fileName = this.files[0] ? this.files[0].name : 'Choose Screenshot File';
                        document.getElementById('rechargeFileName').innerText = fileName;
                        if(this.files[0]) {
                            const reader = new FileReader();
                            reader.onload = function(e) {
                                document.getElementById('image_preview').src = e.target.result;
                                document.getElementById('image_preview_box').style.display = 'block';
                            }
                            reader.readAsDataURL(this.files[0]);
                        } else {
                            document.getElementById('image_preview_box').style.display = 'none';
                        }
                    ">
                </div>
                <div class="mt-2 text-end" id="image_preview_box" style="display: none;">
                    <img src="<?php echo $m_url; ?>assets/images/logo/no-image.jpg" id="image_preview" style="height: 80px; width: auto; border-radius: 10px; border: 1px solid #1A3F66;">
                </div>
            </div>

            <!-- Info Verification Alert Box -->
            <div class="dh-info-alert-box">
                <i class="bi bi-info-circle-fill dh-info-alert-icon"></i>
                <div>
                    <div class="dh-info-alert-title">Please make sure the details are correct before submitting.</div>
                    <div class="dh-info-alert-sub">Your recharge will be verified shortly.</div>
                </div>
            </div>

            <!-- Primary Submit Button -->
            <button type="submit" name="add_recharge" class="dh-btn-recharge-now">
                <span>Recharge Now</span>
                <i class="bi bi-arrow-right" style="font-size: 18px;"></i>
            </button>
        </form>
    </div>
</div>

<script>
    function show_qr_code(price_amount_id) {
        $.ajax({
            url: "<?php echo $m_url; ?>ajax.php",
            type: "POST",
            data: {
                price_amount_id: price_amount_id
            },
            success: function(data) {
                $("#qr_code_box").html(data);
            }
        });
    }

    function addQuickAmount(val) {
        const input = document.getElementById('price_amount_id');
        if (input) {
            let currentVal = parseInt(input.value) || 0;
            let newVal = currentVal + val;
            input.value = newVal;
            show_qr_code(newVal);
        }
    }
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
