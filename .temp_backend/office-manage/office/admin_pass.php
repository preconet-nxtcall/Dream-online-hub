<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}


if(ISSET($_POST['admin_upd_pass'])){
    $old_pass = $_POST["old_pass"];
    
    $new_pass = $_POST["new_pass"];
    $old_pass_give = $_POST["old_pass_give"];

    $id = $_POST["id"];
    
    date_default_timezone_set("Asia/Calcutta");
    $date = date("Y-m-d");
    $time = date("h:i:sa");

    if($old_pass == $old_pass_give){
    $qry= mysqli_query($conn, "UPDATE `users` set `password` = '".$new_pass."', `date` = '".$date."', `time` = '".$time."' WHERE `id` = '".$id."' ") or die(mysqli_error());    
    if($qry){
            $_SESSION['swl_type'] = "success";
			$_SESSION['head'] = "Successfull !";
			$_SESSION['text'] = "Old Password Changed!";
			if(ISSET($_SESSION['swl_type'])){
				header("Refresh:0;");
				exit;
			}
        }
    }else{  
        $_SESSION['swl_type'] = "error";
        $_SESSION['head'] = "Error !";
        $_SESSION['text'] = "Old Password Did not Match!";
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

    <div class="card cntnt-start border-rounded shadow-sm mx-4" >
        <div class="card-header text-center gradient-15" >
            <h5 class="card-title text-white my-1">Enter Details Here</h5>
        </div>
        <div class="card-body">
            <form method="post" action="admin_pass" onsubmit ="return verifyPassword()" enctype="multipart/form-data">
                <div class="card-body card-block">
                    <input type="hidden" name="id" value="<?php echo $admn_dls["id"] ?>">
                    <input type="hidden" name="old_pass" value="<?php echo $admn_dls["password"] ?>">
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Old Password</label>
                            <div class="input-group mb-3">
                                <span class="input-group-text" id="basic-addon1">✎</span>
                                <input type="text" class="form-control" name="old_pass_give" aria-describedby="basic-addon1" required>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>New Password</label>
                            <div class="input-group mb-3">
                                <span class="input-group-text" id="basic-addon1">✎</span>
                                <input type="password" id="pass" class="form-control" aria-label="Username" aria-describedby="basic-addon1" required>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <label class="text-dark"><i class="bi bi-check2-all"> </i>Retype Password</label>
                            <div class="input-group mb-3">
                                <span class="input-group-text" id="basic-addon1">✎</span>
                                <input type="password" class="form-control" name="new_pass" id="confirmpass" aria-label="Username" aria-describedby="basic-addon1" required>
                            </div>
                        </div>
                    </div> 
                    <hr class="ml-100">
                    <div class="d-flex gap-3 mb-3">
                        <button name="admin_upd_pass" type="submit" class="mx-auto btn btn-lg one-click btn_primary wave-effect w-50">
                        <i class="bi bi-check me-2"></i> SUBMIT
                        </button>
                        <button type="reset" name="reset" class="mx-auto btn one-click btn_secondary wave-effect w-50">
                        <i class="bi bi-x me-2"></i> RESET 
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
    <br><br><br><br><br><br><br><br>
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
<?php include 'partials/_footer.php' ?>
<script>
    function verifyPassword() {
        var password = document.getElementById("pass").value;
        var confirmPassword = document.getElementById("confirmpass").value;
        
        if (password == "") {
            swal({
				title: "Error !",
				text: "The password field is Empty.",
				icon: "error",
				button: "Ok Done!",
				showConfirmButton: false,
  				timer: 5000
			});
			return false;            
        }
        else if (password == confirmPassword) {
            return true;
        } else {
            swal({
				title: "Error !",
				text: "Please make sure your passwords match.",
				icon: "error",
				button: "Ok Done!",
				showConfirmButton: false,
  				timer: 5000
			});
            return false;
        }
    }
</script>