		
		<!-- FOOTER -->
    <div class="footer text-center">
        <p>
            © Copyright <script> document.write(new Date().getFullYear()) </script> | Design & Developed by &nbsp;<a class="" href="<?php echo $m_url;?>" target="_blank"> <?php echo $site_dls['heading'];?>.</a>&nbsp; | All Rights Reserved.
        </p>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/summernote/0.9.1/summernote-bs5.min.js"></script>
    <script src="https://cdn.datatables.net/2.3.6/js/dataTables.min.js"></script>
    <!-- Choices.js for searchable select -->
    <script src="assets/js/main.js"></script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_cmstable_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_cmstable": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.delete_btn_cmstable_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			var app_id2 = $(this).closest("tr").find('.image_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then It Is Permanently Deleted !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"del_cmstable": 1,
					"delete_id": app_id1,
					"delete_image": app_id2,
					},
					success: function (response) {
					swal("All Details are Deleted!",{
						icon: "success",
					}).then((result) =>{
						location.reload();
					});
					}
				})
				} 
			});
		});
		});
  	</script>
	
    <script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_feature_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_feature": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.update_btn_money_receivable_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Money Receivable Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"update_money_receivable": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.delete_btn_feature_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			var app_id2 = $(this).closest("tr").find('.image_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then It Is Permanently Deleted !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"del_feature": 1,
					"delete_id": app_id1,
					"delete_image": app_id2,
					},
					success: function (response) {
					swal("All Details are Deleted!",{
						icon: "success",
					}).then((result) =>{
						location.reload();
					});
					}
				})
				} 
			});
		});
		});
  	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_users_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_users": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_user_profit_loss_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_user_profit_loss": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_agency_featured_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Featured Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_agency_featured": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						if (response.trim() === "ONLY_ONE_AGENCY") {
							swal("Only 1 agency is available. It is set as Featured by default and cannot be changed!", {
								icon: "warning",
							});
						} else if (response.trim() === "MISSING_QR_CODES") {
							swal("This agency is not eligible for Featured! It must have at least 1 QR code for every price range.", {
								icon: "warning",
							});
						} else {
							swal("Featured Status Updated Successfully!",{
								icon: "success",
							})
							.then((result) =>{
								location.reload();
							});
						}
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.delete_btn_users_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			var app_id2 = $(this).closest("tr").find('.image_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then It Is Permanently Deleted !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"del_users": 1,
					"delete_id": app_id1,
					"delete_image": app_id2,
					},
					success: function (response) {
					swal("All Details are Deleted!",{
						icon: "success",
					}).then((result) =>{
						location.reload();
					});
					}
				})
				} 
			});
		});
		});
  	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.delete_btn_message_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then It Is Permanently Deleted !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"del_contact": 1,
					"delete_id": app_id1,
					},
					success: function (response) {
					swal("Contact Message is Deleted!",{
						icon: "success",
					}).then((result) =>{
						location.reload();
					});
					}
				})
				} 
			});
		});
		});
  	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_range_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_range": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.delete_btn_range_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Price Range & Related QR Codes are Permanently Deleted !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"del_range": 1,
					"delete_id": app_id1,
					},
					success: function (response) {
					swal("Price Range & Related QR Codes are Deleted!",{
						icon: "success",
					}).then((result) =>{
						location.reload();
					});
					}
				})
				} 
			});
		});
		});
  	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.status_btn_qrcode_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("td").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Status Will Change !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"status_qrcode": 1,
					"status_id": app_id1,
					},
					success: function (response) {
						swal("Status Updated Successfully!",{
							icon: "success",
						})
						.then((result) =>{
							location.reload();
						});
					}
				})
				} 
			});
		});
		});
	</script>

	<script>
		$(document).ready(function () {
		$('#example').on('click','.delete_btn_range_ajax',function(e){
			e.preventDefault();
			var app_id1 = $(this).closest("tr").find('.id_value').val();
			swal({
				title: "Are you sure ?",
				text: "If You Press Ok Then Price Range & Related QR Codes are Permanently Deleted !",
				icon: "warning",
				buttons: true,
				dangerMode: true,
			})
			.then((willDelete) => {
				if (willDelete) {
				$.ajax({
					type: "POST",
					url: "ajax_del.php",
					data: {
					"del_range": 1,
					"delete_id": app_id1,
					},
					success: function (response) {
					swal("Price Range & Related QR Codes are Deleted!",{
						icon: "success",
					}).then((result) =>{
						location.reload();
					});
					}
				})
				} 
			});
		});
		});
  	</script>
	
</body>
</html>