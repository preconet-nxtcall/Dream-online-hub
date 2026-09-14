<?php include 'partials/_header.php'; ?>

<style>
    /* DreamHub Dark Neon Records System (Strict Mockup Match) */
    .records-page-wrapper {
        max-width: 768px !important;
        margin: 20px auto 100px auto !important;
        padding: 0 16px !important;
    }

    /* Main Glass Card */
    .dh-records-card {
        background: linear-gradient(180deg, #071B31 0%, #04111F 100%) !important;
        border: 1px solid rgba(23, 200, 255, 0.25) !important;
        border-radius: 28px !important;
        padding: 14px 5px !important;
        box-shadow: 0 0 30px rgba(8, 123, 255, 0.18), 0 12px 40px rgba(0, 0, 0, 0.5) !important;
    }

    /* Header Row - Strictly Same Row Always */
    .dh-records-header {
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        margin-bottom: 24px !important;
        flex-wrap: nowrap !important;
        gap: 12px !important;
        width: 100% !important;
    }

    .dh-records-header-left {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
        overflow: hidden !important;
        flex: 1 !important;
    }

    .dh-records-icon-box {
        width: 48px !important;
        height: 48px !important;
        border-radius: 14px !important;
        background: rgba(8, 123, 255, 0.2) !important;
        border: 1px solid rgba(23, 200, 255, 0.35) !important;
        color: #17C8FF !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 22px !important;
        flex-shrink: 0 !important;
        box-shadow: 0 0 16px rgba(23, 200, 255, 0.2) !important;
    }

    .dh-records-title-group {
        overflow: hidden !important;
    }

    .dh-records-title-group h2 {
        font-size: 20px !important;
        font-weight: 700 !important;
        color: #F7FAFF !important;
        margin: 0 !important;
        line-height: 1.2 !important;
        white-space: nowrap !important;
        overflow: hidden !important;
        text-overflow: ellipsis !important;
    }

    .dh-records-title-group p {
        font-size: 12px !important;
        color: #9FB8D9 !important;
        margin: 3px 0 0 0 !important;
        line-height: 1.2 !important;
        white-space: nowrap !important;
        overflow: hidden !important;
        text-overflow: ellipsis !important;
    }

    .dh-track-badge {
        background: rgba(11, 36, 64, 0.8) !important;
        border: 1px solid rgba(23, 200, 255, 0.25) !important;
        border-radius: 14px !important;
        padding: 8px 14px !important;
        display: flex !important;
        align-items: center !important;
        gap: 10px !important;
        flex-shrink: 0 !important;
    }

    .dh-track-badge i {
        color: #17C8FF !important;
        font-size: 22px !important;
    }

    .dh-track-badge-text {
        display: flex !important;
        flex-direction: column !important;
        font-size: 11px !important;
        font-weight: 600 !important;
        color: #9FB8D9 !important;
        line-height: 1.2 !important;
    }

    .dh-track-badge-text span:first-child {
        font-weight: 700 !important;
        color: #F7FAFF !important;
    }

    .dh-track-badge-sub {
        font-size: 9px !important;
        color: #6E88A8 !important;
        margin-top: 1px !important;
    }

    /* Tab Switcher Buttons */
    .dh-tabs-nav {
        display: flex !important;
        gap: 12px !important;
        margin-bottom: 20px !important;
    }

    .dh-tab-btn {
        flex: 1 !important;
        height: 48px !important;
        border-radius: 999px !important;
        background: rgba(11, 36, 64, 0.6) !important;
        border: 1px solid #1A3F66 !important;
        color: #9FB8D9 !important;
        font-size: 14px !important;
        font-weight: 600 !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        gap: 8px !important;
        text-decoration: none !important;
        transition: all 0.25s ease !important;
        cursor: pointer !important;
    }

    .dh-tab-btn:hover {
        color: #F7FAFF !important;
        border-color: #17C8FF !important;
    }

    .dh-tab-btn.active {
        background: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%) !important;
        color: #FFFFFF !important;
        border-color: transparent !important;
        box-shadow: 0 8px 24px rgba(8, 123, 255, 0.45) !important;
    }

    /* Toolbar Area */
    .dh-toolbar-row {
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        gap: 12px !important;
        margin-bottom: 16px !important;
    }

    .dh-search-box-wrap {
        position: relative !important;
        display: flex !important;
        align-items: center !important;
        flex: 1 !important;
        max-width: 380px !important;
    }

    .dh-search-icon {
        position: absolute !important;
        left: 14px !important;
        color: #17C8FF !important;
        font-size: 15px !important;
        pointer-events: none !important;
    }

    .dh-search-input {
        width: 100% !important;
        height: 42px !important;
        background: rgba(11, 36, 64, 0.7) !important;
        border: 1px solid rgba(23, 200, 255, 0.22) !important;
        border-radius: 12px !important;
        color: #F7FAFF !important;
        font-size: 13px !important;
        padding-left: 40px !important;
        padding-right: 14px !important;
        outline: none !important;
        transition: all 0.2s ease !important;
    }

    .dh-search-input::placeholder {
        color: #6E88A8 !important;
        opacity: 0.8 !important;
    }

    .dh-search-input:focus {
        border-color: #17C8FF !important;
        box-shadow: 0 0 12px rgba(23, 200, 255, 0.25) !important;
    }

    .dh-showing-select-wrap {
        display: flex !important;
        align-items: center !important;
        gap: 8px !important;
        flex-shrink: 0 !important;
        color: #9FB8D9 !important;
        font-size: 13px !important;
        font-weight: 500 !important;
    }

    .dh-showing-select {
        height: 38px !important;
        background: #0B2440 !important;
        border: 1px solid #1A3F66 !important;
        border-radius: 10px !important;
        color: #F7FAFF !important;
        padding: 0 10px !important;
        font-size: 13px !important;
        font-weight: 600 !important;
        outline: none !important;
        cursor: pointer !important;
    }

    .dh-showing-select option {
        background-color: #071B31 !important;
        color: #F7FAFF !important;
    }

    /* Enclosed Table Container */
    .dh-table-container {
        border: 1px solid rgba(23, 200, 255, 0.2) !important;
        border-radius: 16px !important;
        overflow: hidden !important;
        background: rgba(7, 27, 49, 0.4) !important;
        margin-bottom: 16px !important;
    }

    .dh-records-table {
        width: 100% !important;
        border-collapse: collapse !important;
        margin: 0 !important;
    }

    .dh-records-table th {
        background: rgba(11, 36, 64, 0.9) !important;
        color: #9FB8D9 !important;
        font-size: 11px !important;
        font-weight: 700 !important;
        text-transform: uppercase !important;
        letter-spacing: 0.5px !important;
        padding: 12px 14px !important;
        border-bottom: 1px solid rgba(23, 200, 255, 0.18) !important;
        white-space: nowrap !important;
    }

    .dh-records-table td {
        padding: 14px 14px !important;
        border-bottom: 1px solid rgba(255, 255, 255, 0.05) !important;
        font-size: 13px !important;
        color: #F7FAFF !important;
        vertical-align: middle !important;
    }

    .dh-records-table tr:last-child td {
        border-bottom: none !important;
    }

    .dh-records-table tbody tr:hover {
        background: rgba(23, 200, 255, 0.04) !important;
    }

    /* Status Pill Badges with Glow Dots */
    .dh-status-badge {
        display: inline-flex !important;
        align-items: center !important;
        gap: 6px !important;
        padding: 4px 12px !important;
        border-radius: 999px !important;
        font-size: 11px !important;
        font-weight: 700 !important;
        letter-spacing: 0.3px !important;
    }

    .dh-status-dot {
        width: 6px !important;
        height: 6px !important;
        border-radius: 50% !important;
    }

    .dh-status-success {
        background: rgba(37, 227, 138, 0.12) !important;
        border: 1px solid rgba(37, 227, 138, 0.4) !important;
        color: #25E38A !important;
    }
    .dh-status-success .dh-status-dot {
        background: #25E38A !important;
        box-shadow: 0 0 6px #25E38A !important;
    }

    .dh-status-pending {
        background: rgba(255, 176, 32, 0.12) !important;
        border: 1px solid rgba(255, 176, 32, 0.4) !important;
        color: #FFB020 !important;
    }
    .dh-status-pending .dh-status-dot {
        background: #FFB020 !important;
        box-shadow: 0 0 6px #FFB020 !important;
    }

    .dh-status-failed {
        background: rgba(255, 53, 93, 0.12) !important;
        border: 1px solid rgba(255, 53, 93, 0.4) !important;
        color: #FF355D !important;
    }
    .dh-status-failed .dh-status-dot {
        background: #FF355D !important;
        box-shadow: 0 0 6px #FF355D !important;
    }

    /* Table Footer & Pagination */
    .dh-table-footer {
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        padding: 12px 16px !important;
        border-top: 1px solid rgba(255, 255, 255, 0.05) !important;
        background: rgba(7, 27, 49, 0.6) !important;
        flex-wrap: wrap !important;
        gap: 12px !important;
    }

    .dh-table-info-text {
        font-size: 12px !important;
        color: #6E88A8 !important;
    }

    .dh-pagination-wrap {
        display: flex !important;
        align-items: center !important;
        gap: 6px !important;
    }

    .dh-page-btn {
        min-width: 32px !important;
        height: 32px !important;
        border-radius: 8px !important;
        background: rgba(11, 36, 64, 0.6) !important;
        border: 1px solid #1A3F66 !important;
        color: #9FB8D9 !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 12px !important;
        font-weight: 600 !important;
        cursor: pointer !important;
        transition: all 0.2s ease !important;
        padding: 0 6px !important;
    }

    .dh-page-btn:hover {
        border-color: #17C8FF !important;
        color: #17C8FF !important;
    }

    .dh-page-btn.active {
        background: linear-gradient(90deg, #17C8FF 0%, #087BFF 100%) !important;
        color: #FFFFFF !important;
        border-color: transparent !important;
        box-shadow: 0 4px 12px rgba(8, 123, 255, 0.4) !important;
    }

    /* Support Footer Banner - Strictly Same Row Always */
    .dh-support-banner {
        background: rgba(8, 123, 255, 0.08) !important;
        border: 1px solid rgba(8, 123, 255, 0.25) !important;
        border-radius: 16px !important;
        padding: 14px 18px !important;
        display: flex !important;
        align-items: center !important;
        justify-content: space-between !important;
        gap: 16px !important;
        margin-top: 18px !important;
        flex-wrap: nowrap !important;
        width: 100% !important;
    }

    .dh-support-left {
        display: flex !important;
        align-items: center !important;
        gap: 14px !important;
        overflow: hidden !important;
        flex: 1 !important;
    }

    .dh-support-shield-icon {
        width: 38px !important;
        height: 38px !important;
        border-radius: 10px !important;
        background: #087BFF !important;
        color: #FFFFFF !important;
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
        font-size: 20px !important;
        flex-shrink: 0 !important;
        box-shadow: 0 0 12px rgba(8, 123, 255, 0.5) !important;
    }

    .dh-support-text-wrap {
        overflow: hidden !important;
    }

    .dh-support-title {
        font-size: 13px !important;
        font-weight: 600 !important;
        color: #F7FAFF !important;
        white-space: nowrap !important;
        overflow: hidden !important;
        text-overflow: ellipsis !important;
    }

    .dh-support-sub {
        font-size: 11px !important;
        color: #6E88A8 !important;
        margin-top: 2px !important;
        white-space: nowrap !important;
        overflow: hidden !important;
        text-overflow: ellipsis !important;
    }

    .dh-support-contact-btn {
        background: rgba(11, 36, 64, 0.8) !important;
        border: 1px solid #1A3F66 !important;
        border-radius: 12px !important;
        padding: 8px 14px !important;
        color: #F7FAFF !important;
        display: flex !important;
        align-items: center !important;
        gap: 10px !important;
        text-decoration: none !important;
        transition: all 0.2s ease !important;
        flex-shrink: 0 !important;
    }

    .dh-support-contact-btn:hover {
        border-color: #17C8FF !important;
        color: #17C8FF !important;
    }

    .dh-support-contact-btn i.bi-headset {
        color: #17C8FF !important;
        font-size: 18px !important;
    }

    .dh-support-btn-text {
        display: flex !important;
        flex-direction: column !important;
        font-size: 11px !important;
        line-height: 1.2 !important;
    }

    .dh-support-btn-text span:first-child {
        font-weight: 700 !important;
        color: #F7FAFF !important;
    }

    .dh-support-btn-text span:last-child {
        color: #6E88A8 !important;
    }
</style>

<div class="records-page-wrapper">
    <div class="dh-records-card">
        
        <!-- Header Row (Strictly Same Row) -->
        <div class="dh-records-header">
            <div class="dh-records-header-left">
                <div class="dh-records-icon-box">
                    <i class="bi bi-file-earmark-text-fill"></i>
                </div>
                <div class="dh-records-title-group">
                    <h2>Recharge &amp; Withdraw Records</h2>
                    <p>View your complete transaction history for recharges and withdrawals.</p>
                </div>
            </div>
            
            <div class="dh-track-badge">
                <i class="bi bi-calendar-check"></i>
                <div class="dh-track-badge-text">
                    <span>Track</span>
                    <span>Your History</span>
                    <span class="dh-track-badge-sub">Safe • Secure • Transparent</span>
                </div>
            </div>
        </div>

        <!-- Pill Tabs Navigation -->
        <div class="dh-tabs-nav nav" role="tablist">
            <a href="#recharge-details" class="dh-tab-btn active" data-bs-toggle="tab" role="tab">
                <i class="bi bi-credit-card-2-front-fill"></i>
                <span>Recharge Details</span>
            </a>
            <a href="#withdraw-details" class="dh-tab-btn" data-bs-toggle="tab" role="tab">
                <i class="bi bi-calendar-event"></i>
                <span>Withdraw Details</span>
            </a>
        </div>

        <div class="tab-content">
            <!-- 1. Recharge Details Tab Pane -->
            <div class="tab-pane fade show active" id="recharge-details" role="tabpanel">
                <div class="dh-toolbar-row">
                    <div class="dh-search-box-wrap">
                        <i class="bi bi-search dh-search-icon"></i>
                        <input type="text" id="searchRecharge" class="dh-search-input" placeholder="Search by book name, transaction ID...">
                    </div>
                    <div class="dh-showing-select-wrap">
                        <span>Showing</span>
                        <select id="lengthRecharge" class="dh-showing-select">
                            <option value="5" selected>5</option>
                            <option value="10">10</option>
                            <option value="15">15</option>
                        </select>
                    </div>
                </div>

                <!-- Enclosed Table Container -->
                <div class="dh-table-container">
                    <div class="table-responsive">
                        <table class="dh-records-table" id="tableRecharge">
                            <thead>
                                <tr>
                                    <th style="width: 40px;">#</th>
                                    <th>TRANSACTION DETAILS</th>
                                    <th class="text-end">RECHARGE DETAILS</th>
                                </tr>
                            </thead>
                            <tbody id="bodyRecharge">
                                <?php
                                    $i = 0;
                                    $user_id = $_SESSION['user_id'];
                                    $qrydisplay1 = mysqli_query($conn, "SELECT * FROM `recharge` WHERE user_id = '$user_id' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                                    while($result1 = mysqli_fetch_array($qrydisplay1)){ $i++;                
                                ?>
                                <tr>
                                    <td class="fw-bold" style="color: #F7FAFF;"><?php echo $i; ?></td>
                                    <td>
                                        <div><span style="color: #6E88A8;">Amount:</span> <b style="color: #F7FAFF;"><?php echo htmlspecialchars($result1['amount']); ?></b></div>
                                        <div><span style="color: #6E88A8;">Txn ID:</span> <span style="color: #9FB8D9;"><?php echo htmlspecialchars($result1['transection_id']); ?></span></div>
                                        <div class="mt-1">
                                        <?php
                                            if($result1['stage_status'] == 'EMPLOYEE-DONE'){
                                                echo '<span class="dh-status-badge dh-status-success"><span class="dh-status-dot"></span>SUCCESSFUL</span>';
                                            } else if($result1['stage_status'] == 'AGENCY-REJECT' || $result1['stage_status'] == 'EMPLOYEE-REJECT'){
                                                echo '<span class="dh-status-badge dh-status-failed"><span class="dh-status-dot"></span>FAILED</span>';
                                            } else {
                                                echo '<span class="dh-status-badge dh-status-pending"><span class="dh-status-dot"></span>PENDING</span>';
                                            }
                                        ?>
                                        </div>
                                    </td>
                                    <td class="text-end">
                                        <div class="fw-bold" style="color: #F7FAFF; text-transform: uppercase;">
                                        <?php 
                                            $book_id = $result1['book_id'];
                                            $qrydisplay2 = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$book_id' ") or die(mysqli_error($conn));
                                            $result2 = mysqli_fetch_array($qrydisplay2);
                                            echo htmlspecialchars(isset($result2['name']) ? $result2['name'] : 'N/A');
                                        ?>
                                        </div>
                                        <div style="color: #9FB8D9; font-size: 12px; margin-top: 2px;"><?php echo date('m/d/Y', $result1['date_ts']); ?></div>
                                        <div style="color: #9FB8D9; font-size: 12px;"><?php echo date('h:i a', $result1['date_ts']); ?></div>
                                    </td>
                                </tr>
                                <?php } ?>
                            </tbody>
                        </table>
                    </div>

                    <!-- Table Footer & Dynamic Pagination -->
                    <div class="dh-table-footer">
                        <div class="dh-table-info-text" id="infoRecharge">Showing 1 to 5 of records</div>
                        <div class="dh-pagination-wrap" id="pagRecharge"></div>
                    </div>
                </div>
            </div>

            <!-- 2. Withdraw Details Tab Pane -->
            <div class="tab-pane fade" id="withdraw-details" role="tabpanel">
                <div class="dh-toolbar-row">
                    <div class="dh-search-box-wrap">
                        <i class="bi bi-search dh-search-icon"></i>
                        <input type="text" id="searchWithdraw" class="dh-search-input" placeholder="Search by book name, transaction ID...">
                    </div>
                    <div class="dh-showing-select-wrap">
                        <span>Showing</span>
                        <select id="lengthWithdraw" class="dh-showing-select">
                            <option value="5" selected>5</option>
                            <option value="10">10</option>
                            <option value="15">15</option>
                        </select>
                    </div>
                </div>

                <!-- Enclosed Table Container -->
                <div class="dh-table-container">
                    <div class="table-responsive">
                        <table class="dh-records-table" id="tableWithdraw">
                            <thead>
                                <tr>
                                    <th style="width: 40px;">#</th>
                                    <th>TRANSACTION DETAILS</th>
                                    <th class="text-end">WITHDRAW DETAILS</th>
                                </tr>
                            </thead>
                            <tbody id="bodyWithdraw">
                                <?php
                                    $w_i = 0;
                                    $user_id = $_SESSION['user_id'];
                                    $qrywithdraw = mysqli_query($conn, "SELECT * FROM `withdrawal` WHERE user_id = '$user_id' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                                    while($resultW = mysqli_fetch_array($qrywithdraw)){ $w_i++;                
                                ?>
                                <tr>
                                    <td class="fw-bold" style="color: #F7FAFF;"><?php echo $w_i; ?></td>
                                    <td>
                                        <div><span style="color: #6E88A8;">Amount:</span> <b style="color: #F7FAFF;"><?php echo htmlspecialchars($resultW['amount']); ?></b></div>
                                        <?php if(!empty($resultW['transaction_id'])){ ?>
                                            <div><span style="color: #6E88A8;">Txn ID:</span> <span style="color: #9FB8D9;"><?php echo htmlspecialchars($resultW['transaction_id']); ?></span></div>
                                        <?php } ?>
                                        <div class="mt-1">
                                        <?php
                                            if($resultW['stage_status'] == 'EMPLOYEE-DONE' || $resultW['stage_status'] == 'AGENCY-DONE'){
                                                echo '<span class="dh-status-badge dh-status-success"><span class="dh-status-dot"></span>SUCCESSFUL</span>';
                                            } else if($resultW['stage_status'] == 'AGENCY-REJECT' || $resultW['stage_status'] == 'EMPLOYEE-REJECT'){
                                                echo '<span class="dh-status-badge dh-status-failed"><span class="dh-status-dot"></span>FAILED</span>';
                                            } else {
                                                echo '<span class="dh-status-badge dh-status-pending"><span class="dh-status-dot"></span>PENDING</span>';
                                            }
                                        ?>
                                        </div>
                                    </td>
                                    <td class="text-end">
                                        <div class="fw-bold" style="color: #F7FAFF; text-transform: uppercase;">
                                        <?php 
                                            $w_book_id = $resultW['book_id'];
                                            $qrydisplayW2 = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$w_book_id' ") or die(mysqli_error($conn));
                                            $resultW2 = mysqli_fetch_array($qrydisplayW2);
                                            echo htmlspecialchars(isset($resultW2['name']) ? $resultW2['name'] : 'N/A');
                                        ?>
                                        </div>
                                        <div style="color: #9FB8D9; font-size: 12px; margin-top: 2px;"><?php echo date('m/d/Y, h:i a', $resultW['date_ts']); ?></div>
                                        <?php if(!empty($resultW['emp_agency_image'])){ ?>
                                            <div style="margin-top: 2px;">
                                                <a href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$resultW['emp_agency_image']; ?>" target="_blank" style="color: #17C8FF; font-size: 11px; text-decoration: underline;">View Screenshot</a>
                                            </div>
                                        <?php } ?>
                                    </td>
                                </tr>
                                <?php } ?>
                            </tbody>
                        </table>
                    </div>

                    <!-- Table Footer & Dynamic Pagination -->
                    <div class="dh-table-footer">
                        <div class="dh-table-info-text" id="infoWithdraw">Showing 1 to 5 of records</div>
                        <div class="dh-pagination-wrap" id="pagWithdraw"></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bottom Support Banner (Strictly Same Row) -->
        <div class="dh-support-banner">
            <div class="dh-support-left">
                <div class="dh-support-shield-icon">
                    <i class="bi bi-shield-fill-check"></i>
                </div>
                <div class="dh-support-text-wrap">
                    <div class="dh-support-title">All your transactions are secure and encrypted.</div>
                    <div class="dh-support-sub">If you face any issue, please contact our support team.</div>
                </div>
            </div>
            <?php
                $whatsapp_num = !empty($site_dls['whatsapp']) ? preg_replace('/[^0-9]/', '', $site_dls['whatsapp']) : '';
                $whatsapp_url = !empty($whatsapp_num) ? 'https://api.whatsapp.com/send/?phone=' . $whatsapp_num . '&text=Hello%2C%20I%20need%20assistance' : 'https://api.whatsapp.com/send/?phone=' . htmlspecialchars($site_dls['whatsapp'] ?? '');
            ?>
            <a href="<?php echo $whatsapp_url; ?>" target="_blank" class="dh-support-contact-btn">
                <i class="bi bi-headset"></i>
                <div class="dh-support-btn-text">
                    <span>Need Help?</span>
                    <span>Contact Support</span>
                </div>
                <i class="bi bi-chevron-right" style="color: #6E88A8; font-size: 12px;"></i>
            </a>
        </div>

    </div>
</div>

<script>
    function setupTablePagination(inputId, selectId, bodyId, pagId, infoId) {
        const searchInput = document.getElementById(inputId);
        const tableBody = document.getElementById(bodyId);
        const pagination = document.getElementById(pagId);
        const infoDisplay = document.getElementById(infoId);
        if (!tableBody || !pagination) return;

        const rows = Array.from(tableBody.querySelectorAll('tr'));
        const tableLengthSelect = document.getElementById(selectId);
        let currentPage = 1;
        let rowsPerPage = parseInt(tableLengthSelect ? tableLengthSelect.value : 5, 10);
        let filteredRows = [...rows];

        if (tableLengthSelect) {
            tableLengthSelect.addEventListener('change', function() {
                rowsPerPage = parseInt(this.value, 10);
                currentPage = 1;
                renderTable();
            });
        }

        function renderTable() {
            tableBody.innerHTML = '';
            const totalRecords = filteredRows.length;
            const start = (currentPage - 1) * rowsPerPage;
            const end = Math.min(start + rowsPerPage, totalRecords);
            const paginatedRows = filteredRows.slice(start, end);
            
            if (paginatedRows.length === 0) {
                const colCount = tableBody.closest('table')?.querySelectorAll('thead th').length || 2;
                tableBody.innerHTML = `<tr><td colspan="${colCount}" class="text-center py-4" style="color: #6E88A8;">No transaction records found</td></tr>`;
                if (infoDisplay) infoDisplay.textContent = 'Showing 0 to 0 of 0 records';
            } else {
                paginatedRows.forEach(row => tableBody.appendChild(row));
                if (infoDisplay) infoDisplay.textContent = `Showing ${start + 1} to ${end} of ${totalRecords} records`;
            }
            renderPagination();
        }

        function renderPagination() {
            pagination.innerHTML = '';
            const totalPages = Math.ceil(filteredRows.length / rowsPerPage);
            if (totalPages <= 1) return;

            // Prev Button
            let prevBtn = document.createElement('button');
            prevBtn.className = 'dh-page-btn';
            prevBtn.innerHTML = '‹';
            prevBtn.onclick = () => { if (currentPage > 1) { currentPage--; renderTable(); } };
            pagination.appendChild(prevBtn);

            // Page Buttons
            for (let i = 1; i <= totalPages; i++) {
                let btn = document.createElement('button');
                btn.className = 'dh-page-btn' + (i === currentPage ? ' active' : '');
                btn.innerText = i;
                btn.onclick = () => { currentPage = i; renderTable(); };
                pagination.appendChild(btn);
            }

            // Next Button
            let nextBtn = document.createElement('button');
            nextBtn.className = 'dh-page-btn';
            nextBtn.innerHTML = '›';
            nextBtn.onclick = () => { if (currentPage < totalPages) { currentPage++; renderTable(); } };
            pagination.appendChild(nextBtn);
        }

        if (searchInput) {
            searchInput.addEventListener('input', function(e) {
                const term = e.target.value.toLowerCase();
                filteredRows = rows.filter(row => row.innerText.toLowerCase().includes(term));
                currentPage = 1;
                renderTable();
            });
        }

        renderTable();
    }

    document.addEventListener('DOMContentLoaded', function() {
        setupTablePagination('searchRecharge', 'lengthRecharge', 'bodyRecharge', 'pagRecharge', 'infoRecharge');
        setupTablePagination('searchWithdraw', 'lengthWithdraw', 'bodyWithdraw', 'pagWithdraw', 'infoWithdraw');
    });
</script>

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
            }).then(function(){
                location.reload();
            });
        });
    </script>
<?php
    unset($_SESSION['head']);
    unset($_SESSION['text']);
    unset($_SESSION['swl_type']);
}
?>

<?php include 'partials/_footer.php'; ?>
