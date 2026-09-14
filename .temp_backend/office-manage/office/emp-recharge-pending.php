<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: emp-recharge-pending');
}
$msg='';
if(ISSET($_POST['edit_emp_recharge_pending'])){
    $id = $_POST["id"];
    $agency_id = $_POST["agency_id"];
    $amount = $_POST["amount"];
    $stage_status = !empty($_POST["stage_status"]) ? addslashes($_POST["stage_status"]) : 'AGENCY-DONE';
    $employee_remark = addslashes($_POST["employee_remark"]);
    $employee_read_status = "READ";

    $qry = "UPDATE `recharge` SET `stage_status` = '".$stage_status."', `employee_read_status` = '".$employee_read_status."', `employee_remark` = '".$employee_remark."' WHERE `id` = '".$id."'" or die(mysqli_error());
    $query = mysqli_query($conn,$qry);
    if($query){
        if($stage_status == 'EMPLOYEE-DONE') {

            if(!file_exists(__DIR__ . '/partials/fpdf.php')){
                file_put_contents(__DIR__ . '/partials/fpdf.php', file_get_contents("https://raw.githubusercontent.com/Setasign/FPDF/master/fpdf.php"));
            }
            if(!is_dir(__DIR__ . '/partials/font')){
                mkdir(__DIR__ . '/partials/font', 0777, true);
            }
            if(!file_exists(__DIR__ . '/partials/font/helvetica.json')){
                file_put_contents(__DIR__ . '/partials/font/helvetica.json', file_get_contents("https://raw.githubusercontent.com/Setasign/FPDF/master/font/helvetica.json"));
            }
            if(!file_exists(__DIR__ . '/partials/font/helveticab.json')){
                file_put_contents(__DIR__ . '/partials/font/helveticab.json', file_get_contents("https://raw.githubusercontent.com/Setasign/FPDF/master/font/helveticab.json"));
            }
            require_once __DIR__ . '/partials/fpdf.php';
            
            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = (SELECT user_id FROM recharge WHERE id = '$id')");
            $resusr = mysqli_fetch_array($qryusr);
            
            $qryrec = mysqli_query($conn, "SELECT * FROM recharge WHERE id = '$id'");
            $resrec = mysqli_fetch_array($qryrec);

            $qrysitedls = mysqli_query($conn, "SELECT * FROM `site_stng` WHERE id = '1'");
            $ressitedls = mysqli_fetch_array($qrysitedls);
            
            $book_name = "N/A";
            if(!empty($resrec['book_id'])){
                $qrybk = mysqli_query($conn, "SELECT name FROM features WHERE id = '".$resrec['book_id']."'");
                $resbk = mysqli_fetch_array($qrybk);
                if($resbk) $book_name = $resbk['name'];
            }

            $qryrandprd = mysqli_query($conn, "SELECT * FROM features WHERE type = 'PRODUCT' ORDER BY RAND() LIMIT 1");
            $resrandprd = mysqli_fetch_array($qryrandprd);
            
            // Number to words function
            if (!function_exists('numberToWords')) {
                function numberToWords($num) {
                    $ones = array(
                        0 => "zero", 1 => "one", 2 => "two", 3 => "three", 4 => "four", 5 => "five",
                        6 => "six", 7 => "seven", 8 => "eight", 9 => "nine", 10 => "ten", 
                        11 => "eleven", 12 => "twelve", 13 => "thirteen", 14 => "fourteen", 
                        15 => "fifteen", 16 => "sixteen", 17 => "seventeen", 18 => "eighteen", 19 => "nineteen"
                    );
                    $tens = array(
                        0 => "zero", 1 => "ten", 2 => "twenty", 3 => "thirty", 4 => "forty", 5 => "fifty", 
                        6 => "sixty", 7 => "seventy", 8 => "eighty", 9 => "ninety"
                    );
                    $hundreds = array(
                        "hundred", "thousand", "million", "billion", "trillion", "quadrillion"
                    );
                    $num = number_format($num,2,".",","); 
                    $num_arr = explode(".",$num); 
                    $wholenum = $num_arr[0]; 
                    $decnum = $num_arr[1]; 
                    $whole_arr = array_reverse(explode(",",$wholenum)); 
                    krsort($whole_arr); 
                    $rettxt = ""; 
                    foreach($whole_arr as $key => $i){ 
                        if($i < 20){ 
                            $rettxt .= $ones[intval($i)]; 
                        }elseif($i < 100){ 
                            $rettxt .= $tens[substr($i,0,1)]; 
                            $rettxt .= " ".$ones[substr($i,1,1)]; 
                        }else{ 
                            $rettxt .= $ones[substr($i,0,1)]." ".$hundreds[0]; 
                            $rettxt .= " ".$tens[substr($i,1,1)]; 
                            $rettxt .= " ".$ones[substr($i,2,1)]; 
                        } 
                        if($key > 0){ 
                            $rettxt .= " ".$hundreds[$key]." "; 
                        } 
                    } 
                    if($decnum > 0){ 
                        $rettxt .= " and "; 
                        if($decnum < 20){ 
                            $rettxt .= $ones[intval($decnum)]; 
                        }elseif($decnum < 100){ 
                            $rettxt .= $tens[substr($decnum,0,1)]; 
                            $rettxt .= " ".$ones[substr($decnum,1,1)]; 
                        } 
                        $rettxt .= " paise";
                    } 
                    return ucfirst(trim(str_replace("zero", "", $rettxt))) . " rupees only";
                }
            }

            // Fetch agency details
            $agency_name = "N/A";
            $agency_id_text = "N/A";
            if(!empty($resusr['agency_id'])) {
                $qryag = mysqli_query($conn, "SELECT name, agency_unq_id FROM users WHERE id = '".$resusr['agency_id']."'");
                if($resag = mysqli_fetch_array($qryag)) {
                    $agency_name = $resag['name'];
                    $agency_id_text = $resag['agency_unq_id'];
                }
            }
            
            $pdf = new FPDF();
            $pdf->AddPage();
            
            // Logo / Icon Box (Left)
            $pdf->SetFillColor(62, 85, 117);
            if (!empty($ressitedls['logo']) && file_exists(ADD_PHOTO_SERVER_PATH.$ressitedls['logo'])) {
                $pdf->Image(ADD_PHOTO_SERVER_PATH.$ressitedls['logo'], 15, 12, 60);
            } else {
                // Draw a simple box if no logo
                $pdf->Rect(15, 11, 20, 20, 'F');
                $pdf->SetTextColor(255, 255, 255);
                $pdf->SetFont('Arial', 'B', 14);
                $pdf->SetXY(15, 11);
                $pdf->Cell(20, 20, 'Logo', 0, 0, 'C');
            }
            
            // INVOICE Header (Right)
            $pdf->SetFillColor(62, 85, 117);
            $pdf->Rect(130, 15, 1.5, 12, 'F');
            $pdf->Rect(133, 15, 1.5, 12, 'F');
            $pdf->SetFont('Arial', 'B', 24);
            $pdf->SetTextColor(255, 255, 255);
            $pdf->SetXY(136, 15);
            $pdf->Cell(58, 12, 'INVOICE', 0, 1, 'C', true);
            
            // Invoice number and Date
            $pdf->SetTextColor(0, 0, 0);
            $pdf->SetFont('Arial', 'B', 10);
            $pdf->SetXY(15, 53);
            $pdf->Cell(50, 6, 'Invoice Number: IN' . $id, 0, 1);
            $pdf->SetFont('Arial', '', 10);
            $pdf->SetX(15);
            $pdf->Cell(50, 6, 'Date: ' . date('d/m/Y', $resrec['date_ts']), 0, 1);
            
            // Light blue horizontal line
            $pdf->SetDrawColor(180, 200, 220);
            $pdf->Line(15, 70, 195, 70);
            
            // Bill From & Bill To
            $pdf->SetXY(15, 77);
            $pdf->SetFont('Arial', 'B', 10);
            $pdf->Cell(100, 6, 'Bill from:', 0, 0);
            $pdf->Cell(80, 6, 'Bill to:', 0, 1);
            
            $pdf->SetFont('Arial', '', 9);
            $pdf->SetX(15);
            $pdf->Cell(100, 5, 'Agency Name : ' . $agency_name, 0, 0);
            $pdf->Cell(80, 5, 'Consumer Name : ' . $resusr['name'], 0, 1);
            
            $pdf->SetX(15);
            $pdf->Cell(100, 5, 'Agency ID : ' . $agency_id_text, 0, 0);
            $pdf->Cell(80, 5, 'Email ID : ' . $resusr['email'], 0, 1);
            
            // Light blue horizontal line
            $pdf->Line(15, 97, 195, 97);
            
            // Table Header
            $pdf->SetXY(15, 101);
            $pdf->SetFont('Arial', 'B', 10);
            $pdf->Cell(100, 8, 'Item', 0, 0, 'L');
            $pdf->Cell(40, 8, 'Quantity', 0, 0, 'C');
            $pdf->Cell(40, 8, 'Amount', 0, 1, 'R');
            
            // Horizontal line
            $pdf->Line(15, 110, 195, 110);
            
            // Table Content
            $pdf->SetXY(15, 117);
            $pdf->SetFont('Arial', '', 10);
            $pdf->Cell(100, 7, $resrandprd['name'].' ('.$resrec['book_id'].')', 0, 0, 'L');
            $pdf->Cell(40, 7, '01', 0, 0, 'C');
            $pdf->Cell(40, 7, 'Rs. ' . number_format($resrec['amount'], 2), 0, 1, 'R');
            
            // Subtotal Line
            $pdf->SetDrawColor(180, 180, 180);
            $pdf->Line(15, 150, 195, 150);
            
            // Amount in words
            $pdf->Ln(2);
            $pdf->SetXY(15, 160);
            $amount_in_words = ucfirst(numberToWords(intval($resrec['amount']))) . ".";
            $pdf->Cell(180, 7, '** ' . $amount_in_words, 0, 1, 'L');
            
            // Subtotal
            $pdf->SetXY(100, 160);
            $pdf->SetFont('Arial', '', 10);
            $pdf->Cell(40, 8, 'Subtotal:', 0, 0, 'R');
            $pdf->Cell(40, 8, 'Rs. ' . number_format($resrec['amount'], 2), 0, 1, 'R');
            
            // Thick black line under subtotal
            $pdf->SetDrawColor(0, 0, 0);
            $pdf->SetLineWidth(0.6);
            $pdf->Line(115, 172, 195, 172);
            $pdf->SetLineWidth(0.2); // reset line width
            
            // Total Paid Box
            $pdf->SetFillColor(62, 85, 117);
            $pdf->SetTextColor(255, 255, 255);
            $pdf->SetFont('Arial', 'B', 12);
            $pdf->SetXY(115, 185);
            $pdf->Cell(80, 12, 'Total Paid :   Rs. ' . number_format($resrec['amount'], 2), 0, 1, 'C', true);
            
            $pdf->SetTextColor(0, 0, 0);
            
            $date_ts = !empty($resrec['date_ts']) ? $resrec['date_ts'] : time();
            $pdf_filename = 'Invoice_' . $date_ts . '_' . $id . '.pdf';
            if (!file_exists(ADD_DOCUMENT_SERVER_PATH)) {
                @mkdir(ADD_DOCUMENT_SERVER_PATH, 0777, true);
            }
            $pdf->Output('F', ADD_DOCUMENT_SERVER_PATH . $pdf_filename);

            // Call Chat Assistant Transaction Status API
            $api_url = getenv('CHAT_API_URL') ?: (defined('SITE_PATH') ? rtrim(SITE_PATH, '/') . '/api/v1/transaction/status-update' : 'https://fairbizcrm.com/api/v1/transaction/status-update');
            $api_token = getenv('CHAT_API_TOKEN') ?: 'chat_fixed_auth_token_2026_prod';

            $sender_id = $resrec['emp_id'];
            $recipient_id = !empty($resrec['user_id']) ? (string)$resrec['user_id'] : (!empty($resusr['id']) ? (string)$resusr['id'] : '');
            $txn_id = !empty($resrec['transection_id']) ? (string)$resrec['transection_id'] : (string)$id;

            $payload = array(
                'sender_id' => $sender_id,
                'recipient_id' => $recipient_id,
                'transaction_id' => $txn_id,
                'status' => 'approved',
                'type' => 'recharge',
                'amount' => isset($resrec['amount']) ? (float)$resrec['amount'] : (float)$amount,
                'reason' => !empty($employee_remark) ? $employee_remark : null,
                'book_name' => (!empty($book_name) && $book_name !== "N/A") ? $book_name : null,
                'utr' => 'Recharge-ID-'.$id,
                'invoice_url' => $m_url.'uploads/documents/'.$pdf_filename 
            );

            $ch = curl_init($api_url);
            curl_setopt_array($ch, array(
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => array(
                    'Content-Type: application/json',
                    'Authorization: Bearer ' . $api_token
                ),
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_TIMEOUT => 10,
                CURLOPT_CONNECTTIMEOUT => 5
            ));
            $api_response = curl_exec($ch);
            // print_r ($api_response);
            // die;
            curl_close($ch);

            $qry1 = "UPDATE `recharge` set `invoice` = '".$pdf_filename."' WHERE `id` = '".$id."'" or die(mysqli_error());
            $query1 = mysqli_query($conn,$qry1);
        }   
        if($stage_status == 'EMPLOYEE-REJECT'){
            $qryrec = mysqli_query($conn, "SELECT * FROM recharge WHERE id = '$id'");
            $resrec = mysqli_fetch_array($qryrec);

            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = (SELECT user_id FROM recharge WHERE id = '$id')");
            $resusr = mysqli_fetch_array($qryusr);

            $book_name = "N/A";
            if(!empty($resrec['book_id'])){
                $qrybk = mysqli_query($conn, "SELECT name FROM features WHERE id = '".$resrec['book_id']."'");
                $resbk = mysqli_fetch_array($qrybk);
                if($resbk) $book_name = $resbk['name'];
            }

            $qry1 = "UPDATE `agency_cash_book` set `recharge_limit_live` = `recharge_limit_live` + '".$amount."' , `rs_inhand_expected` = `rs_inhand_expected` - '".$amount."' WHERE `agency_id` = '".$agency_id."'" or die(mysqli_error());
            $query1 = mysqli_query($conn,$qry1);

            // Call Chat Assistant Transaction Status API for rejection
            $api_url = 'https://chat-assistant-5698.onrender.com/api/v1/transaction/status-update';
            $api_token = 'chat_fixed_auth_token_2026_prod';

            $sender_id = $resrec['emp_id'];
            $recipient_id = !empty($resrec['user_id']) ? (string)$resrec['user_id'] : (!empty($resusr['id']) ? (string)$resusr['id'] : '');
            $txn_id = !empty($resrec['transection_id']) ? (string)$resrec['transection_id'] : (string)$id;

            $payload = array(
                'sender_id' => $sender_id,
                'recipient_id' => $recipient_id,
                'transaction_id' => $txn_id,
                'status' => 'rejected',
                'type' => 'recharge',
                'amount' => isset($resrec['amount']) ? (float)$resrec['amount'] : (float)$amount,
                'reason' => !empty($employee_remark) ? $employee_remark : null,
                'book_name' => (!empty($book_name) && $book_name !== "N/A") ? $book_name : null,
                'utr' => !empty($resrec['transection_id']) ? (string)$resrec['transection_id'] : null
            );

            $ch = curl_init($api_url);
            curl_setopt_array($ch, array(
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => array(
                    'Content-Type: application/json',
                    'Authorization: Bearer ' . $api_token
                ),
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_TIMEOUT => 10,
                CURLOPT_CONNECTTIMEOUT => 5
            ));
            $api_response = curl_exec($ch);
            curl_close($ch);
        }
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successfull !";
        $_SESSION['text'] = "Recharge Updated Successfully!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    }
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

    <div class="card cntnt-start border-rounded shadow mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1"><strong>Employee Recharge</strong> Pending List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Image</th>
                            <th class="text-center" scope="col">Details</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `recharge` WHERE stage_status = 'EMPLOYEE-PENDING' AND employee_read_status = 'READ' ORDER BY ABS(id) DESC") or die(mysqli_error());
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $subscription_id= $result['subscription_id'];
                            $qrysubscription = mysqli_query($conn, "SELECT * FROM `subscription` WHERE id = '$subscription_id' ") or die(mysqli_error());
                            $ressub = mysqli_fetch_array($qrysubscription);
                            $qrybook = mysqli_query($conn, "SELECT * FROM `features` WHERE id = '$result[book_id]' ") or die(mysqli_error());
                            $resbook = mysqli_fetch_array($qrybook);
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
                            <td>Amount : <?php echo $result['amount']; ?> <br> Transaction ID : <?php echo $result['transection_id']; ?></td>
                            <td>
                                <button type="button" id="quet_id" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;" ><i class="bi bi-eye"></i>
                                </button>
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Check Recharge Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <div class="container-fluid mt-4">
                                                        <div class="row">
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Agency :  <p class="fw-500"><i>AGENCY-<?php echo $result['emp_id']; ?></i></p>
                                                                <hr>
                                                                Book Name :  <p class="fw-500"><i><?php echo $resbook['name']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                User Name :  <p class="fw-500"><i><?php echo $ressub['username']; ?></i></p>
                                                                <hr>
                                                                Password :  <p class="fw-500"><i><?php echo $ressub['password']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2">
                                                                Amount :  <p class="fw-500"><i><?php echo $result['amount']; ?></i></p>
                                                                <hr>
                                                                Website Link :  <p class="fw-500"><i><?php echo $resbook['detail']; ?></i></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Transaction ID  : <p class="fw-500"><i> <?php echo $result['transection_id']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Agency Remark : <p class="fw-500"><i><?php echo $result['remark']; ?></i></p>
                                                            </div>
                                                            <div class="col-md-4 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Date : <?php echo date('d M Y, h:i A', $result['date_ts']); ?>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;"><i class="bi bi-check"></i></button>
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-md">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Verify Recharge (Employee)</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="emp-recharge-pending" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $result['emp_id']; ?>" name="agency_id"/>
                                                        <input type="hidden" value="<?php echo $result['amount']; ?>" name="amount"/>
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Choose Status </label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <select class="form-select" name="stage_status">
                                                                            <option value="">Select Status</option>
                                                                            <option value="EMPLOYEE-DONE">Successfull</option>
                                                                            <option value="EMPLOYEE-REJECT">Rejected</option>
                                                                        </select>    
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                  <label class="col-sm-4 col-form-label">Employee Remark </label>
                                                                  <div class="col-sm-8">
                                                                      <div class="input-group mb-3">
                                                                          <textarea class="form-control" name="employee_remark"><?php echo $result['employee_remark'];?></textarea>    
                                                                      </div>
                                                                  </div>
                                                                  <div class="col-sm-12 mb-2 d-flex flex-column gap-1">
                                                                      <button type="button" class="btn btn-sm btn-outline-success text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Payment verified and recharge approved successfully.';">
                                                                          <i class="bi bi-check-circle-fill me-1"></i> Payment verified and recharge approved successfully.
                                                                      </button>
                                                                      <button type="button" class="btn btn-sm btn-outline-warning text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Transaction ID / UTR number does not match.';">
                                                                          <i class="bi bi-exclamation-triangle-fill me-1"></i> Transaction ID / UTR number does not match.
                                                                      </button>
                                                                      <button type="button" class="btn btn-sm btn-outline-danger text-start py-1 px-2" style="font-size: 0.78rem;" onclick="this.closest('.row').querySelector('textarea').value = 'Payment not received in the bank account.';">
                                                                          <i class="bi bi-x-circle-fill me-1"></i> Payment not received in the bank account.
                                                                      </button>
                                                                  </div>
                                                              </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_emp_recharge_pending" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                                                    <i class="bi bi-check-lg me-2"></i> UPDATE
                                                                    </button>
                                                                    <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect">
                                                                    <i class="bi bi-x-lg me-2"></i> RESET
                                                                    </button>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
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
