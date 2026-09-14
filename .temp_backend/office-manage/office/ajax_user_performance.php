<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    echo '<div class="alert alert-danger">Session expired. Please log in again.</div>';
    exit;
}

if(!isset($_POST['user_id']) || empty($_POST['user_id'])){
    echo '<div class="alert alert-warning">Invalid User ID.</div>';
    exit;
}

$user_id = mysqli_real_escape_string($conn, $_POST['user_id']);

// Fetch User Info
$qry_usr = mysqli_query($conn, "SELECT * FROM `users` WHERE `id` = '$user_id' AND `type` = 'USER'") or die(mysqli_error($conn));
if(mysqli_num_rows($qry_usr) == 0){
    echo '<div class="alert alert-danger">User not found.</div>';
    exit;
}
$usr = mysqli_fetch_array($qry_usr);

// Fetch Agency Info
$agency_id = $usr['agency_id'];
$agency_name = "N/A";
if(!empty($agency_id)){
    $qry_agnc = mysqli_query($conn, "SELECT * FROM `users` WHERE `id` = '$agency_id'") or die(mysqli_error($conn));
    if(mysqli_num_rows($qry_agnc) > 0){
        $agnc_data = mysqli_fetch_array($qry_agnc);
        $agency_name = $agnc_data['name'] . " (" . (!empty($agnc_data['agency_unq_id']) ? $agnc_data['agency_unq_id'] : 'AGENCY-'.$agnc_data['id']) . ")";
    }
}

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

// --- BOOK / SUBSCRIPTION METRICS ---
$subscriptions = [];
$active_sub_cnt = 0;
$total_sub_cnt = 0;
$qry_sub = mysqli_query($conn, "SELECT s.*, f.name as book_name, f.slag as book_slag FROM `subscription` s LEFT JOIN `features` f ON s.book_id = f.id WHERE s.user_id = '$user_id' ORDER BY ABS(s.id) DESC") or die(mysqli_error($conn));
while($sub = mysqli_fetch_array($qry_sub)){
    $total_sub_cnt++;
    $st = strtoupper($sub['stage_status']);
    $shw = strtoupper($sub['show_status']);
    if($st == 'DONE' && $shw == 'ACTIVE'){
        $active_sub_cnt++;
    }
    $subscriptions[] = $sub;
}

// --- RECHARGE METRICS ---
$rcg_today_app_cnt = 0; $rcg_today_app_amt = 0;
$rcg_today_pnd_cnt = 0; $rcg_today_pnd_amt = 0;
$rcg_today_rej_cnt = 0; $rcg_today_rej_amt = 0;

$rcg_mth_app_cnt = 0; $rcg_mth_app_amt = 0;

$rcg_tot_app_cnt = 0; $rcg_tot_app_amt = 0;
$rcg_tot_pnd_cnt = 0; $rcg_tot_pnd_amt = 0;
$rcg_tot_rej_cnt = 0; $rcg_tot_rej_amt = 0;

$qry_rcg = mysqli_query($conn, "SELECT * FROM `recharge` WHERE `user_id` = '$user_id'") or die(mysqli_error($conn));
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

$qry_wth = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE `user_id` = '$user_id'") or die(mysqli_error($conn));
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

// --- PROFIT / LOSS METRICS ---
$tot_profit = 0;
$tot_loss = 0;
$qry_pl = mysqli_query($conn, "SELECT SUM(profit) as total_profit, SUM(loss) as total_loss FROM `profit_loss` WHERE `user_id` = '$user_id'") or die(mysqli_error($conn));
if($pl_row = mysqli_fetch_array($qry_pl)){
    $tot_profit = floatval($pl_row['total_profit']);
    $tot_loss = floatval($pl_row['total_loss']);
}
$net_pl = $tot_profit - $tot_loss;

// Financial Balance
$net_user_balance = $rcg_tot_app_amt - $wth_tot_app_amt;
?>

