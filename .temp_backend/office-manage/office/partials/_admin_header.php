<?php
$app_u_id = $_SESSION['u_id'];
$qrydisplay1 = mysqli_query($conn, "SELECT * FROM `users` WHERE `id` = '".$app_u_id."'") or die(mysqli_error());
$admn_dls = mysqli_fetch_array($qrydisplay1);
$id_1 = 1;

// Ensure chat SSO token cookie is always active for logged in Admin/Agency
if (!empty($_SESSION['u_id']) && !empty($_SESSION['loggedin']) && function_exists('generate_chat_jwt')) {
    if (empty($_COOKIE['token']) || empty($_COOKIE['chat_token'])) {
        $type = $_SESSION['u_type'] ?? 'ADMIN';
        $ch_id = $_SESSION['u_id'];
        $chat_role = ($type === 'ADMIN') ? 'admin' : 'agent';
        $user_email = !empty($admn_dls['email']) ? $admn_dls['email'] : (!empty($admn_dls['mob']) ? $admn_dls['mob'] : $ch_id);
        $chat_jwt = generate_chat_jwt([
            'emailId' => $user_email,
            'name'    => $admn_dls['name'] ?? $user_email,
            'role'    => $chat_role,
            'agentId' => ($chat_role === 'agent') ? $ch_id : null
        ]);
        setcookie('token', $chat_jwt, time() + (7 * 24 * 60 * 60), '/');
        setcookie('chat_token', $chat_jwt, time() + (7 * 24 * 60 * 60), '/');
    }
}

$fullName = $admn_dls['name'];
$shortName = ProfilePicFromName($fullName);
function ProfilePicFromName($fullName) {
    $fullNameArr = explode(" ", $fullName);
    $firstWord = current($fullNameArr);
    $lastWord  = end($fullNameArr);
    $firstCharacter = substr($firstWord, 0, 1);
    $lastCharacter = substr($lastWord, 0, 1);
    $defaultProfile = strtoupper($firstCharacter);
    return $defaultProfile;
}
$qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error());
$site_dls = mysqli_fetch_array($qrydisplay20); 

  $read_status = "PENDING";
  $emp_id = $app_u_id;

