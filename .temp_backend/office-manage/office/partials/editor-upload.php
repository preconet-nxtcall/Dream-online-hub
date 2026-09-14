<?php 
require '_dbconnect.php';
if(empty($_FILES['file']))
{
	exit();	
}
$errorImgFile = "./img/img_upload_error.jpg";
$temp = explode(".", $_FILES["file"]["name"]);
$newfilename = round(microtime(true)) . '.' . end($temp);
$destinationFilePath = '../../uploads/ckeditor/'.$newfilename ;

if(!move_uploaded_file($_FILES['file']['tmp_name'], $destinationFilePath)){
	echo $errorImgFile;
}
else{
$destinationFilePath2 = $m_url.'uploads/ckeditor/'.$newfilename ;
echo $destinationFilePath2;
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