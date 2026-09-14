<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: pending-recharge');
}
$msg='';
if(ISSET($_POST['edit_recharge'])){
    $id = $_POST["id"];
    $agency_id = $_POST['emp_id'];
    $amount = $_POST["amount"];
    if(EMPTY($_POST["stage_status"])){
        $stage_status = "AGENCY-PENDING";
    }else{
        $stage_status = addslashes($_POST["stage_status"]);
    }
    $read_status = "READ";
    $remark = addslashes($_POST["remark"]);
    $transection_id = addslashes($_POST["transection_id"]);

    $qry = "UPDATE `recharge` set `stage_status` = '".$stage_status."', `agency_read_status` = '".$read_status."', `transection_id` = '".$transection_id."', `remark` = '".$remark."' WHERE `id` = '".$id."'" or die(mysqli_error());
    $query = mysqli_query($conn,$qry);
    
    if($query){   
        if($stage_status == 'AGENCY-REJECT'){
            $qry1 = "UPDATE `agency_cash_book` set `recharge_limit_live` = `recharge_limit_live` + '".$amount."' , `rs_inhand_expected` = `rs_inhand_expected` - '".$amount."' WHERE `agency_id` = '".$agency_id."'" or die(mysqli_error());
            $query1 = mysqli_query($conn,$qry1);
        }
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Recharge Update Successfully!";
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

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>User Recharge</strong> Pending List</h5>
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
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `recharge` WHERE emp_id = '$emp_id' AND agency_read_status = 'READ' AND (stage_status = 'AGENCY-PENDING' OR stage_status = 'AGENCY-DONE' OR stage_status = 'EMPLOYEE-PENDING') ORDER BY ABS(id) DESC") or die(mysqli_error());
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[user_id]' ") or die(mysqli_error());
                            $resusr = mysqli_fetch_array($qryusr);
                            $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$result[book_id]' ") or die(mysqli_error());
                            $resbook = mysqli_fetch_array($qrybook);
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
                            <td>Amount : <?php echo $result['amount']; ?> <br> Transaction ID : <?php echo $result['transection_id']; ?>
                                <?php if($result['stage_status'] == "EMPLOYEE-PENDING" || $result['stage_status'] == "AGENCY-DONE"){?>
                                    <br><span class="text-danger"><b>Authority Not Verified Yet.</b></span>
                                <?php } ?>
                            </td>
                            <td>
                                <button type="button" id="quet_id" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;" ><i class="bi bi-eye"></i>
                                </button>
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Check Recharge Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <form action="pending-recharge" method="POST">
                                                            <button type="submit" name="modal_close" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                        </form>    
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <div class="container-fluid mt-4">
                                                        <div class="row">
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Player Name :  <p class="fw-500"><i><?php echo $resusr['name']; ?></i></p>
                                                                <hr>
                                                                Book Name :  <p class="fw-500"><i><?php echo $resbook['name']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Date :  <p class="fw-500"><i><?php echo date('d M Y, h:i A', $result['date_ts']); ?></i></p>
                                                                <hr>
                                                                Email :  <p class="fw-500"><i><?php echo $resusr['email']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Amount :  <p class="fw-500"><i><?php echo $result['amount']; ?></i></p>
                                                                <hr>
                                                                Transaction ID :  <p class="fw-500"><i><?php echo $result['transection_id']; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <?php if($result['stage_status'] == "AGENCY-PENDING"){?>
                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="Verify"><i class="bi bi-check"></i></button>
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-md">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Verify Recharge</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="pending-recharge" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $result['emp_id']; ?>" name="emp_id"/>
                                                        <input type="hidden" value="<?php echo $result['amount']; ?>" name="amount"/>
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Choose Status </label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <select class="form-select" name="stage_status">
                                                                            <option value="">Select Status</option>
                                                                            <option value="AGENCY-DONE">Successfull</option>
                                                                            <option value="AGENCY-REJECT">Rejected</option>
                                                                        </select>    
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Transaction ID </label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <input type="text" class="form-control" name="transection_id" value="<?php echo $result['transection_id'];?>"  required >    
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Remark </label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <textarea class="form-control" name="remark" required><?php echo $result['remark'];?></textarea>    
                                                                    </div>
                                                                </div>
                                                                <div class="col-sm-12 mb-2 d-flex flex-column gap-1">
                                                                    <button type="button" class="btn btn-sm btn-outline-success text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Payment verified and recharge approved successfully.';">
                                                                        <i class="bi bi-check-circle-fill me-1"></i> Payment verified and recharge approved successfully.
                                                                    </button>
                                                                    <button type="button" class="btn btn-sm btn-outline-warning text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Transaction ID / UTR number does not match.';">
                                                                        <i class="bi bi-exclamation-triangle-fill me-1"></i> Transaction ID / UTR number does not match.
                                                                    </button>
                                                                    <button type="button" class="btn btn-sm btn-outline-danger text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Payment not received in the bank account.';">
                                                                        <i class="bi bi-x-circle-fill me-1"></i> Payment not received in the bank account.
                                                                    </button>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_recharge" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                                                    <i class="bi bi-check-lg me-2"></i> UPDATE
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
                                <?php } ?>
                            </td>
                        </tr>
                    <?php  }  ?>
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