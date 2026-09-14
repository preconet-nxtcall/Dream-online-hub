<?php
  $var_value = $_SERVER['REQUEST_URI'];
  $var_value2 = explode("/",$var_value,5);
  if(empty($var_value2[3])) {
      $var_value2[3] = $var_value2[2];
  }
  // $var_value3[0] use for get ?Before page name.
  $var_value3 = explode("?",$var_value2[3],2);
  // $var_value4[1] use for get ?= VALUE.
  $var_value4 = explode("=",$var_value,2);
  if(ISSET($var_value4[1])){
    $var_value5 = str_replace("-"," ",$var_value4[1]);
  }
?>

<!-- SIDEBAR -->
<div class="sidebar" id="sidebar">

    <a href="admin_dashboard" class="<?php if(($var_value2[3] == "admin_dashboard") || ($var_value2[3] == "admin_dashboard.php")){ echo "active"; } else { echo ""; } ?> menu-link one-click wave-effect pt-0 mt-0">
        <div><i class="bi bi-house"></i> <span class="ms-2">Dashboard</span></div>
    </a>
    <?php if($_SESSION['u_type'] == "ADMIN" || $_SESSION['u_type'] == "AGENCY") { ?>
    <a href="<?php echo str_replace('office-manage/','', $m_url);?>chat/chat.html" target="_blank" class="menu-link wave-effect">
        <div><i class="bi bi-chat-dots-fill text-success"></i> <span class="ms-2">Live Chat Panel</span></div>
    </a>
    <?php } ?>
    <a href="contact-enq" class="<?php if(($var_value2[3] == "contact-enq")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-chat-square-text"></i> <span class="ms-2">Contact Enquiry</span></div>
    </a>

    <?php if($_SESSION['u_type'] == "ADMIN") { ?>

    <a class="<?php if($var_value2[3] == "admin-check-recharge" || $var_value2[3] == "admin-check-withdrawl" || $var_value2[3] == "admin-check-agency-wise-payments"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu2">
        <div><i class="bi bi-currency-rupee"></i> <span class="ms-2">Cash Flows</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu2" data-bs-parent="#sidebar">
        <a href="admin-check-recharge" class="<?php if(($var_value2[3] == "admin-check-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Users Recharge</a>
        <a href="admin-check-withdrawl" class="<?php if(($var_value2[3] == "admin-check-withdrawl")){ echo "active"; } ?> menu-link one-click wave-effect">Users Withdrawl</a>
        <a href="admin-check-agency-wise-payments" class="<?php if(($var_value2[3] == "admin-check-agency-wise-payments")){ echo "active"; } ?> menu-link one-click wave-effect">Agencies Deposit</a>
    </div>

    <a href="agencies" class="<?php if(($var_value2[3] == "agencies")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-person-vcard"></i> <span class="ms-2">Agencies</span></div>
    </a>

    <a href="users" class="<?php if(($var_value2[3] == "users")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-person"></i> <span class="ms-2">All Users</span></div>
    </a>

    <a href="books" class="<?php if(($var_value2[3] == "books")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-journal-text"></i> <span class="ms-2">Books</span></div>
    </a>

    <a href="price-ranges" class="<?php if(($var_value2[3] == "price-ranges" || $var_value3[0] == "qrcodes")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-qr-code-scan"></i> <span class="ms-2">Price & QR</span></div>
    </a>

    <a href="banks" class="<?php if(($var_value2[3] == "banks")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-bank"></i> <span class="ms-2">Banks</span></div>
    </a>

    <a class="<?php if($var_value2[3] == "expense-head" || $var_value2[3] == "expense-manage"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu4">
        <div><i class="bi bi-cash-coin"></i> <span class="ms-2">Expenses</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu4" data-bs-parent="#sidebar">
        <a href="expense-head" class="<?php if(($var_value2[3] == "expense-head")){ echo "active"; } ?> menu-link one-click wave-effect">Expense Head</a>
        <a href="expense-manage" class="<?php if($var_value2[3] == "expense-manage"){ echo "active"; } ?> menu-link one-click wave-effect">Expense Manage</a>
    </div>

    <a href="payments-record" class="<?php if(($var_value2[3] == "payments-record")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-graph-up-arrow"></i> <span class="ms-2">Payment Record</span></div>
    </a>

    <a href="daily-ledger" class="<?php if(($var_value2[3] == "daily-ledger")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-calendar-range"></i> <span class="ms-2">Daily Ledger</span></div>
    </a>
    
    <a href="profit-loss" class="<?php if(($var_value2[3] == "profit-loss")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-currency-exchange"></i> <span class="ms-2">Profit & Loss</span></div>
    </a>

    <a href="products" class="<?php if(($var_value2[3] == "products")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-boxes"></i> <span class="ms-2">Products</span></div>
    </a>

    <a class="<?php if($var_value2[3] == "home-slides" || $var_value2[3] == "site-stng" || $var_value2[3] == "admin_pass"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#sk">
        <div><i class="bi bi-shield-lock"></i> <span class="ms-2">Security & Settings</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="sk" data-bs-parent="#sidebar">
        <a class="menu-link wave-effect <?php if(($var_value2[3] == "home-slides")){ echo "active"; } ?>" href="home-slides">Home Slides</a>
        <a class="menu-link wave-effect <?php if(($var_value2[3] == "site-stng")){ echo "active"; } ?>" href="site-stng">Site Settings</a>
        <a class="menu-link wave-effect <?php if(($var_value2[3] == "admin_pass")){ echo "active"; } ?>" href="admin_pass">Update Password</a>
    </div>

    <?php } elseif($_SESSION['u_type'] == "AGENCY") { ?>

    <a class="<?php if($var_value2[3] == "recharge-req" || $var_value2[3] == "pending-recharge" || $var_value2[3] == "complete-recharge" || $var_value2[3] == "reject-recharge"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu2">
        <div><i class="bi bi-currency-rupee"></i> <span class="ms-2">Recharge Request</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu2" data-bs-parent="#sidebar">
        <a href="recharge-req" class="<?php if(($var_value2[3] == "recharge-req")){ echo "active"; } ?> menu-link one-click wave-effect">Recharge Request</a>
        <a href="pending-recharge" class="<?php if(($var_value2[3] == "pending-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Pending Recharge</a>
        <a href="complete-recharge" class="<?php if(($var_value2[3] == "complete-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Recharge</a>
        <a href="reject-recharge" class="<?php if(($var_value2[3] == "reject-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Rejected Recharge</a>
    </div>

    <a class="<?php if($var_value2[3] == "agency-withdraw-req" || $var_value2[3] == "agency-withdraw-pending" || $var_value2[3] == "agency-withdraw-success"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu6">
        <div><i class="bi bi-wallet2"></i> <span class="ms-2">Withdrawal Request</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu6" data-bs-parent="#sidebar">
        <a href="agency-withdraw-req" class="<?php if(($var_value2[3] == "agency-withdraw-req")){ echo "active"; } ?> menu-link one-click wave-effect">Withdrawal Request</a>
        <a href="agency-withdraw-pending" class="<?php if(($var_value2[3] == "agency-withdraw-pending")){ echo "active"; } ?> menu-link one-click wave-effect">Pending Withdrawal</a>
        <a href="agency-withdraw-success" class="<?php if(($var_value2[3] == "agency-withdraw-success")){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Withdrawal</a>
    </div>

    <a href="users" class="<?php if(($var_value2[3] == "users")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-person"></i> <span class="ms-2">All Users</span></div>
    </a>

    <a href="price-ranges" class="<?php if(($var_value2[3] == "price-ranges" || $var_value3[0] == "qrcodes")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-qr-code-scan"></i> <span class="ms-2">Price & QR</span></div>
    </a>

    <a href="banks" class="<?php if(($var_value2[3] == "banks")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-bank"></i> <span class="ms-2">Banks</span></div>
    </a>

    <a href="expense-manage" class="<?php if(($var_value2[3] == "expense-manage")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-cash-coin"></i> <span class="ms-2">Expenses</span></div>
    </a>

    <a href="pay-to-admin" class="<?php if(($var_value2[3] == "pay-to-admin")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-card-heading"></i> <span class="ms-2">Pay To Admin</span></div>
    </a>
    
    <a href="payments-record" class="<?php if(($var_value2[3] == "payments-record")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-graph-up-arrow"></i> <span class="ms-2">Payment Record</span></div>
    </a>

    <a href="daily-ledger" class="<?php if(($var_value2[3] == "daily-ledger")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-calendar-range"></i> <span class="ms-2">Daily Ledger</span></div>
    </a>

    <a href="agency-employees" class="<?php if(($var_value2[3] == "agency-employees")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-person-lines-fill"></i> <span class="ms-2">Agency Employees</span></div>
    </a>

    <a href="admin_pass" class="<?php if(($var_value2[3] == "admin_pass")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-shield-lock"></i> <span class="ms-2">Update Password</span></div>
    </a>

    <?php } elseif($_SESSION['u_type'] == "AGENCYS-EMPLOYEE") { ?>

    <a class="<?php if($var_value2[3] == "recharge-req" || $var_value2[3] == "pending-recharge" || $var_value2[3] == "complete-recharge" || $var_value2[3] == "reject-recharge"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu2">
        <div><i class="bi bi-currency-rupee"></i> <span class="ms-2">Recharge Request</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu2" data-bs-parent="#sidebar">
        <a href="recharge-req" class="<?php if(($var_value2[3] == "recharge-req")){ echo "active"; } ?> menu-link one-click wave-effect">Recharge Request</a>
        <a href="pending-recharge" class="<?php if(($var_value2[3] == "pending-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Pending Recharge</a>
        <a href="complete-recharge" class="<?php if(($var_value2[3] == "complete-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Recharge</a>
        <a href="reject-recharge" class="<?php if(($var_value2[3] == "reject-recharge")){ echo "active"; } ?> menu-link one-click wave-effect">Rejected Recharge</a>
    </div>

    <a class="<?php if($var_value2[3] == "agency-withdraw-req" || $var_value2[3] == "agency-withdraw-pending" || $var_value2[3] == "agency-withdraw-success"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu6">
        <div><i class="bi bi-wallet2"></i> <span class="ms-2">Withdrawal Request</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu6" data-bs-parent="#sidebar">
        <a href="agency-withdraw-req" class="<?php if(($var_value2[3] == "agency-withdraw-req")){ echo "active"; } ?> menu-link one-click wave-effect">Withdrawal Request</a>
        <a href="agency-withdraw-pending" class="<?php if(($var_value2[3] == "agency-withdraw-pending")){ echo "active"; } ?> menu-link one-click wave-effect">Pending Withdrawal</a>
        <a href="agency-withdraw-success" class="<?php if(($var_value2[3] == "agency-withdraw-success")){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Withdrawal</a>
    </div>

    <a href="admin_pass" class="<?php if(($var_value2[3] == "admin_pass")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-shield-lock"></i> <span class="ms-2">Update Password</span></div>
    </a>
    
    <?php } else { ?>

    <a class="<?php if($var_value2[3] == "emp-recharge-req" || $var_value2[3] == "emp-recharge-pending" || $var_value2[3] == "emp-recharge-success" || $var_value2[3] == "emp-recharge-reject"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu7">
        <div><i class="bi bi-receipt"></i> <span class="ms-2">Recharges</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu7" data-bs-parent="#sidebar">
        <a href="emp-recharge-req" class="<?php if(($var_value2[3] == "emp-recharge-req")){ echo "active"; } ?> menu-link one-click wave-effect">Recharge Request</a>
        <a href="emp-recharge-pending" class="<?php if($var_value2[3] == "emp-recharge-pending"){ echo "active"; } ?> menu-link one-click wave-effect">Pending Recharge</a>
        <a href="emp-recharge-success" class="<?php if($var_value2[3] == "emp-recharge-success"){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Recharge</a>
        <a href="emp-recharge-reject" class="<?php if($var_value2[3] == "emp-recharge-reject"){ echo "active"; } ?> menu-link one-click wave-effect">Rejected Recharge</a>
    </div>

    <a class="<?php if($var_value2[3] == "emp-withdraw-req" || $var_value2[3] == "emp-withdraw-pending" || $var_value2[3] == "emp-withdraw-success" || $var_value2[3] == "emp-withdraw-reject"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu9">
        <div><i class="bi bi-hourglass-split"></i> <span class="ms-2">Withdrawl's</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu9" data-bs-parent="#sidebar">
        <a href="emp-withdraw-req" class="<?php if(($var_value2[3] == "emp-withdraw-req")){ echo "active"; } ?> menu-link one-click wave-effect">Withdrawl Request</a>
        <a href="emp-withdraw-pending" class="<?php if($var_value2[3] == "emp-withdraw-pending"){ echo "active"; } ?> menu-link one-click wave-effect">Pending Withdrawl</a>
        <a href="emp-withdraw-success" class="<?php if($var_value2[3] == "emp-withdraw-success"){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Withdrawl</a>
        <a href="emp-withdraw-reject" class="<?php if($var_value2[3] == "emp-withdraw-reject"){ echo "active"; } ?> menu-link one-click wave-effect">Rejected Withdrawl</a>
    </div>

    <a class="<?php if($var_value2[3] == "emp-agency-payment-req" || $var_value2[3] == "emp-agency-payment-pending" || $var_value2[3] == "emp-agency-payment-success" || $var_value2[3] == "emp-agency-payment-reject"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu10">
        <div><i class="bi bi-exclamation-triangle"></i> <span class="ms-2">Agency's Payment</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu10" data-bs-parent="#sidebar">
        <a href="emp-agency-payment-req" class="<?php if(($var_value2[3] == "emp-agency-payment-req")){ echo "active"; } ?> menu-link one-click wave-effect">Agency Payment Request</a>
        <a href="emp-agency-payment-pending" class="<?php if($var_value2[3] == "emp-agency-payment-pending"){ echo "active"; } ?> menu-link one-click wave-effect">Pending Agency Payment</a>
        <a href="emp-agency-payment-success" class="<?php if($var_value2[3] == "emp-agency-payment-success"){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Agency Payment</a>
        <a href="emp-agency-payment-reject" class="<?php if($var_value2[3] == "emp-agency-payment-reject"){ echo "active"; } ?> menu-link one-click wave-effect">Rejected Agency Payment</a>
    </div>

    <a class="<?php if($var_value2[3] == "subscription-req" || $var_value2[3] == "pending-subscription" || $var_value2[3] == "complete-subscription"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu3">
        <div><i class="bi bi-book"></i> <span class="ms-2">Subscription Request</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu3" data-bs-parent="#sidebar">
        <a href="subscription-req" class="<?php if(($var_value2[3] == "subscription-req")){ echo "active"; } ?> menu-link one-click wave-effect">Subscription Request</a>
        <a href="pending-subscription" class="<?php if(($var_value2[3] == "pending-subscription")){ echo "active"; } ?> menu-link one-click wave-effect">Pending Subscription</a>
        <a href="complete-subscription" class="<?php if(($var_value2[3] == "complete-subscription")){ echo "active"; } ?> menu-link one-click wave-effect">Successfull Subscription</a>
    </div>

    <!--<a class="<?php if($var_value2[3] == "user-req" || $var_value2[3] == "pending-admin-user" || $var_value2[3] == "users"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#Menu1">
        <div><i class="bi bi-person"></i> <span class="ms-2">User</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="Menu1" data-bs-parent="#sidebar">
        <a href="user-req" class="<?php if(($var_value2[3] == "user-req")){ echo "active"; } ?> menu-link one-click wave-effect">Unseen Registration</a>
        <a href="pending-admin-user" class="<?php if($var_value2[3] == "pending-admin-user"){ echo "active"; } ?> menu-link one-click wave-effect">Not Assigned To Agency</a>
        <a href="users" class="<?php if($var_value2[3] == "users"){ echo "active"; } ?> menu-link one-click wave-effect">All Users</a>
    </div>-->

    <a class="<?php if($var_value2[3] == "emp-user-bank-ac-unreed" || $var_value2[3] == "emp-user-bank-ac-pending"){ echo "active"; }?> menu-link wave-effect" data-bs-toggle="collapse" href="#MenuBankAC">
        <div><i class="bi bi-bank2"></i> <span class="ms-2">User Bank AC</span></div>
        <i class="bi bi-chevron-down arrow"></i>
    </a>
    <div class="collapse submenu" id="MenuBankAC" data-bs-parent="#sidebar">
        <a href="emp-user-bank-ac-unreed" class="<?php if(($var_value2[3] == "emp-user-bank-ac-unreed")){ echo "active"; } ?> menu-link one-click wave-effect">Unseen Bank AC</a>
        <a href="emp-user-bank-ac-pending" class="<?php if(($var_value2[3] == "emp-user-bank-ac-pending")){ echo "active"; } ?> menu-link one-click wave-effect">Pending Bank AC</a>
    </div>

    <a href="users" class="<?php if(($var_value2[3] == "users")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-person"></i> <span class="ms-2">All Users</span></div>
    </a>

    <a href="profit-loss" class="<?php if(($var_value2[3] == "profit-loss")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-currency-exchange"></i> <span class="ms-2">Profit & Loss</span></div>
    </a>

    <a href="admin_pass" class="<?php if(($var_value2[3] == "admin_pass")){ echo "active"; } else { echo ""; } ?> menu-link wave-effect">
        <div><i class="bi bi-shield-lock"></i> <span class="ms-2">Update Password</span></div>
    </a>

    <?php } ?>
    
    <a href="partials/logout" class="menu-link wave-effect">
        <div><i class="bi bi-box-arrow-right"></i> <span class="ms-2">Log Out</span></div>
    </a>

