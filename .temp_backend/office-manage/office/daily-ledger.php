<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

$startdate = date('Y-m-d');
$enddate = date('Y-m-d');
$reportfor = "";
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

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Daily Ledger</strong> Report Filter</h5>
        </div>
        <div class="card-body p-4">
            <form action="daily-ledger-pdf" method="get" id="ledgerForm" target="_blank">
                <div class="row mb-3">
                    <div class="col-md-4">
                        <label class="form-label fw-bold">Start Date <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-calendar"></i></span>
                            <input type="date" class="form-control" name="startdate" value="<?php echo $startdate; ?>" required>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <label class="form-label fw-bold">End Date <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-calendar"></i></span>
                            <input type="date" class="form-control" name="enddate" value="<?php echo $enddate; ?>" required>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label fw-bold">Report For <span class="text-danger">*</span></label>
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-person-lines-fill"></i></span>
                            <?php if($_SESSION['u_type'] == "ADMIN") { ?>
                            <select class="form-select" name="reportfor" required>
                                <option value="">-- Choose Option --</option>
                                <option value="ONLY_ADMIN">ONLY ADMIN</option>
                                <option value="ADMIN_AGENCIES">ADMIN + AGENCIES</option>
                                <option value="ONLY_AGENCIES">ONLY AGENCIES</option>
                                <optgroup label="AGENCY">
                                    <?php
                                    $qryagencies = mysqli_query($conn, "SELECT * FROM `users` WHERE type = 'AGENCY' AND show_status = 'ACTIVE' ORDER BY name ASC") or die(mysqli_error($conn));
                                    while($resagency = mysqli_fetch_array($qryagencies)){
                                        echo '<option value="agency_'.$resagency['id'].'">'.$resagency['name'].'</option>';
                                    }
                                    ?>
                                </optgroup>
                            </select>
                            <?php } else { ?>
                                <select class="form-select" name="reportfor" required>
                                    <option value="agency_<?php echo $_SESSION['u_id']; ?>"><?php echo $admn_dls['name']; ?></option>
                                </select>
                            <?php } ?>
                        </div>
                    </div>
                </div>

                <div class="row mt-4">
                    <div class="col-12 text-center">
                        <button type="submit" class="btn btn_primary btn-lg wave-effect px-5">
                            <i class="bi bi-file-earmark-pdf me-2"></i> Generate Ledger PDF
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<?php include 'partials/_footer.php' ?>