if($_SESSION['u_type'] == "ADMIN"){
    //1
    $qrydisplayh3 = mysqli_query($conn, "SELECT * FROM `contact` WHERE read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount3 = mysqli_num_rows($qrydisplayh3);

    //2
    $qrydisplayh4 = mysqli_query($conn, "SELECT IFNULL(SUM(amount),0) AS total_done_amount FROM `recharge` WHERE stage_status = 'EMPLOYEE-DONE'") or die(mysqli_error($conn));
    $row4 = mysqli_fetch_assoc($qrydisplayh4);
    $rowcount4 = $row4['total_done_amount'];

    //3 
    $qrydisplayh5 = mysqli_query($conn, "SELECT IFNULL(SUM(amount),0) AS total_done_amount FROM `withdrawal` WHERE stage_status = 'EMPLOYEE-DONE'") or die(mysqli_error($conn));
    $row5 = mysqli_fetch_assoc($qrydisplayh5);
    $rowcount5 = $row5['total_done_amount'];

    //4
    $qrydisplayh7 = mysqli_query($conn, "SELECT IFNULL(SUM(amount),0) AS total_done_amount FROM `pay_to_admin` WHERE stage_status = 'EMPLOYEE-DONE'") or die(mysqli_error($conn));
    $row7 = mysqli_fetch_assoc($qrydisplayh7);
    $rowcount7 = $row7['total_done_amount'];

    //5
    $qrydisplayh8 = mysqli_query($conn, "SELECT * FROM `users` WHERE show_status = 'ACTIVE' AND type = 'USER'") or die(mysqli_error($conn));
    $rowcount8 = mysqli_num_rows($qrydisplayh8);

    //6
    $qrydisplayh9 = mysqli_query($conn, "SELECT * FROM `users` WHERE show_status = 'ACTIVE' AND type = 'AGENCY'") or die(mysqli_error($conn));
    $rowcount9 = mysqli_num_rows($qrydisplayh9);

    $rowcount6 = $rowcount3;
}elseif($_SESSION['u_type'] == "AGENCY"){
    // 1.
    $qrydisplayh3 = mysqli_query($conn, "SELECT * FROM `contact` WHERE emp_id = '$emp_id' AND read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount3 = mysqli_num_rows($qrydisplayh3);

    // 2.
    $qrydisplayh4 = mysqli_query($conn, "SELECT * FROM `recharge` WHERE emp_id = '$emp_id' AND agency_read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount4 = mysqli_num_rows($qrydisplayh4);

    // 3.
    $qrydisplayh5 = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE agency_read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount5 = mysqli_num_rows($qrydisplayh5);

    // 4.
    $qrydisplayh7 = mysqli_query($conn, "SELECT * FROM `users` WHERE agency_id = '$emp_id' AND show_status = 'ACTIVE' AND type = 'USER'") or die(mysqli_error($conn));
    $rowcount7 = mysqli_num_rows($qrydisplayh7);

    // 5.
    $qrydisplayh8 = mysqli_query($conn, "SELECT * FROM `agency_cash_book` WHERE agency_id = '$emp_id'") or die(mysqli_error($conn));
    $row8 = mysqli_fetch_array($qrydisplayh8);
    $rowcount8 = $row8['rs_inhand_expected'];

    // 6.
    $qrydisplayh9 = mysqli_query($conn, "SELECT * FROM `agency_cash_book` WHERE agency_id = '$emp_id'") or die(mysqli_error($conn));
    $row9 = mysqli_fetch_array($qrydisplayh9);
    $rowcount9 = $row9['recharge_limit_live'];

    $rowcount6 = $rowcount3 + $rowcount4 + $rowcount5;
} elseif($_SESSION['u_type'] == "AGENCYS-EMPLOYEE"){
    $emp_id = $admn_dls['agency_id'];
    // 1.
    $qrydisplayh3 = mysqli_query($conn, "SELECT * FROM `contact` WHERE emp_id = '$emp_id' AND read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount3 = mysqli_num_rows($qrydisplayh3);

    // 2.
    $qrydisplayh4 = mysqli_query($conn, "SELECT * FROM `recharge` WHERE emp_id = '$emp_id' AND agency_read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount4 = mysqli_num_rows($qrydisplayh4);

    // 3.
    $qrydisplayh5 = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE agency_read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount5 = mysqli_num_rows($qrydisplayh5);

    $rowcount6 = $rowcount3 + $rowcount4 + $rowcount5;
}else{
    // 1.
    $qrydisplayh3 = mysqli_query($conn, "SELECT * FROM `contact` WHERE emp_id = '1' AND read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount3 = mysqli_num_rows($qrydisplayh3);
    
    // 2.
    $qrydisplayh4 = mysqli_query($conn, "SELECT * FROM `recharge` WHERE employee_read_status = '$read_status' AND (stage_status = 'AGENCY-DONE' OR stage_status = 'AGENCY-PENDING')") or die(mysqli_error($conn));
    $rowcount4 = mysqli_num_rows($qrydisplayh4);

    // 3.
    $qrydisplayh5 = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount5 = mysqli_num_rows($qrydisplayh5);

    // 4.
    $qrydisplayh7 = mysqli_query($conn, "SELECT * FROM `subscription` WHERE read_status = '$read_status'") or die(mysqli_error($conn));
    $rowcount7 = mysqli_num_rows($qrydisplayh7);

    // 5.
    $qrydisplayh8 = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE (stage_status = 'AGENCY-PENDING' AND agency_id = '1' AND employee_read_status = '$read_status' AND agency_read_status = '$read_status') OR (stage_status = 'AGENCY-DONE' AND agency_id != '1' AND employee_read_status = '$read_status' AND agency_read_status = 'READ')") or die(mysqli_error($conn));
    $rowcount8 = mysqli_num_rows($qrydisplayh8);

    // 6.
    $qrydisplayh9 = mysqli_query($conn, "SELECT * FROM `pay_to_admin` WHERE (read_status = '$read_status' OR read_status IS NULL OR read_status = '') AND (stage_status = 'ADMIN-PENDING' OR stage_status = 'AGENCY-DONE' OR stage_status = 'AGENCY-PENDING')") or die(mysqli_error($conn));
    $rowcount9 = mysqli_num_rows($qrydisplayh9);

    // 7.
    $qrydisplayh10 = mysqli_query($conn, "SELECT * FROM `users` WHERE show_status = 'ACTIVE' AND type = 'USER'") or die(mysqli_error($conn));
    $rowcount10 = mysqli_num_rows($qrydisplayh10);

    $rowcount6 = $rowcount3 + $rowcount4 + $rowcount5 + $rowcount7 + $rowcount8 + $rowcount9;
}

$theme_mode = !empty($site_dls['theme_mode']) ? $site_dls['theme_mode'] : 'dark';
$theme_primary = !empty($site_dls['theme_primary']) ? $site_dls['theme_primary'] : '#8b5cf6';
$theme_secondary = !empty($site_dls['theme_secondary']) ? $site_dls['theme_secondary'] : '#6366f1';
$theme_bg = !empty($site_dls['theme_bg']) ? $site_dls['theme_bg'] : ($theme_mode === 'light' ? '#f4f6f9' : '#0b071e');
$theme_card = !empty($site_dls['theme_card']) ? $site_dls['theme_card'] : ($theme_mode === 'light' ? '#ffffff' : '#161333');
$theme_text = !empty($site_dls['theme_text']) ? $site_dls['theme_text'] : ($theme_mode === 'light' ? '#0f172a' : '#f8fafc');
?>

<!DOCTYPE html>
<html lang="en" data-theme-mode="<?php echo $theme_mode; ?>">
<head>
  <meta charset="UTF-8">
  <title><?php echo $site_dls['heading']; ?></title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="shortcut icon" type="image/png" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['fevicon']; ?>">

  <!-- Bootstrap 5 -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">  
  <!-- Custom CSS -->  
  <link href="assets/css/style.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/sweetalert/1.1.3/sweetalert.min.css"/>
  <script src="https://unpkg.com/sweetalert/dist/sweetalert.min.js"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/summernote/0.9.1/summernote-bs5.min.css"/>
  <link rel="stylesheet" href="https://cdn.datatables.net/2.3.6/css/dataTables.dataTables.min.css">

  <!-- Dynamic Admin Theme Styles -->
  <style id="admin-theme-vars">
    :root {
      --theme-primary: <?php echo $theme_primary; ?>;
      --theme-secondary: <?php echo $theme_secondary; ?>;
      --theme-primary-gradient: linear-gradient(135deg, <?php echo $theme_secondary; ?> 0%, <?php echo $theme_primary; ?> 100%);
      --theme-glow: <?php echo $theme_primary . '44'; ?>;
    }

    /* LIGHT / WHITE MODE (Applied when data-theme-mode="light" or .light-mode active) */
    html[data-theme-mode="light"]:not(.dark-mode),
    html.light-mode {
      --theme-mode: light;
      --theme-bg: <?php echo (!empty($site_dls['theme_bg']) && $theme_mode === 'light') ? $site_dls['theme_bg'] : '#f0fdf4'; ?>;
      --theme-card: <?php echo (!empty($site_dls['theme_card']) && $theme_mode === 'light') ? $site_dls['theme_card'] : '#ffffff'; ?>;
      --theme-text: <?php echo (!empty($site_dls['theme_text']) && $theme_mode === 'light') ? $site_dls['theme_text'] : '#0f172a'; ?>;
      --theme-text-muted: #64748b;
      --theme-border: rgba(0, 0, 0, 0.08);
      --theme-input-bg: #ffffff;
      --theme-input-border: #cbd5e1;
      --theme-input-text: #0f172a;
      --theme-nav-bg: linear-gradient(135deg, <?php echo $theme_secondary; ?>, <?php echo $theme_primary; ?>);
      --theme-sidebar-bg: #ffffff;
      --theme-sidebar-color: #475569;
      --theme-card-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
    }

    /* DARK MODE (Applied when data-theme-mode="dark" or .dark-mode active) */
    html[data-theme-mode="dark"]:not(.light-mode),
    html.dark-mode {
      --theme-mode: dark;
      --theme-bg: <?php echo (!empty($site_dls['theme_bg']) && $theme_mode === 'dark') ? $site_dls['theme_bg'] : '#0b071e'; ?>;
      --theme-card: <?php echo (!empty($site_dls['theme_card']) && $theme_mode === 'dark') ? $site_dls['theme_card'] : '#161333'; ?>;
      --theme-text: <?php echo (!empty($site_dls['theme_text']) && $theme_mode === 'dark') ? $site_dls['theme_text'] : '#f8fafc'; ?>;
      --theme-text-muted: #94a3b8;
      --theme-border: <?php echo $theme_primary . '33'; ?>;
      --theme-input-bg: #1c183d;
      --theme-input-border: <?php echo $theme_primary . '44'; ?>;
      --theme-input-text: #f8fafc;
      --theme-nav-bg: #0e0b24;
      --theme-sidebar-bg: #120e2e;
      --theme-sidebar-color: #94a3b8;
      --theme-card-shadow: 0 4px 20px rgba(0, 0, 0, 0.35);
    }

    body {
      background: var(--theme-bg) !important;
      color: var(--theme-text) !important;
      transition: background 0.3s ease, color 0.3s ease;
    }

    .navbar {
      background: var(--theme-nav-bg) !important;
      border-bottom: 1px solid var(--theme-border) !important;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15) !important;
    }

    /* HAMBURGER TOGGLE BUTTON: Completely remove black outline/border */
    #sidebarToggle {
      border: none !important;
      outline: none !important;
      box-shadow: none !important;
      background: transparent !important;
      padding: 4px 6px !important;
      cursor: pointer;
      display: inline-flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }

    #sidebarToggle:focus,
    #sidebarToggle:hover,
    #sidebarToggle:active {
      border: none !important;
      outline: none !important;
      box-shadow: none !important;
      background: rgba(255, 255, 255, 0.15) !important;
      border-radius: 6px !important;
    }

    #sidebarToggle .bar {
      background-color: #ffffff !important;
      box-shadow: 0 1px 2px rgba(0,0,0,0.15);
      border-radius: 2px;
    }

    .sidebar {
      background: var(--theme-sidebar-bg) !important;
      border-right: 1px solid var(--theme-border) !important;
      transition: background 0.3s ease;
    }

    .sidebar a {
      color: var(--theme-sidebar-color) !important;
    }

    .sidebar a:hover,
    .sidebar a.active {
      background: var(--theme-primary-gradient) !important;
      color: #ffffff !important;
      box-shadow: 0 4px 12px var(--theme-glow) !important;
    }

    .submenu {
      background: var(--theme-bg) !important;
    }

    .btn_primary {
      background: var(--theme-primary-gradient) !important;
      color: #ffffff !important;
      border: none !important;
      border-radius: 8px !important;
      box-shadow: 0 4px 12px var(--theme-glow) !important;
      transition: all 0.25s ease !important;
    }

    .btn_primary:hover {
      color: #ffffff !important;
      filter: brightness(1.1);
      transform: translateY(-1px);
      box-shadow: 0 6px 18px var(--theme-glow) !important;
    }

    .card {
      background: var(--theme-card) !important;
      border: 1px solid var(--theme-border) !important;
      color: var(--theme-text) !important;
      border-radius: 14px !important;
      box-shadow: var(--theme-card-shadow) !important;
      transition: background 0.3s ease, color 0.3s ease, border-color 0.3s ease;
    }

    .table {
      color: var(--theme-text) !important;
    }

    /* Universal form inputs in dark mode */
    html.dark-mode .form-control,
    html[data-theme-mode="dark"]:not(.light-mode) .form-control,
    html.dark-mode .form-select,
    html[data-theme-mode="dark"]:not(.light-mode) .form-select,
    html.dark-mode .input-group-text,
    html[data-theme-mode="dark"]:not(.light-mode) .input-group-text {
      background-color: var(--theme-input-bg) !important;
      color: var(--theme-input-text) !important;
      border-color: var(--theme-input-border) !important;
    }

    /* Override hardcoded text-dark in dark mode */
    html.dark-mode .text-dark,
    html[data-theme-mode="dark"]:not(.light-mode) .text-dark,
    html.dark-mode label.text-dark,
    html[data-theme-mode="dark"]:not(.light-mode) label.text-dark {
      color: var(--theme-text) !important;
    }

    .badge.bg-primary {
      background: var(--theme-primary-gradient) !important;
    }
  </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar navbar-dark fixed-top px-3">
    <div class="d-flex align-items-center gap-2 me-4">
        <!-- SINGLE TOGGLE BUTTON -->
        <button class="btn border-0 bg-transparent p-1 shadow-none" id="sidebarToggle" type="button" aria-label="Toggle Sidebar">
            <span class="bar bar1"></span>
            <span class="bar bar2"></span>
            <span class="bar bar3"></span>
        </button>

        <span class="text-white fw-bold navlogo">
            <a href="<?php echo $m_url;?>" class="mx-auto d-flex align-items-center justify-content-center text-center">
                <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['white_logo']; ?>"  class="brand-logo" alt="">
            </a>
        </span>
    </div>

    <div class="d-flex align-items-center gap-3 d-none d-sm-block">
        <form class="d-flex" role="search">
            <input class="form-control form-control-sm me-2" type="search" placeholder="Search..." aria-label="Search">
            <a class="btn btn-outline-light btn-sm" href="<?php echo $m_url;?>"><i class="bi bi-search"></i></a>
        </form>
    </div>

    <div class="d-flex align-items-center mx-auto d-none d-lg-block gap-3">
        <span class="fw-semibold fs-5 text-white"><?php echo $site_dls['heading']; ?></span>
    </div>

    <div class="d-flex align-items-center gap-2">
        <button type="button" id="goFS" onclick="toggleFullScreen()" class="btn btn-outline-light border-0 btn-sm">
            <i class="bi bi-fullscreen"></i>
        </button>

        <button class="btn btn-outline-light border-0 btn-sm position-relative" type="button" data-bs-toggle="offcanvas" data-bs-target="#ntmn" aria-controls="ntmn">
            <i class="bi bi-bell"></i>
            <span id="notifCount" class="badge notif-badge position-absolute top-0 end-0 translate-middle rounded-pill bg-danger"><?php if ($rowcount6 > 99){echo "9+";}else{echo $rowcount6;}?></span>
        </button>

        <?php if(($_SESSION['u_type']) == 'ADMIN') { ?>
        <div class="offcanvas offcanvas-end offcanvas-wdth" data-bs-scroll="true" tabindex="-1" id="ntmn" aria-labelledby="ntmnLabel">
            <div class="offcanvas-header">
                <h5 class="offcanvas-title" id="ntmnLabel">Notifications</h5>
                <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button>
            </div>
            <div class="offcanvas-body pt-0">
                <ul class="nav nav-tabs" id="myTab" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active px-1" id="contact-tab" data-bs-toggle="tab" data-bs-target="#contact-tab-pane" type="button" role="tab" aria-controls="contact-tab-pane" aria-selected="true">Contact Enquiry</button>
                    </li>
                    
                </ul>
                <div class="tab-content" id="myTabContent">

                    <div class="tab-pane fade show active" id="contact-tab-pane" role="tabpanel" aria-labelledby="contact-tab" tabindex="0">
                        <div class="row py-3">
                            <b><u>All Unread Contact Enquiry</u></b>
                        </div>
                        <?php 
                            while($con_dls = mysqli_fetch_array($qrydisplayh3)){
                            $fullName5 = $con_dls['name'];
                            $shortName5 = ProfilePicFromName($fullName5);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="contact-enq">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortName5; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo $con_dls['name'];?></b>
                                    <p>Date : <?php echo date('d/m/Y',strtotime($con_dls['date'])); ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                </div>
            </div>
        </div>
        <?php } ?>
        <?php if(($_SESSION['u_type']) == 'AGENCY' || ($_SESSION['u_type']) == 'AGENCYS-EMPLOYEE') { ?>
        <div class="offcanvas offcanvas-end offcanvas-wdth" data-bs-scroll="true" tabindex="-1" id="ntmn" aria-labelledby="ntmnLabel">
            <div class="offcanvas-header">
                <h5 class="offcanvas-title" id="ntmnLabel">Notifications</h5>
                <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button>
            </div>
            <div class="offcanvas-body pt-0">
                <ul class="nav nav-tabs" id="myTab" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active px-2" id="recharge-tab" data-bs-toggle="tab" data-bs-target="#recharge-tab-pane" type="button" role="tab" aria-controls="recharge-tab-pane" aria-selected="true">Recharge</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-2" id="withdrawal-tab" data-bs-toggle="tab" data-bs-target="#withdrawal-tab-pane" type="button" role="tab" aria-controls="withdrawal-tab-pane" aria-selected="true">Withdrawal</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-2" id="contact-tab" data-bs-toggle="tab" data-bs-target="#contact-tab-pane" type="button" role="tab" aria-controls="contact-tab-pane" aria-selected="true">Contact</button>
                    </li>
                </ul>
                <div class="tab-content" id="myTabContent">

                    <div class="tab-pane fade show active" id="recharge-tab-pane" role="tabpanel" aria-labelledby="recharge-tab" tabindex="0">
                        <div class="row py-3">
                            <b><u>All Unread Recharge Requests</u></b>
                        </div>
                        <?php 
                            while($rcg_dls = mysqli_fetch_array($qrydisplayh4)){
                            $resusr = mysqli_query($conn,"SELECT * FROM users WHERE id = '{$rcg_dls['user_id']}'");
                            $rowusr = mysqli_fetch_array($resusr);
                            $fullName4 = isset($rowusr['name']) ? $rowusr['name'] : 'N/A';
                            $shortName4 = ProfilePicFromName($fullName4);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="recharge-req">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortName4; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo isset($rowusr['name']) ? $rowusr['name'] : 'N/A';?></b>
                                    <p>Date : <?php echo is_numeric($rcg_dls['date_ts']) ? date('m/d/Y', (int)$rcg_dls['date_ts']) : $rcg_dls['date_ts']; ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <div class="tab-pane fade show " id="withdrawal-tab-pane" role="tabpanel" aria-labelledby="withdrawal-tab" tabindex="0">
                        <div class="row py-3">
                            <b><u>All Unread Withdrawal Requests</u></b>
                        </div>
                        <?php 
                            $j = 0;
                            while($wth_dls = mysqli_fetch_array($qrydisplayh5)){
                            $j++;
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="agency-withdraw-req">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $j; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Txn : <?php echo $wth_dls['transaction_id'];?></b>
                                    <p>Date : <?php echo date('m/d/Y', $wth_dls['date_ts']); ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <div class="tab-pane fade show " id="contact-tab-pane" role="tabpanel" aria-labelledby="contact-tab" tabindex="0">
                        <div class="row py-3">
                            <b><u>All Unread Contact Enquiry</u></b>
                        </div>
                        <?php 
                            while($con_dls = mysqli_fetch_array($qrydisplayh3)){
                            $fullName5 = $con_dls['name'];
                            $shortName5 = ProfilePicFromName($fullName5);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="contact-enq">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortName5; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo $con_dls['name'];?></b>
                                    <p>Date : <?php echo date('d/m/Y',strtotime($con_dls['date'])); ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                </div>
            </div>
        </div>
        <?php } ?>
        <?php if(($_SESSION['u_type']) == 'EMPLOYEE') { ?>
        <div class="offcanvas offcanvas-end offcanvas-wdth" data-bs-scroll="true" tabindex="-1" id="ntmn" aria-labelledby="ntmnLabel">
            <div class="offcanvas-header">
                <h5 class="offcanvas-title" id="ntmnLabel">Notifications</h5>
                <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close"></button>
            </div>
            <div class="offcanvas-body pt-0">
                <ul class="nav nav-tabs" id="myTabEmp" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active px-1" id="emp-sub-tab" data-bs-toggle="tab" data-bs-target="#emp-sub-pane" type="button" role="tab">Subscription</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-1" id="emp-recharge-tab" data-bs-toggle="tab" data-bs-target="#emp-recharge-pane" type="button" role="tab">Recharge</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-1" id="emp-withdraw-tab" data-bs-toggle="tab" data-bs-target="#emp-withdraw-pane" type="button" role="tab">Withdrawal</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-1" id="emp-agency-tab" data-bs-toggle="tab" data-bs-target="#emp-agency-pane" type="button" role="tab">Agency Payment</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-1" id="emp-contact-tab" data-bs-toggle="tab" data-bs-target="#emp-contact-pane" type="button" role="tab">Contact</button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link px-1" id="emp-bankac-tab" data-bs-toggle="tab" data-bs-target="#emp-bankac-pane" type="button" role="tab">Bank AC</button>
                    </li>
                </ul>
                <div class="tab-content" id="myTabEmpContent">

                    <!-- Subscription Requests -->
                    <div class="tab-pane fade show active" id="emp-sub-pane" role="tabpanel">
                        <div class="row py-3">
                            <b><u>All Unread Subscription Requests</u></b>
                        </div>
                        <?php 
                            while($apn_dls = mysqli_fetch_array($qrydisplayh7)){
                            $resusr = mysqli_query($conn,"SELECT * FROM users WHERE id = '{$apn_dls['user_id']}'");
                            $rowusr = mysqli_fetch_array($resusr);
                            $fullNameS = isset($rowusr['name']) ? $rowusr['name'] : 'N/A';
                            $shortNameS = ProfilePicFromName($fullNameS);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="subscription-req">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortNameS; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Book : <?php echo isset($rowusr['name']) ? $rowusr['name'] : 'N/A';?></b>
                                    <p>Date : <?php echo is_numeric($apn_dls['date_ts']) ? date('m/d/Y', (int)$apn_dls['date_ts']) : $apn_dls['date_ts']; ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <!-- Recharge Requests -->
                    <div class="tab-pane fade" id="emp-recharge-pane" role="tabpanel">
                        <div class="row py-3">
                            <b><u>All Unread Recharge Requests</u></b>
                        </div>
                        <?php 
                            while($rcg_dls = mysqli_fetch_array($qrydisplayh4)){
                            $resusr = mysqli_query($conn,"SELECT * FROM users WHERE id = '{$rcg_dls['user_id']}'");
                            $rowusr = mysqli_fetch_array($resusr);
                            $fullName4 = isset($rowusr['name']) ? $rowusr['name'] : 'N/A';
                            $shortName4 = ProfilePicFromName($fullName4);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="emp-recharge-req">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortName4; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo isset($rowusr['name']) ? $rowusr['name'] : 'N/A';?></b>
                                    <p>Amount: ₹<?php echo $rcg_dls['amount']; ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <!-- Withdrawal Requests -->
                    <div class="tab-pane fade" id="emp-withdraw-pane" role="tabpanel">
                        <div class="row py-3">
                            <b><u>All Unread Withdrawal Requests</u></b>
                        </div>
                        <?php 
                            while($wth_dls = mysqli_fetch_array($qrydisplayh8)){
                            $resusr = mysqli_query($conn,"SELECT * FROM users WHERE id = '{$wth_dls['user_id']}'");
                            $rowusr = mysqli_fetch_array($resusr);
                            $fullNameW = isset($rowusr['name']) ? $rowusr['name'] : 'N/A';
                            $shortNameW = ProfilePicFromName($fullNameW);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="emp-withdraw-req">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortNameW; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo isset($rowusr['name']) ? $rowusr['name'] : 'N/A';?></b>
                                    <p>Amount: ₹<?php echo $wth_dls['amount']; ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <!-- Agency Payment Requests -->
                    <div class="tab-pane fade" id="emp-agency-pane" role="tabpanel">
                        <div class="row py-3">
                            <b><u>All Unread Agency Payment Requests</u></b>
                        </div>
                        <?php 
                            while($agp_dls = mysqli_fetch_array($qrydisplayh9)){
                            $resagency = mysqli_query($conn,"SELECT * FROM users WHERE id = '{$agp_dls['agency_id']}'");
                            $rowagency = mysqli_fetch_array($resagency);
                            $fullNameA = isset($rowagency['name']) ? $rowagency['name'] : 'AGENCY-'.$agp_dls['agency_id'];
                            $shortNameA = ProfilePicFromName($fullNameA);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="emp-agency-payment-req">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortNameA; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Agency: <?php echo $fullNameA;?></b>
                                    <p>Amount: ₹<?php echo $agp_dls['amount']; ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <!-- Contact Enquiry -->
                    <div class="tab-pane fade" id="emp-contact-pane" role="tabpanel">
                        <div class="row py-3">
                            <b><u>All Unread Contact Enquiry</u></b>
                        </div>
                        <?php 
                            while($con_dls = mysqli_fetch_array($qrydisplayh3)){
                            $fullName5 = $con_dls['name'];
                            $shortName5 = ProfilePicFromName($fullName5);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="contact-enq">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortName5; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo $con_dls['name'];?></b>
                                    <p>Date : <?php echo date('d/m/Y',strtotime($con_dls['date'])); ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } ?>
                    </div>

                    <!-- Bank AC Requests -->
                    <div class="tab-pane fade" id="emp-bankac-pane" role="tabpanel">
                        <div class="row py-3">
                            <b><u>All Unread User Bank Accounts</u></b>
                        </div>
                        <?php 
                            if(isset($qrydisplayh5) && $qrydisplayh5){
                                // mysqli_data_seek($qrydisplayh11, 0);
                                while($bank_dls = mysqli_fetch_array($qrydisplayh5)){
                                $resusr = mysqli_query($conn,"SELECT * FROM users WHERE id = '{$bank_dls['user_id']}'");
                                $rowusr = mysqli_fetch_array($resusr);
                                $fullNameB = isset($rowusr['name']) ? $rowusr['name'] : 'N/A';
                                $shortNameB = ProfilePicFromName($fullNameB);
                        ?>
                        <a class="text-decoration-none text-black ntmn-atg" href="emp-user-bank-ac-unreed">
                            <div class="row d-flex align-items-center py-2">
                                <div class="col-2">
                                    <div class="header-ntmn d-flex align-items-center justify-content-center text-center">
                                        <h5 class="mb-0"> <?php echo $shortNameB; ?> </h5>
                                    </div>
                                </div>
                                <div class="col-10">
                                    <b>Name : <?php echo isset($rowusr['name']) ? htmlspecialchars($rowusr['name']) : 'N/A';?></b>
                                    <p>Acc No: <?php echo htmlspecialchars($bank_dls['account_no']); ?></p>
                                </div>
                            </div>
                        </a>
                        <hr class="my-2">
                        <?php } } ?>
                    </div>

                </div>
            </div>
        </div>
        <?php } ?>

        <button id="themeToggle" class="btn border-0 btn-outline-light btn-sm" title="Toggle theme" aria-pressed="false">
            <i id="themeIcon" class="bi bi-moon"></i>
        </button>

        <!-- RIGHT DROPDOWN -->
        <div class="dropdown">
            <a href="#" class="text-decoration-none" data-bs-toggle="dropdown">
                <div class="header-info d-flex align-items-center justify-content-center text-center text-white">
                    <?php if(!empty($admn_dls['img'])){?>
                        <img class="img-fluid header-info-img" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$admn_dls['img']; ?>">
                    <?php } else { ?>
                        <h3 class=""><b> <?php echo $shortName;?> </b></h3>
                    <?php } ?>
                </div>
            </a>
            <ul class="dropdown-menu dropdown-menu-end">
                <li><a class="dropdown-item" href="admin_pass">Update Password</a></li>
                <?php if($_SESSION['u_type'] == "ADMIN"){ ?>
                <li><a class="dropdown-item" href="site-stng">Settings</a></li>
                <?php } ?>
                <li><hr class="dropdown-divider"></li>
                <li><a class="dropdown-item text-danger" href="partials/logout">Logout</a></li>
            </ul>
        </div>
    </div>
</nav>