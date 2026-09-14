<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    echo '<div class="alert alert-danger">Session expired. Please log in again.</div>';
    exit;
}

if(!isset($_POST['agency_id']) || empty($_POST['agency_id'])){
    echo '<div class="alert alert-warning">Invalid Agency ID.</div>';
    exit;
}

$agency_id = mysqli_real_escape_string($conn, $_POST['agency_id']);

// Fetch Agency Info
$qry_agnc = mysqli_query($conn, "SELECT * FROM `users` WHERE `id` = '$agency_id' AND (`type` = 'AGENCY' OR `type` = 'AGENCYS-EMPLOYEE')") or die(mysqli_error($conn));
if(mysqli_num_rows($qry_agnc) == 0){
    echo '<div class="alert alert-danger">Agency/Employee not found.</div>';
    exit;
}
$agnc = mysqli_fetch_array($qry_agnc);

// Fetch Cash Book info
$qry_cb = mysqli_query($conn, "SELECT * FROM `agency_cash_book` WHERE `agency_id` = '$agency_id'") or die(mysqli_error($conn));
$cb = mysqli_fetch_array($qry_cb);
$collect_limit = isset($agnc['collect_limit']) ? floatval($agnc['collect_limit']) : 0;
$recharge_limit_live = isset($cb['recharge_limit_live']) ? floatval($cb['recharge_limit_live']) : 0;
$rs_inhand_expected = isset($cb['rs_inhand_expected']) ? floatval($cb['rs_inhand_expected']) : 0;

// User Statistics
$qry_tot_usr = mysqli_query($conn, "SELECT COUNT(*) as total FROM `users` WHERE `agency_id` = '$agency_id' AND `type` = 'USER'") or die(mysqli_error($conn));
$tot_usr = mysqli_fetch_array($qry_tot_usr)['total'];

$qry_act_usr = mysqli_query($conn, "SELECT COUNT(*) as total FROM `users` WHERE `agency_id` = '$agency_id' AND `type` = 'USER' AND `show_status` = 'ACTIVE' AND `verification` = 'DONE'") or die(mysqli_error($conn));
$act_usr = mysqli_fetch_array($qry_act_usr)['total'];

$qry_pnd_usr = mysqli_query($conn, "SELECT COUNT(*) as total FROM `users` WHERE `agency_id` = '$agency_id' AND `type` = 'USER' AND `verification` = 'PENDING'") or die(mysqli_error($conn));
$pnd_usr = mysqli_fetch_array($qry_pnd_usr)['total'];

// Today & Month timestamps
$today_start = strtotime('today midnight');
$today_end = strtotime('today 23:59:59');
$month_start = strtotime('first day of this month midnight');
$month_end = strtotime('last day of this month 23:59:59');

// Helper to parse date_ts
function parse_ts($val){
    if(empty($val)) return 0;
    return is_numeric($val) ? (int)$val : strtotime($val);
}

// --- RECHARGE METRICS ---
$rcg_today_app_cnt = 0; $rcg_today_app_amt = 0;
$rcg_today_pnd_cnt = 0; $rcg_today_pnd_amt = 0;
$rcg_today_rej_cnt = 0; $rcg_today_rej_amt = 0;

$rcg_mth_app_cnt = 0; $rcg_mth_app_amt = 0;

$rcg_tot_app_cnt = 0; $rcg_tot_app_amt = 0;
$rcg_tot_pnd_cnt = 0; $rcg_tot_pnd_amt = 0;
$rcg_tot_rej_cnt = 0; $rcg_tot_rej_amt = 0;

$qry_rcg = mysqli_query($conn, "SELECT r.* FROM `recharge` r LEFT JOIN `users` u ON r.user_id = u.id WHERE (r.emp_id = '$agency_id' OR u.agency_id = '$agency_id')") or die(mysqli_error($conn));
while($r = mysqli_fetch_array($qry_rcg)){
    $amt = floatval($r['amount']);
    $st = strtoupper($r['stage_status']);
    $ts = parse_ts($r['date_ts']);
    $is_today = ($ts >= $today_start && $ts <= $today_end);
    $is_month = ($ts >= $month_start && $ts <= $month_end);

    if(in_array($st, ['EMPLOYEE-DONE', 'AGENCY-DONE', 'DONE'])){
        $rcg_tot_app_cnt++; $rcg_tot_app_amt += $amt;
        if($is_today){ $rcg_today_app_cnt++; $rcg_today_app_amt += $amt; }
        if($is_month){ $rcg_mth_app_cnt++; $rcg_mth_app_amt += $amt; }
    } elseif(in_array($st, ['AGENCY-REJECT', 'EMPLOYEE-REJECT', 'REJECTED'])){
        $rcg_tot_rej_cnt++; $rcg_tot_rej_amt += $amt;
        if($is_today){ $rcg_today_rej_cnt++; $rcg_today_rej_amt += $amt; }
    } else {
        $rcg_tot_pnd_cnt++; $rcg_tot_pnd_amt += $amt;
        if($is_today){ $rcg_today_pnd_cnt++; $rcg_today_pnd_amt += $amt; }
    }
}

