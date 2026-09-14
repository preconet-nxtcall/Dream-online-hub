<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

$qrydisplay = mysqli_query($conn, "SELECT * FROM `cmstable` WHERE type = 'TERMS'") or die(mysqli_error());
$result = mysqli_fetch_array($qrydisplay);

$msg='';

if(ISSET($_POST['edit_about'])){
	$id = $_POST["id"];
	$old_img = $_POST["old_img"];
	$name = addslashes($_POST["name"]);
	$detail = addslashes($_POST["detail"]);
	$msg='';

    if($msg == ''){

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
				$img_new1=$date_ts.'_Terms-and-Conditions.'.pathinfo($img1, PATHINFO_EXTENSION);
				move_uploaded_file($_FILES['image']['tmp_name'],ADD_PHOTO_SERVER_PATH.$img_new1);
			}
		}
		else{
			$img_new1= $old_img;
		}
		
		$qry = "UPDATE `cmstable` set `name` = '".$name."', `detail` = '".$detail."', `image` = '".$img_new1."', `date` = '".$date."' WHERE `id` = '".$id."'" or die(mysqli_error());
		$query = mysqli_query($conn,$qry);
		if($query){
			if(!empty($img_new1)){
				if($img_new1 != $old_img && !empty($old_img)){
					unlink(ADD_PHOTO_SERVER_PATH.$old_img);
				}
			}
			$_SESSION['swl_type'] = "success";
			$_SESSION['head'] = "Successfull !";
			$_SESSION['text'] = "Data Updated Successfully!";
			if(ISSET($_SESSION['swl_type'])){
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
            <a href="admin_dashboard" class="btn btn_primary btn-sm">Dashboard <i class="bi bi-arrow-right ms-2"></i></a>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow-sm mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Terms & </strong> Conditions</h5>
        </div>
        <div class="card-body pb-0">
            <form class="row px-2" action="terms-and-conditions" method="post" enctype="multipart/form-data">
                <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
				<input type="hidden" value="<?php echo $result['image']; ?>" name="old_img"/>
                <div class="card-body card-block">
                    <div class="row mb-3">
                        <div class="col-md-12">
                            <label for="inputEmail5"> Title</label>
                            <div class="input-group mb-3">
                                <span class="input-group-text" id="basic-addon1">✎</span>
                                <input type="text" class="form-control" name="name" value="<?php echo $result['name']; ?>">
                            </div>
                        </div>
                    </div>
                    <hr class="md-100">
                    <div class="row mx-1 mb-3">
                        <label class="">Description</label>
                        <textarea class="form-control editor" id="summernote" name="detail"><?php echo $result['detail'];?></textarea>
                    </div>
                    <hr class="md-100">
                    <div class="row mb-3">
                        <div class="col-sm-4">
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
                        <div class="col-sm-8">
                            <label class="">Upload Photo</label>
                            <br>
                            <div class="input-group mb-3">
                                <span class="input-group-text" id="basic-addon1">✎</span>
                                <input type="file" class="form-control" name="image" accept="image/*" onchange="loadFile(event)">
                            </div>
                        </div>
                    </div>
                    <hr class="md-100">
                    <div class="d-flex gap-3 mt-3">
                        <button name="edit_about" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                        <i class="bi bi-check-lg me-2"></i> UPDATE
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