<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
$date_ts = time();
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
            <div>
                <button type="button" onclick="exportTableToExcel('example', 'payments_record')" class="btn btn_success btn-sm me-2">Export to Excel <i class="bi bi-file-earmark-excel ms-1"></i></button>
                <button type="button" data-bs-toggle="modal" data-bs-target="#insert_partnr" class="btn btn_warning btn-sm">Search Payments <i class="bi bi-search ms-1"></i></button>
            </div>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong> Payment Records </strong> List</h5>
        </div>
        <div class="card-body pb-0">
			<!-- Modal Dialog for Search -->
            <div class="modal fade mt-4 pt-4" id="insert_partnr" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!important;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1 w-100 align-items-center">
                                <div class="col-8 text-start">
                                    <h5 class="modal-title text-white"><b>Search Payments</b></h5>
                                </div>
                                <div class="col-4 text-end">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                        <form class="row" action="payments-record" method="get" id="form">
                            <div class="card-body card-block">
								<?php
									$to_date = date('Y-m-d');
									$from_date = date('Y-m-d');
                                    $stage_status = "";
                                    $payment_type = "";
                                    $bank_id = "";
                                    $agency_id = "";
                                    $emp_id = "";
									if(isset($_REQUEST['to_date']) && isset($_REQUEST['from_date'])){
										$from_date = date('Y-m-d',strtotime($_REQUEST['from_date']));
										$to_date = date('Y-m-d',strtotime($_REQUEST['to_date']));
									}
                                    if(isset($_REQUEST['stage_status'])){
                                        $stage_status = $_REQUEST['stage_status'];
                                    }
                                    if(isset($_REQUEST['payment_type'])){
                                        $payment_type = $_REQUEST['payment_type'];
                                    }
                                    if(isset($_REQUEST['bank_id'])){
                                        $bank_id = $_REQUEST['bank_id'];
                                    }
                                    if(isset($_REQUEST['agency_id'])){
                                        $agency_id = $_REQUEST['agency_id'];
                                    }
                                    if(isset($_REQUEST['emp_id'])){
                                        $emp_id = $_REQUEST['emp_id'];
                                    }
								?>
                                <div class="row mb-3">
                                    <label class="col-sm-2 col-form-label">From Date</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text"><i class="bi bi-calendar"></i></span>
                                            <input type="date" class="form-control" name="from_date" value="<?php echo $from_date; ?>" required>
                                        </div>
                                    </div>
                                    <label class="col-sm-2 col-form-label">To Date</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text"><i class="bi bi-calendar"></i></span>
                                            <input type="date" class="form-control" name="to_date" value="<?php echo $to_date; ?>" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-2 col-form-label">Category</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text"><i class="bi bi-tags"></i></span>
                                            <select class="form-select" name="payment_type">
                                                <option value="">All (Recharge, Withdraw, Expense, Deposit)</option>
                                                <option value="RECHARGE" <?php if($payment_type == 'RECHARGE') echo 'selected'; ?>>Recharge</option>
                                                <option value="WITHDRAWAL" <?php if($payment_type == 'WITHDRAWAL') echo 'selected'; ?>>Withdrawal</option>
                                                <option value="EXPENSE" <?php if($payment_type == 'EXPENSE') echo 'selected'; ?>>Expense</option>
                                                <option value="PAY_TO_ADMIN" <?php if($payment_type == 'PAY_TO_ADMIN') echo 'selected'; ?>>Agency Deposit (Pay To Admin)</option>
                                            </select>
                                        </div>
                                    </div>
                                    <label class="col-sm-2 col-form-label">Status</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text"><i class="bi bi-pencil-square"></i></span>
                                            <select class="form-select" name="stage_status">
                                                <option value="">All Statuses (Pending, Done, Rejected)</option>
                                                <option value="PENDING" <?php if($stage_status == 'PENDING') echo 'selected'; ?>>PENDING</option>
                                                <option value="DONE" <?php if($stage_status == 'DONE') echo 'selected'; ?>>DONE</option>
                                                <option value="REJECTED" <?php if($stage_status == 'REJECTED') echo 'selected'; ?>>REJECTED</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <?php if($_SESSION['u_type'] == "ADMIN") { ?>
                                    <label class="col-sm-2 col-form-label">Agency</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text"><i class="bi bi-building"></i></span>
                                            <select class="form-select" name="agency_id" onchange="get_banks_by_agency(this.value); get_users_by_agency(this.value);">
                                                <option value="">All Agencies</option>
                                                <?php
                                                    $qryagencies = mysqli_query($conn, "SELECT * FROM `users` WHERE type = 'AGENCY' AND show_status = 'ACTIVE' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                                                    while($resagency = mysqli_fetch_array($qryagencies)){
                                                        $selected = ($agency_id == $resagency['id']) ? "selected" : "";
                                                        echo '<option value="'.$resagency['id'].'" '.$selected.'>'.$resagency['name'].'</option>';
                                                    }
                                                ?>
                                            </select>
                                        </div>
                                    </div>
                                    <?php } else { ?>
                                    <label class="col-sm-2 col-form-label">Agency</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text"><i class="bi bi-building"></i></span>
                                            <select class="form-select" name="agency_id" required>
                                                <option value="<?php echo $_SESSION['u_id']; ?>"><?php echo $admn_dls['name']; ?></option>
                                            </select>
                                        </div>
                                    </div>
                                    <?php } ?>

                                    <label class="col-sm-2 col-form-label">Bank Account</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3" id="bank_accounts">
                                            <span class="input-group-text"><i class="bi bi-bank"></i></span>
                                            <select class="form-select" name="bank_id">
                                                <option value="">All Banks</option>
                                                <?php
                                                // Fetch banks from recharge, expense, pay_to_admin, withdrawal
                                                $bank_map = [];
                                                $queries = [
                                                    "SELECT DISTINCT bank_slag, bank_name FROM recharge WHERE bank_slag != ''",
                                                    "SELECT DISTINCT bank_slag, bank_name FROM expense WHERE bank_slag != ''",
                                                    "SELECT DISTINCT bank_slag, bank_name FROM withdrawal WHERE bank_slag != ''",
                                                    "SELECT DISTINCT bank_slag, bank_name FROM pay_to_admin WHERE bank_slag != ''",
                                                    "SELECT DISTINCT admin_bank_slag AS bank_slag, admin_bank_name AS bank_name FROM pay_to_admin WHERE admin_bank_slag != ''"
                                                ];
                                                foreach($queries as $bq) {
                                                    $qres = mysqli_query($conn, $bq);
                                                    if($qres) {
                                                        while($brow = mysqli_fetch_array($qres)) {
                                                            if(!empty($brow['bank_slag'])) {
                                                                $b_name = !empty($brow['bank_name']) ? $brow['bank_name'] : $brow['bank_slag'];
                                                                $bank_map[$brow['bank_slag']] = $b_name;
                                                            }
                                                        }
                                                    }
                                                }
                                                foreach($bank_map as $bslag => $bname) {
                                                    $selected = ($bank_id == $bslag) ? "selected" : "";
                                                    echo '<option value="'.$bslag.'" '.$selected.'>'.$bname.'</option>';
                                                }
                                                ?>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <label class="col-sm-2 col-form-label">User Name</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3" id="user_accounts">
                                            <span class="input-group-text"><i class="bi bi-person"></i></span>
                                            <select class="form-select" name="emp_id">
                                                <option value="">All Users</option>
                                                <?php
                                                    $user_qry = "SELECT id, name FROM users WHERE type = 'USER' ORDER BY name ASC";
                                                    $qryusers = mysqli_query($conn, $user_qry) or die(mysqli_error($conn));
                                                    while($resuser = mysqli_fetch_array($qryusers)){
                                                        $selected = ($emp_id == $resuser['id']) ? "selected" : "";
                                                        echo '<option value="'.$resuser['id'].'" '.$selected.'>'.$resuser['name'].'</option>';
                                                    }
                                                ?>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                <hr class="ml-100">
                                <div class="row">
                                    <div class="d-flex gap-3 mt-3">
                                        <button name="add_agency" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
                            <th class="text-center" scope="col">Category</th>
							<th class="text-center" scope="col">User / Party Name</th>
							<th class="text-center" scope="col">Book / Detail</th>
							<th class="text-center" scope="col">Amount</th>
							<th class="text-center" scope="col">Txn ID</th>
							<th class="text-center" scope="col">Date</th>
							<th class="text-center" scope="col">Bank A/C</th>
                            <th class="text-center" scope="col">Agency</th>
							<th class="text-center" scope="col">Status</th>
						</tr>
					</thead>
					<tbody>
					<?php
						$i = 0;
                        $from_ts = strtotime($from_date . " 00:00:00");
                        $to_ts = strtotime($to_date . " 23:59:59");
                        $all_records = [];

                        // 1. RECHARGE
                        if(empty($payment_type) || $payment_type == 'RECHARGE') {
                            $sql_r = "SELECT r.* FROM recharge r LEFT JOIN users u ON r.user_id = u.id WHERE r.date_ts >= '$from_ts' AND r.date_ts <= '$to_ts'";
                            if($_SESSION['u_type'] == "ADMIN"){
                                if($agency_id != ''){
                                    $sql_r .= " AND (r.emp_id = '$agency_id' OR u.agency_id = '$agency_id')";
                                }
                            } else {
                                $sql_r .= " AND (r.emp_id = '".$_SESSION['u_id']."' OR u.agency_id = '".$_SESSION['u_id']."')";
                            }
                            if($emp_id != ''){
                                $sql_r .= " AND r.user_id = '$emp_id'";
                            }
                            if($bank_id != ''){
                                $sql_r .= " AND r.bank_slag = '$bank_id'";
                            }
                            if($stage_status == 'DONE'){
                                $sql_r .= " AND (r.stage_status = 'EMPLOYEE-DONE' OR r.stage_status = 'AGENCY-DONE' OR r.stage_status = 'DONE')";
                            } elseif($stage_status == 'REJECTED'){
                                $sql_r .= " AND (r.stage_status = 'EMPLOYEE-REJECT' OR r.stage_status = 'AGENCY-REJECT' OR r.stage_status = 'REJECTED')";
                            } elseif($stage_status == 'PENDING'){
                                $sql_r .= " AND (r.stage_status NOT LIKE '%DONE%' AND r.stage_status NOT LIKE '%REJECT%')";
                            }

                            $qry_r = mysqli_query($conn, $sql_r);
                            while($r = mysqli_fetch_array($qry_r)){
                                $u_name = "N/A";
                                $ag_name = "N/A";
                                if(!empty($r['user_id'])){
                                    $q_usr = mysqli_query($conn, "SELECT name, agency_id FROM users WHERE id = '".$r['user_id']."'");
                                    if($r_usr = mysqli_fetch_array($q_usr)){
                                        $u_name = $r_usr['name'];
                                        if(!empty($r_usr['agency_id'])){
                                            $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$r_usr['agency_id']."'");
                                            if($r_ag = mysqli_fetch_array($q_ag)){
                                                $ag_name = $r_ag['name'];
                                            }
                                        }
                                    }
                                }
                                if($ag_name == "N/A" && !empty($r['emp_id'])){
                                    $q_emp = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$r['emp_id']."'");
                                    if($r_emp = mysqli_fetch_array($q_emp)){
                                        $ag_name = $r_emp['name'];
                                    }
                                }

                                $b_name = "N/A";
                                if(!empty($r['book_id'])){
                                    $q_bk = mysqli_query($conn, "SELECT name FROM features WHERE id = '".$r['book_id']."'");
                                    if($r_bk = mysqli_fetch_array($q_bk)) $b_name = $r_bk['name'];
                                }

                                $stg = strtoupper($r['stage_status']);
                                $norm_stg = 'PENDING';
                                if(strpos($stg, 'DONE') !== false){
                                    $norm_stg = 'DONE';
                                } elseif(strpos($stg, 'REJECT') !== false){
                                    $norm_stg = 'REJECTED';
                                }

                                $all_records[] = [
                                    'id' => $r['id'],
                                    'type' => 'RECHARGE',
                                    'type_label' => 'Recharge',
                                    'type_badge' => 'bg-success',
                                    'user_name' => $u_name,
                                    'detail' => $b_name,
                                    'amount' => $r['amount'],
                                    'txn_id' => !empty($r['transection_id']) ? $r['transection_id'] : 'N/A',
                                    'date_ts' => is_numeric($r['date_ts']) ? (int)$r['date_ts'] : strtotime($r['date_ts']),
                                    'bank_name' => !empty($r['bank_name']) ? $r['bank_name'] : (!empty($r['bank_slag']) ? $r['bank_slag'] : 'N/A'),
                                    'agency_name' => $ag_name,
                                    'status' => $norm_stg
                                ];
                            }
                        }

                        // 2. WITHDRAWAL
                        if(empty($payment_type) || $payment_type == 'WITHDRAWAL') {
                            $sql_w = "SELECT w.* FROM withdrawal w LEFT JOIN users u ON w.user_id = u.id WHERE w.date_ts >= '$from_ts' AND w.date_ts <= '$to_ts'";
                            if($_SESSION['u_type'] == "ADMIN"){
                                if($agency_id != ''){
                                    $sql_w .= " AND (w.agency_id = '$agency_id' OR u.agency_id = '$agency_id')";
                                }
                            } else {
                                $sql_w .= " AND (w.agency_id = '".$_SESSION['u_id']."' OR u.agency_id = '".$_SESSION['u_id']."')";
                            }
                            if($emp_id != ''){
                                $sql_w .= " AND w.user_id = '$emp_id'";
                            }
                            if($bank_id != ''){
                                $sql_w .= " AND w.bank_slag = '$bank_id'";
                            }
                            if($stage_status == 'DONE'){
                                $sql_w .= " AND (w.stage_status = 'EMPLOYEE-DONE' OR w.stage_status = 'AGENCY-DONE' OR w.stage_status = 'DONE')";
                            } elseif($stage_status == 'REJECTED'){
                                $sql_w .= " AND (w.stage_status = 'EMPLOYEE-REJECT' OR w.stage_status = 'AGENCY-REJECT' OR w.stage_status = 'REJECTED')";
                            } elseif($stage_status == 'PENDING'){
                                $sql_w .= " AND (w.stage_status NOT LIKE '%DONE%' AND w.stage_status NOT LIKE '%REJECT%')";
                            }

                            $qry_w = mysqli_query($conn, $sql_w);
                            while($w = mysqli_fetch_array($qry_w)){
                                $u_name = "N/A";
                                if(!empty($w['user_id'])){
                                    $q_usr = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$w['user_id']."'");
                                    if($r_usr = mysqli_fetch_array($q_usr)) $u_name = $r_usr['name'];
                                }

                                $ag_name = "N/A";
                                if(!empty($w['agency_id'])){
                                    $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$w['agency_id']."'");
                                    if($r_ag = mysqli_fetch_array($q_ag)) $ag_name = $r_ag['name'];
                                }

                                $b_name = "N/A";
                                if(!empty($w['book_id'])){
                                    $q_bk = mysqli_query($conn, "SELECT name FROM features WHERE id = '".$w['book_id']."'");
                                    if($r_bk = mysqli_fetch_array($q_bk)) $b_name = $r_bk['name'];
                                }

                                $stg = strtoupper($w['stage_status']);
                                $norm_stg = 'PENDING';
                                if(strpos($stg, 'DONE') !== false){
                                    $norm_stg = 'DONE';
                                } elseif(strpos($stg, 'REJECT') !== false){
                                    $norm_stg = 'REJECTED';
                                }

                                $all_records[] = [
                                    'id' => $w['id'],
                                    'type' => 'WITHDRAWAL',
                                    'type_label' => 'Withdrawal',
                                    'type_badge' => 'bg-danger',
                                    'user_name' => $u_name,
                                    'detail' => $b_name,
                                    'amount' => $w['amount'],
                                    'txn_id' => !empty($w['transaction_id']) ? $w['transaction_id'] : 'N/A',
                                    'date_ts' => is_numeric($w['date_ts']) ? (int)$w['date_ts'] : strtotime($w['date_ts']),
                                    'bank_name' => !empty($w['bank_name']) ? $w['bank_name'] : (!empty($w['bank_slag']) ? $w['bank_slag'] : 'N/A'),
                                    'agency_name' => $ag_name,
                                    'status' => $norm_stg
                                ];
                            }
                        }

                        // 3. EXPENSE
                        if(empty($payment_type) || $payment_type == 'EXPENSE') {
                            if(empty($stage_status) || $stage_status == 'DONE') {
                                $sql_e = "SELECT e.* FROM expense e LEFT JOIN users u ON e.emp_id = u.id WHERE e.date_ts >= '$from_ts' AND e.date_ts <= '$to_ts'";
                                if($_SESSION['u_type'] == "ADMIN"){
                                    if($agency_id != ''){
                                        $sql_e .= " AND (e.emp_id = '$agency_id' OR u.agency_id = '$agency_id')";
                                    }
                                } else {
                                    $sql_e .= " AND (e.emp_id = '".$_SESSION['u_id']."' OR u.agency_id = '".$_SESSION['u_id']."')";
                                }
                                if($bank_id != ''){
                                    $sql_e .= " AND e.bank_slag = '$bank_id'";
                                }

                                $qry_e = mysqli_query($conn, $sql_e);
                                while($e = mysqli_fetch_array($qry_e)){
                                    $head_name = "Expense";
                                    if(!empty($e['head_id'])){
                                        $q_hd = mysqli_query($conn, "SELECT name FROM expense_heads WHERE id = '".$e['head_id']."'");
                                        if($r_hd = mysqli_fetch_array($q_hd)) $head_name = $r_hd['name'];
                                    }

                                    $ag_name = "N/A";
                                    if(!empty($e['emp_id'])){
                                        $q_emp = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$e['emp_id']."'");
                                        if($r_emp = mysqli_fetch_array($q_emp)) $ag_name = $r_emp['name'];
                                    }

                                    $all_records[] = [
                                        'id' => $e['id'],
                                        'type' => 'EXPENSE',
                                        'type_label' => 'Expense',
                                        'type_badge' => 'bg-warning text-dark',
                                        'user_name' => $ag_name,
                                        'detail' => $head_name,
                                        'amount' => $e['amount'],
                                        'txn_id' => !empty($e['transection_id']) ? $e['transection_id'] : 'N/A',
                                        'date_ts' => is_numeric($e['date_ts']) ? (int)$e['date_ts'] : strtotime($e['date_ts']),
                                        'bank_name' => !empty($e['bank_name']) ? $e['bank_name'] : (!empty($e['bank_slag']) ? $e['bank_slag'] : 'N/A'),
                                        'agency_name' => $ag_name,
                                        'status' => 'DONE'
                                    ];
                                }
                            }
                        }

                        // 4. PAY_TO_ADMIN (Agency Deposit)
                        if(empty($payment_type) || $payment_type == 'PAY_TO_ADMIN') {
                            $sql_p = "SELECT p.* FROM pay_to_admin p WHERE p.date_ts >= '$from_ts' AND p.date_ts <= '$to_ts'";
                            if($_SESSION['u_type'] == "ADMIN"){
                                if($agency_id != ''){
                                    $sql_p .= " AND p.agency_id = '$agency_id'";
                                }
                            } else {
                                $sql_p .= " AND p.agency_id = '".$_SESSION['u_id']."'";
                            }
                            if($bank_id != ''){
                                $sql_p .= " AND (p.bank_slag = '$bank_id' OR p.admin_bank_slag = '$bank_id')";
                            }
                            if($stage_status == 'DONE'){
                                $sql_p .= " AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE')";
                            } elseif($stage_status == 'REJECTED'){
                                $sql_p .= " AND (p.stage_status = 'EMPLOYEE-REJECT' OR p.stage_status = 'ADMIN-REJECT' OR p.stage_status = 'REJECTED')";
                            } elseif($stage_status == 'PENDING'){
                                $sql_p .= " AND (p.stage_status NOT LIKE '%DONE%' AND p.stage_status NOT LIKE '%REJECT%')";
                            }

                            $qry_p = mysqli_query($conn, $sql_p);
                            while($p = mysqli_fetch_array($qry_p)){
                                $ag_name = "N/A";
                                if(!empty($p['agency_id'])){
                                    $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$p['agency_id']."'");
                                    if($r_ag = mysqli_fetch_array($q_ag)) $ag_name = $r_ag['name'];
                                }

                                $stg = strtoupper($p['stage_status']);
                                $norm_stg = 'PENDING';
                                if(strpos($stg, 'DONE') !== false){
                                    $norm_stg = 'DONE';
                                } elseif(strpos($stg, 'REJECT') !== false){
                                    $norm_stg = 'REJECTED';
                                }

                                $all_records[] = [
                                    'id' => $p['id'],
                                    'type' => 'PAY_TO_ADMIN',
                                    'type_label' => 'Deposit',
                                    'type_badge' => 'bg-info text-dark',
                                    'user_name' => $ag_name,
                                    'detail' => 'Agency Deposit to Admin',
                                    'amount' => $p['amount'],
                                    'txn_id' => !empty($p['transaction_id']) ? $p['transaction_id'] : 'N/A',
                                    'date_ts' => is_numeric($p['date_ts']) ? (int)$p['date_ts'] : strtotime($p['date_ts']),
                                    'bank_name' => !empty($p['admin_bank_name']) ? $p['admin_bank_name'] : (!empty($p['bank_name']) ? $p['bank_name'] : (!empty($p['bank_slag']) ? $p['bank_slag'] : 'N/A')),
                                    'agency_name' => $ag_name,
                                    'status' => $norm_stg
                                ];
                            }
                        }

                        // Sort combined records DESC by date_ts
                        usort($all_records, function($a, $b) {
                            return $b['date_ts'] - $a['date_ts'];
                        });

                        foreach($all_records as $rec){ $i++;
					?>
						<tr id="row_<?php echo $rec['type'].'_'.$rec['id']; ?>">
							<td scope="row"><?php echo $i; ?></td>
                            <td>
                                <span class="badge <?php echo $rec['type_badge']; ?> px-2 py-1"><?php echo $rec['type_label']; ?></span>
                            </td>
							<td><?php echo $rec['user_name']; ?></td>
							<td><?php echo $rec['detail']; ?></td>
							<td><b>₹<?php echo number_format($rec['amount'], 2); ?></b></td>
							<td><?php echo $rec['txn_id']; ?></td>
							<td><?php echo date('d-m-Y h:i A', $rec['date_ts']); ?></td>
							<td><?php echo $rec['bank_name']; ?></td>
                            <td><?php echo $rec['agency_name']; ?></td>
							<td> 
                                <?php if($rec['status'] == 'DONE'){ ?>
                                    <span class="badge bg-success">DONE</span>
                                <?php } else if($rec['status'] == 'PENDING') { ?>
                                    <span class="badge bg-warning text-dark">PENDING</span>
                                <?php } else if($rec['status'] == 'REJECTED') { ?>
                                    <span class="badge bg-danger">REJECTED</span>
                                <?php } ?>
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
<script>
function exportTableToExcel(tableID, filename = ''){
    var downloadLink;
    var dataType = 'application/vnd.ms-excel';
    var tableSelect = document.getElementById(tableID);
    
    var tableHTML = `
        <html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
        <head>
            <meta charset="utf-8">
            <style>
                td { mso-number-format:"\\@"; }
            </style>
        </head>
        <body>
            ${tableSelect.outerHTML}
        </body>
        </html>
    `;
    
    filename = filename ? filename + '_<?php echo $date_ts; ?>.xls' : 'payments_record_<?php echo $date_ts; ?>.xls';
    
    downloadLink = document.createElement("a");
    document.body.appendChild(downloadLink);
    
    var blob = new Blob(['\ufeff', tableHTML], {
        type: dataType
    });
    
    if(navigator.msSaveOrOpenBlob){
        navigator.msSaveOrOpenBlob(blob, filename);
    } else {
        var url = URL.createObjectURL(blob);
        downloadLink.href = url;
        downloadLink.download = filename;
        downloadLink.click();
        
        setTimeout(function() {
            document.body.removeChild(downloadLink);
            window.URL.revokeObjectURL(url);
        }, 100);
    }
}
</script>
<script>
    function get_banks_by_agency(agency_id) {
        $.ajax({
            url: "ajax_del.php",
            type: "POST",
            data: {
                get_banks_by_agency: 1, 
                agency_id: agency_id
            },
            success: function(response) {
                $("#bank_accounts").html(response);
            }
        });
    }

    function get_users_by_agency(agency_id) {
        $.ajax({
            url: "ajax_del.php",
            type: "POST",
            data: {
                get_users_by_agency: 1, 
                agency_id: agency_id
            },
            success: function(response) {
                $("#user_accounts").html(response);
            }
        });
    }
</script>
<?php include 'partials/_footer.php' ?>