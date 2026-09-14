<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: emp-user-bank-ac-pending');
    exit;
}

// Action: Approve
if(ISSET($_POST['approve_bank_ac'])){
    $bank_ac_id = intval($_POST['bank_ac_id']);
    $qry_app = mysqli_query($conn, "UPDATE `user_payment_accounts` SET `stage_status` = 'EMPLOYEE-APPROVE', `read_status` = 'READ' WHERE `id` = '$bank_ac_id'");
    if($qry_app){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successful!";
        $_SESSION['text'] = "User Bank Account Approved Successfully!";
        header("Location: emp-user-bank-ac-unreed");
        exit;
    }
}

// Action: Delete
if(ISSET($_POST['delete_bank_ac'])){
    $bank_ac_id = intval($_POST['bank_ac_id']);
    $res = mysqli_query($conn, "SELECT image FROM `user_payment_accounts` WHERE `id` = '$bank_ac_id'");
    if($res && $row = mysqli_fetch_assoc($res)){
        if(!empty($row['image']) && file_exists(ADD_PHOTO_SERVER_PATH.$row['image'])){
            @unlink(ADD_PHOTO_SERVER_PATH.$row['image']);
        }
    }
    $qry_del = mysqli_query($conn, "DELETE FROM `user_payment_accounts` WHERE `id` = '$bank_ac_id'");
    if($qry_del){
        $_SESSION['swl_type'] = "success";
        $_SESSION['head'] = "Successful!";
        $_SESSION['text'] = "User Bank Account Record Deleted Successfully!";
        header("Location: emp-user-bank-ac-unreed");
        exit;
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

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1"><strong>Unseen User Bank Accounts</strong> List</h5>
        </div>
        <div class="card-body pb-0">
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">User</th>
                            <th class="text-center" scope="col">Passbook / QR</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        $qrydisplay = mysqli_query($conn, "SELECT * FROM `user_payment_accounts` WHERE `read_status` = 'PENDING' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $user_id = $result['user_id'];
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE `id` = '$user_id'") or die(mysqli_error($conn));
                            $resusr = mysqli_fetch_array($qryusr);
                    ?>
                        <tr id="row_<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                <b><?php echo isset($resusr['name']) ? htmlspecialchars($resusr['name']) : 'N/A'; ?></b><br>
                            </td>
                            <td>
                                <?php if(!empty($result['image'])){ ?>
                                    <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>">
                                        <img class="mx-auto tab-img img-thumbnail shadow" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>" style="max-height:60px;" />
                                    </a>
                                <?php } else { ?>
                                    <span class="text-muted">No Image</span>
                                <?php } ?>
                            </td>
                            <td>
                                <button type="button" onclick="upd_status('<?php echo $result['id']; ?>')" id="quet_id_<?php echo $result['id']; ?>" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#viewModal<?php echo $result['id'];?>" style="vertical-align:middle;" ><i class="bi 
                                    <?php
                                        $status = $result['read_status'];
                                        $read = "READ";
                                        if($status == $read){
                                            echo ' bi-eye';
                                        }
                                        else{
                                            echo ' bi-eye-slash';
                                        }
                                        
                                        ?>								
                                    "></i>
                                </button>
                                <script>
                                    function upd_status(qte_id){
                                        jQuery.ajax({
                                            url: 'ajax_del.php',
                                            type:'post',
                                            data: {
                                                "emp_user_bank_ac_upd_status": 1,
                                                "qte_id": qte_id,
                                            },
                                            success:function(result){
                                                jQuery('#quet_id_' + qte_id).html('<i class="bi bi-eye"></i>');
                                            }
                                        });
                                    }
                                </script>                                

                                <!-- View Modal -->
                                <div class="modal fade mt-4 pt-4" id="viewModal<?php echo $result['id']; ?>" tabindex="-1" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!important;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white"><b>User Bank Account Details</b></h5>
                                                    </div>
                                                    <div class="col-4 text-end">
                                                        <form action="emp-user-bank-ac-unreed" method="POST">
                                                            <button type="submit" name="modal_close" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                        </form>        
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="modal-body text-dark text-start">
                                                <div class="row g-3">
                                                    <div class="col-md-6 border p-3 rounded">
                                                        <h6 class="fw-bold text-primary">User Information</h6>
                                                        <p class="mb-1"><b>Name:</b> <?php echo isset($resusr['name']) ? htmlspecialchars($resusr['name']) : 'N/A'; ?></p>
                                                        <p class="mb-1"><b>Phone:</b> <?php echo isset($resusr['mob']) ? htmlspecialchars($resusr['mob']) : 'N/A'; ?></p>
                                                        <p class="mb-1"><b>Email:</b> <?php echo isset($resusr['email']) ? htmlspecialchars($resusr['email']) : 'N/A'; ?></p>
                                                    </div>
                                                    <div class="col-md-6 border p-3 rounded">
                                                        <h6 class="fw-bold text-primary">Bank Account Details</h6>
                                                        <p class="mb-1"><b>Account Holder:</b> <?php echo htmlspecialchars($result['account_name']); ?></p>
                                                        <p class="mb-1"><b>Account No:</b> <?php echo htmlspecialchars($result['account_no']); ?></p>
                                                        <p class="mb-1"><b>Bank Name:</b> <?php echo htmlspecialchars($result['bank_name']); ?></p>
                                                        <p class="mb-1"><b>IFSC Code:</b> <?php echo htmlspecialchars($result['ifsc_code']); ?></p>
                                                        <p class="mb-1"><b>UPI ID:</b> <?php echo htmlspecialchars($result['upi_id']); ?></p>
                                                    </div>
                                                    <div class="col-12 text-center mt-3">
                                                        <?php if(!empty($result['image'])){ ?>
                                                            <a target="_blank" href="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>">
                                                                <img class="img-fluid rounded border shadow" src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$result['image']; ?>" style="max-height: 250px;" />
                                                            </a>
                                                        <?php } ?>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="modal-footer">
                                                <form action="emp-user-bank-ac-unreed" method="POST" style="display:inline;">
                                                    <input type="hidden" name="bank_ac_id" value="<?php echo $result['id']; ?>">
                                                    <button type="button" onclick="confirmApproveBankAc(this)" class="btn btn-success"><i class="bi bi-check-circle"></i> Approve</button>
                                                    <button type="submit" name="approve_bank_ac" style="display:none;"></button>
                                                </form>
                                                <form action="emp-user-bank-ac-unreed" method="POST" style="display:inline;">
                                                    <input type="hidden" name="bank_ac_id" value="<?php echo $result['id']; ?>">
                                                    <button type="button" onclick="confirmDeleteBankAc(this)" class="btn btn-danger"><i class="bi bi-trash"></i> Delete</button>
                                                    <button type="submit" name="delete_bank_ac" style="display:none;"></button>
                                                </form>
                                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
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

<script>
function confirmApproveBankAc(btn) {
    swal({
        title: "Are you sure?",
        text: "If you press OK, the bank account status will be approved!",
        icon: "warning",
        buttons: true,
        dangerMode: false,
    }).then((willApprove) => {
        if (willApprove) {
            var form = btn.closest('form');
            var submitBtn = form.querySelector('button[name="approve_bank_ac"]');
            if (submitBtn) {
                submitBtn.click();
            } else {
                form.submit();
            }
        }
    });
}

function confirmDeleteBankAc(btn) {
    swal({
        title: "Are you sure?",
        text: "If you press OK, this bank account detail will be permanently deleted!",
        icon: "warning",
        buttons: true,
        dangerMode: true,
    }).then((willDelete) => {
        if (willDelete) {
            var form = btn.closest('form');
            var submitBtn = form.querySelector('button[name="delete_bank_ac"]');
            if (submitBtn) {
                submitBtn.click();
            } else {
                form.submit();
            }
        }
    });
}
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