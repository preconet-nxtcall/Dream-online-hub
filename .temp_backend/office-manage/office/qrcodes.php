<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_GET['sj'])){
    $ids = $_GET['sj'];
    $emp_id = intval($_SESSION['u_id']);
    $qrydisplay1 = mysqli_query($conn, "SELECT * FROM `pricerange` WHERE id = $ids") or die(mysqli_error());
    $result1 = mysqli_fetch_array($qrydisplay1);
}

if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: qrcodes');
}

$msg='';

if(isset($_POST['add_qrcode'])){
    $bank_id = $_POST['bank_id'];
    $emp_id = $_SESSION['u_id'];
    $range_id = $_POST['range_id'];
    $check_first = mysqli_query($conn, "SELECT id FROM qrcode WHERE range_id = '$range_id' AND emp_id = '$emp_id'");
    $show_status = (mysqli_num_rows($check_first) == 0) ? "ACTIVE" : "INACTIVE";
    $msg = '';
    if(empty($bank_id)){
        $msg = "1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Please select bank!";
        if(isset($_SESSION['swl_type'])){
            header("Refresh:0; url=qrcodes?sj=$range_id");
            exit;
        }
    } 
    $res1=mysqli_query($conn,"select * from qrcode where range_id = '$range_id' and emp_id = '$emp_id' and bank_id='$bank_id'");
	$check=mysqli_num_rows($res1);
	if($check>0){
		$msg="1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "QR already exist!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0; url=qrcodes?sj=$range_id");
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
                header("Refresh:0; url=qrcodes?sj=$range_id");
                exit;
            }
        }
        else{
            $img_new1=$date_ts.'_QR.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
        }
    }
    else{
        $img_new1='';
    }

    if($msg == ''){
        $qry = "INSERT INTO `qrcode`(`range_id`, `emp_id`, `bank_id`, `image`, `show_status`, `date_ts`) VALUES ('".$range_id."','".$emp_id."','".$bank_id."','".$img_new1."','".$show_status."','".$date_ts."')";
        $query = mysqli_query($conn,$qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "QR Code Add Successfully!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0; url=qrcodes?sj=$range_id");
                exit;
            }
        }
    }
}

