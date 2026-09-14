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
                    <h5 class="mb-0"><?php echo isset($brdcmp) ? $brdcmp : 'Check Users Recharge Flow'; ?></h5><br>
                    <span>Home / <?php echo isset($brdcmp) ? $brdcmp : 'Check Users Recharge Flow'; ?></span>
                </p>
            </div>
            <a href="admin_dashboard" class="btn btn_primary btn-sm">Dashboard <i class="bi bi-arrow-right ms-2"></i></a>
        </div>
    </div>

    <?php
        // Fetch summary metrics for quick overview cards
        $unseen_count = 0;
        $pending_count = 0;
        $pending_amount = 0;
        $success_count = 0;
        $success_amount = 0;
        $rejected_count = 0;

        $qry_stats = mysqli_query($conn, "SELECT stage_status, employee_read_status, agency_read_status, amount FROM `recharge`") or die(mysqli_error($conn));
        while($st = mysqli_fetch_array($qry_stats)){
            $amt = (float)$st['amount'];
            $status = strtoupper($st['stage_status']);
            $emp_read = isset($st['employee_read_status']) ? strtoupper($st['employee_read_status']) : '';

            if($emp_read != 'READ'){
                $unseen_count++;
            }

            if($status == 'EMPLOYEE-DONE' || $status == 'AGENCY-DONE' || $status == 'DONE'){
                $success_count++;
                $success_amount += $amt;
            } elseif($status == 'EMPLOYEE-REJECT' || $status == 'AGENCY-REJECT' || $status == 'REJECTED'){
                $rejected_count++;
            } else {
                $pending_count++;
                $pending_amount += $amt;
            }
        }
    ?>

    <!-- Summary KPI Cards -->
    

    <!-- Main Table Card -->
    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Check All User Recharge</strong> Flow & Status List</h5>
        </div>
        <div class="card-body pb-0">
            <div class="row px-4 mb-4">
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-info text-dark p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-dark-50">Unseen Recharges</h6>
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
                                <h6 class="mb-1 text-dark-50">Pending Recharges</h6>
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
                                <h6 class="mb-1 text-white-50">Success Recharge</h6>
                                <h4 class="mb-0 fw-bold"><?php echo $success_count; ?></h4>
                                <small class="text-white-50">₹<?php echo number_format($success_amount, 2); ?> Approved</small>
                            </div>
                            <div class="fs-1 text-white-50"><i class="bi bi-check-circle-fill"></i></div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-2">
                    <div class="card border-0 shadow-sm rounded-3 bg-gradient bg-danger text-white p-3">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <h6 class="mb-1 text-white-50">Reject Recharges</h6>
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
                            <th class="text-center" scope="col">Screenshot</th>
                            <th class="text-center" scope="col">User & Book</th>
                            <th class="text-center" scope="col">Txn / UTR ID</th>
                            <th class="text-center" scope="col">Stage Status</th>
                            <th class="text-center" scope="col">Read Status</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `recharge` ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[user_id]' ") or die(mysqli_error($conn));
                            $resusr = mysqli_fetch_array($qryusr);

                            $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$result[book_id]' ") or die(mysqli_error($conn));
                            $resbook = mysqli_fetch_array($qrybook);

                            $qryagency = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$result[emp_id]' ") or die(mysqli_error($conn));
                            $resagency = mysqli_fetch_array($qryagency);
                    ?>
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                <?php
                                    if(!empty($result['image'])){
                                        echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' title='Click to view full screenshot'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' style='max-height:60px; max-width:80px; object-fit:cover;' /></a>";
                                    }
                                    else {
                                        echo "<img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH."no-img.png' style='max-height:60px; max-width:80px; object-fit:cover;' />"; 
                                    }
                                ?>
                            </td>
                            <td>
                                <b>User:</b> <?php echo isset($resusr['name']) ? $resusr['name'] : 'N/A'; ?> <br>
                                <small class="text-muted"><b>Book:</b> <?php echo isset($resbook['name']) ? $resbook['name'] : 'N/A'; ?></small>
                            </td>
                            <td>
                                <b>Amount : ₹<?php echo number_format($result['amount'], 2); ?></b><br>
                                <b>Txn ID:</b> <?php echo !empty($result['transection_id']) ? $result['transection_id'] : 'N/A'; ?> <br>
                                <small class="text-muted"><b>Bank:</b> <?php echo !empty($result['bank_name']) ? $result['bank_name'] : (!empty($result['bank_slag']) ? $result['bank_slag'] : 'N/A'); ?></small>
                            </td>
                            <td>
                                Agency : <?php echo isset($resagency['name']) ? $resagency['name'] : (!empty($result['emp_id']) ? 'EMP/AGENCY-'.$result['emp_id'] : 'Unassigned'); ?>
                                <br>
                                <?php
                                    $status = strtoupper($result['stage_status']);
                                    if($status == 'EMPLOYEE-PENDING'){
                                        echo '<span class="badge bg-warning text-dark px-3 py-2"><i class="bi bi-hourglass-split me-1"></i> Employee Pending</span>';
                                    } elseif($status == 'EMPLOYEE-PASS'){
                                        echo '<span class="badge bg-info text-dark px-3 py-2"><i class="bi bi-arrow-right-circle me-1"></i> Passed to Agency</span>';
                                    } elseif($status == 'AGENCY-PENDING' || $status == 'PENDING'){
                                        echo '<span class="badge bg-primary px-3 py-2"><i class="bi bi-clock-history me-1"></i> Agency Pending</span>';
                                    } elseif($status == 'AGENCY-DONE'){
                                        echo '<span class="badge bg-info text-dark px-3 py-2"><i class="bi bi-check-circle me-1"></i> Agency Verified</span>';
                                    } elseif($status == 'EMPLOYEE-DONE' || $status == 'DONE'){
                                        echo '<span class="badge bg-success px-3 py-2"><i class="bi bi-check-all me-1"></i> Recharge Complete</span>';
                                    } elseif($status == 'EMPLOYEE-REJECT' || $status == 'REJECTED'){
                                        echo '<span class="badge bg-danger px-3 py-2"><i class="bi bi-x-circle me-1"></i> Employee Rejected</span>';
                                    } elseif($status == 'AGENCY-REJECT'){
                                        echo '<span class="badge bg-danger px-3 py-2"><i class="bi bi-x-circle-fill me-1"></i> Agency Rejected</span>';
                                    } else {
                                        echo '<span class="badge bg-secondary px-3 py-2">'.$status.'</span>';
                                    }
                                ?>
                            </td>
                            <td>
                                <div>
                                    <small>Emp Read:</small>
                                    <?php if(isset($result['employee_read_status']) && $result['employee_read_status'] == 'READ'){ ?>
                                        <span class="badge bg-success">READ</span>
                                    <?php } else { ?>
                                        <span class="badge bg-secondary">PENDING</span>
                                    <?php } ?>
                                </div>
                                <div class="mt-1">
                                    <small>Agency Read:</small>
                                    <?php if(isset($result['agency_read_status']) && $result['agency_read_status'] == 'READ'){ ?>
                                        <span class="badge bg-success">READ</span>
                                    <?php } else { ?>
                                        <span class="badge bg-secondary">PENDING</span>
                                    <?php } ?>
                                </div>
                            </td>
                            <td>
                                <!-- View Flow Details Button -->
                                <button type="button" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;">
                                    <i class="bi bi-eye"></i> View Flow
                                </button>

                                <!-- Modal View Flow -->
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1 w-100 align-items-center">
                                                    <div class="col-8 text-start">
                                                        <h5 class="modal-title text-white"><b>User Recharge Full Flow Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-end">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body text-start">
                                                <div class="container-fluid text-dark">
                                                    
                                                    <!-- Basic Info Card -->
                                                    <div class="row my-3">
                                                        <div class="col-md-4 text-center border border-primary shadow-sm py-2 rounded">
                                                            <b class="text-primary"><i class="bi bi-person-fill me-1"></i> User Details</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Name:</b> <i><?php echo isset($resusr['name']) ? $resusr['name'] : 'N/A'; ?></i></p>
                                                            <p class="mb-1"><b>Email:</b> <i><?php echo isset($resusr['email']) ? $resusr['email'] : 'N/A'; ?></i></p>
                                                            <p class="mb-0"><b>Mobile:</b> <i><?php echo isset($resusr['mob']) ? $resusr['mob'] : 'N/A'; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 text-center border border-primary shadow-sm py-2 rounded">
                                                            <b class="text-primary"><i class="bi bi-card-checklist me-1"></i> Recharge Overview</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Book:</b> <i><?php echo isset($resbook['name']) ? $resbook['name'] : 'N/A'; ?></i></p>
                                                            <p class="mb-1"><b>Amount:</b> <i class="fw-bold text-success">₹<?php echo number_format($result['amount'], 2); ?></i></p>
                                                            <p class="mb-0"><b>Date:</b> <i><?php echo is_numeric($result['date_ts']) ? date('m/d/Y H:i:s a', (int)$result['date_ts']) : $result['date_ts']; ?></i></p>
                                                        </div>
                                                        <div class="col-md-4 text-center border border-primary shadow-sm py-2 rounded">
                                                            <b class="text-primary"><i class="bi bi-building me-1"></i> Agency / Employee</b>
                                                            <hr class="my-1">
                                                            <p class="mb-1"><b>Assigned To:</b> <i><?php echo isset($resagency['name']) ? $resagency['name'] : (!empty($result['emp_id']) ? 'ID-'.$result['emp_id'] : 'Unassigned'); ?></i></p>
                                                            <p class="mb-0"><b>Employee ID:</b> <i><?php echo !empty($result['emp_id']) ? $result['emp_id'] : 'N/A'; ?></i></p>
                                                        </div>
                                                    </div>

                                                    <!-- Payment Screenshot Section -->
                                                    <div class="card mb-3 border-primary shadow-sm">
                                                        <div class="card-header bg-light d-flex justify-content-between align-items-center py-2">
                                                            <h6 class="mb-0 text-primary"><b><i class="bi bi-image me-1"></i> Payment Screenshot & Invoice</b></h6>
                                                            <?php if(!empty($result['invoice'])){ ?>
                                                                <a target="_blank" href="<?php echo $m_url.ADD_DOCUMENT_SITE_PATH.$result['invoice']; ?>" class="btn btn-sm btn-outline-primary py-0"><i class="bi bi-download me-1"></i> Download Invoice</a>
                                                            <?php } ?>
                                                        </div>
                                                        <div class="card-body text-center py-3">
                                                            <div class="row align-items-center">
                                                                <div class="col-md-6 mb-2">
                                                                    <span class="fw-bold d-block mb-2">User Uploaded Screenshot:</span>
                                                                    <?php if(!empty($result['image'])){ ?>
                                                                        <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>">
                                                                            <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>" class="img-thumbnail shadow hover-zoom" style="max-height: 220px; border-radius: 8px;" alt="User Payment Screenshot" />
                                                                        </a>
                                                                    <?php } else { ?>
                                                                        <div class="p-3 border rounded bg-light text-muted">
                                                                            <i class="bi bi-image-alt fs-2 d-block"></i>
                                                                            No Screenshot Image Uploaded
                                                                        </div>
                                                                    <?php } ?>
                                                                </div>
                                                                <div class="col-md-6 mb-2 text-start border-start">
                                                                    <b class="d-block mb-1"><i class="bi bi-receipt me-1"></i> Transaction & Bank Info:</b>
                                                                    <ul class="list-group list-group-flush small">
                                                                        <li class="list-group-item bg-transparent px-0 py-1"><b>Txn / UTR ID:</b> <?php echo !empty($result['transection_id']) ? $result['transection_id'] : '<span class="text-muted">N/A</span>'; ?></li>
                                                                        <li class="list-group-item bg-transparent px-0 py-1"><b>Bank Name:</b> <?php echo !empty($result['bank_name']) ? $result['bank_name'] : '<span class="text-muted">N/A</span>'; ?></li>
                                                                        <?php if(!empty($result['bank_details'])){ ?>
                                                                            <li class="list-group-item bg-transparent px-0 py-1"><b>Bank Details:</b> <?php echo nl2br($result['bank_details']); ?></li>
                                                                        <?php } ?>
                                                                    </ul>

                                                                    <?php if(!empty($result['emp_agency_image'])){ ?>
                                                                        <div class="mt-3">
                                                                            <span class="fw-bold d-block mb-1">Agency / Employee Proof Screenshot:</span>
                                                                            <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['emp_agency_image']; ?>">
                                                                                <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['emp_agency_image']; ?>" class="img-thumbnail shadow" style="max-height: 100px;" alt="Agency Proof Image" />
                                                                            </a>
                                                                        </div>
                                                                    <?php } ?>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <!-- Recharge Flow Status Step Breakdown -->
                                                    <div class="card mb-3 border-info shadow-sm">
                                                        <div class="card-header bg-light py-2">
                                                            <h6 class="mb-0 text-primary"><b><i class="bi bi-diagram-3 me-1"></i> Recharge Lifecycle & Flow Tracking</b></h6>
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
                                                                         if($stg == 'AGENCY-DONE' || $stg == 'EMPLOYEE-PENDING' || $stg == 'EMPLOYEE-DONE' || $stg == 'DONE'){
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

                                                    <!-- Remarks & Notes Section -->
                                                    <?php if(!empty($result['remark']) || !empty($result['employee_remark'])){ ?>
                                                    <div class="card border-secondary shadow-sm">
                                                        <div class="card-header bg-light py-2">
                                                            <h6 class="mb-0 text-secondary"><b><i class="bi bi-chat-left-text me-1"></i> Remarks & Verification Notes</b></h6>
                                                        </div>
                                                        <div class="card-body py-2">
                                                            <?php if(!empty($result['remark'])){ ?>
                                                                <p class="mb-1"><b>Agency Review Remark:</b> <i><?php echo nl2br($result['remark']); ?></i></p>
                                                            <?php } ?>
                                                            <?php if(!empty($result['employee_remark'])){ ?>
                                                                <p class="mb-0"><b>Employee Review Remark:</b> <i><?php echo nl2br($result['employee_remark']); ?></i></p>
                                                            <?php } ?>
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
