<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: emp-recharge-success');
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

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Successfull Employee Recharge</strong> List</h5>
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
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `recharge` WHERE stage_status = 'EMPLOYEE-DONE' ORDER BY ABS(id) DESC") or die(mysqli_error());
                        
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qrysubscription = mysqli_query($conn, "SELECT * FROM `subscription` WHERE id = '$result[subscription_id]' ") or die(mysqli_error());
                            $ressub = mysqli_fetch_array($qrysubscription);
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
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <div class="container-fluid mt-4">
                                                        <div class="row">
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Agency :  <p class="fw-500"><i>AGENCY-<?php echo $result['emp_id']; ?></i></p>
                                                                <hr>
                                                                Book Name :  <p class="fw-500"><i><?php echo $resbook['name']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                User Name :  <p class="fw-500"><i><?php echo $ressub['username']; ?></i></p>
                                                                <hr>
                                                                Password :  <p class="fw-500"><i><?php echo $ressub['password']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Amount :  <p class="fw-500"><i><?php echo $result['amount']; ?></i></p>
                                                                <hr>
                                                                Website Link :  <p class="fw-500"><i><?php echo $resbook['detail']; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="col-md-6 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Transaction ID  : <p class="fw-500"><i> <?php echo $result['transection_id']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-6 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Agency Remark : <p class="fw-500"><i><?php echo $result['remark']; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="col-md-6 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Your Remark : <p class="fw-500"><i><?php echo $result['employee_remark']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-6 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Date : <?php echo date('d M Y, h:i A', $result['date_ts']); ?>
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
