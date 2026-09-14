<?php
require 'office/partials/_dbconnect.php';

function get_safe_value($conn,$str){
	if($str!=''){
		$str=trim($str);
		return mysqli_real_escape_string($conn,$str);
	}
}

if(isset($_POST['add_subscribe'])){
	$book_id=get_safe_value($conn,$_POST['book_id']);
	$user_id = $_SESSION['user_id'];
	$qryusrdetls = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$user_id'") or die(mysqli_error());
    $rmusrdetls = mysqli_fetch_array($qryusrdetls);
	$agency_id = $rmusrdetls['agency_id'];
	$read_status = "PENDING";
	$stage_status = "PENDING";
	$show_status = "ACTIVE";
	if($rmusrdetls['agency_id'] == 1){
		$user_under = "ADMIN";
	} else {
		$user_under = "AGENCY";
	}	
	$qrymctpp = mysqli_query($conn, "INSERT INTO `subscription`(`user_id`, `book_id`, `emp_id`, `stage_status`, `read_status`, `show_status`, `user_under`, `date_ts`) VALUES ('$user_id', '$book_id', '$agency_id', '$stage_status', '$read_status', '$show_status', '$user_under', '$date_ts')") or die(mysqli_error());
    $rmctpp = mysqli_fetch_array($qrymctpp);
	echo $rmctpp;
}

if(isset($_POST['price_amount_id'])){
    $price_amount = get_safe_value($conn, $_POST['price_amount_id']);
	$user_id = $_SESSION['user_id'];
	$range_id = '';
	
	$qryusrdetls = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$user_id'") or die(mysqli_error());
    $rmusrdetls = mysqli_fetch_array($qryusrdetls);
	$agency_id = $rmusrdetls['agency_id'];
	$collect_limit = $rmusrdetls['collect_limit'];

	//Check agency Recharge Limit
	$inhandamt = mysqli_fetch_array(mysqli_query($conn, "SELECT * FROM `agency_cash_book` WHERE agency_id = '$agency_id'"));
	$agency_recharge_live_limit = $inhandamt['recharge_limit_live'];
	
	$qrygetrange = mysqli_query($conn, "SELECT * FROM `pricerange` WHERE CAST(price_start AS UNSIGNED) <= '$price_amount' AND CAST(price_end AS UNSIGNED) >= '$price_amount' AND show_status = 'ACTIVE'") or die(mysqli_error($conn));
	$rmprcrange = mysqli_fetch_array($qrygetrange);
	if(mysqli_num_rows($qrygetrange)>0){
		$range_id = $rmprcrange['id'];
		if($agency_recharge_live_limit > $price_amount){
			$qryprcrange = mysqli_query($conn, "SELECT * FROM `qrcode` WHERE range_id = '$range_id' AND emp_id = '$agency_id' AND show_status = 'ACTIVE' LIMIT 1") or die(mysqli_error($conn));
			$rmprcrange = mysqli_fetch_array($qryprcrange);
		} else {
			$agency_id = 1;
			$qryprcrange = mysqli_query($conn, "SELECT * FROM `qrcode` WHERE range_id = '$range_id' AND emp_id = '$agency_id' AND show_status = 'ACTIVE' LIMIT 1") or die(mysqli_error($conn));
			$rmprcrange = mysqli_fetch_array($qryprcrange);
		}
		if(mysqli_num_rows($qryprcrange)>0){
			$html = '<img src="'.$m_url.''.ADD_PHOTO_SITE_PATH.$rmprcrange['image'].'" style="width: 200px; margin: 0 auto; display: block; margin-bottom: 20px;">
					<p class="text-center fw-5 fs-4">Scan this QR code to recharge your wallet.</p>
					<input type="hidden" name="qr_id" value="'.$rmprcrange['id'].'">
					<input type="hidden" name="emp_id" value="'.$agency_id.'">
					<input type="hidden" name="range_id" value="'.$range_id.'">					
					';
		} else {
			$html = '<p class="text-center fw-5 fs-4">Only Cash Transaction Available.</p>
					<input type="hidden" name="qr_id" value="">
					<input type="hidden" name="emp_id" value="'.$agency_id.'">
					<input type="hidden" name="range_id" value="'.$range_id.'">
					';
		}
	}else{
		$html = '<p class="text-center fw-5 fs-4">Only Cash Transaction Available.</p>
					<input type="hidden" name="qr_id" value="">
					<input type="hidden" name="emp_id" value="'.$agency_id.'">
					<input type="hidden" name="range_id" value="'.$range_id.'">
					';
	}
	echo $html;
}

?>