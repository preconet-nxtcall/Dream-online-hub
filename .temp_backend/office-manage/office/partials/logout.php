<?php
session_start();

unset($_SESSION['loggedin']);
unset($_SESSION['id']);
unset($_SESSION['u_id']);
unset($_SESSION['head']);
unset($_SESSION['text']);
unset($_SESSION['swl_type']);
header("location: ../index");

?>