<!-- Header Info Banner -->
<div class="row align-items-center bg-light border rounded-3 p-3 mx-1 my-4 shadow-sm">
    <div class="col-md-2 text-center mb-2 mb-md-0">
        <?php
            if(!empty($usr['img'])){
                echo "<img class='img-thumbnail rounded-circle shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$usr['img']."' style='width: 80px; height: 80px; object-fit: cover;' />";
            } else {
                echo "<img class='img-thumbnail rounded-circle shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' style='width: 80px; height: 80px; object-fit: cover;' />";
            }
        ?>
    </div>
    <div class="col-md-6">
        <h4 class="mb-1 text-primary font-weight-bold"><?php echo htmlspecialchars($usr['name']); ?></h4>
        <p class="text-muted mb-1 small">
            <i class="bi bi-telephone me-1"></i> Phone: <strong><?php echo htmlspecialchars($usr['mob']); ?></strong> &nbsp;|&nbsp; 
            <i class="bi bi-envelope me-1"></i> Email: <strong><?php echo htmlspecialchars($usr['email']); ?></strong><br>
            <i class="bi bi-building me-1"></i> Agency: <strong><?php echo htmlspecialchars($agency_name); ?></strong>
        </p>
        <div>
            <span class="badge <?php echo ($usr['show_status'] == 'ACTIVE') ? 'bg-success' : 'bg-danger'; ?> me-2">
                Status: <?php echo $usr['show_status']; ?>
            </span>
            <span class="badge <?php echo ($usr['verification'] == 'DONE') ? 'bg-info text-dark' : 'bg-warning text-dark'; ?>">
                Verification: <?php echo $usr['verification']; ?>
            </span>
        </div>
    </div>
    <div class="col-md-4 text-md-end mt-2 mt-md-0">
        <div class="bg-white border p-2 rounded shadow-sm text-center">
            <span class="text-muted small d-block">Net Balance (Recharge - Withdrawal)</span>
            <span class="fs-4 fw-bold <?php echo ($net_user_balance >= 0) ? 'text-success' : 'text-danger'; ?>">
                ₹<?php echo number_format($net_user_balance, 2); ?>
            </span>
            <div class="text-muted border-top pt-1 mt-1 fs-7">
                Active Books: <strong class="text-primary"><?php echo $active_sub_cnt; ?> / <?php echo $total_sub_cnt; ?></strong>
            </div>
        </div>
    </div>
</div>

