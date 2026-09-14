<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: agency-withdraw-pending');
}
$msg='';
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
            <h5 class="card-title text-white my-1"><strong>Agency Withdrawal</strong> Request List</h5>
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
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE agency_id = '$emp_id' AND stage_status = 'EMPLOYEE-PASS' AND agency_read_status = 'PENDING' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[user_id]' ") or die(mysqli_error($conn));
                            $resusr = mysqli_fetch_array($qryusr);
                            $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$result[book_id]' ") or die(mysqli_error($conn));
                            $resbook = mysqli_fetch_array($qrybook);
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
                                User : <?php echo isset($resusr['name']) ? $resusr['name'] : 'N/A'; ?> <br>
                                Amount : <?php echo $result['amount']; ?>
                            </td>
                            <td> 
                                <button type="button" onclick="upd_agency_withdraw_status('<?php echo $result['id']; ?>')" id="quet_id_<?php echo $result['id']; ?>" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;">
                                    <i class="bi <?php echo ($result['agency_read_status'] == 'READ') ? 'bi-eye' : 'bi-eye-slash'; ?>"></i>
                                </button>
                                <script>
                                    function upd_agency_withdraw_status(qte_id){
                                        jQuery.ajax({
                                            url: 'ajax_del.php',
                                            type:'post',
                                            data: {
                                                "agency_withdraw_req_upd_status": 1,
                                                "qte_id": qte_id,
                                            },
                                            success:function(result){
                                                jQuery('#quet_id_'+qte_id).html(result);
                                            }
                                        });
                                    }
                                </script>
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Check Withdrawal Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <form action="agency-withdraw-req" method="POST">
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
                                                                Agency : <p class="fw-500"><i><?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?></i></p>
                                                                <hr>
                                                                Book Name : <p class="fw-500"><i><?php echo isset($resbook['name']) ? $resbook['name'] : 'N/A'; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                User Name : <p class="fw-500"><i><?php echo isset($resusr['name']) ? $resusr['name'] : 'N/A'; ?></i></p>
                                                                <hr>
                                                                User Email : <p class="fw-500"><i><?php echo isset($resusr['email']) ? $resusr['email'] : 'N/A'; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Amount : <p class="fw-500"><i><?php echo $result['amount']; ?></i></p>
                                                                <hr>
                                                                Date : <p class="fw-500"><i><?php echo is_numeric($result['date_ts']) ? date('d M Y, h:i A', (int)$result['date_ts']) : $result['date_ts']; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="col-md-12 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Description / Detail : <p class="fw-500"><i><?php echo !empty($result['deatil']) ? $result['deatil'] : 'N/A'; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row mt-3">
                                                            <div class="col-md-12">
                                                                 <div class="card border border-primary shadow-sm">
                                                                     <div class="card-header bg-funky-moon2 text-white text-center py-1">
                                                                         <h6 class="mb-0 text-white"><b>User Payment Account Details</b></h6>
                                                                     </div>
                                                                     <div class="card-body p-3 text-start">
                                                                         <div class="row g-2">
                                                                             <div class="col-md-6 border-end">
                                                                                 <p class="mb-1"><b>Account Holder Name:</b> <?php echo !empty($result['user_ac_holder_name']) ? htmlspecialchars($result['user_ac_holder_name']) : 'N/A'; ?></p>
                                                                                 <p class="mb-1"><b>Account Number:</b> <?php echo !empty($result['user_ac_number']) ? htmlspecialchars($result['user_ac_number']) : 'N/A'; ?></p>
                                                                                 <p class="mb-1"><b>Bank Name:</b> <?php echo !empty($result['user_bank_name']) ? htmlspecialchars($result['user_bank_name']) : 'N/A'; ?></p>
                                                                             </div>
                                                                             <div class="col-md-6">
                                                                                 <p class="mb-1"><b>IFSC Code:</b> <?php echo !empty($result['user_bank_ifsc']) ? htmlspecialchars($result['user_bank_ifsc']) : 'N/A'; ?></p>
                                                                                 <p class="mb-1"><b>UPI ID:</b> <?php echo !empty($result['user_upi_id']) ? htmlspecialchars($result['user_upi_id']) : 'N/A'; ?></p>
                                                                             </div>
                                                                             <?php if(!empty($result['image'])){ ?>
                                                                                 <div class="col-12 text-center mt-2 pt-2 border-top">
                                                                                     <b>QR Code / Passbook Image:</b><br>
                                                                                     <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>">
                                                                                         <img class="img-fluid rounded border shadow-sm mt-1" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>" style="max-height: 150px;" />
                                                                                     </a>
                                                                                 </div>
                                                                             <?php } ?>
                                                                         </div>
                                                                     </div>
                                                                 </div></div>
                                                            </div>
                                                        </div>
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
