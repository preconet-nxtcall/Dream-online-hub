<?php
require 'partials/_dbconnect.php';

$date_ts = time();

$qrydisplay20 = mysqli_query($conn, "SELECT * FROM `site_stng`") or die(mysqli_error($conn));
$site_dls = mysqli_fetch_array($qrydisplay20); 

$startdate_in = isset($_GET['startdate']) ? $_GET['startdate'] : date('Y-m-d');
$enddate_in = isset($_GET['enddate']) ? $_GET['enddate'] : date('Y-m-d');
$reportfor = isset($_GET['reportfor']) ? $_GET['reportfor'] : 'ADMIN_AGENCIES';

$start_ts = strtotime($startdate_in . " 00:00:00");
$end_ts = strtotime($enddate_in . " 23:59:59");

$start_date_formatted = date('d/m/Y', strtotime($startdate_in));
$end_date_formatted = date('d/m/Y', strtotime($enddate_in));
$download_date_formatted = date('d/m/Y');

// Resolve Report For Label & Filter Conditions
$report_for_label = "Admin + Agencies";
$agency_filter_id = null;
$report_type = "ALL"; // ALL, ONLY_ADMIN, ONLY_AGENCIES, SINGLE_AGENCY

if ($reportfor == 'ONLY_ADMIN') {
    $report_for_label = "Only Admin";
    $report_type = "ONLY_ADMIN";
} else if ($reportfor == 'ADMIN_AGENCIES') {
    $report_for_label = "Admin + Agencies";
    $report_type = "ALL";
} else if ($reportfor == 'ONLY_AGENCIES') {
    $report_for_label = "Only Agencies";
    $report_type = "ONLY_AGENCIES";
} else if (strpos($reportfor, 'agency_') === 0) {
    $agency_filter_id = str_replace('agency_', '', $reportfor);
    $qry_ag_name = mysqli_query($conn, "SELECT name FROM `users` WHERE id = '$agency_filter_id'");
    if ($res_ag_name = mysqli_fetch_array($qry_ag_name)) {
        $report_for_label = $res_ag_name['name'];
    } else {
        $report_for_label = "Agency ID: " . $agency_filter_id;
    }
    $report_type = "SINGLE_AGENCY";
}

// ----------------------------------------------------
// Helper Functions for Data Queries (recharge, pay_to_admin, expense, withdrawal)
// ----------------------------------------------------

// Calculate total credit prior to start date
function getPriorCredits($conn, $start_ts, $report_type, $agency_filter_id) {
    // 1. Completed Recharges
    $sql_r = "SELECT SUM(r.amount) as total FROM recharge r LEFT JOIN users u ON r.user_id = u.id WHERE r.date_ts < '$start_ts' AND (r.stage_status = 'EMPLOYEE-DONE' OR r.stage_status = 'AGENCY-DONE' OR r.stage_status = 'DONE')";
    if ($report_type == 'ONLY_ADMIN') {
        $sql_r .= " AND (u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL OR r.emp_id = '1')";
    } else if ($report_type == 'ONLY_AGENCIES') {
        $sql_r .= " AND (u.agency_id > '1' OR r.emp_id > '1')";
    } else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
        $sql_r .= " AND (u.agency_id = '$agency_filter_id' OR r.user_id = '$agency_filter_id' OR r.emp_id = '$agency_filter_id')";
    }
    $res_r = mysqli_query($conn, $sql_r);
    $row_r = mysqli_fetch_array($res_r);
    $total_r = !empty($row_r['total']) ? floatval($row_r['total']) : 0;

    // 2. Pay To Admin (Credit for Admin or ALL)
    $total_p = 0;
    if ($report_type == 'ONLY_ADMIN' || $report_type == 'ALL') {
        $sql_p = "SELECT SUM(p.amount) as total FROM pay_to_admin p WHERE p.date_ts < '$start_ts' AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE')";
        $res_p = mysqli_query($conn, $sql_p);
        $row_p = mysqli_fetch_array($res_p);
        $total_p = !empty($row_p['total']) ? floatval($row_p['total']) : 0;
    }

    return $total_r + $total_p;
}

