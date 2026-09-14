<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: emp-agency-payment-pending');
}
$msg='';

if(ISSET($_POST['edit_emp_agency_payment_pending'])){
    $id = $_POST["id"];
    $agency_id = $_POST["agency_id"];
    $amount = $_POST["amount"];
    $stage_status = !empty($_POST["stage_status"]) ? addslashes($_POST["stage_status"]) : 'EMPLOYEE-DONE';
    $remark = isset($_POST["remark"]) ? addslashes($_POST["remark"]) : '';

    $qry = "UPDATE `pay_to_admin` SET 
        `stage_status` = '".$stage_status."', 
        `read_status` = 'READ',
        `remark` = '".$remark."'
        WHERE `id` = '".$id."'";
    $query = mysqli_query($conn, $qry) or die(mysqli_error($conn));

    if($query){
        if($stage_status == "EMPLOYEE-DONE"){
            $qryupd = mysqli_query($conn,"UPDATE `agency_cash_book` SET `recharge_limit_live` = `recharge_limit_live` + '".$amount."' , `rs_inhand_expected` = `rs_inhand_expected` - '".$amount."' WHERE `agency_id` = '".$agency_id."' ") or die(mysqli_error($conn));
        }
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Agency Payment Request Updated Successfully!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    }
}
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
            <a href="admin_dashboard" class="btn btn_primary btn-sm">Dashboard <i class="bi bi-arrow-right ms-2"></i></a>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Pending Agency Payment</strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Image</th>
                            <th class="text-center" scope="col">Details</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `pay_to_admin` WHERE read_status = 'READ' AND (stage_status = 'ADMIN-PENDING' OR stage_status = 'EMPLOYEE-PENDING' OR stage_status = 'AGENCY-PENDING') ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
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
                                    }
                                    else {
                                        echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                    }
                                ?>
                            </td>
                            <td>
                                Agency : <?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?> <br>
                                Amount : <?php echo $result['amount']; ?> <br>
                                Txn ID : <?php echo $result['transaction_id']; ?>
                            </td>
                            <td> 
                                <button type="button" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id'];?>" style="vertical-align:middle;">
                                    <i class="bi bi-pencil-square"></i> Update
                                </button>

                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Process Agency Payment</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <form action="emp-agency-payment-pending" method="POST">
                                                            <button type="submit" name="modal_close" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                        </form>    
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <form class="row px-2" action="emp-agency-payment-pending" method="post" enctype="multipart/form-data">
                                                    <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                    <input type="hidden" value="<?php echo $result['agency_id']; ?>" name="agency_id"/>
                                                    <input type="hidden" value="<?php echo $result['amount']; ?>" name="amount"/>
                                                    <div class="card-body card-block">
                                                        <div class="row mb-3">
                                                            <label class="col-sm-4 col-form-label">Agency Name</label>
                                                            <div class="col-sm-8 text-start fw-bold">
                                                                <?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?>
                                                            </div>
                                                        </div>
                                                        <div class="row mb-3">
                                                            <label class="col-sm-4 col-form-label">Amount</label>
                                                            <div class="col-sm-8 text-start fw-bold text-success">
                                                                ₹<?php echo $result['amount']; ?>
                                                            </div>
                                                        </div>
                                                        <div class="row mb-3">
                                                            <label class="col-sm-4 col-form-label">Transaction ID</label>
                                                            <div class="col-sm-8 text-start fw-bold">
                                                                <?php echo $result['transaction_id']; ?>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row mb-3">
                                                            <label class="col-sm-4 col-form-label">Update Status</label>
                                                            <div class="col-sm-8">
                                                                <select class="form-select" name="stage_status" required>
                                                                    <option value="EMPLOYEE-PENDING" selected>Pending</option>
                                                                    <option value="EMPLOYEE-DONE">Successful</option>
                                                                    <option value="EMPLOYEE-REJECT">Reject</option>                                                                    
                                                                </select>
                                                            </div>
                                                        </div>
                                                        <div class="row mb-3">
                                                            <label class="col-sm-4 col-form-label">Remark</label>
                                                            <div class="col-sm-8">
                                                                <div class="input-group mb-3">
                                                                    <textarea class="form-control" name="remark" placeholder="Enter remark..."><?php echo $result['remark']; ?></textarea>
                                                                </div>
                                                            </div>
                                                            <div class="col-sm-12 mb-2 d-flex flex-column gap-1">
                                                                <button type="button" class="btn btn-sm btn-outline-success text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Payment received and verified successfully.';">
                                                                    <i class="bi bi-check-circle-fill me-1"></i> Payment received and verified successfully.
                                                                </button>
                                                                <button type="button" class="btn btn-sm btn-outline-warning text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Transaction ID / UTR reference incorrect.';">
                                                                    <i class="bi bi-exclamation-triangle-fill me-1"></i> Transaction ID / UTR reference incorrect.
                                                                </button>
                                                                <button type="button" class="btn btn-sm btn-outline-danger text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Payment verification failed / Rejected.';">
                                                                    <i class="bi bi-x-circle-fill me-1"></i> Payment verification failed / Rejected.
                                                                </button>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="d-flex gap-3 mt-3">
                                                                <button name="edit_emp_agency_payment_pending" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                                                    <i class="bi bi-check-lg me-2"></i> SUBMIT
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
                            </td>
                        </tr>
                    <?php } ?>
                    </tbody>
                </table>
            </div>
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
<?php include 'partials/_footer.php'; ?>
