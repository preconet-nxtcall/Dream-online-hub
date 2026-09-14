<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

$qrydisplay2 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error());
$stg_result = mysqli_fetch_array($qrydisplay2);

if(isset($_POST['site_stng']) && $_SERVER['REQUEST_METHOD'] == 'POST'){
    $heading = addslashes($_POST["heading"]);
    $tag_line = addslashes($_POST["tag_line"]);
    $meta = addslashes($_POST["meta"]);
	$address = addslashes($_POST["address"]);
	$embed_map = $_POST["embed_map"];
	$video_link = $_POST["video_link"];
	$email = $_POST["email"];
	$mobile = $_POST["mobile"];
	$whatsapp = $_POST["whatsapp"];
	$land_no = $_POST["land_no"];
	$facebook = $_POST["facebook"];
	$instagram = $_POST["instagram"];
	$twitter = $_POST["twitter"];
	$youtube = $_POST["youtube"];
	$notice = addslashes($_POST["notice"]);
	$sms_key = $_POST["sms_key"];
	$sms_sender = $_POST["sms_sender"];
	$pay_key = $_POST["pay_key"];
	$pay_code = $_POST["pay_code"];
	$count_1 = $_POST["count_1"];
	$count_2 = $_POST["count_2"];
	$count_3 = $_POST["count_3"];
	$count_4 = $_POST["count_4"];

	$theme_mode = (isset($_POST['theme_mode']) && $_POST['theme_mode'] === 'light') ? 'light' : 'dark';
	$theme_primary = !empty($_POST['theme_primary']) ? preg_replace('/[^#a-zA-Z0-9]/', '', $_POST['theme_primary']) : '#8b5cf6';
	$theme_secondary = !empty($_POST['theme_secondary']) ? preg_replace('/[^#a-zA-Z0-9]/', '', $_POST['theme_secondary']) : '#6366f1';
	$theme_bg = !empty($_POST['theme_bg']) ? preg_replace('/[^#a-zA-Z0-9]/', '', $_POST['theme_bg']) : ($theme_mode === 'light' ? '#f8fafc' : '#0b071e');
	$theme_card = !empty($_POST['theme_card']) ? preg_replace('/[^#a-zA-Z0-9]/', '', $_POST['theme_card']) : ($theme_mode === 'light' ? '#ffffff' : '#161333');
	$theme_text = !empty($_POST['theme_text']) ? preg_replace('/[^#a-zA-Z0-9]/', '', $_POST['theme_text']) : ($theme_mode === 'light' ? '#0f172a' : '#f8fafc');

	date_default_timezone_set("Asia/Calcutta");
	$date = date("Y-m-d");
	$time = date("H:i:s");

    $id=1;
    
    $old_logo_image = $_POST["old_logo"];
    $old_fevicon_image = $_POST["old_fevicon"];
	$old_white_logo_image = $_POST["old_white_logo"];
	$old_small_logo_image = $_POST["old_small_logo"];

	if (!file_exists(ADD_PHOTO_SERVER_PATH)) {
		@mkdir(ADD_PHOTO_SERVER_PATH, 0777, true);
	}
	@chmod(ADD_PHOTO_SERVER_PATH, 0777);
	
	$new_logo_image = $_FILES["logo"]['name'];
	if($_FILES['logo']['name']!=''){
		if ($_FILES['logo']['size'] > 52428800){
			$_SESSION['swl_type'] = "error";
			$_SESSION['head'] = "Error !";
			$_SESSION['text'] = "Select image under 50Mb!";
			if(ISSET($_SESSION['swl_type'])){
				header("Refresh:0;");
				exit;
			}
		}		
		else{
			$new_logo_image1=$date_ts.'_Logo_photo.'.pathinfo($new_logo_image, PATHINFO_EXTENSION);
			move_uploaded_file($_FILES['logo']['tmp_name'],ADD_PHOTO_SERVER_PATH.$new_logo_image1);
		}
	}
	else{
		$new_logo_image1 = $old_logo_image;
	}

    $new_fevicon_image = $_FILES["fevicon"]['name'];
	if($_FILES['fevicon']['name']!=''){
		if ($_FILES['fevicon']['size'] > 52428800){
			$_SESSION['swl_type'] = "error";
			$_SESSION['head'] = "Error !";
			$_SESSION['text'] = "Select image under 50Mb!";
			if(ISSET($_SESSION['swl_type'])){
				header("Refresh:0;");
				exit;
			}
		}	
		else{
			$new_fevicon_image1=$date_ts.'_fevicon_photo.'.pathinfo($new_fevicon_image, PATHINFO_EXTENSION);
			move_uploaded_file($_FILES['fevicon']['tmp_name'],ADD_PHOTO_SERVER_PATH.$new_fevicon_image1);
		}
	}
	else{
		$new_fevicon_image1 = $old_fevicon_image;
	}
	
	$new_white_logo_image = $_FILES["white_logo"]['name'];
	if($_FILES['white_logo']['name']!=''){
		if ($_FILES['white_logo']['size'] > 52428800){
			$_SESSION['swl_type'] = "error";
			$_SESSION['head'] = "Error !";
			$_SESSION['text'] = "Select image under 50Mb!";
			if(ISSET($_SESSION['swl_type'])){
				header("Refresh:0;");
				exit;
			}
		}	
		else{
			$new_white_logo_image1=$date_ts.'_white_logo_photo.'.pathinfo($new_white_logo_image, PATHINFO_EXTENSION);
			move_uploaded_file($_FILES['white_logo']['tmp_name'],ADD_PHOTO_SERVER_PATH.$new_white_logo_image1);
		}
	}
	else{
		$new_white_logo_image1 = $old_white_logo_image;
	}
	
	$new_small_logo_image = $_FILES["small_logo"]['name'];
	if($_FILES['small_logo']['name']!=''){
		if ($_FILES['small_logo']['size'] > 52428800){
			$_SESSION['swl_type'] = "error";
			$_SESSION['head'] = "Error !";
			$_SESSION['text'] = "Select image under 50Mb!";
			if(ISSET($_SESSION['swl_type'])){
				header("Refresh:0;");
				exit;
			}
		}	
		else{
			$new_small_logo_image1=$date_ts.'_small_logo_photo.'.pathinfo($new_small_logo_image, PATHINFO_EXTENSION);
			move_uploaded_file($_FILES['small_logo']['tmp_name'],ADD_PHOTO_SERVER_PATH.$new_small_logo_image1);
		}
	}
	else{
		$new_small_logo_image1 = $old_small_logo_image;
	}
		
	$qry = mysqli_query($conn, "UPDATE `site_stng` set `heading` = '".$heading."', `tag_line` = '".$tag_line."', `meta` = '".$meta."', `logo` = '".$new_logo_image1."', `fevicon` = '".$new_fevicon_image1."', `white_logo` = '".$new_white_logo_image1."', `small_logo` = '".$new_small_logo_image1."', `address` = '".$address."', `embed_map` = '".$embed_map."', `video_link` = '".$video_link."',`email` = '".$email."', `mobile` = '".$mobile."', `whatsapp` = '".$whatsapp."', `land_no` = '".$land_no."', `facebook` = '".$facebook."', `instagram` = '".$instagram."', `twitter` = '".$twitter."', `youtube` = '".$youtube."', `notice` = '".$notice."', `sms_key` = '".$sms_key."', `sms_sender` = '".$sms_sender."', `pay_key` = '".$pay_key."', `pay_code` = '".$pay_code."', `count_1` = '".$count_1."', `count_2` = '".$count_2."', `count_3` = '".$count_3."', `count_4` = '".$count_4."', `theme_mode` = '".$theme_mode."', `theme_primary` = '".$theme_primary."', `theme_secondary` = '".$theme_secondary."', `theme_bg` = '".$theme_bg."', `theme_card` = '".$theme_card."', `theme_text` = '".$theme_text."', `date` = '".$date."', `time` = '".$time."' WHERE `id` = '".$id."'") or die($conn->query($qry));
	if($qry){
        if(!empty($new_logo_image1)){
			if($new_logo_image1 != $old_logo_image && !empty($old_logo_image)){
				unlink(ADD_PHOTO_SERVER_PATH.$old_logo_image);
			}
		}
		if(!empty($new_fevicon_image1)){
			if($new_fevicon_image1 != $old_fevicon_image && !empty($old_fevicon_image)){
				unlink(ADD_PHOTO_SERVER_PATH.$old_fevicon_image);
			}
		}
		if(!empty($new_white_logo_image1)){
			if($new_white_logo_image1 != $old_white_logo_image && !empty($old_white_logo_image)){
				unlink(ADD_PHOTO_SERVER_PATH.$old_white_logo_image);
			}
		}
		if(!empty($new_small_logo_logo_image1)){
			if($new_small_logo_image1 != $old_small_logo_image && !empty($old_small_logo_image)){
				unlink(ADD_PHOTO_SERVER_PATH.$old_small_logo_image);
			}
		}
		$_SESSION['swl_type'] = "success";
		$_SESSION['head'] = "Successfull !";
		$_SESSION['text'] = "Site Updates Successfully!";
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

    <div class="card cntnt-start border-rounded shadow-sm mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1">Enter Details Here</h5>
        </div>
        <div class="card-body">
            <form method="post" action="site-stng" enctype="multipart/form-data">
                <div class="card-body card-block">
                    <input type="hidden" name="old_logo" value="<?php echo $stg_result["logo"] ?>">
                    <input type="hidden" name="old_fevicon" value="<?php echo $stg_result["fevicon"] ?>">
                    <input type="hidden" name="old_white_logo" value="<?php echo $stg_result["white_logo"] ?>">
                    <input type="hidden" name="old_small_logo" value="<?php echo $stg_result["small_logo"] ?>">
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Site Title</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="heading" value="<?php echo $stg_result['heading'];?>" >
                            </div>
                        </div>
                        <div class="col-md-8">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Meta Description</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="meta" value="<?php echo $stg_result['meta'];?>" >
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Mobile</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="mobile" value="<?php echo $stg_result['mobile'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Whatsapp</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="whatsapp" value="<?php echo $stg_result['whatsapp'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Email ID</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="email"   value="<?php echo $stg_result['email'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Land-Line</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="land_no" value="<?php echo $stg_result['land_no'];?>" >
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Address</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="address" value="<?php echo $stg_result['address'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Embeded Map</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="embed_map" value="<?php echo $stg_result['embed_map'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> YouTube Video Link</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="video_link" value="<?php echo $stg_result['video_link'];?>" >
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Facebook Link</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="facebook" value="<?php echo $stg_result['facebook'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Instagram Link</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text"  class="form-control" name="instagram" value="<?php echo $stg_result['instagram'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Twitter Link</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="twitter"   value="<?php echo $stg_result['twitter'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>YouTube Channel</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="youtube" value="<?php echo $stg_result['youtube'];?>" >
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row">
                        <div class="col-md-6">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Small Description</label>
                            <div class="input-group input-group-sm mb-3">
                                <textarea type="text" class="form-control h-50" style="height: 120px!important;" name="tag_line" value="<?php echo $stg_result['tag_line'];?>"><?php echo $stg_result['tag_line'];?></textarea>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Notice</label>
                            <div class="input-group input-group-sm mb-3">
                                <textarea type="text" class="form-control h-50" style="height: 120px!important;" name="notice" value="<?php echo $stg_result['notice'];?>"><?php echo $stg_result['notice'];?></textarea>
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Sms Key</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="sms_key" value="<?php echo $stg_result['sms_key'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>SMS Sender</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text"  class="form-control" name="sms_sender" value="<?php echo $stg_result['sms_sender'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Payment Key</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="pay_key" value="<?php echo $stg_result['pay_key'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Payment Code</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="pay_code" value="<?php echo $stg_result['pay_code'];?>" >
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-6 border border-primary shadow p-4">
                            <div class="input-group input-group-sm">
                                <label class="text-dark"><i class="bi bi-check2-all"> </i>Logo Image</label><br>
                                <img class="img-fluid rounded mx-auto d-block img-thumbnail shadow w-25" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$stg_result['logo']; ?>" />
                            </div>
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Logo Image</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="file" class="form-control" name="logo">
                            </div>
                        </div>
                        <div class="col-md-6 border border-primary shadow p-4">
                            <div class="input-group input-group-sm">
                                <label class="text-dark"><i class="bi bi-check2-all"> </i>Fabicon Image</label><br>
                                <img class="img-fluid rounded mx-auto d-block img-thumbnail shadow w-25" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$stg_result['fevicon']; ?>" />
                            </div>
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Fabicon Image</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="file"  class="form-control" name="fevicon">
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-6 border border-primary shadow p-4">
                            <div class="input-group input-group-sm">
                                <label class="text-dark"><i class="bi bi-check2-all"> </i>White Logo Image</label><br>
                                <img class="img-fluid rounded mx-auto d-block img-thumbnail shadow w-25" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$stg_result['white_logo']; ?>" />
                            </div>
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> White Logo Image </label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="file" class="form-control" name="white_logo">
                            </div>
                        </div>
                        <div class="col-md-6 border border-primary shadow p-4">
                            <div class="input-group input-group-sm">
                                <label class="text-dark"><i class="bi bi-check2-all"> </i>Small (Crop) Logo</label><br>
                                <img class="img-fluid rounded mx-auto d-block img-thumbnail shadow w-25" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$stg_result['small_logo']; ?>" />
                            </div>
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Small (Crop) Logo</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="file"  class="form-control" name="small_logo">
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="row mb-3">
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i> Number Count 1</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="count_1" value="<?php echo $stg_result['count_1'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Number Count 2</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" name="count_2" class="form-control"  value="<?php echo $stg_result['count_2'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Number Count 3</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="count_3"   value="<?php echo $stg_result['count_3'];?>" >
                            </div>
                        </div>
                        <div class="col-md-3">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Number Count 4</label>
                            <div class="input-group input-group-sm mb-3">
                                <span class="input-group-text" >✎</span>
                                <input type="text" class="form-control" name="count_4"   value="<?php echo $stg_result['count_4'];?>" >
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <?php
                        $cur_mode = $stg_result['theme_mode'] ?? 'dark';
                        $cur_primary = $stg_result['theme_primary'] ?? '#8b5cf6';
                        $cur_secondary = $stg_result['theme_secondary'] ?? '#6366f1';
                        $cur_bg = $stg_result['theme_bg'] ?? '#0b071e';
                        $cur_card = $stg_result['theme_card'] ?? '#161333';
                        $cur_text = $stg_result['theme_text'] ?? '#f8fafc';
                    ?>
                    <!-- Dynamic Platform Theme & Appearance Settings -->
                    <div class="row mb-4">
                        <div class="col-12">
                            <div class="card shadow-sm border-0" style="border-radius: 16px; overflow: hidden; background: var(--theme-card); border: 1px solid var(--theme-border) !important;">
                                <div class="card-header d-flex align-items-center justify-content-between p-3" style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: #ffffff;">
                                    <div class="d-flex align-items-center gap-2">
                                        <i class="bi bi-palette-fill fs-5"></i>
                                        <div>
                                            <h6 class="mb-0 fw-bold text-white">Dynamic Platform Theme & Appearance</h6>
                                            <small class="text-white-50">Admin-controlled dark/white mode and custom color palettes for the whole platform</small>
                                        </div>
                                    </div>
                                    <span class="badge bg-light text-dark px-3 py-2 rounded-pill fw-bold">Live Synced</span>
                                </div>
                                <div class="card-body p-4" style="background: transparent; color: var(--theme-text);">
                                    
                                    <!-- 1. Theme Mode: Dark vs Light -->
                                    <label class="fw-bold mb-2" style="color: var(--theme-text);"><i class="bi bi-circle-half me-1"></i> 1. Platform Display Mode</label>
                                    <div class="row g-3 mb-4">
                                        <div class="col-md-6">
                                            <label class="theme-mode-card w-100 p-3 rounded-3 border d-flex align-items-center gap-3" id="mode-card-dark" style="cursor: pointer; transition: all 0.2s; background: var(--theme-card); border-color: var(--theme-border) !important;">
                                                <input type="radio" name="theme_mode" value="dark" class="form-check-input mt-0" <?php echo ($cur_mode === 'dark') ? 'checked' : ''; ?> onchange="onModeChange('dark')">
                                                <div class="d-flex align-items-center justify-content-center rounded-circle" style="width: 44px; height: 44px; background: #0b071e; color: #a78bfa;">
                                                    <i class="bi bi-moon-stars-fill fs-5"></i>
                                                </div>
                                                <div>
                                                    <div class="fw-bold" style="color: var(--theme-text);">🌙 Dark Mode (Signature)</div>
                                                    <small class="text-muted">High-tech deep space canvas with ambient glow & glassmorphism</small>
                                                </div>
                                            </label>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="theme-mode-card w-100 p-3 rounded-3 border d-flex align-items-center gap-3" id="mode-card-light" style="cursor: pointer; transition: all 0.2s; background: var(--theme-card); border-color: var(--theme-border) !important;">
                                                <input type="radio" name="theme_mode" value="light" class="form-check-input mt-0" <?php echo ($cur_mode === 'light') ? 'checked' : ''; ?> onchange="onModeChange('light')">
                                                <div class="d-flex align-items-center justify-content-center rounded-circle" style="width: 44px; height: 44px; background: #f1f5f9; color: #f59e0b;">
                                                    <i class="bi bi-sun-fill fs-5"></i>
                                                </div>
                                                <div>
                                                    <div class="fw-bold" style="color: var(--theme-text);">☀️ Light / White Mode</div>
                                                    <small class="text-muted">Ultra-clean, crisp white canvas with soft modern drop-shadows</small>
                                                </div>
                                            </label>
                                        </div>
                                    </div>

                                    <!-- 2. One-Click Curated Presets -->
                                    <div class="d-flex align-items-center justify-content-between mb-2">
                                        <label class="fw-bold mb-0" style="color: var(--theme-text);"><i class="bi bi-magic me-1"></i> 2. Curated 1-Click Color Presets</label>
                                        <small class="text-muted">Click any preset to fill color pickers</small>
                                    </div>
                                    <div class="d-flex flex-wrap gap-2 mb-4">
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('cyber-violet')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #8b5cf6;"></span> Cyber Violet (Dark)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('midnight-azure')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #38bdf8;"></span> Midnight Azure (Dark)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('emerald-matrix')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #10b981;"></span> Emerald Matrix (Dark)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('obsidian-gold')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #eab308;"></span> Obsidian Gold (Dark)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('crimson-blaze')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #f43f5e;"></span> Crimson Blaze (Dark)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('clean-minimal')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #6366f1; border: 1px solid #ccc;"></span> Clean Minimal (Light)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('arctic-frost')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #0284c7; border: 1px solid #ccc;"></span> Arctic Frost (Light)
                                        </button>
                                        <button type="button" class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 fw-semibold d-inline-flex align-items-center gap-2" onclick="applyPreset('emerald-fresh')">
                                            <span class="rounded-circle" style="width: 12px; height: 12px; background: #059669; border: 1px solid #ccc;"></span> Emerald Fresh (Light)
                                        </button>
                                    </div>

                                    <!-- 3. Free Color Pickers & Live Preview Grid -->
                                    <div class="row g-4">
                                        <div class="col-lg-7">
                                            <label class="fw-bold mb-2" style="color: var(--theme-text);"><i class="bi bi-eyedropper me-1"></i> 3. Free Custom Color Pickers</label>
                                            
                                            <div class="row g-3">
                                                <!-- Primary Accent -->
                                                <div class="col-md-6">
                                                    <label class="form-label small fw-semibold mb-1" style="color: var(--theme-text);">Primary Brand Accent</label>
                                                    <div class="input-group">
                                                        <input type="color" class="form-control form-control-color border-end-0" id="picker_theme_primary" value="<?php echo $cur_primary; ?>" oninput="syncColorInput('theme_primary', this.value)" style="width: 50px; height: 38px; cursor: pointer; padding: 2px;">
                                                        <input type="text" class="form-control font-monospace" name="theme_primary" id="input_theme_primary" value="<?php echo $cur_primary; ?>" oninput="syncPickerInput('theme_primary', this.value)">
                                                    </div>
                                                    <small class="text-muted">Buttons, active badges, highlights</small>
                                                </div>

                                                <!-- Secondary Accent -->
                                                <div class="col-md-6">
                                                    <label class="form-label small fw-semibold mb-1" style="color: var(--theme-text);">Secondary / Gradient End</label>
                                                    <div class="input-group">
                                                        <input type="color" class="form-control form-control-color border-end-0" id="picker_theme_secondary" value="<?php echo $cur_secondary; ?>" oninput="syncColorInput('theme_secondary', this.value)" style="width: 50px; height: 38px; cursor: pointer; padding: 2px;">
                                                        <input type="text" class="form-control font-monospace" name="theme_secondary" id="input_theme_secondary" value="<?php echo $cur_secondary; ?>" oninput="syncPickerInput('theme_secondary', this.value)">
                                                    </div>
                                                    <small class="text-muted">Button gradients & glow aura</small>
                                                </div>

                                                <!-- Canvas Background -->
                                                <div class="col-md-6">
                                                    <label class="form-label small fw-semibold mb-1" style="color: var(--theme-text);">Canvas Background</label>
                                                    <div class="input-group">
                                                        <input type="color" class="form-control form-control-color border-end-0" id="picker_theme_bg" value="<?php echo $cur_bg; ?>" oninput="syncColorInput('theme_bg', this.value)" style="width: 50px; height: 38px; cursor: pointer; padding: 2px;">
                                                        <input type="text" class="form-control font-monospace" name="theme_bg" id="input_theme_bg" value="<?php echo $cur_bg; ?>" oninput="syncPickerInput('theme_bg', this.value)">
                                                    </div>
                                                    <small class="text-muted">Main page canvas background</small>
                                                </div>

                                                <!-- Card Background -->
                                                <div class="col-md-6">
                                                    <label class="form-label small fw-semibold mb-1" style="color: var(--theme-text);">Card / Surface Background</label>
                                                    <div class="input-group">
                                                        <input type="color" class="form-control form-control-color border-end-0" id="picker_theme_card" value="<?php echo $cur_card; ?>" oninput="syncColorInput('theme_card', this.value)" style="width: 50px; height: 38px; cursor: pointer; padding: 2px;">
                                                        <input type="text" class="form-control font-monospace" name="theme_card" id="input_theme_card" value="<?php echo $cur_card; ?>" oninput="syncPickerInput('theme_card', this.value)">
                                                    </div>
                                                    <small class="text-muted">Panels, cards, widgets</small>
                                                </div>

                                                <!-- Text Color -->
                                                <div class="col-md-6">
                                                    <label class="form-label small fw-semibold mb-1" style="color: var(--theme-text);">Primary Text Color</label>
                                                    <div class="input-group">
                                                        <input type="color" class="form-control form-control-color border-end-0" id="picker_theme_text" value="<?php echo $cur_text; ?>" oninput="syncColorInput('theme_text', this.value)" style="width: 50px; height: 38px; cursor: pointer; padding: 2px;">
                                                        <input type="text" class="form-control font-monospace" name="theme_text" id="input_theme_text" value="<?php echo $cur_text; ?>" oninput="syncPickerInput('theme_text', this.value)">
                                                    </div>
                                                    <small class="text-muted">Headings, values & primary labels</small>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Live Preview Box -->
                                        <div class="col-lg-5">
                                            <label class="fw-bold mb-2" style="color: var(--theme-text);"><i class="bi bi-tv me-1"></i> Real-time Live Preview</label>
                                            <div id="live-theme-preview" class="p-3 rounded-4 shadow-sm position-relative overflow-hidden" style="min-height: 270px; transition: all 0.3s ease; border: 1px solid rgba(0,0,0,0.1);">
                                                <!-- Header Mockup -->
                                                <div class="d-flex align-items-center justify-content-between pb-2 mb-3 border-bottom" style="border-color: rgba(255,255,255,0.1) !important;" id="preview-header">
                                                    <div class="d-flex align-items-center gap-2">
                                                        <div class="rounded-circle d-flex align-items-center justify-content-center fw-bold" id="preview-logo-badge" style="width: 28px; height: 28px; font-size: 11px; color: #fff;">OM</div>
                                                        <span class="fw-bold fs-6" id="preview-site-title"><?php echo htmlspecialchars($stg_result['heading']); ?></span>
                                                    </div>
                                                    <span class="badge rounded-pill" id="preview-badge" style="font-size: 11px;">VIP Pro</span>
                                                </div>

                                                <!-- Balance Card Mockup -->
                                                <div class="p-3 rounded-3 mb-3" id="preview-card" style="transition: all 0.3s ease;">
                                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                                        <small id="preview-card-muted" style="font-size: 12px;">Available Balance</small>
                                                        <span class="badge bg-success" style="font-size: 10px;">Synced</span>
                                                    </div>
                                                    <div class="fs-4 fw-bold mb-2" id="preview-balance">₹ 24,500.00</div>
                                                    <div class="d-flex gap-2">
                                                        <button type="button" class="btn btn-sm w-100 fw-bold" id="preview-btn" style="border-radius: 8px; font-size: 12px; color: #fff;">Recharge</button>
                                                        <button type="button" class="btn btn-sm w-100 border text-muted" id="preview-btn-sub" style="border-radius: 8px; font-size: 12px; background: rgba(128,128,128,0.08);">Withdraw</button>
                                                    </div>
                                                </div>

                                                <!-- Feature tags -->
                                                <div class="d-flex gap-1 justify-content-center">
                                                    <span class="badge" id="preview-tag-1" style="font-size: 11px; padding: 4px 8px; background: rgba(128,128,128,0.15);">Dynamic Theme</span>
                                                    <span class="badge" id="preview-tag-2" style="font-size: 11px; padding: 4px 8px; background: rgba(128,128,128,0.15);">Custom CSS</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </div>

                    <script>
                        const themePresets = {
                            'cyber-violet': {
                                mode: 'dark',
                                primary: '#8b5cf6',
                                secondary: '#6366f1',
                                bg: '#0b071e',
                                card: '#161333',
                                text: '#f8fafc'
                            },
                            'midnight-azure': {
                                mode: 'dark',
                                primary: '#38bdf8',
                                secondary: '#2563eb',
                                bg: '#050e1d',
                                card: '#0b1c36',
                                text: '#f8fafc'
                            },
                            'emerald-matrix': {
                                mode: 'dark',
                                primary: '#10b981',
                                secondary: '#059669',
                                bg: '#05140f',
                                card: '#0d281e',
                                text: '#f8fafc'
                            },
                            'obsidian-gold': {
                                mode: 'dark',
                                primary: '#eab308',
                                secondary: '#d97706',
                                bg: '#0f0c05',
                                card: '#231c0a',
                                text: '#f8fafc'
                            },
                            'crimson-blaze': {
                                mode: 'dark',
                                primary: '#f43f5e',
                                secondary: '#e11d48',
                                bg: '#140508',
                                card: '#280a12',
                                text: '#f8fafc'
                            },
                            'clean-minimal': {
                                mode: 'light',
                                primary: '#6366f1',
                                secondary: '#8b5cf6',
                                bg: '#f8fafc',
                                card: '#ffffff',
                                text: '#0f172a'
                            },
                            'arctic-frost': {
                                mode: 'light',
                                primary: '#0284c7',
                                secondary: '#2563eb',
                                bg: '#f0f9ff',
                                card: '#ffffff',
                                text: '#0c4a6e'
                            },
                            'emerald-fresh': {
                                mode: 'light',
                                primary: '#059669',
                                secondary: '#10b981',
                                bg: '#f0fdf4',
                                card: '#ffffff',
                                text: '#064e3b'
                            }
                        };

                        function syncColorInput(field, val) {
                            document.getElementById('input_' + field).value = val;
                            updateLivePreview();
                        }

                        function syncPickerInput(field, val) {
                            if (/^#[0-9A-F]{6}$/i.test(val)) {
                                document.getElementById('picker_' + field).value = val;
                            }
                            updateLivePreview();
                        }

                        function onModeChange(mode) {
                            const darkCard = document.getElementById('mode-card-dark');
                            const lightCard = document.getElementById('mode-card-light');
                            if (mode === 'dark') {
                                darkCard.classList.add('border-primary', 'shadow-sm');
                                lightCard.classList.remove('border-primary', 'shadow-sm');
                            } else {
                                lightCard.classList.add('border-primary', 'shadow-sm');
                                darkCard.classList.remove('border-primary', 'shadow-sm');
                            }
                            updateLivePreview();
                        }

                        function applyPreset(presetKey) {
                            const p = themePresets[presetKey];
                            if (!p) return;

                            // Set mode
                            const radio = document.querySelector(`input[name="theme_mode"][value="${p.mode}"]`);
                            if (radio) {
                                radio.checked = true;
                                onModeChange(p.mode);
                            }

                            // Set colors
                            const fields = ['primary', 'secondary', 'bg', 'card', 'text'];
                            fields.forEach(f => {
                                const key = 'theme_' + f;
                                const val = p[f];
                                const picker = document.getElementById('picker_' + key);
                                const input = document.getElementById('input_' + key);
                                if (picker) picker.value = val;
                                if (input) input.value = val;
                            });

                            updateLivePreview();
                        }

                        function updateLivePreview() {
                            const modeInput = document.querySelector('input[name="theme_mode"]:checked');
                            const mode = modeInput ? modeInput.value : 'dark';
                            const primary = document.getElementById('input_theme_primary').value || '#8b5cf6';
                            const secondary = document.getElementById('input_theme_secondary').value || '#6366f1';
                            const bg = document.getElementById('input_theme_bg').value || '#0b071e';
                            const card = document.getElementById('input_theme_card').value || '#161333';
                            const text = document.getElementById('input_theme_text').value || '#f8fafc';

                            const preview = document.getElementById('live-theme-preview');
                            if (!preview) return;

                            preview.style.backgroundColor = bg;
                            preview.style.color = text;
                            preview.style.borderColor = mode === 'dark' ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.08)';

                            const siteTitle = document.getElementById('preview-site-title');
                            if (siteTitle) siteTitle.style.color = text;

                            const logoBadge = document.getElementById('preview-logo-badge');
                            if (logoBadge) {
                                logoBadge.style.background = `linear-gradient(135deg, ${secondary} 0%, ${primary} 100%)`;
                            }

                            const badge = document.getElementById('preview-badge');
                            if (badge) {
                                badge.style.background = `linear-gradient(135deg, ${secondary} 0%, ${primary} 100%)`;
                                badge.style.color = '#ffffff';
                            }

                            const cardEl = document.getElementById('preview-card');
                            if (cardEl) {
                                cardEl.style.backgroundColor = card;
                                cardEl.style.border = mode === 'dark' ? `1px solid ${primary}40` : '1px solid rgba(0,0,0,0.08)';
                                cardEl.style.boxShadow = mode === 'dark' ? '0 6px 20px rgba(0,0,0,0.3)' : '0 4px 15px rgba(0,0,0,0.05)';
                            }

                            const cardMuted = document.getElementById('preview-card-muted');
                            if (cardMuted) {
                                cardMuted.style.color = mode === 'dark' ? '#94a3b8' : '#64748b';
                            }

                            const balance = document.getElementById('preview-balance');
                            if (balance) balance.style.color = text;

                            const btn = document.getElementById('preview-btn');
                            if (btn) {
                                btn.style.background = `linear-gradient(135deg, ${secondary} 0%, ${primary} 100%)`;
                                btn.style.color = '#ffffff';
                                btn.style.boxShadow = `0 3px 12px ${primary}55`;
                            }

                            const btnSub = document.getElementById('preview-btn-sub');
                            if (btnSub) {
                                btnSub.style.borderColor = mode === 'dark' ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)';
                                btnSub.style.color = mode === 'dark' ? '#cbd5e1' : '#475569';
                            }
                        }

                        // Run on load
                        document.addEventListener('DOMContentLoaded', function() {
                            const curMode = '<?php echo $cur_mode; ?>';
                            onModeChange(curMode);
                            updateLivePreview();
                        });
                    </script>
                    <hr class="ml-100">
                    <div class="d-flex gap-3 mb-3">
                        <button name="site_stng" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect w-50">
                        <i class="bi bi-check me-2"></i> UPDATE
                        </button>
                        <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect w-50">
                        <i class="bi bi-x me-2"></i> RESET 
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