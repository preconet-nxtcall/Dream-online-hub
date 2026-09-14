<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: expense-manage');
}

$msg = '';
if(ISSET($_POST['add_expense'])){
    $head_id = addslashes($_POST["head_id"]);
    $emp_id = $_SESSION['u_id'];
    $amount = addslashes($_POST["amount"]);
    $bank_id = addslashes($_POST["bank_id"]);
    $qrybndls = mysqli_query($conn, "SELECT * FROM `features` WHERE `id` = '$bank_id'") or die(mysqli_error());
    $rbndls = mysqli_fetch_array($qrybndls);
    $bank_name = $rbndls['name'];
    $bank_slag = $rbndls['slag'];
    
    $transection_id = addslashes($_POST["transection_id"]);
    $remark = addslashes($_POST["remark"]);
    $date_ts_val = time();

    $img_new1 = '';
    if(!empty($_FILES['image']['name'])){
        $img1 = $_FILES['image']['name'];
        $ext = pathinfo($img1, PATHINFO_EXTENSION);
        $img_new1 = rand()."_Expense.".$ext;
        move_uploaded_file($_FILES['image']['tmp_name'], ADD_PHOTO_SERVER_PATH.$img_new1);
    }

    $qry = "INSERT INTO `expense` (`head_id`, `emp_id`, `amount`, `bank_id`, `bank_name`, `bank_slag`, `transection_id`, `image`, `remark`, `date_ts`) VALUES ('".$head_id."', '".$emp_id."', '".$amount."', '".$bank_id."', '".$bank_name."', '".$bank_slag."', '".$transection_id."', '".$img_new1."', '".$remark."', '".$date_ts_val."')";
    $query = mysqli_query($conn, $qry);
    if($query){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successful !";
        $_SESSION['text'] = "Expense Added Successfully!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    }
}

if(ISSET($_POST['edit_expense'])){
    $id = $_POST["id"];
    $head_id = addslashes($_POST["head_id"]);
    $amount = addslashes($_POST["amount"]);
    $bank_id = addslashes($_POST["bank_id"]);
    $qrybndls = mysqli_query($conn, "SELECT * FROM `features` WHERE `id` = '$bank_id'") or die(mysqli_error());
    $rbndls = mysqli_fetch_array($qrybndls);
    $bank_name = $rbndls['name'];
    $bank_slag = $rbndls['slag'];
    $transection_id = addslashes($_POST["transection_id"]);
    $remark = addslashes($_POST["remark"]);
    $old_img = $_POST["old_img"];

    $img_sql = "";
    if(!empty($_FILES['image']['name'])){
        $img1 = $_FILES['image']['name'];
        $ext = pathinfo($img1, PATHINFO_EXTENSION);
        $img_new1 = rand()."_Expense.".$ext;
        move_uploaded_file($_FILES['image']['tmp_name'], ADD_PHOTO_SERVER_PATH.$img_new1);
        if(!empty($old_img) && file_exists(ADD_PHOTO_SERVER_PATH.$old_img)){
            @unlink(ADD_PHOTO_SERVER_PATH.$old_img);
        }
        $img_sql = ", `image` = '".$img_new1."'";
    }

    $qry = "UPDATE `expense` SET `head_id` = '".$head_id."', `amount` = '".$amount."', `bank_id` = '".$bank_id."', `bank_name` = '".$bank_name."', `bank_slag` = '".$bank_slag."', `transection_id` = '".$transection_id."', `remark` = '".$remark."' ".$img_sql." WHERE `id` = '".$id."'";
    $query = mysqli_query($conn, $qry);
    if($query){
        
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successful !";
        $_SESSION['text'] = "Expense Updated Successfully!";
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
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_expense" class="btn btn_warning btn-sm">Add Expense <i class="bi bi-plus-lg ms-1"></i></button>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Expense</strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for Insert Expense -->
            <div class="modal fade mt-4 pt-4" id="insert_expense" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!important;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Add New Expense</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                            <form class="row" action="expense-manage" method="post" enctype="multipart/form-data" id="form">
                                <div class="card-body card-block">
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Expense Head</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text"><i class="bi bi-tags"></i></span>
                                                <select class="form-select" name="head_id" required>
                                                    <option value="">Select Expense Head</option>
                                                    <?php
                                                        if($_SESSION['u_type'] == 'ADMIN') {
                                                            $qryhead = mysqli_query($conn, "SELECT * FROM `expense_heads` WHERE use_for = 'ADMIN' ORDER BY name ASC");
                                                        }else {
                                                            $qryhead = mysqli_query($conn, "SELECT * FROM `expense_heads` WHERE use_for = 'AGENCY' ORDER BY name ASC");
                                                        }
                                                        while($reshead = mysqli_fetch_array($qryhead)){
                                                            if($reshead['use_for'] == 'ADMIN'){
                                                                echo "<option value='".$reshead['id']."'>".$reshead['name']." (ADMIN)</option>";
                                                            } elseif($reshead['use_for'] == 'AGENCY'){
                                                                echo "<option value='".$reshead['id']."'>".$reshead['name']." (AGENCY)</option>";
                                                            }
                                                        }
                                                    ?>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Amount (Rs.)</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text">₹</span>
                                                <input type="number" step="0.01" class="form-control" name="amount" placeholder="Enter Amount" required>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Bank</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text"><i class="bi bi-bank"></i></span>
                                                <select class="form-select" name="bank_id" required>
                                                    <option value="">Select Bank</option>
                                                    <?php
                                                        $qrybank = mysqli_query($conn, "SELECT * FROM `features` WHERE type = 'BANK' AND order_no = '$emp_id' AND show_status = 'ACTIVE' ORDER BY name ASC");
                                                        while($resbank = mysqli_fetch_array($qrybank)){
                                                            echo "<option value='".$resbank['id']."'>".$resbank['name']."</option>";
                                                        }
                                                    ?>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Transaction ID / Ref No</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text">✎</span>
                                                <input type="text" class="form-control" name="transection_id" placeholder="Enter Transaction ID" required>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Receipt Image</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text"><i class="bi bi-image"></i></span>
                                                <input type="file" class="form-control" name="image" accept="image/*">
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Remark / Details</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text">✎</span>
                                                <textarea class="form-control" name="remark" placeholder="Enter Remark / Notes"></textarea>
                                            </div>
                                        </div>
                                    </div>
                                    <hr class="ml-100">
                                    <div class="row">
                                        <div class="d-flex gap-3 mt-3">
                                            <button name="add_expense" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
                                                <i class="bi bi-check-lg me-2"></i> SUBMIT
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

            <!-- Table displaying expenses -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Receipt</th>
                            <th class="text-center" scope="col">Expense Amount</th>
                            <th class="text-center" scope="col">Bank & Transaction ID</th>
                            <th class="text-center" scope="col">Remark</th>
                            <th class="text-center" scope="col">Date</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `expense` WHERE emp_id = '".$_SESSION['u_id']."' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $head_name = "N/A";
                            $use_for = "";
                            if(!empty($result['head_id'])){
                                $qryh = mysqli_query($conn, "SELECT name, use_for FROM `expense_heads` WHERE id = '".$result['head_id']."'");
                                if($resh = mysqli_fetch_array($qryh)){
                                    $head_name = $resh['name'];
                                    $use_for = $resh['use_for'];
                                }
                            }

                            $bank_name = "N/A";
                            if(!empty($result['bank_id'])){
                                $qryb = mysqli_query($conn, "SELECT name FROM `features` WHERE id = '".$result['bank_id']."'");
                                if($resb = mysqli_fetch_array($qryb)){
                                    $bank_name = $resb['name'];
                                }
                            }
                    ?>
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                <?php
                                    if(!empty($result['image']) && file_exists(ADD_PHOTO_SERVER_PATH.$result['image'])){
                                        echo "<a target='_blank' href='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."'><img class='mx-auto tab-img img-thumbnail shadow' src='".$m_url.ADD_PHOTO_SITE_PATH.$result['image']."' style='max-height: 50px;' /></a>";
                                    } else {
                                        echo "<span class='text-muted'>No Receipt</span>";
                                    }
                                ?>
                            </td>
                            <td>
                                <strong><?php echo $head_name; ?></strong>
                                <?php 
                                    // if($use_for == '1'){
                                    //     echo ' <span class="badge bg-primary ms-1">ADMIN</span>';
                                    // } elseif($use_for == '2'){
                                    //     echo ' <span class="badge bg-warning text-dark ms-1">AGENCY</span>';
                                    // }
                                ?>
                                <br>
                                <strong>₹<?php echo number_format((float)$result['amount'], 2); ?></strong>
                            </td>
                            <td>
                                Bank: <?php echo $bank_name; ?><br>
                                <small class="text-muted">Txn ID: <?php echo $result['transection_id']; ?></small>
                            </td>
                            <td><?php echo !empty($result['remark']) ? $result['remark'] : '-'; ?></td>
                            <td><?php echo !empty($result['date_ts']) ? date('d/m/Y h:i A', $result['date_ts']) : '-'; ?></td>
                            <td>
                                <button class="btn py-1 px-2 btn_success btn-icon" type="button" data-bs-toggle="modal" data-bs-target="#edit<?php echo $result['id']; ?>" style="vertical-align:middle;" data-bs-toggle="tooltip" data-bs-title="Edit">
                                    <i class="bi bi-pencil-square"></i>
                                </button>
                                
                                <!-- Modal Dialog for edit -->
                                <div class="modal fade mt-4 pt-4" id="edit<?php echo $result['id']; ?>" tabindex="4" data-keyboard="false" data-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Update Expense</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="expense-manage" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <input type="hidden" value="<?php echo $result['image']; ?>" name="old_img"/>
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Expense Head</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text"><i class="bi bi-tags"></i></span>
                                                                        <select class="form-select" name="head_id" required>
                                                                            <option value="">Select Expense Head</option>
                                                                            <?php
                                                                                if($_SESSION['u_type'] == 'ADMIN') {
                                                                                    $qryhead_edit = mysqli_query($conn, "SELECT * FROM `expense_heads` WHERE use_for = 'ADMIN' ORDER BY name ASC");
                                                                                }else {
                                                                                    $qryhead_edit = mysqli_query($conn, "SELECT * FROM `expense_heads` WHERE use_for = 'AGENCY' ORDER BY name ASC");
                                                                                }
                                                                                while($reshead_edit = mysqli_fetch_array($qryhead_edit)){
                                                                                    if($reshead_edit['use_for'] == 'ADMIN'){
                                                                                        $use_label_edit = ' (ADMIN)';
                                                                                    }elseif($reshead_edit['use_for'] == 'AGENCY'){
                                                                                        $use_label_edit = ' (AGENCY)';
                                                                                    }
                                                                                    $sel = ($reshead_edit['id'] == $result['head_id']) ? 'selected' : '';
                                                                                    echo "<option value='".$reshead_edit['id']."' ".$sel.">".$reshead_edit['name'].$use_label_edit."</option>";
                                                                                }
                                                                            ?>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Amount (Rs.)</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text">₹</span>
                                                                        <input type="number" step="0.01" class="form-control" name="amount" value="<?php echo $result['amount']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Bank</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text"><i class="bi bi-bank"></i></span>
                                                                        <select class="form-select" name="bank_id" required>
                                                                            <option value="">Select Bank</option>
                                                                            <?php
                                                                                $qrybank_edit = mysqli_query($conn, "SELECT * FROM `features` WHERE type = 'BANK' AND order_no = '$emp_id' AND show_status = 'ACTIVE' ORDER BY name ASC");
                                                                                while($resbank_edit = mysqli_fetch_array($qrybank_edit)){
                                                                                    $selb = ($resbank_edit['id'] == $result['bank_id']) ? 'selected' : '';
                                                                                    echo "<option value='".$resbank_edit['id']."' ".$selb.">".$resbank_edit['name']."</option>";
                                                                                }
                                                                            ?>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Transaction ID / Ref No</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text">✎</span>
                                                                        <input type="text" class="form-control" name="transection_id" value="<?php echo $result['transection_id']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Receipt Image</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text"><i class="bi bi-image"></i></span>
                                                                        <input type="file" class="form-control" name="image" accept="image/*">
                                                                    </div>
                                                                    <?php if(!empty($result['image'])){ ?>
                                                                        <small class="text-muted">Current image: <?php echo $result['image']; ?></small>
                                                                    <?php } ?>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Remark / Details</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text">✎</span>
                                                                        <textarea class="form-control" name="remark"><?php echo $result['remark']; ?></textarea>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_expense" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
                    <?php } ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<?php
if(!empty($_SESSION['swl_type']) && $_SESSION['swl_type'] != ''){
?>
    <script>
        window.addEventListener('load', function(){
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