</div>
<?php if($var_value2[3] == "contact-enq") {
        $brdcmp = "Contact Messages";
    }elseif($var_value2[3] == "recharge-req") {
        $brdcmp = "Recharge Request";
    }elseif($var_value2[3] == "pending-recharge") {
        $brdcmp = "Pending Recharge";
    }elseif($var_value2[3] == "complete-recharge") {
        $brdcmp = "Successfull Recharge";
    }elseif($var_value2[3] == "reject-recharge") {
        $brdcmp = "Rejected Recharge";
    }elseif($var_value2[3] == "subscription-req") {
        $brdcmp = "Subscription Request";
    }elseif($var_value2[3] == "pending-subscription") {
        $brdcmp = "Pending Subscription";
    }elseif($var_value2[3] == "complete-subscription") {
        $brdcmp = "Successfull Subscription";
    }elseif($var_value2[3] == "admin-check-withdrawl") {
        $brdcmp = "Check Withdrawl";
    }elseif($var_value2[3] == "user-req") {
        $brdcmp = "Unseen User Registration";
    }elseif($var_value2[3] == "pending-admin-user") {
        $brdcmp = "Not Assigned To Agency";
    }elseif($var_value2[3] == "users") {
        $brdcmp = "All Users";
    }elseif($var_value2[3] == "agencies") {
        $brdcmp = "Agencies";
    }elseif($var_value2[3] == "agency-employees") {
        $brdcmp = "Agency Employees";
    }elseif($var_value2[3] == "admin-check-recharge") {
        $brdcmp = "Check Users Recharge";
    }elseif($var_value2[3] == "emp-recharge-req") {
        $brdcmp = "Recharge Request";
    }elseif($var_value2[3] == "emp-recharge-pending") {
        $brdcmp = "Pending Recharge";
    }elseif($var_value2[3] == "emp-recharge-success") {
        $brdcmp = "Successfull Recharge";
    }elseif($var_value2[3] == "emp-recharge-reject") {
        $brdcmp = "Rejected Recharge";
    }elseif($var_value2[3] == "emp-withdraw-req") {
        $brdcmp = "Withdrawal Request";
    }elseif($var_value2[3] == "emp-withdraw-pending") {
        $brdcmp = "Pending Withdrawal";
    }elseif($var_value2[3] == "emp-withdraw-success") {
        $brdcmp = "Successfull Withdrawal";
    }elseif($var_value2[3] == "emp-withdraw-reject") {
        $brdcmp = "Rejected Withdrawal";
    }elseif($var_value2[3] == "emp-user-bank-ac-unreed") {
        $brdcmp = "Unseen User Bank Accounts";
    }elseif($var_value2[3] == "emp-user-bank-ac-pending") {
        $brdcmp = "Pending User Bank Accounts";
    }elseif($var_value2[3] == "agency-withdraw-req") {
        $brdcmp = "Agency Withdrawal Request";
    }elseif($var_value2[3] == "agency-withdraw-pending") {
        $brdcmp = "Pending Agency Withdrawal";
    }elseif($var_value2[3] == "agency-withdraw-success") {
        $brdcmp = "Successfull Agency Withdrawal";
    }elseif($var_value2[3] == "emp-agency-payment-req") {
        $brdcmp = "Agency Payment Request";
    }elseif($var_value2[3] == "emp-agency-payment-pending") {
        $brdcmp = "Pending Agency Payment";
    }elseif($var_value2[3] == "emp-agency-payment-success") {
        $brdcmp = "Successfull Agency Payment";
    }elseif($var_value2[3] == "emp-agency-payment-reject") {
        $brdcmp = "Rejected Agency Payment";
    }elseif($var_value2[3] == "admin-check-agency-wise-payments") {
        $brdcmp = "Check Agency Payments Flow";
    }elseif($var_value2[3] == "pay-to-admin") {
        $brdcmp = "Pay To Admin";
    }elseif($var_value2[3] == "books") {
        $brdcmp = "Books";
    }elseif($var_value2[3] == "price-ranges") {
        $brdcmp = "Price Ranges";
    }elseif($var_value3[0] == "qrcodes") {
        $brdcmp = "QRCodes";
    }elseif($var_value2[3] == "banks") {
        $brdcmp = "Banks";
    }elseif($var_value2[3] == "payments-record") {
        $brdcmp = "Payment Record";
    }elseif($var_value2[3] == "expense-head") {
        $brdcmp = "Expense Head";
    }elseif($var_value2[3] == "expense-manage") {
        $brdcmp = "Expense Manage";
    }elseif($var_value2[3] == "products") {
        $brdcmp = "Products";
    }elseif($var_value2[3] == "daily-ledger") {
        $brdcmp = "Daily Ledger";
    }elseif($var_value2[3] == "profit-loss") {
        $brdcmp = "Profit & Loss";
    }elseif($var_value2[3] == "user-profit-loss") {
        $brdcmp = "User Profit & Loss";
    }elseif($var_value2[3] == "home-slides") {
        $brdcmp = "Home Slides";
    }elseif($var_value2[3] == "site-stng") {
        $brdcmp = "Website Settings";
    }elseif($var_value2[3] == "admin_pass") {
        $brdcmp = "Update Password";
    }else {
        $brdcmp = "Dashboard"; 
    }
?>
