<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$user_dls = null;
$agency_dls = null;

if($user_id > 0){
    $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '$user_id'") or die(mysqli_error($conn));
    if(mysqli_num_rows($qryusr) > 0){
        $user_dls = mysqli_fetch_array($qryusr);
        if(!empty($user_dls['agency_id'])){
            $qragency = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '".$user_dls['agency_id']."'") or die(mysqli_error($conn));
            $agency_dls = mysqli_fetch_array($qragency);
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
                    <span>Home / User Profit & Loss</span>
                </p>
            </div>
            <div>
                <a href="users" class="btn btn_secondary btn-sm"><i class="bi bi-arrow-left me-1"></i> Back to Users</a>
            </div>
        </div>
    </div>

    <div class="card cntnt-start border-rounded shadow mx-4">
        <div class="card-header text-center gradient-15">
            <h5 class="card-title text-white my-1">
                <strong>Profit & Loss List</strong> 
                <?php if($user_dls){ echo 'for ' . htmlspecialchars($user_dls['name']); } ?>
            </h5>
        </div>
        <div class="card-body pb-0">
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
                        if($user_id > 0){
                            $qrydisplay = mysqli_query($conn, "SELECT pl.*, f.name as book_name FROM `profit_loss` pl LEFT JOIN `features` f ON pl.book_id = f.id WHERE pl.user_id = '$user_id' ORDER BY ABS(pl.id) DESC") or die(mysqli_error($conn));
                        } else {
                            $qrydisplay = mysqli_query($conn, "SELECT pl.*, f.name as book_name FROM `profit_loss` pl LEFT JOIN `features` f ON pl.book_id = f.id ORDER BY ABS(pl.id) DESC") or die(mysqli_error($conn));
                        }

                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                            $qryusr = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '".$result['user_id']."'");
                            $resultusr = mysqli_fetch_array($qryusr);
                            $qragency = mysqli_query($conn, "SELECT * FROM `users` WHERE id = '".$resultusr['agency_id']."'");
                            $resulagc = mysqli_fetch_array($qragency);
                    ?>  
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td>
                                User : <?php echo htmlspecialchars($resultusr['name'] ?? ''); ?><br>
                                Agency : <?php echo htmlspecialchars($resulagc['name'] ?? ''); ?>
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
                                <?php echo htmlspecialchars($result['start_date']); ?> <br><small>to</small><br> <?php echo htmlspecialchars($result['end_date']); ?>
                            </td>
                        </tr>
                    <?php } 
                        if($i == 0){
                            echo '<tr><td colspan="5" class="text-center text-muted py-4">No profit & loss records found.</td></tr>';
                        }
                    ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
</div>

<?php include 'partials/_footer.php' ?>