// Calculate total debit prior to start date
function getPriorDebits($conn, $start_ts, $report_type, $agency_filter_id) {
    // 1. Expenses
    $sql_e = "SELECT SUM(e.amount) as total FROM expense e LEFT JOIN users u ON e.emp_id = u.id WHERE e.date_ts < '$start_ts'";
    if ($report_type == 'ONLY_ADMIN') {
        $sql_e .= " AND (u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL OR e.emp_id = '1')";
    } else if ($report_type == 'ONLY_AGENCIES') {
        $sql_e .= " AND (u.agency_id > '1' OR e.emp_id > '1')";
    } else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
        $sql_e .= " AND (u.agency_id = '$agency_filter_id' OR e.emp_id = '$agency_filter_id')";
    }
    $res_e = mysqli_query($conn, $sql_e);
    $row_e = mysqli_fetch_array($res_e);
    $total_e = !empty($row_e['total']) ? floatval($row_e['total']) : 0;

    // 2. Completed Withdrawals
    $sql_w = "SELECT SUM(w.amount) as total FROM withdrawal w LEFT JOIN users u ON w.user_id = u.id WHERE w.date_ts < '$start_ts' AND (w.stage_status = 'EMPLOYEE-DONE' OR w.stage_status = 'AGENCY-DONE' OR w.stage_status = 'DONE')";
    if ($report_type == 'ONLY_ADMIN') {
        $sql_w .= " AND (w.agency_id = '1' OR u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL)";
    } else if ($report_type == 'ONLY_AGENCIES') {
        $sql_w .= " AND (w.agency_id > '1' OR u.agency_id > '1')";
    } else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
        $sql_w .= " AND (w.agency_id = '$agency_filter_id' OR w.user_id = '$agency_filter_id' OR u.agency_id = '$agency_filter_id')";
    }
    $res_w = mysqli_query($conn, $sql_w);
    $row_w = mysqli_fetch_array($res_w);
    $total_w = !empty($row_w['total']) ? floatval($row_w['total']) : 0;

    // 3. Pay To Admin (Debit for Agency when viewing Agency report)
    $total_p = 0;
    if ($report_type == 'SINGLE_AGENCY' || $report_type == 'ONLY_AGENCIES') {
        $sql_p = "SELECT SUM(p.amount) as total FROM pay_to_admin p WHERE p.date_ts < '$start_ts' AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE')";
        if (!empty($agency_filter_id)) {
            $sql_p .= " AND p.agency_id = '$agency_filter_id'";
        }
        $res_p = mysqli_query($conn, $sql_p);
        $row_p = mysqli_fetch_array($res_p);
        $total_p = !empty($row_p['total']) ? floatval($row_p['total']) : 0;
    }

    return $total_e + $total_w + $total_p;
}

// Opening balance before start_ts
$opening_balance = getPriorCredits($conn, $start_ts, $report_type, $agency_filter_id) - getPriorDebits($conn, $start_ts, $report_type, $agency_filter_id);

// ----------------------------------------------------
// Query Credit Items (Recharge & Pay To Admin) within Date Range
// ----------------------------------------------------
$credit_items = [];
$total_credit = 0;

// 1. Recharges
$sql_credit = "SELECT r.* FROM recharge r LEFT JOIN users u ON r.user_id = u.id WHERE r.date_ts >= '$start_ts' AND r.date_ts <= '$end_ts' AND (r.stage_status = 'EMPLOYEE-DONE' OR r.stage_status = 'AGENCY-DONE' OR r.stage_status = 'DONE')";
if ($report_type == 'ONLY_ADMIN') {
    $sql_credit .= " AND (u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL OR r.emp_id = '1')";
} else if ($report_type == 'ONLY_AGENCIES') {
    $sql_credit .= " AND (u.agency_id > '1' OR r.emp_id > '1')";
} else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
    $sql_credit .= " AND (u.agency_id = '$agency_filter_id' OR r.user_id = '$agency_filter_id' OR r.emp_id = '$agency_filter_id')";
}

$qry_credit = mysqli_query($conn, $sql_credit);
while ($row = mysqli_fetch_array($qry_credit)) {
    $amt = floatval($row['amount']);
    $total_credit += $amt;

    // Fetch user details
    $user_name = "N/A";
    $agency_name = "N/A";
    if (!empty($row['user_id'])) {
        $q_usr = mysqli_query($conn, "SELECT name, agency_id FROM users WHERE id = '".$row['user_id']."'");
        if ($r_usr = mysqli_fetch_array($q_usr)) {
            $user_name = $r_usr['name'];
            if (!empty($r_usr['agency_id'])) {
                $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$r_usr['agency_id']."'");
                if ($r_ag = mysqli_fetch_array($q_ag)) {
                    $agency_name = $r_ag['name'];
                }
            }
        }
    }

    if ($agency_name == "N/A" && !empty($row['emp_id'])) {
        $q_emp = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$row['emp_id']."'");
        if ($r_emp = mysqli_fetch_array($q_emp)) {
            $agency_name = $r_emp['name'];
        }
    }

    // Fetch book details
    $book_name = "N/A";
    if (!empty($row['book_id'])) {
        $q_bk = mysqli_query($conn, "SELECT name FROM features WHERE id = '".$row['book_id']."'");
        if ($r_bk = mysqli_fetch_array($q_bk)) {
            $book_name = $r_bk['name'];
        }
    }

    $bank_acc = !empty($row['bank_name']) ? $row['bank_name'] : (!empty($row['bank_slag']) ? $row['bank_slag'] : 'N/A');
    $dt_ts_val = is_numeric($row['date_ts']) ? (int)$row['date_ts'] : strtotime($row['date_ts']);
    $dt_str = date('d/m/Y h:i:s A', $dt_ts_val);

    $credit_items[] = [
        'amount' => $amt,
        'user_name' => $user_name . ' (Recharge)',
        'book_name' => $book_name,
        'bank_acc' => $bank_acc,
        'txn_id' => !empty($row['transection_id']) ? $row['transection_id'] : 'N/A',
        'date_str' => $dt_str,
        'agency_name' => $agency_name,
        'date_ts' => $dt_ts_val
    ];
}