if(isset($_POST['edit_qrcode'])){
    $id = $_POST['id'];
    $bank_id = $_POST['bank_id'];
    $old_image = $_POST['old_image'];
    $emp_id = $_SESSION['u_id'];
    
    $qry = mysqli_query($conn, "SELECT range_id FROM qrcode WHERE id = '$id'");
    $res = mysqli_fetch_array($qry);
    $range_id = $res['range_id'];
    
    $msg = '';
    if(empty($bank_id)){
        $msg = "1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Please select bank!";
        if(isset($_SESSION['swl_type'])){
            header("Refresh:0; url=qrcodes?sj=$range_id");
            exit;
        }
    } 
    
    $res1=mysqli_query($conn,"select * from qrcode where range_id = '$range_id' and emp_id = '$emp_id' and bank_id='$bank_id' and id != '$id'");
	$check=mysqli_num_rows($res1);
	if($check>0){
		$msg="1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "QR already exist for this bank!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0; url=qrcodes?sj=$range_id");
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
                header("Refresh:0; url=qrcodes?sj=$range_id");
                exit;
            }
        }
        else{
            $img_new1=$date_ts.'_QR.'.pathinfo($img1, PATHINFO_EXTENSION);
            move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
            if(!empty($old_image) && file_exists(ADD_PHOTO_SERVER_PATH.$old_image)){
                @unlink(ADD_PHOTO_SERVER_PATH.$old_image);
            }
        }
    }
    else{
        $img_new1 = $old_image;
    }

    if($msg == ''){
        $qry = "UPDATE `qrcode` SET `bank_id` = '".$bank_id."', `image` = '".$img_new1."' WHERE `id` = '".$id."'";
        $query = mysqli_query($conn,$qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "QR Code Updated Successfully!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0; url=qrcodes?sj=$range_id");
                exit;
            }
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
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_partnr" class="btn btn_warning btn-sm">Add Qr Code<i class="bi bi-arrow-right ms-2"></i></button>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>QR codes </strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for update -->
            <div class="modal fade mt-4 pt-4" id="insert_partnr" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!importent;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Add QR Code</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                        <form class="row" action="" method="post" enctype="multipart/form-data" id="form">
                            <input type="hidden" value="<?php echo $ids; ?>" name="range_id"/>
                            <div class="card-body card-block">                                
                                <div class="row mb-3">
                                    <label class="col-sm-6 col-form-label">Choose Bank</label>
                                    <div class="col-sm-6">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <select class="form-select" name="bank_id" required>
                                                <option value="">Select Bank</option>
                                                <?php
                                                    $qrydisplay3 = mysqli_query($conn, "SELECT * FROM `features` WHERE order_no = '".$_SESSION['u_id']."' AND type = 'BANK' AND show_status = 'ACTIVE' ORDER BY ABS(id) DESC") or die(mysqli_error());
                                                    while($result3 = mysqli_fetch_array($qrydisplay3)){
                                                        echo '<option value="'.$result3['id'].'">'.$result3['name'].'</option>';
                                                    }
                                                ?>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mx-1 mb-3">
                                    <label class="col-form-label">Upload Qr Code Image</label>
                                    <input class="form-control" type="file" name="image" accept="image/*" required>
                                </div>
                                <hr class="ml-100">
                                <div class="row">
                                    <div class="d-flex gap-3 mt-3">
                                        <button name="add_qrcode" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
                        $ids = $_GET['sj'] ?? '';
                        $emp_id = intval($_SESSION['u_id']);
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `qrcode` WHERE range_id = '$ids' AND emp_id = '$emp_id'") or die(mysqli_error());
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
                                Price : <?php echo $result1['price_start']; ?> - <?php echo $result1['price_end']; ?>
                                <br>
                                <?php 
                                    $bank_id = $result['bank_id']; 
                                    $qrydisplay2 = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '".$bank_id."' ") or die(mysqli_error());
                                    $result2 = mysqli_fetch_array($qrydisplay2);
                                    $bank_name = isset($result2['name']) ? $result2['name'] : '';
                                    echo "<span class='text-muted'>Bank A/C : ".$bank_name."</span>";
                                ?>
                            </td>
                            <td> 
                                <input type="hidden" class="id_value" value="<?php echo $result['id']; ?>" >
                                <?php if($result['show_status'] == "INACTIVE"){ ?>
                                <a class="text-white pr-2 status_btn_qrcode_ajax" href="javascript:void(0)" data-bs-toggle="tooltip" data-bs-title="Status">
                                    <button class="btn py-1 px-2 btn-rds btn_secondary" type="button" style="vertical-align:middle">
                                        <span><i class="bi bi-x-lg"></i> </span>
                                    </button>
                                </a>
                                <?php } else { ?>
                                <a class="text-white pr-2 btn py-1 px-2 btn-rds btn_primary" style="vertical-align:middle; pointer-events: none; opacity: 0.8;" data-bs-toggle="tooltip" data-bs-title="Status">
                                    <span><i class="bi bi-check-circle"></i> </span>
                                </a>
                                <?php } ?>
                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="Edit"><i class="bi bi-pencil-square"></i></button>
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Update Qr Code</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $result['image']; ?>" name="old_image" />
                                                        <div class="card-body card-block">
                                                            <div class="row mb-6">
                                                                <label class="col-sm-6 col-form-label">Choose Bank</label>
                                                                <div class="col-sm-6">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <select class="form-control" name="bank_id" required>
                                                                            <option value="">Select Bank</option>
                                                                            <?php
                                                                                $qrydisplay4 = mysqli_query($conn, "SELECT * FROM `features` WHERE order_no = '".$_SESSION['u_id']."' AND type = 'BANK' AND show_status = 'ACTIVE' ORDER BY ABS(id) DESC") or die(mysqli_error());
                                                                                while($result4 = mysqli_fetch_array($qrydisplay4)){
                                                                                    echo "<option value='".$result4['id']."' ".(($result4['id'] == $bank_id) ? 'selected' : '').">".$result4['name']."</option>";
                                                                                }
                                                                            ?>
                                                                        </select>
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
                                                                <label class="col-sm-2">Update QR Code Image</label>
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
                                                                    <button name="edit_qrcode" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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