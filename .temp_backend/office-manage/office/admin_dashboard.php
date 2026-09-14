<?php
require 'partials/_dbconnect.php';

if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
?>
<?php include 'partials/_admin_header.php' ?>
<?php include 'partials/_admin_sidenav.php' ?>

<!-- CONTENT -->
<div class="content mb-3">
    
    <div class="brdcmp px-4 pt-4">
        <div class="d-flex justify-content-between align-items-center pb-4 mb-3">
            <div class="row">
                <p>
                    <h5 class="mb-0"><?php echo $brdcmp; ?></h5><br>
                    <span>Home / <?php echo $brdcmp; ?></span>
                </p>
            </div>
            <a href="admin_dashboard" class="btn btn_primary btn-sm">Refresh <i class="bi bi-arrow-clockwise ms-2"></i></a>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow-sm mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Welcome To </strong> <?php echo $admn_dls['name']; ?></h5>
        </div>
        <div class="card-body">
            <?php if($_SESSION['u_type'] == "ADMIN"){ ?>
            <div class="row g-3 stats-row">
                <!-- 1. Unseen User Registrations -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-11 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-chat-left-text"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount3; ?></h3>
                            <p class="title mb-1">Unseen Contact Enquirys</p>
                            <a href="contact-enq" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 2. Unseen Recharge Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-9 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-credit-card-2-front"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><i class="bi bi-currency-rupee"></i> <?php echo $rowcount4; ?></h3>
                            <p class="title mb-1">Total Successful Recharge</p>
                            <a href="admin-check-recharge" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 3. Unseen Subscription Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-17 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-book"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><i class="bi bi-currency-rupee"></i> <?php echo $rowcount5; ?></h3>
                            <p class="title mb-1">Total Successful Withdrawl</p>
                            <a href="admin-check-withdrawl" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 4. Total Users -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-14 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-bank"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><i class="bi bi-currency-rupee"></i> <?php echo $rowcount7; ?></h3>
                            <p class="title mb-1">Total Agency Payment</p>
                            <a href="admin-check-agency-wise-payments" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 5. Successful Recharges Total -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-18 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-people"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount8; ?></h3>
                            <p class="title mb-1">Total Active Users</p>
                            <a href="users" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 6. Agencies Payments / Deposits -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-13 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-person-plus"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount9; ?></h3>
                            <p class="title mb-1">Total Active Agencies</p>
                            <a href="agencies" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>
            </div>
            <?php }elseif($_SESSION['u_type'] == "AGENCY"){ ?>
            <div class="row g-3 stats-row">
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-11 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-envelope"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount3; ?></h3>
                            <p class="title mb-1">Total Unread Contact Enquiry</p>
                            <a href="contact-enq" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-17 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-globe"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount4; ?></h3>
                            <p class="title mb-1">Total Unseen Recharge Request</p>
                            <a href="recharge-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-9 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-mortarboard"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount5; ?></h3>
                            <p class="title mb-1">Total Withdarw Requests</p>
                            <a href="agency-withdraw-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-14 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-credit-card-2-front"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount7; ?></h3>
                            <p class="title mb-1">Total Active Users</p>
                            <a href="users" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>
                
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-13 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-coin"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><i class="bi bi-currency-rupee"></i> <?php echo $rowcount8; ?></h3>
                            <p class="title mb-1">Remain Collect Limit</p>
                            <a href="daily-ledger" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-18 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-bookmark-star"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><i class="bi bi-currency-rupee"></i> <?php echo $rowcount9; ?></h3>
                            <p class="title mb-1">Cash In Hand</p>
                            <a href="daily-ledger" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>
            </div>
            <?php }elseif($_SESSION['u_type'] == "AGENCYS-EMPLOYEE"){ ?>
            <div class="row g-3 stats-row">
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-11 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-envelope"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount3; ?></h3>
                            <p class="title mb-1">Total Unread Contact Enquiry</p>
                            <a href="contact-enq" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-17 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-globe"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount4; ?></h3>
                            <p class="title mb-1">Total Unseen Recharge Request</p>
                            <a href="recharge-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-9 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-mortarboard"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount5; ?></h3>
                            <p class="title mb-1">Total Withdarw Requests</p>
                            <a href="agency-withdraw-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>
            </div>
            <?php } else { ?>
            <div class="row g-3 stats-row">
                <!-- 1. Unread Contact Enquiries -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-11 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-envelope"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount3; ?></h3>
                            <p class="title mb-1">Unread Contact Enquiries</p>
                            <a href="contact-enq" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 2. Unseen Recharge Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-17 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-credit-card-2-front"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount4; ?></h3>
                            <p class="title mb-1">Unseen Recharge Requests</p>
                            <a href="emp-recharge-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 3. Unseen Subscription Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-14 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-book"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount7; ?></h3>
                            <p class="title mb-1">Unseen Subscription Requests</p>
                            <a href="subscription-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 4. Unseen Withdrawal Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-13 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-hourglass-split"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount8; ?></h3>
                            <p class="title mb-1">Unseen Withdrawal Requests</p>
                            <a href="emp-withdraw-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 5. Unseen Agency Payment Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-18 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-bank"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo $rowcount9; ?></h3>
                            <p class="title mb-1">Unseen Agency Transfer </p>
                            <a href="emp-agency-payment-req" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>

                <!-- 6. Unseen User Bank AC Requests -->
                <div class="col-12 col-sm-6 col-md-4 col-lg-4">
                    <div class="stat-card gradient-8 py-3">
                        <div class="icon bg-white text-black"><i class="bi bi-bank2"></i></div>
                        <div>
                            <h3 class="title-number mb-0"><?php echo isset($rowcount5) ? $rowcount5 : 0; ?></h3>
                            <p class="title mb-1">Unseen Bank AC Requests</p>
                            <a href="emp-user-bank-ac-unreed" class="value">Visit Page Now </a>
                        </div>
                    </div>
                </div>
            </div>
            <?php } ?>
        </div>
    </div>
</div>
    
<?php include 'partials/_footer.php'?>