<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

$msg = '';

if(ISSET($_POST['add_pay_to_admin'])){
    $agency_id = $_SESSION['u_id'];
    $amount = isset($_POST['amount']) ? addslashes($_POST['amount']) : '0';
    $transaction_id = isset($_POST['transaction_id']) ? addslashes($_POST['transaction_id']) : '';
    $bank_id = isset($_POST['bank_id']) ? $_POST['bank_id'] : '';
    $remark = isset($_POST['remark']) ? addslashes($_POST['remark']) : '';
    $admin_bank_id = $_POST['admin_bank_id'];

    $stage_status = "ADMIN-PENDING";
    $read_status = "PENDING";

    $bank_name = "";
    $bank_slag = "";
    if(!empty($bank_id)){
        $qrybk = mysqli_query($conn, "SELECT * FROM `features` WHERE `id` = '$bank_id'");
        if($resbk = mysqli_fetch_array($qrybk)){
            $bank_name = addslashes($resbk['name']);
            $bank_slag = addslashes($resbk['slag']);
        }
    }

    $admin_bank_name = "";
    $admin_bank_slag = "";
    if(!empty($admin_bank_id)){
        $qrybka = mysqli_query($conn, "SELECT * FROM `features` WHERE `id` = '$admin_bank_id'");
        if($resbka = mysqli_fetch_array($qrybka)){
            $admin_bank_name = addslashes($resbka['name']);
            $admin_bank_slag = addslashes($resbka['slag']);
        }
    }

    $img_new1 = "";
    if(!empty($_FILES['image']['name'])){
        $img1 = $_FILES['image']['name'];
        $img_new1 = $date_ts . '_PayToAdmin_Image.' . pathinfo($img1, PATHINFO_EXTENSION);
        move_uploaded_file($_FILES['image']['tmp_name'], ADD_PHOTO_SERVER_PATH . $img_new1);
    }

    $qryins = mysqli_query($conn, "INSERT INTO `pay_to_admin` (
        `agency_id`, `amount`, `transaction_id`, `bank_id`, `bank_name`, `bank_slag`, `image`, `remark`, `admin_bank_id`, `admin_bank_name`, `admin_bank_slag`, `stage_status`, `read_status`, `date_ts`
    ) VALUES (
        '$agency_id', '$amount', '$transaction_id', '$bank_id', '$bank_name', '$bank_slag', '$img_new1', '$remark', '$admin_bank_id', '$admin_bank_name', '$admin_bank_slag', '$stage_status', '$read_status', '$date_ts'
    )") or die(mysqli_error($conn));

    if($qryins){
        //$qryupd = mysqli_query($conn,"UPDATE `agency_cash_book` SET `recharge_limit_live` = `recharge_limit_live` + '".$amount."' , `rs_inhand_expected` = `rs_inhand_expected` - '".$amount."' WHERE `agency_id` = '".$agency_id."' ") or die(mysqli_error($conn));
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Payment Submitted to Admin Successfully!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    }
}

// Fetch agency live cash info
$qry_cash = mysqli_query($conn, "SELECT * FROM `agency_cash_book` WHERE `agency_id` = '".$_SESSION['u_id']."'");
$res_cash = mysqli_fetch_array($qry_cash);
$rs_inhand_expected = isset($res_cash['rs_inhand_expected']) ? $res_cash['rs_inhand_expected'] : 0;
$recharge_limit_live = isset($res_cash['recharge_limit_live']) ? $res_cash['recharge_limit_live'] : 0;

?>
<?php include 'partials/_admin_header.php' ?>
<?php include 'partials/_admin_sidenav.php' ?>