// 2. Pay To Admin (as Credit when viewing Admin or ALL)
if ($report_type == 'ONLY_ADMIN' || $report_type == 'ALL') {
    $sql_p_credit = "SELECT p.* FROM pay_to_admin p WHERE p.date_ts >= '$start_ts' AND p.date_ts <= '$end_ts' AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE')";
    $qry_p_credit = mysqli_query($conn, $sql_p_credit);
    while ($row = mysqli_fetch_array($qry_p_credit)) {
        $amt = floatval($row['amount']);
        $total_credit += $amt;

        $agency_name = "N/A";
        if (!empty($row['agency_id'])) {
            $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$row['agency_id']."'");
            if ($r_ag = mysqli_fetch_array($q_ag)) {
                $agency_name = $r_ag['name'];
            }
        }

        $bank_acc = !empty($row['admin_bank_name']) ? $row['admin_bank_name'] : (!empty($row['bank_name']) ? $row['bank_name'] : (!empty($row['bank_slag']) ? $row['bank_slag'] : 'N/A'));
        $dt_ts_val = is_numeric($row['date_ts']) ? (int)$row['date_ts'] : strtotime($row['date_ts']);
        $dt_str = date('d/m/Y h:i:s A', $dt_ts_val);

        $credit_items[] = [
            'amount' => $amt,
            'user_name' => $agency_name . ' (Agency Deposit)',
            'book_name' => 'Agency Deposit',
            'bank_acc' => $bank_acc,
            'txn_id' => !empty($row['transaction_id']) ? $row['transaction_id'] : 'N/A',
            'date_str' => $dt_str,
            'agency_name' => $agency_name,
            'date_ts' => $dt_ts_val
        ];
    }
}

// Sort credit items chronologically
usort($credit_items, function($a, $b) {
    return $a['date_ts'] - $b['date_ts'];
});


// ----------------------------------------------------
// Query Debit Items (Expense, Withdrawal & Pay To Admin) within Date Range
// ----------------------------------------------------
$debit_items = [];
$total_debit = 0;

// 1. Expenses
$sql_debit = "SELECT e.* FROM expense e LEFT JOIN users u ON e.emp_id = u.id WHERE e.date_ts >= '$start_ts' AND e.date_ts <= '$end_ts'";
if ($report_type == 'ONLY_ADMIN') {
    $sql_debit .= " AND (u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL OR e.emp_id = '1')";
} else if ($report_type == 'ONLY_AGENCIES') {
    $sql_debit .= " AND (u.agency_id > '1' OR e.emp_id > '1')";
} else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
    $sql_debit .= " AND (u.agency_id = '$agency_filter_id' OR e.emp_id = '$agency_filter_id')";
}

$qry_debit = mysqli_query($conn, $sql_debit);
while ($row = mysqli_fetch_array($qry_debit)) {
    $amt = floatval($row['amount']);
    $total_debit += $amt;

    // Fetch expense head
    $head_name = "Expense";
    if (!empty($row['head_id'])) {
        $q_hd = mysqli_query($conn, "SELECT name FROM expense_heads WHERE id = '".$row['head_id']."'");
        if ($r_hd = mysqli_fetch_array($q_hd)) {
            $head_name = $r_hd['name'];
        }
    }

    $bank_acc = !empty($row['bank_name']) ? $row['bank_name'] : (!empty($row['bank_slag']) ? $row['bank_slag'] : 'N/A');

    $agency_name = "N/A";
    if (!empty($row['emp_id'])) {
        $q_emp = mysqli_query($conn, "SELECT name, type, agency_id FROM users WHERE id = '".$row['emp_id']."'");
        if ($r_emp = mysqli_fetch_array($q_emp)) {
            if ($r_emp['type'] == 'AGENCY') {
                $agency_name = $r_emp['name'];
            } else if (!empty($r_emp['agency_id'])) {
                $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$r_emp['agency_id']."'");
                if ($r_ag = mysqli_fetch_array($q_ag)) {
                    $agency_name = $r_ag['name'];
                }
            } else {
                $agency_name = $r_emp['name'];
            }
        }
    }

    $dt_ts_val = is_numeric($row['date_ts']) ? (int)$row['date_ts'] : strtotime($row['date_ts']);
    $dt_str = date('d/m/Y h:i:s A', $dt_ts_val);

    $debit_items[] = [
        'amount' => $amt,
        'title' => strtoupper($head_name),
        'sub_detail' => 'Type : Expense',
        'bank_acc' => $bank_acc,
        'txn_id' => !empty($row['transection_id']) ? $row['transection_id'] : 'N/A',
        'date_str' => $dt_str,
        'agency_name' => $agency_name,
        'date_ts' => $dt_ts_val
    ];
}

// 2. Withdrawals
$sql_w_debit = "SELECT w.* FROM withdrawal w LEFT JOIN users u ON w.user_id = u.id WHERE w.date_ts >= '$start_ts' AND w.date_ts <= '$end_ts' AND (w.stage_status = 'EMPLOYEE-DONE' OR w.stage_status = 'AGENCY-DONE' OR w.stage_status = 'DONE')";
if ($report_type == 'ONLY_ADMIN') {
    $sql_w_debit .= " AND (w.agency_id = '1' OR u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL)";
} else if ($report_type == 'ONLY_AGENCIES') {
    $sql_w_debit .= " AND (w.agency_id > '1' OR u.agency_id > '1')";
} else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
    $sql_w_debit .= " AND (w.agency_id = '$agency_filter_id' OR w.user_id = '$agency_filter_id' OR u.agency_id = '$agency_filter_id')";
}

