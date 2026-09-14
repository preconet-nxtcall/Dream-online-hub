<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: home-slides');
}
if(ISSET($_POST['add_image'])){
    $name = addslashes($_POST["name"]);
    $slag = addslashes($_POST["slag"]);
    $title = addslashes($_POST["title"]);
    $detail = addslashes($_POST["detail"]);
    $type = "HOME-SLIDE";
    date_default_timezone_set("Asia/Calcutta");
	$date = date("Y-m-d");
    $show_status = "ACTIVE";
    $msg = '';
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
            $img_new1=$date_ts.'_Slider.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
        }
    }
    else{
        $msg = 1;
    }
    if($msg == ''){
        $qry = "INSERT INTO `cmstable`(`name`, `title`, `slag`, `detail`, `image`, `show_status`, `type`, `date`) VALUES ('".$name."','".$title."','".$slag."','".$detail."','".$img_new1."','".$show_status."','".$type."','".$date."')";
        $query = mysqli_query($conn,$qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "Image Add Successfully!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
    }else{
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Please Must Be Add Image File!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    }
}

$msg='';
if(ISSET($_POST['edit_slides'])){
	$id = $_POST["id"];
    $name = addslashes($_POST["name"]);
    $slag = addslashes($_POST["slag"]);
    $title = addslashes($_POST["title"]);
    $detail = addslashes($_POST["detail"]);
    $msg = '';
    $old_img = $_POST["old_image"];
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
            $img_new1=$date_ts.'_Slider.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
        }
    }
    else{
        $img_new1= $old_img;
    }

    $qry = "UPDATE `cmstable` set `name` = '".$name."', `title` = '".$title."', `slag` = '".$slag."', `detail` = '".$detail."', `image` = '".$img_new1."', `date` = '".$date."' WHERE `id` = '".$id."'" or die(mysqli_error());
    $query = mysqli_query($conn,$qry);
    
    if($query){
        if(!empty($img_new1)){
            if($img_new1 != $old_img && !empty($old_img)){
                unlink(ADD_PHOTO_SERVER_PATH.$old_img);
            }
        }
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Slides Update Successfully!";
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
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_partnr" class="btn btn_warning btn-sm">Add Slider <i class="bi bi-arrow-right ms-2"></i></button>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Slider</strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for update -->
            <div class="modal fade mt-4 pt-4" id="insert_partnr" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!importent;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Add Slider Image</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                        <form class="row" action="home-slides" method="post" enctype="multipart/form-data" id="form">
                            <div class="card-body card-block">
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Slide Title</label>
                                    <div class="col-sm-9">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="name" placeholder="Enter Name" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Slide Button Title</label>
                                    <div class="col-sm-9">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="title" placeholder="Enter Button Title" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Slide Button Link</label>
                                    <div class="col-sm-9">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="detail" placeholder="Enter Button Link" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-3 col-form-label">Slide detail</label>
                                    <div class="col-sm-9">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="text" class="form-control" name="slag" placeholder="Enter detail" required>
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
                                        <button name="add_image" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                        <i class="bi bi-check-lg me-2"></i> SUBMIT
                                        </button>
                                        <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect">
                                        <i class="bi bi-x-lg me-2"></i> RESET 
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form><!-- End update Multi Columns Form -->
                        </div>
                    </div>
                </div>
            </div>
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example"  style="min-width: auto;">
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
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `cmstable` WHERE type = 'HOME-SLIDE' ORDER BY id DESC") or die(mysqli_error());
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                    ?>
                        <tr id="<?php echo $result['id'] ?>" >
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                            <?php
                                if(!empty($result['image'])){
                                    echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' /></a>";
                                }
                                else {
                                    echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                } ?>
                            </td>
                            <td>
                                <?php echo $result['name']; ?>
                            </td>
                            <td> 
                                <input type="hidden" class="id_value" value="<?php echo $result['id']; ?>" >
                                <a class="text-white pr-2 status_btn_cmstable_ajax" href="javascript:void(0)" data-bs-toggle="tooltip" data-bs-title="Status"><button class="btn py-1 px-2 btn-rds
                                <?php if($result['show_status'] == "ACTIVE"){ ?> btn_primary<?php }else{?> btn_secondary<?php }?>
                                " type="button" style="vertical-align:middle"><span>
                                <?php if($result['show_status'] == "ACTIVE"){ ?> <i class="bi bi-check-circle"></i><?php }else{?><i class="bi bi-x-lg"></i><?php }?>    
                                </span></button></a>
                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-placement="tooltip" data-bs-title="Edit"><i class="bi bi-pencil-square"></i></button>
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Update Slides</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="home-slides" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $result['image']; ?>" name="old_image" />
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-2 col-form-label">Name</label>
                                                                <div class="col-sm-10">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="name" value="<?php echo $result['name']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div> 
                                                            <div class="row mb-3">
                                                                <label class="col-sm-2 col-form-label">Slide Detail</label>
                                                                <div class="col-sm-10">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="slag" value="<?php echo $result['slag']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-2 col-form-label">Button Title</label>
                                                                <div class="col-sm-4">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="title" value="<?php echo $result['title']; ?>" required>
                                                                    </div>
                                                                </div>
                                                                <label class="col-sm-2 col-form-label">Button Link</label>
                                                                <div class="col-sm-4">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="detail" value="<?php echo $result['detail']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row mb-3 d-flex justify-content-center align-items-center">
                                                                <div class="col-sm-2">
                                                                    <label class="">Current image</label>
                                                                    <div class="input-group">
                                                                        <?php
                                                                            if(!empty($result['image'])){
                                                                                echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."'><img class='mx-auto img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' style='max-height: 100px !important; max-width: 100px !important;'/></a>";
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
                                                            <div class="d-flex gap-3 mt-3">
                                                                <button name="edit_slides" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                                                <i class="bi bi-check-lg me-2"></i> SUBMIT
                                                                </button>
                                                                <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect">
                                                                <i class="bi bi-x-lg me-2"></i> RESET 
                                                                </button>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <input type="hidden" class="image_value" value="<?php echo $result['image']; ?>" >
                                <a class="text-white pr-2 delete_btn_cmstable_ajax" href="javascript:void(0)"><button class="btn py-1 px-2 btn_danger" type="button" style="vertical-align:middle" data-bs-toggle="tooltip" data-bs-title="Delete"><span><i class="bi bi-trash"></i> </span></button></a>
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