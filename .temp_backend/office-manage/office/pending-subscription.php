<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: pending-subscription');
}
$msg='';
if(ISSET($_POST['edit_subscription'])){
    $id = $_POST["id"];
    $emp_id = $_POST["emp_id"];
    $stage_status = "DONE";
    $read_status = "READ";
    if($emp_id == 1){
		$user_under = "ADMIN";
	} else {
		$user_under = "AGENCY";
	}
    $username = addslashes($_POST["username"]);
    $username_slag = strtolower(preg_replace("/[^0-9a-zA-Z]+ /", "-", $username));
    $username_slag = rtrim($username_slag, "-");
    $password = addslashes($_POST["password"]);

    $qry = "UPDATE `subscription` set `stage_status` = '".$stage_status."', `read_status` = '".$read_status."', `user_under` = '".$user_under."', `username` = '".$username."', `username_slag` = '".$username_slag."', `password` = '".$password."' WHERE `id` = '".$id."'";
    $query = mysqli_query($conn,$qry) or die(mysqli_error($conn));
    
    if($query){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Subscription Update Successfully!";
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
            <h5 class="card-title text-white my-1"><strong>User Subscription</strong> Pending List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">User Details</th>
                            <th class="text-center" scope="col">Book Details</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `subscription` WHERE read_status = 'READ' AND stage_status = 'PENDING' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[user_id]' ") or die(mysqli_error());
                            $resusr = mysqli_fetch_array($qryusr);
                            $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$result[book_id]' ") or die(mysqli_error());
                            $resbook = mysqli_fetch_array($qrybook);
                    ?>
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                User Name : <?php echo $resusr['name']; ?> <br> Phone : <?php echo $resusr['mob']; ?>
                            </td>
                            <td>
                                Book Name : <?php echo $resbook['name']; ?> <br> 
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
                                                        <h5 class="modal-title text-white ml-1"><b>Check Subscription Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <form action="pending-subscription" method="POST">
                                                            <button type="submit" name="modal_close" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                        </form>    
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <div class="container-fluid mt-4">
                                                        <div class="row">
                                                            <div class="col-md-5 mx-auto text-center border border-primary shadow py-2">
                                                                User Name :  <p class="fw-500"><i><?php echo $resusr['name']; ?></i></p>
                                                                <hr>
                                                                Book Name :  <p class="fw-500"><i><?php echo $resbook['name']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-5 mx-auto text-center border border-primary shadow py-2">
                                                                Phone :  <p class="fw-500"><i><?php echo $resusr['mob']; ?></i></p>
                                                                <hr>
                                                                Email :  <p class="fw-500"><i><?php echo $resusr['email']; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="col-md-12 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Date : <?php echo date('d M Y, h:i A', $result['date_ts']); ?>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="Verify"><i class="bi bi-check"></i></button>
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-md">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Verify Subscription</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="pending-subscription" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $emp_id; ?>" name="emp_id"/>
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Username </label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <input type="text" class="form-control" name="username" value="<?php echo isset($result['username']) ? $result['username'] : '';?>" required>    
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Password </label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <input type="text" class="form-control" name="password" value="<?php echo isset($result['password']) ? $result['password'] : '';?>" required>    
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_subscription" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                                                    <i class="bi bi-check-lg me-2"></i> UPDATE & COMPLETE
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