$qry_w_debit = mysqli_query($conn, $sql_w_debit);
while ($row = mysqli_fetch_array($qry_w_debit)) {
    $amt = floatval($row['amount']);
    $total_debit += $amt;

    $user_name = "User";
    if (!empty($row['user_id'])) {
        $q_usr = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$row['user_id']."'");
        if ($r_usr = mysqli_fetch_array($q_usr)) {
            $user_name = $r_usr['name'];
        }
    }

    $book_name = "N/A";
    if (!empty($row['book_id'])) {
        $q_bk = mysqli_query($conn, "SELECT name FROM features WHERE id = '".$row['book_id']."'");
        if ($r_bk = mysqli_fetch_array($q_bk)) {
            $book_name = $r_bk['name'];
        }
    }

    $agency_name = "N/A";
    if (!empty($row['agency_id'])) {
        $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$row['agency_id']."'");
        if ($r_ag = mysqli_fetch_array($q_ag)) {
            $agency_name = $r_ag['name'];
        }
    }

    $bank_acc = !empty($row['bank_name']) ? $row['bank_name'] : (!empty($row['bank_slag']) ? $row['bank_slag'] : 'N/A');
    $dt_ts_val = is_numeric($row['date_ts']) ? (int)$row['date_ts'] : strtotime($row['date_ts']);
    $dt_str = date('d/m/Y h:i:s A', $dt_ts_val);

    $debit_items[] = [
        'amount' => $amt,
        'title' => $user_name . ' (Withdrawal)',
        'sub_detail' => 'Book name : ' . $book_name,
        'bank_acc' => $bank_acc,
        'txn_id' => !empty($row['transaction_id']) ? $row['transaction_id'] : 'N/A',
        'date_str' => $dt_str,
        'agency_name' => $agency_name,
        'date_ts' => $dt_ts_val
    ];
}

// 3. Pay To Admin (as Debit when viewing Agency report)
if ($report_type == 'SINGLE_AGENCY' || $report_type == 'ONLY_AGENCIES') {
    $sql_p_debit = "SELECT p.* FROM pay_to_admin p WHERE p.date_ts >= '$start_ts' AND p.date_ts <= '$end_ts' AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE')";
    if (!empty($agency_filter_id)) {
        $sql_p_debit .= " AND p.agency_id = '$agency_filter_id'";
    }

    $qry_p_debit = mysqli_query($conn, $sql_p_debit);
    while ($row = mysqli_fetch_array($qry_p_debit)) {
        $amt = floatval($row['amount']);
        $total_debit += $amt;

        $agency_name = "N/A";
        if (!empty($row['agency_id'])) {
            $q_ag = mysqli_query($conn, "SELECT name FROM users WHERE id = '".$row['agency_id']."'");
            if ($r_ag = mysqli_fetch_array($q_ag)) {
                $agency_name = $r_ag['name'];
            }
        }

        $bank_acc = !empty($row['bank_name']) ? $row['bank_name'] : (!empty($row['bank_slag']) ? $row['bank_slag'] : 'N/A');
        $dt_ts_val = is_numeric($row['date_ts']) ? (int)$row['date_ts'] : strtotime($row['date_ts']);
        $dt_str = date('d/m/Y h:i:s A', $dt_ts_val);

        $debit_items[] = [
            'amount' => $amt,
            'title' => 'PAID TO ADMIN (DEPOSIT)',
            'sub_detail' => 'Type : Pay To Admin',
            'bank_acc' => $bank_acc,
            'txn_id' => !empty($row['transaction_id']) ? $row['transaction_id'] : 'N/A',
            'date_str' => $dt_str,
            'agency_name' => $agency_name,
            'date_ts' => $dt_ts_val
        ];
    }
}

// Sort debit items chronologically
usort($debit_items, function($a, $b) {
    return $a['date_ts'] - $b['date_ts'];
});

// Closing balance calculation
$closing_balance = $opening_balance + $total_credit - $total_debit;

// ----------------------------------------------------
// Grouping by Agency & Bank Account for bottom summary section
// ----------------------------------------------------
$agency_bank_summary = [];

// Unified Bank Accounts collection across recharge, pay_to_admin, expense, and withdrawal
$bank_info_map = [];  // bank_slag => bank_name
$bank_emp_map = [];   // bank_slag => emp_id / agency_id

// 1. From recharge
$sql_r_banks = "SELECT DISTINCT r.bank_slag, r.bank_name, r.emp_id, u.agency_id FROM recharge r LEFT JOIN users u ON r.user_id = u.id WHERE r.bank_slag != '' AND r.date_ts <= '$end_ts' AND (r.stage_status = 'EMPLOYEE-DONE' OR r.stage_status = 'AGENCY-DONE' OR r.stage_status = 'DONE')";
if ($report_type == 'ONLY_ADMIN') {
    $sql_r_banks .= " AND (u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL OR r.emp_id = '1')";
} else if ($report_type == 'ONLY_AGENCIES') {
    $sql_r_banks .= " AND (u.agency_id > '1' OR r.emp_id > '1')";
} else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
    $sql_r_banks .= " AND (u.agency_id = '$agency_filter_id' OR r.user_id = '$agency_filter_id' OR r.emp_id = '$agency_filter_id')";
}