// --- WITHDRAWAL METRICS ---
$wth_today_app_cnt = 0; $wth_today_app_amt = 0;
$wth_today_pnd_cnt = 0; $wth_today_pnd_amt = 0;
$wth_today_rej_cnt = 0; $wth_today_rej_amt = 0;

$wth_mth_app_cnt = 0; $wth_mth_app_amt = 0;

$wth_tot_app_cnt = 0; $wth_tot_app_amt = 0;
$wth_tot_pnd_cnt = 0; $wth_tot_pnd_amt = 0;
$wth_tot_rej_cnt = 0; $wth_tot_rej_amt = 0;

$qry_wth = mysqli_query($conn, "SELECT w.* FROM `withdrawal` w LEFT JOIN `users` u ON w.user_id = u.id WHERE (w.agency_id = '$agency_id' OR u.agency_id = '$agency_id')") or die(mysqli_error($conn));
while($w = mysqli_fetch_array($qry_wth)){
    $amt = floatval($w['amount']);
    $st = strtoupper($w['stage_status']);
    $ts = parse_ts($w['date_ts']);
    $is_today = ($ts >= $today_start && $ts <= $today_end);
    $is_month = ($ts >= $month_start && $ts <= $month_end);

    if(in_array($st, ['EMPLOYEE-DONE', 'AGENCY-DONE', 'DONE'])){
        $wth_tot_app_cnt++; $wth_tot_app_amt += $amt;
        if($is_today){ $wth_today_app_cnt++; $wth_today_app_amt += $amt; }
        if($is_month){ $wth_mth_app_cnt++; $wth_mth_app_amt += $amt; }
    } elseif(in_array($st, ['AGENCY-REJECT', 'EMPLOYEE-REJECT', 'REJECTED'])){
        $wth_tot_rej_cnt++; $wth_tot_rej_amt += $amt;
        if($is_today){ $wth_today_rej_cnt++; $wth_today_rej_amt += $amt; }
    } else {
        $wth_tot_pnd_cnt++; $wth_tot_pnd_amt += $amt;
        if($is_today){ $wth_today_pnd_cnt++; $wth_today_pnd_amt += $amt; }
    }
}

// --- AGENCY DEPOSIT (PAY TO ADMIN) METRICS ---
$dep_today_app_cnt = 0; $dep_today_app_amt = 0;
$dep_today_pnd_cnt = 0; $dep_today_pnd_amt = 0;
$dep_today_rej_cnt = 0; $dep_today_rej_amt = 0;

$dep_mth_app_cnt = 0; $dep_mth_app_amt = 0;

$dep_tot_app_cnt = 0; $dep_tot_app_amt = 0;
$dep_tot_pnd_cnt = 0; $dep_tot_pnd_amt = 0;
$dep_tot_rej_cnt = 0; $dep_tot_rej_amt = 0;

$qry_dep = mysqli_query($conn, "SELECT * FROM `pay_to_admin` WHERE `agency_id` = '$agency_id'") or die(mysqli_error($conn));
while($d = mysqli_fetch_array($qry_dep)){
    $amt = floatval($d['amount']);
    $st = strtoupper($d['stage_status']);
    $ts = parse_ts($d['date_ts']);
    $is_today = ($ts >= $today_start && $ts <= $today_end);
    $is_month = ($ts >= $month_start && $ts <= $month_end);

    if(in_array($st, ['EMPLOYEE-DONE', 'ADMIN-DONE', 'DONE'])){
        $dep_tot_app_cnt++; $dep_tot_app_amt += $amt;
        if($is_today){ $dep_today_app_cnt++; $dep_today_app_amt += $amt; }
        if($is_month){ $dep_mth_app_cnt++; $dep_mth_app_amt += $amt; }
    } elseif(in_array($st, ['EMPLOYEE-REJECT', 'ADMIN-REJECT', 'REJECTED'])){
        $dep_tot_rej_cnt++; $dep_tot_rej_amt += $amt;
        if($is_today){ $dep_today_rej_cnt++; $dep_today_rej_amt += $amt; }
    } else {
        $dep_tot_pnd_cnt++; $dep_tot_pnd_amt += $amt;
        if($is_today){ $dep_today_pnd_cnt++; $dep_today_pnd_amt += $amt; }
    }
}

