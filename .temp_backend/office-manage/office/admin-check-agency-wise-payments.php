<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
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

    <?php
        // Fetch summary metrics for agency deposit overview cards
        $unseen_count = 0;
        $pending_count = 0;
        $pending_amount = 0;
        $successful_count = 0;
        $successful_amount = 0;
        $rejected_count = 0;

        $qry_p_stats = mysqli_query($conn, "SELECT stage_status, read_status, amount FROM `pay_to_admin`") or die(mysqli_error($conn));
        while($p_st = mysqli_fetch_array($qry_p_stats)){
            $amt = (float)$p_st['amount'];
            $status = strtoupper($p_st['stage_status']);
            $read_st = isset($p_st['read_status']) ? strtoupper($p_st['read_status']) : '';

            if($read_st != 'READ'){
                $unseen_count++;
            }

            if($status == 'EMPLOYEE-DONE' || $status == 'ADMIN-DONE' || $status == 'DONE'){
                $successful_count++;
                $successful_amount += $amt;
            } elseif($status == 'EMPLOYEE-REJECT' || $status == 'ADMIN-REJECT' || $status == 'REJECTED'){
                $rejected_count++;
            } else {
                $pending_count++;
                $pending_amount += $amt;
            }
        }
    ?>

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Check All Agency Payments</strong> Flow & Status List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Summary KPI Cards -->
            <div class="row px-4 mb-1">
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-info text-dark p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-dark-50">Unseen Deposits</h6>
                                <h4 class="mb-0 fw-bold"><?php echo $unseen_count; ?></h4>
                                <small class="text-dark-50">Unread Requests</small>
                            </div>
                            <div class="fs-1 text-dark-50"><i class="bi bi-eye-slash-fill"></i></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-warning text-dark p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-dark-50">Pending Deposits</h6>
                                <h4 class="mb-0 fw-bold"><?php echo $pending_count; ?></h4>
                                <small class="text-dark-50">₹<?php echo number_format($pending_amount, 2); ?> Pending</small>
                            </div>
                            <div class="fs-1 text-dark-50"><i class="bi bi-hourglass-split"></i></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-success text-white p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-white-50">Success Deposits</h6>
                                <h4 class="mb-0 fw-bold"><?php echo $successful_count; ?></h4>
                                <small class="text-white-50">₹<?php echo number_format($successful_amount, 2); ?> Approved</small>
                            </div>
                            <div class="fs-1 text-white-50"><i class="bi bi-check-circle-fill"></i></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-danger text-white p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-white-50">Reject Deposits</h6>
                                <h4 class="mb-0 fw-bold"><?php echo $rejected_count; ?></h4>
                                <small class="text-white-50">Declined / Void</small>
                            </div>
                            <div class="fs-1 text-white-50"><i class="bi bi-x-circle-fill"></i></div>
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
                            <th class="text-center" scope="col">Agency</th>
                            <th class="text-center" scope="col">Amount</th>
                            <th class="text-center" scope="col">Txn ID & Banks</th>
                            <th class="text-center" scope="col">Stage Status</th>
                            <th class="text-center" scope="col">Read Status</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `pay_to_admin` ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryagency = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[agency_id]' ") or die(mysqli_error($conn));
                            $resagency = mysqli_fetch_array($qryagency);
                    ?>
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                <?php
                                    if(!empty($result['image'])){
                                        echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' /></a>";
                                    }
                                    else {
                                        echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' />"; 
                                    }
                                ?>
                            </td>
                            <td>
                                <b>Name:</b> <?php echo isset($resagency['name']) ? $resagency['name'] : 'N/A'; ?> <br>
                                <small class="text-muted">AGENCY-<?php echo $result['agency_id']; ?></small>
                            </td>
                            <td><b>₹<?php echo $result['amount']; ?></b></td>
                            <td>
                                <b>Txn ID:</b> <?php echo !empty($result['transaction_id']) ? $result['transaction_id'] : 'N/A'; ?> <br>
                                <small><b>Bank:</b> <?php echo !empty($result['bank_name']) ? $result['bank_name'] : 'N/A'; ?></small>
                            </td>
                            <td>
                                <?php
                                    $status = $result['stage_status'];
                                    if($status == 'EMPLOYEE-DONE' || $status == 'ADMIN-DONE'){
                                        echo '<span class="badge bg-success px-3 py-2"><i class="bi bi-check-circle-fill me-1"></i> Successful</span>';
                                    } elseif($status == 'EMPLOYEE-REJECT' || $status == 'ADMIN-REJECT'){
                                        echo '<span class="badge bg-danger px-3 py-2"><i class="bi bi-x-circle-fill me-1"></i> Rejected</span>';
                                    } elseif($status == 'EMPLOYEE-PENDING'){
                                        echo '<span class="badge bg-primary px-3 py-2"><i class="bi bi-hourglass-split me-1"></i> Employee Pending</span>';
                                    } elseif($status == 'ADMIN-PENDING' || $status == 'AGENCY-PENDING'){
                                        echo '<span class="badge bg-warning text-dark px-3 py-2"><i class="bi bi-clock me-1"></i> Pending</span>';
                                    } else {
                                        echo '<span class="badge bg-secondary px-3 py-2">'.$status.'</span>';
                                    }
                                ?>
                            </td>
                            <td>
                                <div>
                                    <?php if(isset($result['read_status']) && $result['read_status'] == 'READ'){ ?>
                                        <span class="badge bg-success">READ</span>
                                    <?php } else { ?>
                                        <span class="badge bg-secondary">PENDING</span>
                                    <?php } ?>
                                </div>
                            </td>
                            <td>
                                <!-- View Details Button -->
                                <button type="button" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;">
                                    <i class="bi bi-eye"></i> View Flow
                                </button>
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Agency Payment Full Flow Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body text-start">
                                                <div class="container-fluid text-dark">
                                                    
                                                    <!-- Basic Info Cards -->
                                                    <div class="row my-3">
                                                        <div class="col-md-4 text-center border border-primary shadow py-2 rounded">
                                                            <b>Agency Details</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Name:</b> <i><?php echo isset($resagency['name']) ? $resagency['name'] : 'N/A'; ?></i></p>
                                                            <p class="mb-1"><b>Email:</b> <i><?php echo isset($resagency['email']) ? $resagency['email'] : 'N/A'; ?></i></p>
                                                            <p class="mb-0"><b>Mobile:</b> <i><?php echo isset($resagency['mob']) ? $resagency['mob'] : 'N/A'; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 text-center border border-primary shadow py-2 rounded">
                                                            <b>Payment Overview</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Amount:</b> <i class="fw-bold text-success">₹<?php echo $result['amount']; ?></i></p>
                                                            <p class="mb-1"><b>Txn ID:</b> <i><?php echo !empty($result['transaction_id']) ? $result['transaction_id'] : 'N/A'; ?></i></p>
                                                            <p class="mb-0"><b>Date:</b> <i><?php echo is_numeric($result['date_ts']) ? date('m/d/Y H:i:s a', (int)$result['date_ts']) : $result['date_ts']; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 text-center border border-primary shadow py-2 rounded">
                                                            <b>Bank Information</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Agency Bank:</b> <i><?php echo !empty($result['bank_name']) ? $result['bank_name'] : 'N/A'; ?></i></p>
                                                            <p class="mb-0"><b>Admin Bank:</b> <i><?php echo !empty($result['admin_bank_name']) ? $result['admin_bank_name'] : 'N/A'; ?></i></p>
                                                        </div>
                                                    </div>

                                                    <!-- Payment Flow Lifecycle Breakdown -->
                                                    <div class="card mb-3 border-info shadow-sm">
                                                        <div class="card-header bg-light">
                                                            <h6 class="mb-0 text-primary"><b><i class="bi bi-diagram-3 me-1"></i> Payment Lifecycle & Status Tracking</b></h6>
                                                        </div>
                                                        <div class="card-body">
                                                            <div class="row text-center align-items-center">
                                                                <div class="col-md-3 py-2 border-end">
                                                                    <span class="fw-bold d-block mb-1">1. Agency Status</span>
                                                                    <?php if(isset($result['read_status']) && $result['read_status'] == 'READ'){ ?>
                                                                        <span class="badge bg-success"><i class="bi bi-eye-fill me-1"></i> Read</span>
                                                                    <?php } else { ?>
                                                                        <span class="badge bg-warning text-dark"><i class="bi bi-eye-slash me-1"></i> Unread</span>
                                                                    <?php } ?>
                                                                </div>
                                                                <div class="col-md-3 py-2 border-end">
                                                                    <span class="fw-bold d-block mb-1">2. Agency Review</span>
                                                                    <?php
                                                                        $stg = strtoupper($result['stage_status']);
                                                                        if($stg == 'ADMIN-DONE' || $stg == 'EMPLOYEE-DONE' || $stg == 'DONE'){
                                                                            echo '<span class="badge bg-success"><i class="bi bi-check-circle-fill me-1"></i> Approve</span>';
                                                                        } elseif($stg == 'ADMIN-REJECT' || $stg == 'EMPLOYEE-REJECT' || $stg == 'REJECTED'){
                                                                            echo '<span class="badge bg-danger"><i class="bi bi-x-circle-fill me-1"></i> Rejected</span>';
                                                                        } else {
                                                                            echo '<span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i> Pending</span>';
                                                                        }
                                                                    ?>
                                                                </div>
                                                                <div class="col-md-3 py-2 border-end">
                                                                    <span class="fw-bold d-block mb-1">3. Employee Status</span>
                                                                    <?php if(isset($result['read_status']) && $result['read_status'] == 'READ'){ ?>
                                                                        <span class="badge bg-success"><i class="bi bi-eye-fill me-1"></i> Read</span>
                                                                    <?php } else { ?>
                                                                        <span class="badge bg-warning text-dark"><i class="bi bi-eye-slash me-1"></i> Unread</span>
                                                                    <?php } ?>
                                                                </div>
                                                                <div class="col-md-3 py-2">
                                                                    <span class="fw-bold d-block mb-1">4. Employee Review</span>
                                                                    <?php
                                                                        $stg = strtoupper($result['stage_status']);
                                                                        if($stg == 'EMPLOYEE-DONE' || $stg == 'ADMIN-DONE' || $stg == 'DONE'){
                                                                            echo '<span class="badge bg-success"><i class="bi bi-check-circle-fill me-1"></i> Approve</span>';
                                                                        } elseif($stg == 'EMPLOYEE-REJECT' || $stg == 'ADMIN-REJECT' || $stg == 'REJECTED'){
                                                                            echo '<span class="badge bg-danger"><i class="bi bi-x-circle-fill me-1"></i> Rejected</span>';
                                                                        } else {
                                                                            echo '<span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i> Pending</span>';
                                                                        }
                                                                    ?>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <!-- Payment Details / Remark / Screenshot -->
                                                    <div class="card border-secondary shadow-sm">
                                                        <div class="card-header bg-light">
                                                            <h6 class="mb-0 text-dark"><b>Additional Payment Details</b></h6>
                                                        </div>
                                                        <div class="card-body">
                                                            <div class="row">
                                                                <div class="col-md-6 mb-2">
                                                                    <b>Agency Review Remark:</b> <span><?php echo !empty($result['remark']) ? nl2br($result['remark']) : 'N/A'; ?></span>
                                                                </div>
                                                                <?php if(!empty($result['image'])){ ?>
                                                                <div class="col-md-6 mt-2 text-center">
                                                                    <b>Payment Screenshot / Receipt:</b><br>
                                                                    <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>">
                                                                        <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>" class="img-thumbnail shadow mt-1" style="max-height: 180px;" />
                                                                    </a>
                                                                </div>
                                                                <?php } ?>
                                                            </div>
                                                        </div>
                                                    </div>

                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
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

<?php include 'partials/_footer.php' ?>
