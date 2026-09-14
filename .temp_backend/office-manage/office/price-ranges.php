<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: price-ranges');
}
if(isset($_POST['add_range'])){
    $price_start = intval($_POST["price_start"]);
    $price_end = intval($_POST["price_end"]);
    $show_status = "ACTIVE";
    $msg = '';

    if($price_start > $price_end){
        $msg = "1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Price start cannot be greater than price end!";
        if(isset($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    } else {
        $range_check_sql = "SELECT id FROM `pricerange` WHERE NOT (CAST(price_end AS UNSIGNED) < $price_start OR CAST(price_start AS UNSIGNED) > $price_end)";
        $range_check_res = mysqli_query($conn, $range_check_sql);
        if(mysqli_num_rows($range_check_res) > 0) {
            $msg = "1";
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error !";
            $_SESSION['text'] = "Price range conflicts with an existing range for the same employee!";
            if(isset($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
    }
    
    if($msg == ''){
        $qry = "INSERT INTO `pricerange` (`price_start`, `price_end`, `show_status`, `date_ts`) VALUES ('".$price_start."', '".$price_end."', '".$show_status."', '".$date_ts."')";
        $query = mysqli_query($conn,$qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "QR Code Add Successfully!";
            if(isset($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
    }
}

$msg='';

if(isset($_POST['edit_range'])){
    $id = intval($_POST["id"]);
    $price_start = intval($_POST["price_start"]);
    $price_end = intval($_POST["price_end"]);
    $show_status = "ACTIVE";
    $msg = '';
    if($price_start > $price_end){
        $msg = "1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Price start cannot be greater than price end!";
        if(isset($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    } else {
        $range_check_sql = "SELECT id FROM `pricerange` WHERE id != '$id' AND NOT (CAST(price_end AS UNSIGNED) < $price_start OR CAST(price_start AS UNSIGNED) > $price_end)";
        $range_check_res = mysqli_query($conn, $range_check_sql);
        if(mysqli_num_rows($range_check_res) > 0) {
            $msg = "1";
            $_SESSION['swl_type'] = "error";
            $_SESSION['head'] = "Error !";
            $_SESSION['text'] = "Price range conflicts with an existing range for the same employee!";
            if(isset($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
    }
    if($msg == ''){
        $qry = "UPDATE `pricerange` SET `price_start` = '".$price_start."', `price_end` = '".$price_end."' WHERE `id` = '".$id."'";
        $query = mysqli_query($conn,$qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successfull !";
            $_SESSION['text'] = "Price Range Updated Successfully!";
            if(isset($_SESSION['swl_type'])){
                header("Refresh:0;");
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
            <?php if($_SESSION['u_type'] == "ADMIN") { ?>
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_partnr" class="btn btn_warning btn-sm">Add Price Range<i class="bi bi-arrow-right ms-2"></i></button>
            <?php } ?>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Price Ranges </strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for update -->
            <div class="modal fade mt-4 pt-4" id="insert_partnr" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!importent;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Add Price Range</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                        <form class="row" action="price-ranges" method="post" enctype="multipart/form-data" id="form">
                            <div class="card-body card-block">
                                <div class="row mb-3">
                                    <label class="col-sm-2 col-form-label">Range Start </label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="number" class="form-control" name="price_start" placeholder="Enter Price Start" required>
                                        </div>
                                    </div>
                                    <label class="col-sm-2 col-form-label">Range End </label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">✎</span>
                                            <input type="number" class="form-control" name="price_end" placeholder="Enter Price End" required>
                                        </div>
                                    </div>
                                </div>
                                <hr class="ml-100">
                                <div class="row">
                                    <div class="d-flex gap-3 mt-3">
                                        <button name="add_range" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
                            <th class="text-center" scope="col">Price Range</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `pricerange` ORDER BY ABS(id) DESC") or die(mysqli_error());
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                    ?>
                        <tr id="<?php echo $result['id'] ?>" >
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                Price range from Rs.<?php echo $result['price_start']; ?>/- Price to Rs.<?php echo $result['price_end']; ?>/-
                            </td>
                            <td> 
                                <?php if($_SESSION['u_type'] == "ADMIN") { ?>
                                <input type="hidden" class="id_value" value="<?php echo $result['id']; ?>" >
                                <a class="text-white pr-2 status_btn_range_ajax" href="javascript:void(0)" data-bs-toggle="tooltip" data-bs-title="Status"><button class="btn py-1 px-2 btn-rds
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
                                                        <h5 class="modal-title text-white ml-1"><b>Update Price Range</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="price-ranges" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <div class="card-body card-block">
                                                            <div class="row mb-6">
                                                                <label class="col-sm-2 col-form-label">Price From </label>
                                                                <div class="col-sm-4">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="number" class="form-control" name="price_start" value="<?php echo $result['price_start']; ?>" required>
                                                                    </div>
                                                                </div>
                                                                <label class="col-sm-2 col-form-label">Price To </label>
                                                                <div class="col-sm-4">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="number" class="form-control" name="price_end" value="<?php echo $result['price_end']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_range" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
                                <a class="btn py-1 px-2 btn_info btn-icon" href="qrcodes?sj=<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="QR Codes"><i class="bi bi-qr-code"></i></a>
                                <?php } else { ?>
                                <a class="btn py-1 px-2 btn_info btn-icon" href="qrcodes?sj=<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="QR Codes"><i class="bi bi-qr-code"></i></a>
                                <?php } ?>
                                <?php if($_SESSION['u_type'] == "ADMIN") { ?>
                                <!--<a class="text-white pr-2 delete_btn_range_ajax" href="javascript:void(0)"><button class="btn py-1 px-2 btn_danger" type="button" style="vertical-align:middle" data-bs-toggle="tooltip" data-bs-title="Delete"><span><i class="bi bi-trash"></i> </span></button></a>-->
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