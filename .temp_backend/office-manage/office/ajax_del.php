<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

function get_safe_value($conn,$str){
	if($str!=''){
		$str=trim($str);
		return mysqli_real_escape_string($conn,$str);
	}
}

if(isset($_POST['status_cmstable'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$active = "ACTIVE";
	$inactive = "INACTIVE";
	$res=mysqli_query($conn,"select * from cmstable where id='$status_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['show_status'];
	if($status == "ACTIVE"){
		mysqli_query($conn, "UPDATE `cmstable` set `show_status` = '".$inactive."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
	else{
		mysqli_query($conn, "UPDATE `cmstable` set `show_status` = '".$active."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
}
if(isset($_POST['del_cmstable'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$image=get_safe_value($conn,$_POST['delete_image']);
	$qry_d = "DELETE FROM `cmstable` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
	if($image !=''){
		unlink(ADD_PHOTO_SERVER_PATH.$image);
	}
}
if(isset($_POST['del_cmstable_video'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$image=get_safe_value($conn,$_POST['delete_image']);
	$video=get_safe_value($conn,$_POST['delete_video']);
	$qry_d = "DELETE FROM `cmstable` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
	if($image !=''){
		unlink(ADD_PHOTO_SERVER_PATH.$image);
	}
	if($video !=''){
		unlink(ADD_VIDEO_SERVER_PATH.$video);
	}
}

if(isset($_POST['status_feature'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$active = "ACTIVE";
	$inactive = "INACTIVE";
	$res=mysqli_query($conn,"select * from features where id='$status_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['show_status'];
	if($status == "ACTIVE"){
		mysqli_query($conn, "UPDATE `features` set `show_status` = '".$inactive."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
	else{
		mysqli_query($conn, "UPDATE `features` set `show_status` = '".$active."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
}
if(isset($_POST['del_feature'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$image=get_safe_value($conn,$_POST['delete_image']);
	$res=mysqli_query($conn,"select * from project_images where project_id='$id'");
	if(mysqli_num_rows($res)>0){
		while($result5 = mysqli_fetch_array($res)){
			$image1 = $result5['image'];
			$id1 = $result5['id'];
			$qry_d1 = "DELETE FROM `project_images` WHERE id='".$id1."'";
			$qry_del1 = mysqli_query($conn, $qry_d1);
			if($image1 !=''){
				unlink(ADD_PHOTO_SERVER_PATH.$image1);
			}
		}
	}
	$qry_d = "DELETE FROM `features` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
	if($image !=''){
		unlink(ADD_PHOTO_SERVER_PATH.$image);
	}
}

if(isset($_POST['status_users'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$active = "ACTIVE";
	$inactive = "INACTIVE";
	$res=mysqli_query($conn,"select * from users where id='$status_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['show_status'];
	if($status == "ACTIVE"){
		mysqli_query($conn, "UPDATE `users` set `show_status` = '".$inactive."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
	else{
		mysqli_query($conn, "UPDATE `users` set `show_status` = '".$active."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
}
if(isset($_POST['status_user_profit_loss'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$active = "ACTIVE";
	$inactive = "INACTIVE";
	$res=mysqli_query($conn,"select * from users where id='$status_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['profit_loss_status'];
	if($status == "ACTIVE"){
		mysqli_query($conn, "UPDATE `users` set `profit_loss_status` = '".$inactive."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
	else{
		mysqli_query($conn, "UPDATE `users` set `profit_loss_status` = '".$active."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
}
if(isset($_POST['status_agency_featured'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$res_u = mysqli_query($conn, "SELECT `type`, `agency_id` FROM `users` WHERE `id` = '$status_id'");
	if($res_u && mysqli_num_rows($res_u) > 0){
		$u_row = mysqli_fetch_assoc($res_u);
		$u_type = $u_row['type'];
		$curr_status = $u_row['agency_id'];
	} else {
		$u_type = 'AGENCY';
		$curr_status = '';
	}

	// First check: agency must have at least 1 QR code on every price range to be eligible for FEATURED
	if($curr_status != 'FEATURED'){
		$res_pr = mysqli_query($conn, "SELECT `id` FROM `pricerange` WHERE `show_status` = 'ACTIVE'");
		if(!$res_pr || mysqli_num_rows($res_pr) == 0){
			$res_pr = mysqli_query($conn, "SELECT `id` FROM `pricerange`");
		}
		if($res_pr && mysqli_num_rows($res_pr) > 0){
			while($pr_row = mysqli_fetch_assoc($res_pr)){
				$range_id = $pr_row['id'];
				$qr_check = mysqli_query($conn, "SELECT `id` FROM `qrcode` WHERE `emp_id` = '$status_id' AND `range_id` = '$range_id'");
				if(!$qr_check || mysqli_num_rows($qr_check) == 0){
					echo "MISSING_QR_CODES";
					exit;
				}
			}
		}
	}

	$res_cnt = mysqli_query($conn, "SELECT COUNT(*) as total FROM `users` WHERE `type` = '$u_type'");
	$row_cnt = mysqli_fetch_assoc($res_cnt);
	$total_agencies = isset($row_cnt['total']) ? (int)$row_cnt['total'] : 0;

	if ($total_agencies <= 1) {
		mysqli_query($conn, "UPDATE `users` SET `agency_id` = 'FEATURED' WHERE `type` = '$u_type'");
		echo "ONLY_ONE_AGENCY";
		exit;
	}

	$res=mysqli_query($conn,"select * from users where id='$status_id' and type='$u_type'");
	if($res && mysqli_num_rows($res) > 0){
		$result5 = mysqli_fetch_array($res);
		$status = $result5['agency_id'];
		if($status == "FEATURED"){
			mysqli_query($conn, "UPDATE `users` set `agency_id` = 'NON-FEATURED' WHERE `id` = '".$status_id."' and `type` = '$u_type'") or die(mysqli_error($conn));
		}
		else{
			mysqli_query($conn, "UPDATE `users` set `agency_id` = 'NON-FEATURED' WHERE `type` = '$u_type'") or die(mysqli_error($conn));
			mysqli_query($conn, "UPDATE `users` set `agency_id` = 'FEATURED' WHERE `id` = '".$status_id."' and `type` = '$u_type'") or die(mysqli_error($conn));
		}
	}
}
if(isset($_POST['del_users'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$image=get_safe_value($conn,$_POST['delete_image']);
	$qry_d = "DELETE FROM `users` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
	if($image !=''){
		unlink(ADD_PHOTO_SERVER_PATH.$image);
	}
	$res_cnt = mysqli_query($conn, "SELECT COUNT(*) as total FROM `users` WHERE `type` = 'AGENCY'");
	if($res_cnt && $row_cnt = mysqli_fetch_assoc($res_cnt)){
		if((int)$row_cnt['total'] === 1){
			mysqli_query($conn, "UPDATE `users` SET `agency_id` = 'FEATURED' WHERE `type` = 'AGENCY'");
		}
	}
}

if(isset($_POST['admin_message_upd_status'])){
	$qte_id=get_safe_value($conn,$_POST['qte_id']);
	$status = "READ";
	$res=mysqli_query($conn,"select * from contact where id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$old_status = $result5['read_status'];
	if($old_status != $status){
		mysqli_query($conn, "UPDATE `contact` set `read_status` = '".$status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	else{
	}
}
if(isset($_POST['del_contact'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$qry_d = "DELETE FROM `contact` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
}

if(isset($_POST['admin_user_req_upd_status'])){
	$qte_id=get_safe_value($conn,$_POST['qte_id']);
	$status = "READ";
	$res=mysqli_query($conn,"select * from users where id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$old_status = $result5['read_status'];
	if($old_status != $status){
		mysqli_query($conn, "UPDATE `users` set `read_status` = '".$status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	else{
	}
}
if(isset($_POST['del_users'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$qry_d = "DELETE FROM `users` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
}

if(isset($_POST['status_range'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$active = "ACTIVE";
	$inactive = "INACTIVE";
	$res=mysqli_query($conn,"select * from pricerange where id='$status_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['show_status'];
	if($status == "ACTIVE"){
		mysqli_query($conn, "UPDATE `pricerange` set `show_status` = '".$inactive."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
	else{
		mysqli_query($conn, "UPDATE `pricerange` set `show_status` = '".$active."' WHERE `id` = '".$status_id."'") or die(mysqli_error());
	}
}
if(isset($_POST['del_range'])){
	$id=get_safe_value($conn,$_POST['delete_id']);
	$res=mysqli_query($conn,"select * from qrcode where range_id='$id'");
	if(mysqli_num_rows($res)>0){
		while($result5 = mysqli_fetch_array($res)){
			$id1 = $result5['id'];
			$qry_d1 = "DELETE FROM `qrcode` WHERE id='".$id1."'";
			$qry_del1 = mysqli_query($conn, $qry_d1);
		}
	}
	$qry_d = "DELETE FROM `pricerange` WHERE id='".$id."'";
	$qry_del = mysqli_query($conn, $qry_d);
}

if(isset($_POST['status_qrcode'])){
	$status_id=get_safe_value($conn,$_POST['status_id']);
	$res=mysqli_query($conn,"select * from qrcode where id='$status_id'");
	if($res && mysqli_num_rows($res) > 0) {
		$result5 = mysqli_fetch_array($res);
		$status = $result5['show_status'];
		$range_id = $result5['range_id'];
		$emp_id = $result5['emp_id'];
		if($status == "INACTIVE"){
			mysqli_query($conn, "UPDATE `qrcode` set `show_status` = 'INACTIVE' WHERE `range_id` = '$range_id' AND `emp_id` = '$emp_id'");
			mysqli_query($conn, "UPDATE `qrcode` set `show_status` = 'ACTIVE' WHERE `id` = '$status_id'");
		}
	}
}

if(isset($_POST['admin_recharge_req_upd_status'])){
	$qte_id=get_safe_value($conn,$_POST['qte_id']);
	$status = "READ";
	$res=mysqli_query($conn,"select * from recharge where id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$old_status = $result5['agency_read_status'];
	if($old_status != $status){
		mysqli_query($conn, "UPDATE `recharge` set `agency_read_status` = '".$status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	else{
	}
}

if(isset($_POST['admin_subscription_req_upd_status'])){
	$qte_id=get_safe_value($conn,$_POST['qte_id']);
	$status = "READ";
	$res=mysqli_query($conn,"select * from subscription where id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$old_status = $result5['read_status'];
	if($old_status != $status){
		mysqli_query($conn, "UPDATE `subscription` set `read_status` = '".$status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	else{
	}
}
if(isset($_POST['get_banks_by_agency'])){
	$agency_id = get_safe_value($conn, $_POST['agency_id']);
	$html = '<span class="input-group-text" id="basic-addon1">✎</span>
             <select class="form-select" name="bank_id">
                 <option value="">All Banks</option>';
	
	$qry = "SELECT DISTINCT bank_slag, bank_name FROM recharge WHERE bank_slag != '' AND bank_name != ''";
    if(isset($_SESSION['u_type']) && $_SESSION['u_type'] == "ADMIN"){
        if($agency_id != ''){
            $qry .= " AND emp_id = '".$agency_id."'";
        }
    } else {
        $qry .= " AND emp_id = '".$_SESSION['u_id']."'";
    }
    $qry .= " ORDER BY bank_name ASC";
    
	$res = mysqli_query($conn, $qry);
	if($res){
		while($row = mysqli_fetch_array($res)){
			$html .= '<option value="'.$row['bank_slag'].'">'.$row['bank_name'].'</option>';
		}
	}
	$html .= '</select>';
	echo $html;
    exit;
}

if(isset($_POST['get_users_by_agency'])){
	$agency_id = get_safe_value($conn, $_POST['agency_id']);
	$html = '<span class="input-group-text" id="basic-addon1">✎</span>
             <select class="form-select" name="emp_id">
                 <option value="">All Users</option>';
	
	$qry = "SELECT DISTINCT u.id, u.name FROM recharge r INNER JOIN users u ON r.user_id = u.id";
    if(isset($_SESSION['u_type']) && $_SESSION['u_type'] == "ADMIN"){
        if($agency_id != ''){
            $qry .= " WHERE r.emp_id = '".$agency_id."'";
        }
    } else {
        $qry .= " WHERE r.emp_id = '".$_SESSION['u_id']."'";
    }
    $qry .= " ORDER BY u.name ASC";
    
	$res = mysqli_query($conn, $qry);
	if($res){
		while($row = mysqli_fetch_array($res)){
			$html .= '<option value="'.$row['id'].'">'.$row['name'].'</option>';
		}
	}
	$html .= '</select>';
	echo $html;
    exit;
}

if(isset($_POST['emp_recharge_req_upd_status'])){
	$qte_id = get_safe_value($conn, $_POST['qte_id']);
	$read = "READ";
	$stage_status = "EMPLOYEE-PENDING";
	$res = mysqli_query($conn, "SELECT * FROM recharge WHERE id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['employee_read_status'];
	if($status != $read){
		mysqli_query($conn, "UPDATE `recharge` SET `employee_read_status` = '".$read."', `agency_read_status` = '".$read."', `stage_status` = '".$stage_status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	echo '<i class="bi bi-eye"></i>';
    exit;
}

if(isset($_POST['emp_withdraw_req_upd_status'])){
	$qte_id = get_safe_value($conn, $_POST['qte_id']);
	$read = "READ";
	$stage_status = "EMPLOYEE-PENDING";
	$res = mysqli_query($conn, "SELECT * FROM withdrawal WHERE id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['employee_read_status'];
	if($status != $read){
		mysqli_query($conn, "UPDATE `withdrawal` SET `employee_read_status` = '".$read."', `stage_status` = '".$stage_status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	echo '<i class="bi bi-eye"></i>';
    exit;
}

if(isset($_POST['agency_withdraw_req_upd_status'])){
	$qte_id = get_safe_value($conn, $_POST['qte_id']);
	$read = "READ";
	$stage_status = "AGENCY-PENDING";
	$res = mysqli_query($conn, "SELECT * FROM withdrawal WHERE id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$status = $result5['agency_read_status'];
	if($status != $read){
		mysqli_query($conn, "UPDATE `withdrawal` SET `agency_read_status` = '".$read."', `stage_status` = '".$stage_status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	echo '<i class="bi bi-eye"></i>';
    exit;
}

if(isset($_POST['update_money_receivable'])){
	$status_id = get_safe_value($conn, $_POST['status_id']);
	$receivable = "ADMIN-RECEIVABLE";
	$res = mysqli_query($conn, "SELECT * FROM features WHERE id='$status_id'");
	$result5 = mysqli_fetch_array($res);
	$order_no = $result5['order_no'];
	$status = isset($result5['admin_payment_receive']) ? $result5['admin_payment_receive'] : '';

	if($status == $receivable){
		mysqli_query($conn, "UPDATE `features` SET `admin_payment_receive` = '' WHERE `id` = '".$status_id."'") or die(mysqli_error($conn));
	} else {
		mysqli_query($conn, "UPDATE `features` SET `admin_payment_receive` = '' WHERE `order_no` = '".$order_no."'") or die(mysqli_error($conn));
		mysqli_query($conn, "UPDATE `features` SET `admin_payment_receive` = '".$receivable."' WHERE `id` = '".$status_id."'") or die(mysqli_error($conn));
	}
	exit;
}

if(isset($_POST['emp_agency_payment_req_upd_status'])){
	$qte_id = get_safe_value($conn, $_POST['qte_id']);
	$read = "READ";
	$stage_status = "EMPLOYEE-PENDING";
	$res = mysqli_query($conn, "SELECT * FROM pay_to_admin WHERE id='$qte_id'");
	$result5 = mysqli_fetch_array($res);
	$status = isset($result5['read_status']) ? $result5['read_status'] : 'PENDING';
	if($status != $read){
		mysqli_query($conn, "UPDATE `pay_to_admin` SET `read_status` = '".$read."', `stage_status` = '".$stage_status."' WHERE `id` = '".$qte_id."'") or die(mysqli_error());
	}
	echo '<i class="bi bi-eye"></i>';
    exit;
}
if(isset($_POST['emp_user_bank_ac_upd_status'])){
    $qte_id = get_safe_value($conn, $_POST['qte_id']);
    $read = "READ";
    $res = mysqli_query($conn, "SELECT * FROM user_payment_accounts WHERE id='$qte_id'");
    $result5 = mysqli_fetch_array($res);
    $status = $result5['read_status'];
    if($status != $read){
        mysqli_query($conn, "UPDATE `user_payment_accounts` SET `read_status` = '$read' WHERE `id` = '$qte_id'") or die(mysqli_error($conn));
    }
    echo 1;
    exit;
}
?>