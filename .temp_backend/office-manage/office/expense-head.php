<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: expense-head');
}

// Ensure use_for column exists in expense_heads table
$check_col = mysqli_query($conn, "SHOW COLUMNS FROM `expense_heads` LIKE 'use_for'");
if(mysqli_num_rows($check_col) == 0){
    mysqli_query($conn, "ALTER TABLE `expense_heads` ADD `use_for` VARCHAR(20) NOT NULL DEFAULT '1'");
}

$msg = '';
if(ISSET($_POST['add_head'])){
    $name = addslashes($_POST["name"]);
    $use_for = addslashes($_POST["use_for"]);
    $slag = strtolower(preg_replace("/[^0-9a-zA-Z]+/", "-", $name));
    $slag = rtrim($slag, "-");
    
    $res1 = mysqli_query($conn, "SELECT * FROM `expense_heads` WHERE `slag` = '$slag'");
    $check = mysqli_num_rows($res1);
    if($check > 0){
        $msg = "1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Expense Head already exists!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    } else {
        $msg = '';
    }

    if($msg == ''){
        $qry = "INSERT INTO `expense_heads` (`name`, `slag`, `use_for`) VALUES ('".$name."', '".$slag."', '".$use_for."')";
        $query = mysqli_query($conn, $qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successful !";
            $_SESSION['text'] = "Expense Head Added Successfully!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
        }
    }
}

if(ISSET($_POST['edit_head'])){
    $id = $_POST["id"];
    $name = addslashes($_POST["name"]);
    $use_for = addslashes($_POST["use_for"]);
    $slag = strtolower(preg_replace("/[^0-9a-zA-Z]+/", "-", $name));
    $slag = rtrim($slag, "-");

    $res1 = mysqli_query($conn, "SELECT * FROM `expense_heads` WHERE `id` <> '$id' AND `slag` = '$slag'");
    $check = mysqli_num_rows($res1);
    if($check > 0){
        $msg = "1";
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Expense Head already exists!";
        if(ISSET($_SESSION['swl_type'])){
            header("Refresh:0;");
            exit;
        }
    } else {
        $msg = '';
    }

    if($msg == ''){
        $qry = "UPDATE `expense_heads` SET `name` = '".$name."', `slag` = '".$slag."', `use_for` = '".$use_for."' WHERE `id` = '".$id."'";
        $query = mysqli_query($conn, $qry);
        if($query){
            $_SESSION['swl_type'] = "success";
            $_SESSION['head'] = "Successful !";
            $_SESSION['text'] = "Expense Head Updated Successfully!";
            if(ISSET($_SESSION['swl_type'])){
                header("Refresh:0;");
                exit;
            }
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
            <button type="button" data-bs-toggle="modal" data-bs-target="#insert_head" class="btn btn_warning btn-sm">Add Expense Head <i class="bi bi-plus-lg ms-1"></i></button>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Expense Head</strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Modal Dialog for insert -->
            <div class="modal fade mt-4 pt-4" id="insert_head" tabindex="3">
                <div class="modal-dialog modal-dialog-scrollable modal-lg">
                    <div class="modal-content" style="overflow: visible!important;">
                        <div class="modal-header shadow bg-funky-moon2 mx-auto">
                            <div class="row mb-1">
                                <div class="col-8 text-left">
                                    <h5 class="modal-title"><b>Add Expense Head</b></h5>
                                </div>
                                <div class="col-4 text-right">
                                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                            </div>  
                        </div>
                        <div class="modal-body">
                            <form class="row" action="expense-head" method="post" enctype="multipart/form-data" id="form">
                                <div class="card-body card-block">
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Expense Head Name</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text" id="basic-addon1">✎</span>
                                                <input type="text" class="form-control" name="name" placeholder="Enter Expense Head Name" required>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <label class="col-sm-4 col-form-label">Use For</label>
                                        <div class="col-sm-8">
                                            <div class="input-group mb-3">
                                                <span class="input-group-text" id="basic-addon2"><i class="bi bi-person-badge"></i></span>
                                                <select class="form-select" name="use_for" required>
                                                    <option value="">Select Use For</option>
                                                    <option value="ADMIN">ADMIN</option>
                                                    <option value="AGENCY">AGENCY</option>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                    <hr class="ml-100">
                                    <div class="row">
                                        <div class="d-flex gap-3 mt-3">
                                            <button name="add_head" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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

            <!-- Table with Expense Heads -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Expense Head Name</th>
                            <th class="text-center" scope="col">Use For</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `expense_heads` ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                    ?>
                        <tr id="<?php echo $result['id'] ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td><?php echo $result['name']; ?></td>
                            <td>
                                <?php 
                                    if($result['use_for'] == 'ADMIN'){
                                        echo '<span class="badge bg-primary px-3 py-2">ADMIN</span>';
                                    } elseif($result['use_for'] == 'AGENCY'){
                                        echo '<span class="badge bg-warning text-dark px-3 py-2">AGENCY</span>';
                                    } else {
                                        echo '<span class="badge bg-secondary px-3 py-2">N/A</span>';
                                    }
                                ?>
                            </td>
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
                                                        <h5 class="modal-title text-white ml-1"><b>Update Expense Head</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <form class="row px-2" action="expense-head" method="post" enctype="multipart/form-data">
                                                        <input type="hidden" value="<?php echo $result['id']; ?>" name="id"/>
                                                        <div class="card-body card-block">
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Expense Head Name</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon1">✎</span>
                                                                        <input type="text" class="form-control" name="name" value="<?php echo $result['name']; ?>" required>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="row mb-3">
                                                                <label class="col-sm-4 col-form-label">Use For</label>
                                                                <div class="col-sm-8">
                                                                    <div class="input-group mb-3">
                                                                        <span class="input-group-text" id="basic-addon2"><i class="bi bi-person-badge"></i></span>
                                                                        <select class="form-select" name="use_for" required>
                                                                            <option value="">Select Use For</option>
                                                                            <option value="ADMIN" <?php if($result['use_for'] == 'ADMIN'){ echo 'selected'; } ?>>ADMIN</option>
                                                                            <option value="AGENCY" <?php if($result['use_for'] == 'AGENCY'){ echo 'selected'; } ?>>AGENCY</option>
                                                                        </select>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <hr class="md-100">
                                                            <div class="row">
                                                                <div class="d-flex gap-3 mt-3">
                                                                    <button name="edit_head" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect">
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