// Calculate Net Agency Performance Metrics
$net_recharge = $rcg_tot_app_amt;
$net_withdrawal = $wth_tot_app_amt;
$net_agency_deposit = $dep_tot_app_amt;
$net_agency_balance = $net_recharge - $net_withdrawal - $net_agency_deposit;
?>

<!-- Header Info Banner -->
<div class="row align-items-center bg-light border rounded-3 p-3 mx-1 my-4 shadow-sm">
    <div class="col-md-2 text-center mb-2 mb-md-0">
        <?php
            if(!empty($agnc['img'])){
                echo "<img class='img-thumbnail rounded-circle shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$agnc['img']."' style='width: 80px; height: 80px; object-fit: cover;' />";
            } else {
                echo "<img class='img-thumbnail rounded-circle shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' style='width: 80px; height: 80px; object-fit: cover;' />";
            }
        ?>
    </div>
    <div class="col-md-6">
        <h4 class="mb-1 text-primary font-weight-bold"><?php echo htmlspecialchars($agnc['name']); ?></h4>
        <p class="text-muted mb-1 small">
            <i class="bi bi-person-vcard me-1"></i> ID: <strong><?php echo !empty($agnc['agency_unq_id']) ? $agnc['agency_unq_id'] : 'AGENCY-'.$agnc['id']; ?></strong> &nbsp;|&nbsp; 
            <i class="bi bi-telephone me-1"></i> Phone: <strong><?php echo htmlspecialchars($agnc['mob']); ?></strong> &nbsp;|&nbsp; 
            <i class="bi bi-envelope me-1"></i> Email: <strong><?php echo htmlspecialchars($agnc['email']); ?></strong>
        </p>
        <div>
            <span class="badge <?php echo ($agnc['show_status'] == 'ACTIVE') ? 'bg-success' : 'bg-danger'; ?> me-2">
                Status: <?php echo $agnc['show_status']; ?>
            </span>
            <span class="badge <?php echo ($agnc['profit_loss_status'] == 'ACTIVE') ? 'bg-info text-dark' : 'bg-secondary'; ?>">
                Profit/Loss View: <?php echo ($agnc['profit_loss_status'] == 'ACTIVE') ? 'Shown' : 'Hide'; ?>
            </span>
        </div>
    </div>
    <div class="col-md-4 text-md-end mt-2 mt-md-0">
        <div class="bg-white border p-2 rounded shadow-sm text-center">
            <span class="text-muted small d-block">Live Recharge Limit</span>
            <span class="fs-4 fw-bold text-success">₹<?php echo number_format($recharge_limit_live, 2); ?></span>
            <div class="text-muted border-top pt-1 mt-1 fs-7">
                Limit Set: <strong>₹<?php echo number_format($collect_limit, 2); ?></strong> | Cash Expected: <strong class="text-danger">₹<?php echo number_format($rs_inhand_expected, 2); ?></strong>
            </div>
        </div>
    </div>
</div>