$qry_r_banks = mysqli_query($conn, $sql_r_banks);
if ($qry_r_banks) {
    while ($rb = mysqli_fetch_array($qry_r_banks)) {
        $b_slag = $rb['bank_slag'];
        $b_name = !empty($rb['bank_name']) ? $rb['bank_name'] : $b_slag;
        $b_owner = (!empty($rb['agency_id']) && $rb['agency_id'] > 1) ? $rb['agency_id'] : $rb['emp_id'];
        
        $bank_info_map[$b_slag] = $b_name;
        if (!isset($bank_emp_map[$b_slag])) {
            $bank_emp_map[$b_slag] = $b_owner;
        }
    }
}

// 2. From pay_to_admin
$sql_p_banks = "SELECT DISTINCT p.bank_slag, p.bank_name, p.admin_bank_slag, p.admin_bank_name, p.agency_id FROM pay_to_admin p WHERE p.date_ts <= '$end_ts' AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE')";
$qry_p_banks = mysqli_query($conn, $sql_p_banks);
if ($qry_p_banks) {
    while ($pb = mysqli_fetch_array($qry_p_banks)) {
        if (!empty($pb['admin_bank_slag'])) {
            $b_slag = $pb['admin_bank_slag'];
            $b_name = !empty($pb['admin_bank_name']) ? $pb['admin_bank_name'] : $b_slag;
            $bank_info_map[$b_slag] = $b_name;
            if (!isset($bank_emp_map[$b_slag])) {
                $bank_emp_map[$b_slag] = '1';
            }
        }
        if (!empty($pb['bank_slag'])) {
            $b_slag = $pb['bank_slag'];
            $b_name = !empty($pb['bank_name']) ? $pb['bank_name'] : $b_slag;
            $bank_info_map[$b_slag] = $b_name;
            if (!isset($bank_emp_map[$b_slag])) {
                $bank_emp_map[$b_slag] = $pb['agency_id'];
            }
        }
    }
}

// 3. From expense
$sql_e_banks = "SELECT DISTINCT e.bank_slag, e.bank_name, e.emp_id, u.agency_id FROM expense e LEFT JOIN users u ON e.emp_id = u.id WHERE e.bank_slag != '' AND e.date_ts <= '$end_ts'";
if ($report_type == 'ONLY_ADMIN') {
    $sql_e_banks .= " AND (u.agency_id = '1' OR u.agency_id = '' OR u.agency_id IS NULL OR e.emp_id = '1')";
} else if ($report_type == 'ONLY_AGENCIES') {
    $sql_e_banks .= " AND (u.agency_id > '1' OR e.emp_id > '1')";
} else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
    $sql_e_banks .= " AND (u.agency_id = '$agency_filter_id' OR e.emp_id = '$agency_filter_id')";
}

$qry_e_banks = mysqli_query($conn, $sql_e_banks);
if ($qry_e_banks) {
    while ($eb = mysqli_fetch_array($qry_e_banks)) {
        $b_slag = $eb['bank_slag'];
        $b_name = !empty($eb['bank_name']) ? $eb['bank_name'] : $b_slag;
        $b_owner = (!empty($eb['agency_id']) && $eb['agency_id'] > 1) ? $eb['agency_id'] : $eb['emp_id'];
        
        if (!isset($bank_info_map[$b_slag])) {
            $bank_info_map[$b_slag] = $b_name;
        }
        if (!isset($bank_emp_map[$b_slag])) {
            $bank_emp_map[$b_slag] = $b_owner;
        }
    }
}

// 4. From withdrawal
$sql_w_banks = "SELECT DISTINCT w.bank_slag, w.bank_name, w.agency_id FROM withdrawal w WHERE w.bank_slag != '' AND w.date_ts <= '$end_ts' AND (w.stage_status = 'EMPLOYEE-DONE' OR w.stage_status = 'AGENCY-DONE' OR w.stage_status = 'DONE')";
if ($report_type == 'ONLY_ADMIN') {
    $sql_w_banks .= " AND (w.agency_id = '1' OR w.agency_id = '' OR w.agency_id IS NULL)";
} else if ($report_type == 'ONLY_AGENCIES') {
    $sql_w_banks .= " AND w.agency_id > '1'";
} else if ($report_type == 'SINGLE_AGENCY' && !empty($agency_filter_id)) {
    $sql_w_banks .= " AND w.agency_id = '$agency_filter_id'";
}

$qry_w_banks = mysqli_query($conn, $sql_w_banks);
if ($qry_w_banks) {
    while ($wb = mysqli_fetch_array($qry_w_banks)) {
        $b_slag = $wb['bank_slag'];
        $b_name = !empty($wb['bank_name']) ? $wb['bank_name'] : $b_slag;
        $b_owner = !empty($wb['agency_id']) ? $wb['agency_id'] : '1';
        
        if (!isset($bank_info_map[$b_slag])) {
            $bank_info_map[$b_slag] = $b_name;
        }
        if (!isset($bank_emp_map[$b_slag])) {
            $bank_emp_map[$b_slag] = $b_owner;
        }
    }
}