<!-- Modal Navigation Tabs -->
<ul class="nav nav-pills nav-fill mb-3 gap-2 px-2" id="userStatsTabs" role="tablist">
    <li class="nav-item" role="presentation">
        <button class="nav-link active fw-semibold shadow-sm" id="user-overview-tab" data-bs-toggle="tab" data-bs-target="#user-tab-overview" type="button" role="tab">
            <i class="bi bi-speedometer2 me-1"></i> Performance Summary
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link fw-semibold shadow-sm" id="user-today-tab" data-bs-toggle="tab" data-bs-target="#user-tab-today" type="button" role="tab">
            <i class="bi bi-calendar-event me-1"></i> Current (Today's)
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link fw-semibold shadow-sm" id="user-lifetime-tab" data-bs-toggle="tab" data-bs-target="#user-tab-lifetime" type="button" role="tab">
            <i class="bi bi-pie-chart me-1"></i> Total (Lifetime)
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link fw-semibold shadow-sm" id="user-books-tab" data-bs-toggle="tab" data-bs-target="#user-tab-books" type="button" role="tab">
            <i class="bi bi-book me-1"></i> Books & Profit/Loss
        </button>
    </li>
</ul>

<!-- Tab Content -->
<div class="tab-content px-1" id="userStatsTabsContent">

    <!-- TAB 1: OVERVIEW SUMMARY -->
    <div class="tab-pane fade show active" id="user-tab-overview" role="tabpanel">
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-primary text-white p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-white-50">Active Subscriptions</h6>
                            <h3 class="mb-0 fw-bold"><?php echo $active_sub_cnt; ?></h3>
                            <small class="text-white-50">Out of <?php echo $total_sub_cnt; ?> Total Books</small>
                        </div>
                        <div class="fs-1 text-white-50"><i class="bi bi-journal-check"></i></div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-success text-white p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-white-50">Total Recharge</h6>
                            <h3 class="mb-0 fw-bold">₹<?php echo number_format($rcg_tot_app_amt, 2); ?></h3>
                            <small class="text-white-50"><?php echo $rcg_tot_app_cnt; ?> Successful Txns</small>
                        </div>
                        <div class="fs-1 text-white-50"><i class="bi bi-wallet2"></i></div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-warning text-dark p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-dark-50">Total Withdrawal</h6>
                            <h3 class="mb-0 fw-bold">₹<?php echo number_format($wth_tot_app_amt, 2); ?></h3>
                            <small class="text-dark-50"><?php echo $wth_tot_app_cnt; ?> Approved Payments</small>
                        </div>
                        <div class="fs-1 text-dark-50"><i class="bi bi-arrow-up-right-circle-fill"></i></div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-info text-dark p-3 h-100">
                    <div class="d-flex align-items-center justify-content-between">
                        <div>
                            <h6 class="mb-1 text-dark-50">Net Profit / Loss</h6>
                            <h3 class="mb-0 fw-bold <?php echo ($net_pl >= 0) ? 'text-success' : 'text-danger'; ?>">₹<?php echo number_format($net_pl, 2); ?></h3>
                            <small class="text-dark-50">P: ₹<?php echo number_format($tot_profit, 2); ?> | L: ₹<?php echo number_format($tot_loss, 2); ?></small>
                        </div>
                        <div class="fs-1 text-dark-50"><i class="bi bi-graph-up-arrow"></i></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Current vs Total Quick Comparison Table -->
        <div class="card border shadow-sm mb-4">
            <div class="card-header bg-light">
                <h6 class="mb-0 fw-bold text-dark"><i class="bi bi-table me-2"></i>User Performance Snapshot Matrix</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover table-bordered align-middle text-center mb-0">
                        <thead class="table-light">
                            <tr>
                                <th scope="col" class="text-start">Category</th>
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
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- TAB 2: TODAY'S CURRENT PERFORMANCE -->
    <div class="tab-pane fade" id="user-tab-today" role="tabpanel">
        <h6 class="fw-bold text-primary mb-3"><i class="bi bi-calendar-check me-2"></i>Current (Today's) Detailed Breakdown</h6>
        <div class="row g-3 mb-3">

            <!-- Today Recharge -->
            <div class="col-md-6">
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
            <div class="col-md-6">
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

        </div>
    </div>

    <!-- TAB 3: LIFETIME PERFORMANCE -->
    <div class="tab-pane fade" id="user-tab-lifetime" role="tabpanel">
        <h6 class="fw-bold text-primary mb-3"><i class="bi bi-infinity me-2"></i>Total (Lifetime) Detailed Breakdown</h6>
        <div class="row g-3 mb-3">

            <!-- Total Recharge -->
            <div class="col-md-6">
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
            <div class="col-md-6">
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

        </div>
    </div>

    <!-- TAB 4: BOOKS & PROFIT/LOSS -->
    <div class="tab-pane fade" id="user-tab-books" role="tabpanel">
        <div class="row g-3">
            <div class="col-md-7">
                <div class="card border shadow-sm h-100">
                    <div class="card-header bg-light d-flex justify-content-between align-items-center">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-journal-bookmark text-primary me-2"></i>Subscribed Books & Accounts</h6>
                        <span class="badge bg-primary rounded-pill"><?php echo count($subscriptions); ?> Total</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0 text-center">
                                <thead class="table-light">
                                    <tr>
                                        <th>Book Name</th>
                                        <th>Username</th>
                                        <th>Password</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php if(empty($subscriptions)){ ?>
                                        <tr>
                                            <td colspan="3" class="text-muted py-4">No subscriptions found for this user.</td>
                                        </tr>
                                    <?php } else { 
                                        foreach($subscriptions as $sb){ ?>
                                        <tr>
                                            <td class="fw-semibold text-start ps-3">
                                                <?php echo !empty($sb['book_name']) ? htmlspecialchars($sb['book_name']) : 'Book #'.$sb['book_id']; ?>
                                            </td>
                                            <td>
                                                <code class="text-dark"><?php echo !empty($sb['username']) ? htmlspecialchars($sb['username']) : 'N/A'; ?></code>
                                            </td>
                                            <td>
                                                <code class="text-dark"><?php echo !empty($sb['password']) ? htmlspecialchars($sb['password']) : 'N/A'; ?></code>
                                            </td>
                                            <td>
                                                <span class="badge <?php echo ($sb['stage_status'] == 'DONE' && $sb['show_status'] == 'ACTIVE') ? 'bg-success' : 'bg-warning text-dark'; ?>">
                                                    <?php echo $sb['stage_status']; ?> (<?php echo $sb['show_status']; ?>)
                                                </span>
                                            </td>
                                        </tr>
                                    <?php } } ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-md-5">
                <div class="card border shadow-sm h-100">
                    <div class="card-header bg-light">
                        <h6 class="mb-0 fw-bold"><i class="bi bi-graph-up-arrow text-success me-2"></i>Profit / Loss Breakdown</h6>
                    </div>
                    <div class="card-body">
                        <div class="list-group list-group-flush">
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bi-plus-circle-fill text-success me-2"></i> Total Profit</span>
                                <span class="fw-bold text-success">₹<?php echo number_format($tot_profit, 2); ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center">
                                <span><i class="bi bi-dash-circle-fill text-danger me-2"></i> Total Loss</span>
                                <span class="fw-bold text-danger">₹<?php echo number_format($tot_loss, 2); ?></span>
                            </div>
                            <div class="list-group-item d-flex justify-content-between align-items-center fw-bold bg-light">
                                <span>Net Profit / Loss</span>
                                <span class="fs-5 fw-bold <?php echo ($net_pl >= 0) ? 'text-success' : 'text-danger'; ?>">
                                    ₹<?php echo number_format($net_pl, 2); ?>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>
