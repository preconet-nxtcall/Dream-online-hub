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
        // Fetch summary metrics for withdrawal overview cards
        $unseen_count = 0;
        $pending_count = 0;
        $pending_amount = 0;
        $successful_count = 0;
        $successful_amount = 0;
        $rejected_count = 0;

        $qry_w_stats = mysqli_query($conn, "SELECT stage_status, employee_read_status, agency_read_status, amount FROM `withdrawal`") or die(mysqli_error($conn));
        while($w_st = mysqli_fetch_array($qry_w_stats)){
            $amt = (float)$w_st['amount'];
            $status = strtoupper($w_st['stage_status']);
            $emp_read = isset($w_st['employee_read_status']) ? strtoupper($w_st['employee_read_status']) : '';

            if($emp_read != 'READ'){
                $unseen_count++;
            }

            if($status == 'EMPLOYEE-DONE' || $status == 'AGENCY-DONE' || $status == 'DONE'){
                $successful_count++;
                $successful_amount += $amt;
            } elseif($status == 'EMPLOYEE-REJECT' || $status == 'AGENCY-REJECT' || $status == 'REJECTED'){
                $rejected_count++;
            } else {
                $pending_count++;
                $pending_amount += $amt;
            }
        }
    ?>

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Check All Withdrawal</strong> Flow & Status List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Summary KPI Cards -->
            <div class="row px-4 mb-4">
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-info text-dark p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-dark-50">Unseen Withdrawals</h6>
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
                                <h6 class="mb-1 text-dark-50">Pending Withdrawals</h6>
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
                                <h6 class="mb-1 text-white-50">Successful Withdrawals</h6>
                                <h4 class="mb-0 fw-bold"><?php echo $successful_count; ?></h4>
                                <small class="text-white-50">₹<?php echo number_format($successful_amount, 2); ?> Paid</small>
                            </div>
                            <div class="fs-1 text-white-50"><i class="bi bi-check-circle-fill"></i></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-danger text-white p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-white-50">Rejected Withdrawals</h6>
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
                            <th class="text-center" scope="col">User & Book</th>
                            <th class="text-center" scope="col">Amount</th>
                            <th class="text-center" scope="col">Agency</th>
                            <th class="text-center" scope="col">Stage Status</th>
                            <th class="text-center" scope="col">Read Status</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `withdrawal` ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[user_id]' ") or die(mysqli_error($conn));
                            $resusr = mysqli_fetch_array($qryusr);
                            $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$result[book_id]' ") or die(mysqli_error($conn));
                            $resbook = mysqli_fetch_array($qrybook);
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
                                <b>User:</b> <?php echo isset($resusr['name']) ? $resusr['name'] : 'N/A'; ?> <br>
                                <b>Book:</b> <?php echo isset($resbook['name']) ? $resbook['name'] : 'N/A'; ?>
                            </td>
                            <td><b>Rs. <?php echo $result['amount']; ?></b></td>
                            <td><?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?></td>
                            <td>
                                <?php
                                    $status = $result['stage_status'];
                                    if($status == 'EMPLOYEE-PENDING'){
                                        echo '<span class="badge bg-warning text-dark px-3 py-2"><i class="bi bi-hourglass-split me-1"></i> Employee Pending</span>';
                                    } elseif($status == 'EMPLOYEE-PASS'){
                                        echo '<span class="badge bg-info text-dark px-3 py-2"><i class="bi bi-arrow-right-circle me-1"></i> Passed to Agency</span>';
                                    } elseif($status == 'AGENCY-PENDING'){
                                        echo '<span class="badge bg-primary px-3 py-2"><i class="bi bi-clock-history me-1"></i> Agency Pending</span>';
                                    } elseif($status == 'AGENCY-DONE'){
                                        echo '<span class="badge bg-success px-3 py-2"><i class="bi bi-check-circle me-1"></i> Agency Done</span>';
                                    } elseif($status == 'EMPLOYEE-DONE'){
                                        echo '<span class="badge bg-success px-3 py-2"><i class="bi bi-check-all me-1"></i> Employee Done</span>';
                                    } elseif($status == 'EMPLOYEE-REJECT'){
                                        echo '<span class="badge bg-danger px-3 py-2"><i class="bi bi-x-circle me-1"></i> Employee Rejected</span>';
                                    } else {
                                        echo '<span class="badge bg-secondary px-3 py-2">'.$status.'</span>';
                                    }
                                ?>
                            </td>
                            <td>
                                <div>
                                    <small>Emp Read:</small>
                                    <?php if($result['employee_read_status'] == 'READ'){ ?>
                                        <span class="badge bg-success">READ</span>
                                    <?php } else { ?>
                                        <span class="badge bg-secondary">PENDING</span>
                                    <?php } ?>
                                </div>
                                <div class="mt-1">
                                    <small>Agency Read:</small>
                                    <?php if($result['agency_read_status'] == 'READ'){ ?>
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
                                                        <h5 class="modal-title text-white ml-1"><b>Withdrawal Full Flow Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body text-start">
                                                <div class="container-fluid text-dark">
                                                    
                                                    <!-- Basic Info Card -->
                                                    <div class="row my-3">
                                                        <div class="col-md-4 text-center border border-primary shadow py-2 rounded">
                                                            <b>User Details</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Name:</b> <i><?php echo isset($resusr['name']) ? $resusr['name'] : 'N/A'; ?></i></p>
                                                            <p class="mb-1"><b>Email:</b> <i><?php echo isset($resusr['email']) ? $resusr['email'] : 'N/A'; ?></i></p>
                                                            <p class="mb-0"><b>Mobile:</b> <i><?php echo isset($resusr['mob']) ? $resusr['mob'] : 'N/A'; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 text-center border border-primary shadow py-2 rounded">
                                                            <b>Request Overview</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Book:</b> <i><?php echo isset($resbook['name']) ? $resbook['name'] : 'N/A'; ?></i></p>
                                                            <p class="mb-1"><b>Amount:</b> <i class="fw-bold text-success">Rs. <?php echo $result['amount']; ?></i></p>
                                                            <p class="mb-0"><b>Date:</b> <i><?php echo is_numeric($result['date_ts']) ? date('m/d/Y H:i:s a', (int)$result['date_ts']) : $result['date_ts']; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 text-center border border-primary shadow py-2 rounded">
                                                            <b>Agency Details</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Agency Name:</b> <i><?php echo isset($resagency['name']) ? $resagency['name'] : 'AGENCY-'.$result['agency_id']; ?></i></p>
                                                            <p class="mb-0"><b>Agency ID:</b> <i><?php echo $result['agency_id']; ?></i></p>
                                                        </div>
                                                    </div>

                                                    <!-- Description / Detail -->
                                                    <div class="row mb-3">
                                                        <div class="col-md-12 border border-secondary shadow py-2 text-wrap rounded">
                                                            <b>User Withdrawal Description:</b> 
                                                            <p class="mb-0 fw-500"><i><?php echo !empty($result['deatil']) ? nl2br($result['deatil']) : 'N/A'; ?></i></p>
                                                        </div>
                                                    </div>

                                                    <!-- Withdrawal Flow Status Step Breakdown -->
                                                    <div class="card mb-3 border-info shadow-sm">
                                                        <div class="card-header bg-light">
                                                            <h6 class="mb-0 text-primary"><b><i class="bi bi-diagram-3 me-1"></i> Withdrawal Lifecycle & Flow Tracking</b></h6>
                                                        </div>
                                                        <div class="card-body">
                                                            <div class="row text-center align-items-center">
                                                                <div class="col-md-3 py-2 border-end">
                                                                    <span class="fw-bold d-block mb-1">1. Agency Status</span>
                                                                    <?php if(isset($result['agency_read_status']) && $result['agency_read_status'] == 'READ'){ ?>
                                                                        <span class="badge bg-success"><i class="bi bi-eye-fill me-1"></i> Read</span>
                                                                    <?php } else { ?>
                                                                        <span class="badge bg-warning text-dark"><i class="bi bi-eye-slash me-1"></i> Unread</span>
                                                                    <?php } ?>
                                                                </div>
                                                                <div class="col-md-3 py-2 border-end">
                                                                    <span class="fw-bold d-block mb-1">2. Agency Review</span>
                                                                    <?php
                                                                        $stg = strtoupper($result['stage_status']);
                                                                        if($stg == 'AGENCY-DONE' || $stg == 'AGENCY-PENDING' || $stg == 'EMPLOYEE-PASS' || $stg == 'EMPLOYEE-DONE' || $stg == 'DONE'){
                                                                            echo '<span class="badge bg-success"><i class="bi bi-check-circle-fill me-1"></i> Approve</span>';
                                                                        } elseif($stg == 'AGENCY-REJECT'){
                                                                            echo '<span class="badge bg-danger"><i class="bi bi-x-circle-fill me-1"></i> Rejected</span>';
                                                                        } else {
                                                                            echo '<span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i> Pending</span>';
                                                                        }
                                                                    ?>
                                                                </div>
                                                                <div class="col-md-3 py-2 border-end">
                                                                    <span class="fw-bold d-block mb-1">3. Employee Status</span>
                                                                    <?php if(isset($result['employee_read_status']) && $result['employee_read_status'] == 'READ'){ ?>
                                                                        <span class="badge bg-success"><i class="bi bi-eye-fill me-1"></i> Read</span>
                                                                    <?php } else { ?>
                                                                        <span class="badge bg-warning text-dark"><i class="bi bi-eye-slash me-1"></i> Unread</span>
                                                                    <?php } ?>
                                                                </div>
                                                                <div class="col-md-3 py-2">
                                                                    <span class="fw-bold d-block mb-1">4. Employee Review</span>
                                                                    <?php
                                                                        $stg = strtoupper($result['stage_status']);
                                                                        if($stg == 'EMPLOYEE-DONE' || $stg == 'DONE'){
                                                                            echo '<span class="badge bg-success"><i class="bi bi-check-circle-fill me-1"></i> Approve</span>';
                                                                        } elseif($stg == 'EMPLOYEE-REJECT' || $stg == 'REJECTED'){
                                                                            echo '<span class="badge bg-danger"><i class="bi bi-x-circle-fill me-1"></i> Rejected</span>';
                                                                        } else {
                                                                            echo '<span class="badge bg-warning text-dark"><i class="bi bi-hourglass-split me-1"></i> Pending</span>';
                                                                        }
                                                                    ?>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <!-- Transaction & Bank Information -->
                                                    <?php if(!empty($result['transaction_id']) || !empty($result['bank_name']) || !empty($result['emp_agency_image']) || !empty($result['remark'])){ ?>
                                                    <div class="card border-success shadow-sm">
                                                        <div class="card-header bg-light">
                                                            <h6 class="mb-0 text-success"><b>Payout / Action Details</b></h6>
                                                        </div>
                                                        <div class="card-body">
                                                            <div class="row">
                                                                <div class="col-md-6 mb-2">
                                                                    <b>Transaction ID:</b> <span><?php echo !empty($result['transaction_id']) ? $result['transaction_id'] : 'N/A'; ?></span>
                                                                    <br>
                                                                    <b>Agency Review Remark:</b> <span><?php echo !empty($result['remark']) ? nl2br($result['remark']) : 'N/A'; ?></span>
                                                                    <br>
                                                                    <b>Bank Name:</b> <span><?php echo !empty($result['bank_name']) ? $result['bank_name'] : 'N/A'; ?></span>
                                                                </div>
                                                                <?php if(!empty($result['emp_agency_image'])){ ?>
                                                                <div class="col-md-6 mt-2 text-center">
                                                                    <b>Payment Screenshot:</b><br>
                                                                    <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['emp_agency_image']; ?>">
                                                                        <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['emp_agency_image']; ?>" class="img-thumbnail shadow mt-1" style="max-height: 150px;" />
                                                                    </a>
                                                                </div>
                                                                <?php } ?>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <?php } ?>

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
