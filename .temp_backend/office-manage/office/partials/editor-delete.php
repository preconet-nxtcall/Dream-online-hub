<?php 
require '_dbconnect.php';
// $src = $this->input->post('src'); 
$src = $_POST['src'];
$urls = $m_url.'uploads/ckeditor/';
$file_name = str_replace($urls, '', $src); // striping host to get relative path
	if(unlink('../../uploads/ckeditor/'.$file_name))
	{
		echo 'File Delete Successfully';
	}
// $src = $this->input->post('src'); 
// if(!empty($src)){
// 	echo $src;
// 	die;
// }

// if(isset($this->input->post('src'))){
// 	
// 	//$src = $_POST['src'];
// 	$file_name = str_replace(base_url(), '', $src); // striping host to get relative path
// 	if(unlink('assets/images/media/ckeditor/'.$file_name);)
// 	{
// 		echo 'File Delete Successfully';
// 	}
// }
?>