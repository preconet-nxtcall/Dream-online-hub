<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: agency-employees');
}
if(ISSET($_POST['add_agency_employee'])){
    $name = addslashes($_POST["name"]);
    $email = addslashes($_POST["email"]);
    $type = "AGENCYS-EMPLOYEE";
    $mob = $_POST["mob"];
    $password = $_POST["password"];
    $emp_id = $_SESSION['u_id'];
    $agency_id = $emp_id;
    $show_status = "ACTIVE";
    $msg = '';
    
    $res1=mysqli_query($conn,"select * from users where (mob='$mob' or email='$email') and type='$type'");
	$check=mysqli_num_rows($res1);
	if($check>0){
		$msg="1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Agency Employee already exist!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
	}else{
		$msg='';
	}

    $img1 = $_FILES["image"]['name'];
    if($_FILES['image']['name']!=''){
        if (($_FILES['image']['size'] > 1048576) || ( $_FILES['image']['type']!='image/png' && $_FILES['image']['type']!='image/jpg' && $_FILES['image']['type']!='image/jpeg' && $_FILES['image']['type']!='image/webp' && $_FILES['image']['type']!='image/avif')){
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error !";
            $_SESSION['text'] = "Select Jpg/png/webp/avif Under 1Mb!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
        else{
            $img_new1=$date_ts.'_Agency_Employee.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
        }
    }
    else{
        $img_new1='';
    }
    if($msg == ''){
        $qrymagnc = mysqli_fetch_assoc(mysqli_query($conn, "SELECT * FROM `users` WHERE `id` = '".$emp_id."'"));
        $agency_unq_id = $qrymagnc['agency_unq_id'];
        $profit_loss_status = $qrymagnc['profit_loss_status'];
        $qry = "INSERT INTO `users`(`name`, `mob`, `email`, `password`, `img`, `agency_id`, `agency_unq_id`, `profit_loss_status`, `type`, `show_status`, `date`) VALUES ('".$name."','".$mob."','".$email."','".$password."','".$img_new1."','".$agency_id."','".$agency_unq_id."','".$profit_loss_status."','".$type."','".$show_status."','".$date."')";
        $query = mysqli_query($conn,$qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "Agency Employee Add Successfully!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
	}
}

$msg='';
if(ISSET($_POST['edit_agency_employee'])){
    $id = $_POST["id"];
    $name = addslashes($_POST["name"]);
    $email = addslashes($_POST["email"]);
    $mob = $_POST["mob"];
    $password = $_POST["password"];
    $old_img = $_POST["old_image"];
    $type = "AGENCYS-EMPLOYEE";

    $res1=mysqli_query($conn,"select * from users where id <> '$id' and (mob='$mob' or email='$email') and type='$type'");
	$check=mysqli_num_rows($res1);
	if($check>0){
		$msg="1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Agency Employee already exist!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
	}else{
		$msg='';
	}

    $img1 = $_FILES["image"]['name'];
    if($_FILES['image']['name']!=''){
        if (($_FILES['image']['size'] > 1048576) || ( $_FILES['image']['type']!='image/png' && $_FILES['image']['type']!='image/jpg' && $_FILES['image']['type']!='image/jpeg' && $_FILES['image']['type']!='image/webp' && $_FILES['image']['type']!='image/avif')){
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error !";
            $_SESSION['text'] = "Select Jpg/png/webp/avif Under 1Mb!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
        else{
            $img_new1=$date_ts.'_Agency_Employee.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
        }
    }
    else{
        $img_new1= $old_img;
    }

    $qry = "UPDATE `users` set `name` = '".$name."', `mob` = '".$mob."', `email` = '".$email."', `password` = '".$password."', `img` = '".$img_new1."' WHERE `id` = '".$id."'" or die(mysqli_error($conn));
    $query = mysqli_query($conn,$qry);
    
    if($query){
        if(!empty($img_new1)){
            if($img_new1 != $old_img && !empty($old_img)){
                unlink(ADD_PHOTO_SERVER_PATH.$old_img);
            }
        }        
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Agency Employee Update Successfully!";
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
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_partnr" class="btn btn_warning btn-sm">Add Agency Employee <i class="bi bi-arrow-right ms-2"></i></button>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Agency Employees </strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for insert -->
            <div class="modal fade mt-4 pt-4" id="insert_partnr" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!importent;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Add Agency Employee</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                        <form class="row" action="agency-employees" method="post" enctype="multipart/form-data" id="form">
                            <div class="card-body card-block">
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Agency Employee Name</label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="name" placeholder="Enter Name" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Mobile Number</label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="mob" placeholder="Enter Mobile Number" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Email ID</label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="email" class="form-control" name="email" placeholder="Enter Email ID" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Collect Limit</label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="number" class="form-control" name="collect_limit" placeholder="Enter Collect Limit" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Password</label>
                                    <div class="col-sm-8">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="password" placeholder="Enter Password" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mx-1 mb-3">
                                    <label class="col-form-label">Upload Image</label>
                                    <input class="form-control" type="file" name="image" required>
                                </div>
                                <hr class="ml-100">
                                <div class="row">
                                    <div class="d-flex gap-3 mt-3">
                                        <button name="add_agency_employee" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Image</th>
                            <th class="text-center" scope="col">Name</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `users` WHERE type = 'AGENCYS-EMPLOYEE' AND agency_id = '$emp_id' ORDER BY ABS(id) DESC") or die(mysqli_error());
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                    ?>
                        <tr id="<?php echo $result['id'] ?>" >
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                            <?php
                                if(!empty($result['img'])){
                                    echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['img']."'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['img']."' /></a>";
                                }
                                else {
                                    echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                } ?>
                            </td>
                            <td>
                                <?php echo $result['name']; ?> <br>
                                Phone : <?php echo $result['mob']; ?>
                            </td>
                            <td> 
                                <input type="hidden" class="id_value" value="<?php echo $result['id']; ?>" >
                                <a class="text-white pr-2 status_btn_users_ajax" href="javascript:void(0)" data-bs-toggle="tooltip" data-bs-title="Status"><button class="btn py-1 px-2 btn-rds
                                <?php if($result['show_status'] == "ACTIVE"){ ?> btn_primary<?php }else{?> btn_secondary<?php }?>
                                " type="button" style="vertical-align:middle"><span>
                                <?php if($result['show_status'] == "ACTIVE"){ ?> <i class="bi bi-check-circle"></i><?php }else{?><i class="bi bi-x-lg"></i><?php }?>    
                                </span></button></a>
                            
                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="Edit"><i class="bi bi-pencil-square"></i></button>
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Update Agency Employee</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="agency-employees" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $result['img']; ?>" name="old_image" />
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Agency Employee Name</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="name" value="<?php echo $result['name']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Phone Number</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="mob" value="<?php echo $result['mob']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Email ID</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="email" class="form-control" name="email" value="<?php echo $result['email']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Password</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="password" value="<?php echo $result['password']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row mb-3 d-flex justify-content-center align-items-center">
                                                                <div class="col-sm-2">
                                                                    <label class="">Current image</label>
                                                                    <div class="input-group">
                                                                        <?php
                                                                            if(!empty($result['img'])){
                                                                                echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['img']."'><img class='mx-auto img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['img']."' style='max-height: 100px !important; max-width: 100px !important;'/></a>";
                                                                            }
                                                                            else {
                                                                                echo "<img class='mx-auto img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                                                            }
                                                                        ?>
                                                                    </div>
                                                                </div>
                                                                <label class="col-sm-2">Update Photo</label>
                                                                <div class="col-sm-6">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="file" class="form-control" name="image" accept="image/*" onchange="loadFile(event)">
                                                                    </div>
                                                                </div>
                                                                <div class="col-sm-2">
                                                                    <img id="output" style="max-height: 100px !important; max-width: 100px !important;"/>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_agency_employee" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
                                <input type="hidden" class="image_value" value="<?php echo $result['img']; ?>" >
                                <a class="text-white pr-2 delete_btn_users_ajax" href="javascript:void(0)"><button class="btn py-1 px-2 btn_danger" type="button" style="vertical-align:middle" data-bs-toggle="tooltip" data-bs-title="Delete"><span><i class="bi bi-trash"></i> </span></button></a>
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

<!-- Agency Employee Performance Details Modal -->
<div class="modal fade mt-4 pt-4" id="agencyPerformanceModal" tabindex="-1" aria-labelledby="agencyPerformanceModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-scrollable modal-xl">
        <div class="modal-content" style="overflow: visible!importent;">
            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                <div class="row mb-1">
                    <div class="col-8 text-left">
                        <h5 class="modal-title text-white ml-1"><b>Agency Employee Performance & Current Details</b></h5>
                    </div>
                    <div class="col-4 text-right">
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                </div>  
            </div>
            <div class="modal-body py-2" id="agencyPerformanceModalBody">
                <div class="text-center py-5">
                    <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <p class="mt-3 text-muted fw-semibold">Loading agency employee performance metrics...</p>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    window.addEventListener('load', function(){
        if (typeof jQuery !== 'undefined') {
            $('#example').on('click', '.view_agency_perf_btn', function(e){
                e.preventDefault();
                var agencyId = $(this).data('agency-id');
                var agencyName = $(this).data('agency-name');
                
                $('#agencyPerformanceModalLabel').html('<i class="bi bi-graph-up-arrow me-2"></i> Performance Details: <b>' + agencyName + '</b>');
                $('#agencyPerformanceModalBody').html(`
                    <div class="text-center py-5">
                        <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                            <span class="visually-hidden">Loading...</span>
                        </div>
                        <p class="mt-3 text-muted fw-semibold">Fetching latest performance details for ` + agencyName + `...</p>
                    </div>
                `);
                
                var perfModal = new bootstrap.Modal(document.getElementById('agencyPerformanceModal'));
                perfModal.show();
                
                $.ajax({
                    type: 'POST',
                    url: 'ajax_agency_performance.php',
                    data: { agency_id: agencyId },
                    success: function(response){
                        $('#agencyPerformanceModalBody').html(response);
                    },
                    error: function(){
                        $('#agencyPerformanceModalBody').html('<div class="alert alert-danger">Error loading performance details. Please try again.</div>');
                    }
                });
            });
        }
    });
</script>

<?php include 'partials/_footer.php' ?>
