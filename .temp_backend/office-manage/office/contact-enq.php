<?php
require 'partials/_dbconnect.php';
if(!isset($_SESSION['loggedin']) || $_SESSION['u_id']!=true){
    header("location: index");
    exit;
}
if(ISSET($_POST['modal_close'])){
    $showModal = "";
    header('Location: contact-enq');
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
            <h5 class="card-title text-white my-1"><strong>Contact </strong> Enquiry List</h5>
        </div>
        <div class="card-body pb-0">
            <!-- Table with stripped rows -->
            <div class="table-responsive px-2">
                <table class="display table table-hover text-center" id="example" style="min-width: auto;">
                    <thead>
                        <tr>
                            <th class="text-center" scope="col">#</th>
                            <th class="text-center" scope="col">Name</th>
                            <th class="text-center" scope="col">Date</th>
                            <th class="text-center" scope="col">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                        $i = 0;
                        if($_SESSION['u_type'] == "ADMIN"){
                            $qrydisplay = mysqli_query($conn, "SELECT * FROM `contact` ORDER BY ABS(id) DESC") or die(mysqli_error());
                        }elseif($_SESSION['u_type'] == "EMPLOYEE"){
                            $qrydisplay = mysqli_query($conn, "SELECT * FROM `contact` WHERE emp_id = '1' ORDER BY ABS(id) DESC") or die(mysqli_error());
                        }else{
                            $qrydisplay = mysqli_query($conn, "SELECT * FROM `contact` WHERE emp_id = '$emp_id' ORDER BY ABS(id) DESC") or die(mysqli_error());
                        }
                        while($result = mysqli_fetch_array($qrydisplay)){ $i++;
                    ?>
                        <tr id="<?php echo $result['id']; ?>">
                            <td scope="row"><?php echo $i; ?></td>
                            <td><?php echo $result['name']; ?></td>
                            <td><?php echo date('d/m/Y',strtotime($result['date'])); ?></td>
                            <td> 
                                <button type="button" onclick="upd_status('<?php echo $result['id']; ?>')" id="quet_id" class="btn btn_primary py-1 px-2" data-bs-toggle="modal" data-bs-target="#view<?php echo $result['id'];?>" style="vertical-align:middle;" ><i class="bi 
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
                                                "admin_message_upd_status": 1,
                                                "qte_id": qte_id,
                                            },
                                            success:function(result){
                                                jQuery('#quet_id').html(result);
                                            }
                                        });
                                    }
                                </script>
                                <div class="modal fade mt-4 pt-4" id="view<?php echo $result['id']?>" tabindex="4" data-bs-keyboard="false" data-bs-backdrop="static">
                                    <div class="modal-dialog modal-dialog-scrollable modal-lg">
                                        <div class="modal-content" style="overflow: visible!importent;">
                                            <div class="modal-header shadow bg-funky-moon2 mx-auto">
                                                <div class="row mb-1">
                                                    <div class="col-8 text-left">
                                                        <h5 class="modal-title text-white ml-1"><b>Check Contact Requests</b></h5>
                                                    </div>
                                                    <div class="col-4 text-right">
                                                        <form action="contact-enq" method="POST">
                                                            <button type="submit" name="modal_close" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                                        </form>    
                                                    </div>
                                                </div>  
                                            </div>
                                            <div class="modal-body">
                                                <div class="container-fluid text-dark">
                                                    <div class="container-fluid mt-4">
                                                        <div class="row">
                                                            <div class="col-md-5 mx-auto text-center border border-primary shadow py-2">
                                                                Name :  <p class="fw-500"><i><?php echo $result['name']; ?></i></p>
                                                                <hr>
                                                                Posted On :  <p class="fw-500"><b><?php echo date('d/m/Y',strtotime($result['date'])); ?></b></p>
                                                            </div>
                                                            <div class="col-md-5 mx-auto text-center border border-primary shadow py-2">
                                                                Phone :  <p class="fw-500"><i><?php echo $result['phone']; ?></i></p>
                                                                <hr>
                                                                Email :  <p class="fw-500"><b><?php echo $result['email']; ?></b></p>
                                                            </div>
                                                        </div>
                                                        <hr>
                                                        <div class="row">
                                                            <div class="col-md-12 mx-auto text-center border border-primary shadow py-2 text-wrap">
                                                                Message :  <?php echo $result['msg']; ?>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <input type="hidden" class="id_value" value="<?php echo $result['id']; ?>" >
                                <a class="text-white pr-2 delete_btn_message_ajax" href="javascript:void(0)"><button class="btn py-1 px-2 btn_danger" type="button" style="vertical-align:middle" data-bs-toggle="tooltip" data-bs-title="Delete"><span><i class="bi bi-trash"></i> </span></button></a>
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