<div class="content mb-4">
    
    <div class="brdcmp px-4 pt-4">
        <div class="d-flex justify-content-between align-items-center pb-4 mb-3">
            <div class="row">
                <p>
                    <h5 class="mb-0"><?php echo $brdcmp; ?></h5><br>
                    <span>Home / <?php echo $brdcmp; ?></span>
                </p>
            </div>
            <button data-bs-toggle="modal" data-bs-target="#payModal" class="btn btn_primary btn-sm">Pay to Admin <i class="bi bi-arrow-right ms-2"></i></button>
        </div>
    </div>

    <!-- Modal for Pay to Admin -->
    <div class="modal fade mt-4 pt-4" id="payModal" tabindex="-1" data-bs-keyboard="false" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-scrollable modal-lg">
            <div class="modal-content" style="overflow: visible!important;">
                <div class="modal-header shadow bg-funky-moon2 mx-auto">
                    <div class="row mb-1">
                        <div class="col-8 text-left">
                            <h5 class="modal-title text-white ml-1"><b>Send Money to Admin</b></h5>
                        </div>
                        <div class="col-4 text-right">
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                    </div>  
                </div>
                <div class="modal-body">
                    <div class="container-fluid text-dark">
                        <div class="row mx-4 my-3 d-flex align-items-center justify-content-center">
                            <div class="col-md-4 col-lg-3 mb-3 mb-md-0">
                                <?php 
                                    $qryadminqr = mysqli_query($conn,"SELECT * FROM `features` WHERE `type` = 'BANK' AND `show_status` = 'ACTIVE' AND `admin_payment_receive` = 'ADMIN-RECEIVABLE' AND `order_no` = '1'") or die(mysqli_error($conn));
                                    $ragencybank = mysqli_fetch_array($qryadminqr);
                                    $adminbank_id = $ragencybank['id'];
                                    $qryadmqr = mysqli_query($conn,"SELECT * FROM `qrcode` WHERE `emp_id` = '1' AND `bank_id` = '$adminbank_id' AND `show_status` = 'ACTIVE' LIMIT 1") or die(mysqli_error($conn));
                                    if(mysqli_num_rows($qryadmqr) < 1){
                                        $qryadmqr = mysqli_query($conn,"SELECT * FROM `qrcode` WHERE `emp_id` = '1' AND `bank_id` = '$adminbank_id' LIMIT 1") or die(mysqli_error($conn));
                                    }
                                    $radmqr = mysqli_fetch_array($qryadmqr);
                                ?>
                                <?php
                                    if(!empty($radmqr['image'])){
                                        echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$radmqr['image']."'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$radmqr['image']."' /></a>";
                                    } else {
                                        echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                    }
                                ?>
                            </div>
                            <div class="col-md-4 col-lg-5 mb-3 mb-md-0">
                                <div class="card border-0 shadow-sm gradient-15 text-white p-3 rounded">
                                    <div class="d-flex align-items-center justify-content-center">
                                        <div>
                                            <h6 class="mb-0 text-white">Cash In-Hand : Rs. <?php echo $rs_inhand_expected; ?></h6>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 col-lg-4 mb-3 mb-md-0">
                                <div class="card border-0 shadow-sm bg-primary text-white p-3 rounded">
                                    <div class="d-flex align-items-center justify-content-center">
                                        <div>
                                            <h6 class="mb-0 text-white">Collact Limit : Rs. <?php echo $recharge_limit_live; ?></h6>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <form class="row px-2" action="pay-to-admin" method="post" enctype="multipart/form-data">
                            <input type="hidden" name="admin_bank_id" value="<?php echo $adminbank_id;?>">
                            <div class="card-body card-block">
                                <div class="row mb-1">
                                    <label class="col-sm-4 col-form-label">Select Bank Account</label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <select class="form-select" name="bank_id" required>
                                                <option value="">Select Bank Account</option>
                                                <?php
                                                    $qryagencybanks = mysqli_query($conn, "SELECT * FROM `features` WHERE order_no = '$app_u_id' AND `type` = 'BANK' AND `show_status` = 'ACTIVE'") or die(mysqli_error($conn));
                                                    while($ragencybank = mysqli_fetch_array($qryagencybanks)){
                                                ?>
                                                <option value="<?php echo $ragencybank['id']; ?>"><?php echo $ragencybank['name']; ?></option>
                                                <?php } ?>
                                            </select>
                                        </div>
                                    </div>
                                </div>

                                <div class="row mb-1">
                                    <label class="col-sm-4 col-form-label">Amount </label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text">Rs.</span>
                                            <input type="number" step="any" min="1" max="<?php echo $rs_inhand_expected; ?>" class="form-control" name="amount" placeholder="Enter Amount" required>
                                        </div>
                                    </div>
                                </div>

                                <div class="row mb-1">
                                    <label class="col-sm-4 col-form-label">Transaction ID </label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <input type="text" class="form-control" name="transaction_id" placeholder="Enter Transaction ID" required>
                                        </div>
                                    </div>
                                </div>

                                <div class="row mb-1">
                                    <label class="col-sm-4 col-form-label">Payment Screenshot </label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <input type="file" class="form-control" name="image" accept="image/*" required>
                                        </div>
                                    </div>
                                </div>

                                <div class="row mb-1">
                                    <label class="col-sm-4 col-form-label">Remark </label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <textarea class="form-control" name="remark" placeholder="Enter Remark" required></textarea>    
                                        </div>
                                    </div>
                                </div>
                                <hr class="md-100">
                                <div class="row">
                                    <div class="d-flex gap-3 mt-1">
                                        <button name="add_pay_to_admin" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                            <i class="bi bi-send me-2"></i> SUBMIT PAYMENT
                                        </button>
                                        <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect">
                                            <i class="bi bi-x-lg me-2"></i> RESET
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Payment Records Table Card -->
    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Pay To Admin</strong> Payment Records</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Screenshot</th>
                            <th class="text-center" scope="col">Agency</th>
                            <th class="text-center" scope="col">Transaction</th>
                            <th class="text-center" scope="col">Date</th>
                            <th class="text-center" scope="col">Status</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        if($_SESSION['u_type'] == 'AGENCY'){
                            $qrydisplay = mysqli_query($conn, "SELECT * FROM `pay_to_admin` WHERE agency_id = '".$_SESSION['u_id']."' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        } else {
                            $qrydisplay = mysqli_query($conn, "SELECT * FROM `pay_to_admin` ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        }
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryagency = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[agency_id]' ") or die(mysqli_error($conn));
                            $resagency = mysqli_fetch_array($qryagency);
                    ?>
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                <?php
                                    if(!empty($result['image'])){
                                        echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' /></a>";
                                    } else {
                                        echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                    }
                                ?>
                            </td>
                            <td>
                                <?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?>
                                <br>
                                <?php echo !empty($result['bank_name']) ? $result['bank_name'] : 'N/A'; ?>
                            </td>
                            <td>
                                <?php echo !empty($result['transaction_id']) ? $result['transaction_id'] : 'N/A'; ?>
                                <br>
                                <b>Rs. <?php echo $result['amount']; ?></b>
                            </td>
                            <td><?php echo is_numeric($result['date_ts']) ? date('m/d/Y H:i:s a', (int)$result['date_ts']) : $result['date_ts']; ?></td>
                            <td>
                                <?php
                                    $status = $result['stage_status'];
                                    if($status == 'ADMIN-PENDING'){
                                        echo '<span class="badge bg-warning text-dark px-3 py-2"><i class="bi bi-hourglass-split me-1"></i> Admin Pending</span>';
                                    } elseif($status == 'ADMIN-DONE' || $status == 'DONE' || $status == 'SUCCESS'){
                                        echo '<span class="badge bg-success px-3 py-2"><i class="bi bi-check-circle me-1"></i> Approved</span>';
                                    } elseif($status == 'ADMIN-REJECT' || $status == 'REJECT'){
                                        echo '<span class="badge bg-danger px-3 py-2"><i class="bi bi-x-circle me-1"></i> Rejected</span>';
                                    } else {
                                        echo '<span class="badge bg-secondary px-3 py-2">'.$status.'</span>';
                                    }
                                ?>
                            </td>
                            <td>
                                <!-- View Details Button -->
                                <button type="button" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;">
                                    <i class="bi bi-eye"></i>
                                </button>
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Payment Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body text-start">
                                                <div class="container-fluid text-dark">
                                                    <div class="row my-3">
                                                        <div class="col-md-4 border border-primary shadow py-2 text-center rounded">
                                                            Agency Name : <p class="fw-500 mb-1"><i><?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?></i></p>
                                                            <hr class="my-1">
                                                            Amount : <p class="fw-500 mb-0"><i>Rs. <?php echo $result['amount']; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 border border-primary shadow py-2 text-center rounded">
                                                            Bank Name : <p class="fw-500 mb-1"><i><?php echo !empty($result['bank_name']) ? $result['bank_name'] : 'N/A'; ?></i></p>
                                                            <hr class="my-1">
                                                            Date : <p class="fw-500 mb-0"><i><?php echo is_numeric($result['date_ts']) ? date('m/d/Y H:i:s a', (int)$result['date_ts']) : $result['date_ts']; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 border border-primary shadow py-2 text-center rounded">
                                                            Transaction ID : <p class="fw-500 mb-0"><i><?php echo !empty($result['transaction_id']) ? $result['transaction_id'] : 'N/A'; ?></i></p>
                                                            <hr class="my-1">
                                                            Status : <p class="fw-500 mb-0"><i><?php echo $result['stage_status']; ?></i></p>
                                                        </div>
                                                    </div>
                                                    <div class="row mb-3">
                                                        <div class="col-md-6 border border-secondary shadow py-2 rounded text-wrap">
                                                            Remark : <p class="fw-500 mb-0"><i><?php echo !empty($result['remark']) ? nl2br($result['remark']) : 'N/A'; ?></i></p>
                                                        </div>
                                                        <?php if(!empty($result['image'])){ ?>
                                                        <div class="col-md-6 text-center border border-secondary shadow py-2 rounded">
                                                            Payment Screenshot : <br>
                                                            <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>">
                                                                <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>" class="img-thumbnail shadow mt-1" style="max-height: 150px;" />
                                                            </a>
                                                        </div>
                                                        <?php } ?>
                                                    </div>                                                    
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </td>
                        </tr>
                    <?php } ?>
                    </tbody>
                </table>
            </div>
            <!-- End Table with stripped rows -->
        </div>
    </div>
    
</div>

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
			});
		});
	</script>
<?php
    unset($_SESSION['head']);
    unset($_SESSION['text']);
    unset($_SESSION['swl_type']);
}
?>
<?php include 'partials/_footer.php' ?>
