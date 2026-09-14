<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

// ───────────────────────────────────────────────────────────
// Handle Excel Upload  (POST  add_profit_loss)
// ───────────────────────────────────────────────────────────
if(ISSET($_POST['add_profit_loss'])){

    $start_date = addslashes($_POST["start_date"]);
    $end_date   = addslashes($_POST["end_date"]);

    // ── Validate file ──────────────────────────────────────
    $file = $_FILES['excel'];
    $ext  = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

    if($ext !== 'xlsx'){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head']     = "Error !";
        $_SESSION['text']     = "Please upload a valid .xlsx file!";
        header("Refresh:0;");
        exit;
    }

    // ── Require SimpleXLSX (auto-download if missing) ──────
    $xlsxLib = __DIR__ . '/partials/SimpleXLSX.php';
    if(!file_exists($xlsxLib)){
        $src = @file_get_contents('https://raw.githubusercontent.com/shuchkin/simplexlsx/master/src/SimpleXLSX.php');
        if($src){
            file_put_contents($xlsxLib, $src);
        } else {
            $_SESSION['swl_type'] = "error";
            $_SESSION['head']     = "Error !";
            $_SESSION['text']     = "Could not download SimpleXLSX library. Please add it manually to office/partials/.";
            header("Refresh:0;");
            exit;
        }
    }
    require_once $xlsxLib;

    // ── Parse the XLSX ─────────────────────────────────────
    $xlsx = \Shuchkin\SimpleXLSX::parse($file['tmp_name']);

    if(!$xlsx){
        $_SESSION['swl_type'] = "error";
        $_SESSION['head']     = "Error !";
        $_SESSION['text']     = "Failed to parse Excel: " . \Shuchkin\SimpleXLSX::parseError();
        header("Refresh:0;");
        exit;
    }

    $rows        = $xlsx->rows();
    $inserted    = 0;
    $skipped     = 0;
    $skippedNames = [];

    // Skip header rows — data starts after the header row that contains "User Name"
    $dataStarted = false;

    foreach($rows as $row){

        // Try to detect header row and skip it
        $firstCell = trim($row[0] ?? '');
        if(!$dataStarted){
            // Skip any row where column-A looks like a header or is empty
            if($firstCell === '' || stripos($firstCell, 'user') !== false || stripos($firstCell, 'name') !== false){
                $dataStarted = true; // next rows are data
                continue;
            }
            // If first cell already looks like a username (no header row), treat as data
            $dataStarted = true;
        }

        // Column A = username
        $excel_username = trim($row[0] ?? '');
        if($excel_username === '') continue; // skip empty rows

        // Take value from 2nd column (B) or 3rd column (C)
        $valB = floatval(str_replace(',', '', ($row[1] ?? '0')));
        $valC = floatval(str_replace(',', '', ($row[2] ?? '0')));

        $value = 0;
        if ($valB != 0) {
            $value = $valB;
        } elseif ($valC != 0) {
            $value = $valC;
        }

        // ── Slugify the Excel username (same logic as pending-subscription.php) ──
        $excel_slug = strtolower(preg_replace("/[^0-9a-zA-Z]+/", "-", $excel_username));
        $excel_slug = rtrim($excel_slug, "-");

        // ── Match against subscription table ───────────────
        // Try username_slag first, fall back to LOWER(username)
        $stmt = $conn->prepare(
            "SELECT id, user_id, book_id, username FROM `subscription`
             WHERE (username_slag = ? OR LOWER(username) = ?)
               AND show_status = 'ACTIVE'
             LIMIT 1"
        );
        $lower_username = strtolower($excel_username);
        $stmt->bind_param("ss", $excel_slug, $lower_username);
        $stmt->execute();
        $res = $stmt->get_result();

        if($res->num_rows === 0){
            $skipped++;
            $skippedNames[] = $excel_username;
            $stmt->close();
            continue;
        }

        $sub = $res->fetch_assoc();
        $stmt->close();

        $sub_user_id  = $sub['user_id'];
        $sub_book_id  = $sub['book_id'];
        $sub_id       = $sub['id'];
        $sub_username = $sub['username'];

        // ── Determine profit / loss ────────────────────────
        $profit = 0;
        $loss   = 0;
        if($value > 0){
            $profit = abs($value);
        } else if($value < 0){
            $loss = abs($value);
        }

        // ── Insert into profit_loss ────────────────────────
        $stmt2 = $conn->prepare(
            "INSERT INTO `profit_loss`
                (`user_id`,`subscription_id`, `book_id`, `username`, `start_date`, `end_date`, `profit`, `loss`, `date_ts`)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        $profitStr = number_format($profit, 2, '.', '');
        $lossStr   = number_format($loss, 2, '.', '');
        $stmt2->bind_param("sssssssss",
            $sub_user_id,
            $sub_id,
            $sub_book_id,
            $sub_username,
            $start_date,
            $end_date,
            $profitStr,
            $lossStr,
            $date_ts
        );

        if($stmt2->execute()){
            $inserted++;
            if($profit > 0){
                $stmt_u = $conn->prepare(
                    "UPDATE `users` SET `available_amount` = COALESCE(NULLIF(`available_amount`, ''), '0') + ? WHERE `id` = ?"
                );
                $stmt_u->bind_param("ds", $profit, $sub_user_id);
                $stmt_u->execute();
                $stmt_u->close();
            }
        }
        $stmt2->close();
    }

    // ── Feedback ───────────────────────────────────────────
    if($inserted > 0){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head']     = "Successfull !";
        $msg = "$inserted record(s) imported.";
        if($skipped > 0){
            $msg .= " $skipped skipped (no subscription match).";
        }
        $_SESSION['text'] = $msg;
    } else {
        $_SESSION['swl_type'] = "error";
        $_SESSION['head']     = "Error !";
        $_SESSION['text']     = "No records imported. $skipped row(s) had no matching subscription.";
    }
    header("Refresh:0;");
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
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_partnr" class="btn btn_warning btn-sm">Upload Profit & Loss <i class="bi bi-upload ms-2"></i></button>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Profit & Loss </strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for Upload -->
            <div class="modal fade mt-4 pt-4" id="insert_partnr" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!importent;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Upload Profit & Loss Excel</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                        <form class="row" action="profit-loss" method="post" enctype="multipart/form-data" id="form">
                            <div class="card-body card-block">
                                <div class="row mb-3">
                                    <label class="col-sm-2 col-form-label">Start Date</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">📅</span>
                                            <input type="date" class="form-control" name="start_date" required>
                                        </div>
                                    </div>
                                    <label class="col-sm-2 col-form-label">End Date</label>
                                    <div class="col-sm-4">
                                        <div class="input-group mb-3">
                                            <span class="input-group-text" id="basic-addon1">📅</span>
                                            <input type="date" class="form-control" name="end_date" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mx-1 mb-3">
                                    <label class="col-form-label">Upload Profit & Loss Excel (.xlsx)</label>
                                    <input class="form-control" type="file" name="excel" accept=".xlsx" required>
                                </div>
                                <hr class="ml-100">
                                <div class="row">
                                    <div class="d-flex gap-3 mt-3">
                                        <button name="add_profit_loss" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                        <i class="bi bi-check-lg me-2"></i> UPLOAD & IMPORT
                                        </button>
                                        <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect">
                                        <i class="bi bi-x-lg me-2"></i> RESET 
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form><!-- End upload Form -->
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
                            <th class="text-center" scope="col">User</th>
                            <th class="text-center" scope="col">Book</th>
                            <th class="text-center" scope="col">Profit/Loss</th>
                            <th class="text-center" scope="col">Date Range</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT pl.*, f.name as book_name FROM `profit_loss` pl LEFT JOIN `features` f ON pl.book_id = f.id ORDER BY ABS(pl.id) DESC") or die(mysqli_error());
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                        $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '".$result['user_id']."'");
                        $resultusr = mysqli_fetch_array($qryusr);
                        $qragency = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '".$resultusr['agency_id']."'");
                        $resulagc = mysqli_fetch_array($qragency);
                    ?>  
                        <tr id="<?php echo $result['id'] ?>" >
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                User : <?php echo $resultusr['name']; ?><br>
                                Agency : <?php echo $resulagc['name']; ?>
                            </td>
                            <td>
                                Book : <?php echo htmlspecialchars($result['book_name'] ?? 'N/A'); ?><br>
                                Username : <?php echo htmlspecialchars($result['username']); ?>
                            </td>
                            <td>
                                Profit : 
                                <?php
                                    $profit = floatval($result['profit']);
                                    if($profit > 0){
                                        echo '<span class="badge bg-success">₹' . number_format($profit, 2) . '</span>';
                                    } else {
                                        echo '<span class="text-muted">—</span>';
                                    }
                                ?><br>
                                Loss : 
                                <?php
                                    $loss = floatval($result['loss']);
                                    if($loss > 0){
                                        echo '<span class="badge bg-danger">₹' . number_format($loss, 2) . '</span>';
                                    } else {
                                        echo '<span class="text-muted">—</span>';
                                    }
                                ?>
                            </td>
                            <td>
                                <?php echo $result['start_date']; ?> <br><small>to</small><br> <?php echo $result['end_date']; ?>
                            </td>
                        </tr>
                    <?php  }  ?>
                    </tbody>
                </table>
            </div>
            <!-- End Table with stripped rows -->
        </div>
    </div>
    
</div>

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
			});
		});
		
	</script>
<?php
    unset($_SESSION['head']);
    unset($_SESSION['text']);
    unset($_SESSION['swl_type']);
}
?>
<?php include 'partials/_footer.php' ?>