// Calculate closing balance for each unified bank account using bank_slag
foreach ($bank_emp_map as $bank_slag_val => $bank_owner_id) {
    $bank_name_val = isset($bank_info_map[$bank_slag_val]) ? $bank_info_map[$bank_slag_val] : $bank_slag_val;

    // Determine Agency Name for display
    $ag_name_val = "Admin";
    if (!empty($bank_owner_id) && $bank_owner_id > 1) {
        $q_ag_owner = mysqli_query($conn, "SELECT name FROM users WHERE id = '$bank_owner_id'");
        if ($r_ag_owner = mysqli_fetch_array($q_ag_owner)) {
            $ag_name_val = $r_ag_owner['name'];
        }
    } else if ($report_type == 'SINGLE_AGENCY' && !empty($report_for_label)) {
        $ag_name_val = $report_for_label;
    }

    // Calculate total credits (recharge + pay_to_admin credits) for this bank account up to $end_ts
    $q_bank_cr1 = mysqli_query($conn, "SELECT SUM(r.amount) AS total FROM recharge r WHERE r.bank_slag = '$bank_slag_val' AND (r.stage_status = 'EMPLOYEE-DONE' OR r.stage_status = 'AGENCY-DONE' OR r.stage_status = 'DONE') AND r.date_ts <= '$end_ts'");
    $r_bank_cr1 = mysqli_fetch_array($q_bank_cr1);
    $total_bank_cr1 = !empty($r_bank_cr1['total']) ? floatval($r_bank_cr1['total']) : 0;

    $q_bank_cr2 = mysqli_query($conn, "SELECT SUM(p.amount) AS total FROM pay_to_admin p WHERE (p.admin_bank_slag = '$bank_slag_val' OR p.bank_slag = '$bank_slag_val') AND (p.stage_status = 'EMPLOYEE-DONE' OR p.stage_status = 'ADMIN-DONE' OR p.stage_status = 'DONE') AND p.date_ts <= '$end_ts'");
    $r_bank_cr2 = mysqli_fetch_array($q_bank_cr2);
    $total_bank_cr2 = !empty($r_bank_cr2['total']) ? floatval($r_bank_cr2['total']) : 0;

    $total_bank_cr = $total_bank_cr1 + $total_bank_cr2;

    // Calculate total debits (expenses + withdrawals) for this bank account up to $end_ts
    $q_bank_db1 = mysqli_query($conn, "SELECT SUM(e.amount) AS total FROM expense e WHERE e.bank_slag = '$bank_slag_val' AND e.date_ts <= '$end_ts'");
    $r_bank_db1 = mysqli_fetch_array($q_bank_db1);
    $total_bank_db1 = !empty($r_bank_db1['total']) ? floatval($r_bank_db1['total']) : 0;

    $q_bank_db2 = mysqli_query($conn, "SELECT SUM(w.amount) AS total FROM withdrawal w WHERE w.bank_slag = '$bank_slag_val' AND (w.stage_status = 'EMPLOYEE-DONE' OR w.stage_status = 'AGENCY-DONE' OR w.stage_status = 'DONE') AND w.date_ts <= '$end_ts'");
    $r_bank_db2 = mysqli_fetch_array($q_bank_db2);
    $total_bank_db2 = !empty($r_bank_db2['total']) ? floatval($r_bank_db2['total']) : 0;

    $bank_closing_bal = $total_bank_cr - ($total_bank_db1 + $total_bank_db2);

    $agency_bank_summary[$ag_name_val][$bank_name_val] = $bank_closing_bal;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daily Ledger Book - <?php echo $start_date_formatted; ?> to <?php echo $end_date_formatted; ?></title>
    <link rel="shortcut icon" type="image/png" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['fevicon']; ?>">
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- FontAwesome / Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">

    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background-color: #f8f9fa;
            color: #000;
        }

        .ledger-page {
            max-width: 850px;
            margin: 20px auto;
            background: transparent;
            padding: 0;
            box-shadow: none;
        }

        .ledger-pdf-page {
            background: #ffffff;
            padding: 20px;
            margin-bottom: 25px;
            box-shadow: 0 0 15px rgba(0,0,0,0.1);
            page-break-after: always;
            break-after: page;
            box-sizing: border-box;
        }

        .ledger-pdf-page:last-child {
            page-break-after: avoid;
            break-after: avoid;
            margin-bottom: 0;
        }

        .ledger-title-container {
            text-align: center;
            margin-bottom: 10px;
        }

        .ledger-title {
            font-size: 20px;
            font-weight: 700;
            display: inline-block;
            border-bottom: 2px solid #000;
            padding-bottom: 2px;
            letter-spacing: 0.5px;
        }

        .meta-header {
            font-size: 12px;
            font-weight: 600;
            line-height: 1.4;
            margin-bottom: 10px;
        }

        /* Main Rounded Box Container */
        .main-ledger-box {
            border: 2px solid #000;
            border-radius: 14px;
            padding: 10px;
            background-color: #fff;
        }

        .balance-banner {
            font-size: 14px;
            font-weight: 700;
            margin-bottom: 8px;
            padding-left: 5px;
        }

        .closing-banner {
            font-size: 14px;
            font-weight: 700;
            margin-top: 8px;
            text-align: center;
        }

        /* Inner Table Box Split */
        .columns-container {
            border: 1.5px solid #000;
            border-radius: 12px;
            display: flex;
            overflow: hidden;
            background: #fff;
        }

        .credit-col {
            width: 50%;
            border-right: 1.5px solid #000;
            display: flex;
            flex-direction: column;
        }

        .debit-col {
            width: 50%;
            display: flex;
            flex-direction: column;
        }

        .col-header {
            font-size: 18px;
            font-weight: 800;
            text-align: center;
            padding: 4px;
            border-bottom: 1.5px solid #000;
            letter-spacing: 1px;
        }

        .table-subheaders {
            display: flex;
            border-bottom: 1.5px solid #000;
            font-weight: 700;
            font-size: 13px;
            padding: 4px 0;
        }

        .amt-th {
            width: 25%;
            text-align: center;
            border-right: 1px solid #000;
        }

        .details-th {
            width: 75%;
            text-align: center;
        }

        .entries-list {
            flex-grow: 1;
            min-height: 150px;
        }

        .entry-row {
            display: flex;
            border-bottom: 1px solid #ddd;
            font-size: 13px;
            line-height: 1.25;
        }

        .entry-row:last-child {
            border-bottom: none;
        }

        .amt-cell {
            width: 25%;
            padding: 4px 4px;
            font-weight: 700;
            font-size: 14px;
            border-right: 1px solid #000;
            text-align: left;
        }

        .details-cell {
            width: 75%;
            padding: 4px 6px;
            word-wrap: break-word;
        }

        .col-footer {
            border-top: 1.5px solid #000;
            padding: 5px;
            text-align: center;
            font-weight: 700;
            font-size: 12px;
            background: #fff;
        }

        .bottom-summary {
            margin-top: 10px;
            font-size: 11px;
            font-weight: 700;
            line-height: 1.35;
            padding-left: 5px;
        }

        .agency-summary-group {
            margin-bottom: 4px;
        }

        .agency-summary-group:last-child {
            margin-bottom: 0;
        }

        .agency-name-title {
            font-size: 12px;
            font-weight: 800;
            color: #000;
            margin-bottom: 2px;
        }

        .account-line {
            font-size: 11px;
            font-weight: 700;
            color: #000;
            line-height: 1.35;
        }

        .page-number-footer {
            text-align: center;
            font-size: 12px;
            font-weight: 700;
            margin-top: 10px;
            color: #000;
        }

        /* Action Toolbar */
        .action-toolbar {
            max-width: 850px;
            margin: 15px auto 0 auto;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        @media print {
            .action-toolbar {
                display: none !important;
            }
            body {
                background: #fff;
            }
            .ledger-page {
                box-shadow: none;
                padding: 0;
                margin: 0 auto;
                max-width: 100%;
            }
            .ledger-pdf-page {
                box-shadow: none;
                padding: 0;
                margin: 0 0 20px 0;
            }
        }
    </style>

    <!-- html2pdf bundle library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
</head>
<body>

    <!-- Action Toolbar (Hidden in Print) -->
    <div class="action-toolbar">
        <button onclick="downloadAsPDF()" class="btn btn-primary btn-md shadow-sm fw-bold">
            <i class="bi bi-download me-1"></i> Download PDF
        </button>
        <button onclick="window.print()" class="btn btn-secondary btn-md shadow-sm fw-bold">
            <i class="bi bi-printer me-1"></i> Print
        </button>
    </div>

    <?php
        $items_per_page = 6;
        $max_items = max(count($credit_items), count($debit_items));
        $total_pages = ($max_items > 0) ? ceil($max_items / $items_per_page) : 1;
    ?>

    <!-- Main Printable Ledger Container -->
    <div class="ledger-page" id="ledger-report-content">
        <?php for($p = 1; $p <= $total_pages; $p++): 
            $page_credit_items = array_slice($credit_items, ($p - 1) * $items_per_page, $items_per_page);
            $page_debit_items  = array_slice($debit_items,  ($p - 1) * $items_per_page, $items_per_page);

            $cum_credit_slice = array_slice($credit_items, 0, $p * $items_per_page);
            $cum_debit_slice  = array_slice($debit_items,  0, $p * $items_per_page);

            $cum_credit_total = 0;
            foreach($cum_credit_slice as $c_item) {
                $cum_credit_total += $c_item['amount'];
            }

            $cum_debit_total = 0;
            foreach($cum_debit_slice as $d_item) {
                $cum_debit_total += $d_item['amount'];
            }
        ?>
        <div class="ledger-pdf-page">
            
            <?php if($p == 1): ?>
            <!-- Document Title (Page 1) -->
            <div class="ledger-title-container">
                <div class="ledger-title">Daily Ledger Book</div>
            </div>

            <!-- Meta Information (Page 1) -->
            <div class="meta-header">
                Starting Date : <?php echo $start_date_formatted; ?><br>
                Ending Date : <?php echo $end_date_formatted; ?><br>
                Report Generate for : <?php echo $report_for_label; ?><br>
                Report Download Date : <?php echo $download_date_formatted; ?>
            </div>
            <?php endif; ?>

            <!-- Main Outer Box Container -->
            <div class="main-ledger-box">
                
                <?php if($p == 1): ?>
                <!-- Opening Balance Banner (Page 1) -->
                <div class="balance-banner">
                    <?php echo $start_date_formatted; ?> Opening Balance : Rs. <?php echo number_format($opening_balance, 0, '.', ''); ?>/-
                </div>
                <?php endif; ?>

                <!-- Two Column Split Table Container -->
                <div class="columns-container">
                    
                    <!-- CREDIT COLUMN -->
                    <div class="credit-col">
                        <div class="col-header">CREDIT</div>
                        
                        <div class="table-subheaders">
                            <div class="amt-th">Amt.</div>
                            <div class="details-th">Details</div>
                        </div>

                        <div class="entries-list">
                            <?php if(empty($page_credit_items)): ?>
                                <div class="text-center text-muted p-4 font-italic" style="font-size: 12px;">No credit entries</div>
                            <?php else: ?>
                                <?php foreach($page_credit_items as $item): ?>
                                    <div class="entry-row">
                                        <div class="amt-cell text-center">Rs.<?php echo $item['amount']; ?>/-</div>
                                        <div class="details-cell">
                                            <strong><?php echo $item['user_name']; ?></strong><br>
                                            Book name : <?php echo $item['book_name']; ?><br>
                                            A/C : <?php echo $item['bank_acc']; ?><br>
                                            Transection ID : <?php echo $item['txn_id']; ?><br>
                                            <?php echo $item['date_str']; ?><br>
                                            Agency : <?php echo $item['agency_name']; ?>
                                        </div>
                                    </div>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </div>

                        <div class="col-footer">
                            Total Credit Amt. : Rs.<?php echo number_format($cum_credit_total, 0, '.', ''); ?>/-
                        </div>
                    </div>

                    <!-- DEBIT COLUMN -->
                    <div class="debit-col">
                        <div class="col-header">DEBIT</div>

                        <div class="table-subheaders">
                            <div class="amt-th">Amt.</div>
                            <div class="details-th">Details</div>
                        </div>

                        <div class="entries-list">
                            <?php if(empty($page_debit_items)): ?>
                                <div class="text-center text-muted p-4 font-italic" style="font-size: 12px;">No debit entries</div>
                            <?php else: ?>
                                <?php foreach($page_debit_items as $item): ?>
                                    <div class="entry-row">
                                        <div class="amt-cell text-center">Rs.<?php echo $item['amount']; ?>/-</div>
                                        <div class="details-cell">
                                            <strong><?php echo $item['title']; ?></strong><br>
                                            <?php if(!empty($item['sub_detail'])){ echo $item['sub_detail'] . '<br>'; } ?>
                                            A/C : <?php echo $item['bank_acc']; ?><br>
                                            Transection ID : <?php echo $item['txn_id']; ?><br>
                                            <?php echo $item['date_str']; ?><br>
                                            Agency : <?php echo $item['agency_name']; ?>
                                        </div>
                                    </div>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </div>

                        <div class="col-footer">
                            Total Debit Amt. : Rs.<?php echo number_format($cum_debit_total, 0, '.', ''); ?>/-
                        </div>
                    </div>

                </div>

                <?php if($p == $total_pages): ?>
                <!-- Closing Balance Banner (Last Page) -->
                <div class="closing-banner">
                    <?php echo $end_date_formatted; ?> Closing Balance : Rs. <?php echo number_format($closing_balance, 0, '.', ''); ?>/-
                </div>
                <?php endif; ?>

            </div>

            <?php if($p == $total_pages): ?>
            <!-- Bottom Summary Breakdown by Agency & Account (Last Page) -->
            <div class="bottom-summary">
                <?php if(empty($agency_bank_summary)): ?>
                    <!-- Default / Fallback summary display if no transactions in range -->
                    <div class="agency-summary-group">
                        <div class="agency-name-title">Agency Name : <?php echo $report_for_label; ?></div>
                        <div class="account-line">A/C : N/A - Total Closing Balance : Rs 0/-</div>
                    </div>
                <?php else: ?>
                    <?php foreach($agency_bank_summary as $ag_name => $accounts): ?>
                        <div class="agency-summary-group">
                            <div class="agency-name-title">Agency Name : <?php echo $ag_name; ?></div>
                            <?php foreach($accounts as $acc_num => $bal): ?>
                                <div class="account-line">A/C : <?php echo $acc_num; ?> - Total Closing Balance : Rs <?php echo number_format($bal, 0, '.', ''); ?>/-</div>
                            <?php endforeach; ?>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
            <?php endif; ?>

            <!-- Page Number Indicator at bottom of each page -->
            <div class="page-number-footer">
                Page Number <?php echo $p; ?> of <?php echo $total_pages; ?>
            </div>

        </div>
        <?php endfor; ?>
    </div>

    <!-- PDF Download Script -->
    <script>
        function downloadAsPDF() {
            const element = document.getElementById('ledger-report-content');
            const opt = {
                margin:       [0.2, 0.2, 0.2, 0.2],
                filename:     'Daily_Ledger_<?php echo str_replace('/', '-', $start_date_formatted); ?>_to_<?php echo str_replace('/', '-', $end_date_formatted); ?>_<?php echo $date_ts; ?>.pdf',
                image:        { type: 'jpeg', quality: 0.98 },
                html2canvas:  { scale: 2, useCORS: true, logging: false, scrollY: 0 },
                jsPDF:        { unit: 'in', format: 'a4', orientation: 'portrait' },
                pagebreak:    { mode: ['css', 'legacy'] }
            };
            html2pdf().set(opt).from(element).save();
        }
    </script>
</body>
</html>