<!-- Modal Navigation Tabs -->
<ul class="nav nav-pills nav-fill mb-3 gap-2 px-2" id="agencyStatsTabs" role="tablist">
    <li class="nav-item" role="presentation">
        <button class="nav-link active fw-semibold shadow-sm" id="overview-tab" data-bs-toggle="tab" data-bs-target="#tab-overview" type="button" role="tab">
            <i class="bi bi-speedometer2 me-1"></i> Performance Summary
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link fw-semibold shadow-sm" id="today-tab" data-bs-toggle="tab" data-bs-target="#tab-today" type="button" role="tab">
            <i class="bi bi-calendar-event me-1"></i> Current (Today's)
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link fw-semibold shadow-sm" id="lifetime-tab" data-bs-toggle="tab" data-bs-target="#tab-lifetime" type="button" role="tab">
            <i class="bi bi-pie-chart me-1"></i> Total (Lifetime)
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link fw-semibold shadow-sm" id="users-tab" data-bs-toggle="tab" data-bs-target="#tab-users" type="button" role="tab">
            <i class="bi bi-people me-1"></i> Users & Cashflow
        </button>
    </li>
</ul>

<!-- Tab Content -->
<div class="tab-content px-1" id="agencyStatsTabsContent">

    <!-- TAB 1: OVERVIEW SUMMARY -->
    <div class="tab-pane fade show active" id="tab-overview" role="tabpanel">
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-primary text-white p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-white-50">Total Agency Users</h6>
                            <h3 class="mb-0 fw-bold"><?php echo number_format($tot_usr); ?></h3>
                            <small class="text-white-50"><?php echo $act_usr; ?> Active | <?php echo $pnd_usr; ?> Pending</small>
                        </div>
                        <div class="fs-1 text-white-50"><i class="bi bi-people-fill"></i></div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-success text-white p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-white-50">Total Recharges</h6>
                            <h3 class="mb-0 fw-bold">₹<?php echo number_format($rcg_tot_app_amt, 2); ?></h3>
                            <small class="text-white-50"><?php echo $rcg_tot_app_cnt; ?> Total Approved</small>
                        </div>
                        <div class="fs-1 text-white-50"><i class="bi bi-wallet2"></i></div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-warning text-dark p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-dark-50">Total Withdrawals</h6>
                            <h3 class="mb-0 fw-bold">₹<?php echo number_format($wth_tot_app_amt, 2); ?></h3>
                            <small class="text-dark-50"><?php echo $wth_tot_app_cnt; ?> Total Paid Out</small>
                        </div>
                        <div class="fs-1 text-dark-50"><i class="bi bi-arrow-up-right-circle-fill"></i></div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-info text-dark p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-dark-50">Deposits to Admin</h6>
                            <h3 class="mb-0 fw-bold">₹<?php echo number_format($dep_tot_app_amt, 2); ?></h3>
                            <small class="text-dark-50"><?php echo $dep_tot_app_cnt; ?> Approved Payments</small>
                        </div>
                        <div class="fs-1 text-dark-50"><i class="bi bi-bank2"></i></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Current vs Total Quick Comparison Table -->
        <div class="card border shadow-sm mb-4">
            <div class="card-header bg-light">
                <h6 class="mb-0 fw-bold text-dark"><i class="bi bi-table me-2"></i>Performance Snapshot Matrix</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover table-bordered align-middle text-center mb-0">
                        <thead class="table-light">
                            <tr>
                                <th scope="col" class="text-start">Metric / Category</th>
                                <th scope="col" class="text-success">Today (Current)</th>
                                <th scope="col" class="text-primary">This Month</th>
                                <th scope="col" class="text-dark">Total (Lifetime)</th>
                                <th scope="col" class="text-warning">Pending Now</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <th scope="row" class="text-start"><i class="bi bi-plus-circle text-success me-2"></i> User Recharges</th>
                                <td class="fw-bold text-success">₹<?php echo number_format($rcg_today_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $rcg_today_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-primary">₹<?php echo number_format($rcg_mth_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $rcg_mth_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-dark">₹<?php echo number_format($rcg_tot_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $rcg_tot_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-warning">₹<?php echo number_format($rcg_tot_pnd_amt, 2); ?> <br><small class="text-muted">(<?php echo $rcg_tot_pnd_cnt; ?> txns)</small></td>
                            </tr>
                            <tr>
                                <th scope="row" class="text-start"><i class="bi bi-dash-circle text-danger me-2"></i> User Withdrawals</th>
                                <td class="fw-bold text-danger">₹<?php echo number_format($wth_today_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $wth_today_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-primary">₹<?php echo number_format($wth_mth_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $wth_mth_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-dark">₹<?php echo number_format($wth_tot_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $wth_tot_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-warning">₹<?php echo number_format($wth_tot_pnd_amt, 2); ?> <br><small class="text-muted">(<?php echo $wth_tot_pnd_cnt; ?> txns)</small></td>
                            </tr>
                            <tr>
                                <th scope="row" class="text-start"><i class="bi bi-bank text-info me-2"></i> Agency Deposits (Pay Admin)</th>
                                <td class="fw-bold text-info">₹<?php echo number_format($dep_today_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $dep_today_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-primary">₹<?php echo number_format($dep_mth_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $dep_mth_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-dark">₹<?php echo number_format($dep_tot_app_amt, 2); ?> <br><small class="text-muted">(<?php echo $dep_tot_app_cnt; ?> txns)</small></td>
                                <td class="fw-bold text-warning">₹<?php echo number_format($dep_tot_pnd_amt, 2); ?> <br><small class="text-muted">(<?php echo $dep_tot_pnd_cnt; ?> txns)</small></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- TAB 2: TODAY'S CURRENT PERFORMANCE -->
    <div class="tab-pane fade" id="tab-today" role="tabpanel">
        <h6 class="fw-bold text-primary mb-3"><i class="bi bi-calendar-check me-2"></i>Current (Today's) Detailed Breakdown</h6>
        <div class="row g-3 mb-3">

            <!-- Today Recharge -->
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-success text-white">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-arrow-down-left-circle me-1"></i> Today's Recharges</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Approved</span>
                            <span class="fw-bold text-success fs-5">₹<?php echo number_format($rcg_today_app_amt, 2); ?> <small class="fs-6">(<?php echo $rcg_today_app_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Pending</span>
                            <span class="fw-bold text-warning fs-5">₹<?php echo number_format($rcg_today_pnd_amt, 2); ?> <small class="fs-6">(<?php echo $rcg_today_pnd_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-muted">Rejected</span>
                            <span class="fw-bold text-danger fs-5">₹<?php echo number_format($rcg_today_rej_amt, 2); ?> <small class="fs-6">(<?php echo $rcg_today_rej_cnt; ?>)</small></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Today Withdrawal -->
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-danger text-white">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-arrow-up-right-circle me-1"></i> Today's Withdrawals</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Approved</span>
                            <span class="fw-bold text-success fs-5">₹<?php echo number_format($wth_today_app_amt, 2); ?> <small class="fs-6">(<?php echo $wth_today_app_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Pending</span>
                            <span class="fw-bold text-warning fs-5">₹<?php echo number_format($wth_today_pnd_amt, 2); ?> <small class="fs-6">(<?php echo $wth_today_pnd_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-muted">Rejected</span>
                            <span class="fw-bold text-secondary fs-5">₹<?php echo number_format($wth_today_rej_amt, 2); ?> <small class="fs-6">(<?php echo $wth_today_rej_cnt; ?>)</small></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Today Deposit -->
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-info text-dark">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-bank me-1"></i> Today's Admin Deposits</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Approved</span>
                            <span class="fw-bold text-success fs-5">₹<?php echo number_format($dep_today_app_amt, 2); ?> <small class="fs-6">(<?php echo $dep_today_app_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Pending</span>
                            <span class="fw-bold text-warning fs-5">₹<?php echo number_format($dep_today_pnd_amt, 2); ?> <small class="fs-6">(<?php echo $dep_today_pnd_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-muted">Rejected</span>
                            <span class="fw-bold text-danger fs-5">₹<?php echo number_format($dep_today_rej_amt, 2); ?> <small class="fs-6">(<?php echo $dep_today_rej_cnt; ?>)</small></span>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- TAB 3: LIFETIME PERFORMANCE -->
    <div class="tab-pane fade" id="tab-lifetime" role="tabpanel">
        <h6 class="fw-bold text-primary mb-3"><i class="bi bi-infinity me-2"></i>Total (Lifetime) Detailed Breakdown</h6>
        <div class="row g-3 mb-3">

            <!-- Total Recharge -->
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-gradient bg-success text-white">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-wallet2 me-1"></i> Total User Recharges</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Approved</span>
                            <span class="fw-bold text-success fs-5">₹<?php echo number_format($rcg_tot_app_amt, 2); ?> <small class="fs-6">(<?php echo $rcg_tot_app_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Pending</span>
                            <span class="fw-bold text-warning fs-5">₹<?php echo number_format($rcg_tot_pnd_amt, 2); ?> <small class="fs-6">(<?php echo $rcg_tot_pnd_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-muted">Rejected</span>
                            <span class="fw-bold text-danger fs-5">₹<?php echo number_format($rcg_tot_rej_amt, 2); ?> <small class="fs-6">(<?php echo $rcg_tot_rej_cnt; ?>)</small></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Total Withdrawal -->
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-gradient bg-danger text-white">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-arrow-up-right-circle me-1"></i> Total User Withdrawals</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Approved</span>
                            <span class="fw-bold text-success fs-5">₹<?php echo number_format($wth_tot_app_amt, 2); ?> <small class="fs-6">(<?php echo $wth_tot_app_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Pending</span>
                            <span class="fw-bold text-warning fs-5">₹<?php echo number_format($wth_tot_pnd_amt, 2); ?> <small class="fs-6">(<?php echo $wth_tot_pnd_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-muted">Rejected</span>
                            <span class="fw-bold text-secondary fs-5">₹<?php echo number_format($wth_tot_rej_amt, 2); ?> <small class="fs-6">(<?php echo $wth_tot_rej_cnt; ?>)</small></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Total Deposit -->
            <div class="col-md-4">
                <div class="card border-0 shadow-sm h-100">
                    <div class="card-header bg-gradient bg-info text-dark">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-bank2 me-1"></i> Total Deposits to Admin</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Approved</span>
                            <span class="fw-bold text-success fs-5">₹<?php echo number_format($dep_tot_app_amt, 2); ?> <small class="fs-6">(<?php echo $dep_tot_app_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom">
                            <span class="text-muted">Pending</span>
                            <span class="fw-bold text-warning fs-5">₹<?php echo number_format($dep_tot_pnd_amt, 2); ?> <small class="fs-6">(<?php echo $dep_tot_pnd_cnt; ?>)</small></span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-muted">Rejected</span>
                            <span class="fw-bold text-danger fs-5">₹<?php echo number_format($dep_tot_rej_amt, 2); ?> <small class="fs-6">(<?php echo $dep_tot_rej_cnt; ?>)</small></span>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- TAB 4: USERS & CASHFLOW SUMMARY -->
    <div class="tab-pane fade" id="tab-users" role="tabpanel">
        <div class="row g-3">
            <div class="col-md-6">
                <div class="card border shadow-sm">
                    <div class="card-header bg-light">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-people-fill text-primary me-2"></i>User Base Breakdown</h6>
                    </div>
                    <div class="card-body">
                        <div class="list-group list-group-flush">
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bi-person-check text-success me-2"></i> Active Verified Users</span>
                                <span class="badge bg-success rounded-pill px-3 py-2 fs-6"><?php echo $act_usr; ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bi-hourglass-split text-warning me-2"></i> Pending Verification Users</span>
                                <span class="badge bg-warning text-dark rounded-pill px-3 py-2 fs-6"><?php echo $pnd_usr; ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bi-person-x text-secondary me-2"></i> Inactive / Unverified Users</span>
                                <span class="badge bg-secondary rounded-pill px-3 py-2 fs-6"><?php echo ($tot_usr - $act_usr - $pnd_usr); ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center fw-bold bg-light">
                                <span>Total Assigned Users</span>
                                <span class="badge bg-primary rounded-pill px-3 py-2 fs-6"><?php echo $tot_usr; ?></span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-6">
                <div class="card border shadow-sm">
                    <div class="card-header bg-light">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-calculator text-success me-2"></i>Net Cashflow & Balance Analysis</h6>
                    </div>
                    <div class="card-body">
                        <div class="list-group list-group-flush">
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bg-success-subtle text-success p-1 rounded bi-plus-lg me-2"></i> Total User Recharge Collected</span>
                                <span class="fw-bold text-success">+ ₹<?php echo number_format($net_recharge, 2); ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bg-danger-subtle text-danger p-1 rounded bi-dash-lg me-2"></i> Total User Withdrawals Paid</span>
                                <span class="fw-bold text-danger">- ₹<?php echo number_format($net_withdrawal, 2); ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bg-info-subtle text-info p-1 rounded bi-dash-lg me-2"></i> Total Paid to Admin</span>
                                <span class="fw-bold text-info">- ₹<?php echo number_format($net_agency_deposit, 2); ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center fw-bold bg-light">
                                <span>Calculated Net Agency Holding</span>
                                <span class="fs-5 fw-bold <?php echo ($net_agency_balance >= 0) ? 'text-success' : 'text-danger'; ?>">
                                    ₹<?php echo number_format($net_agency_balance, 2); ?>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>
