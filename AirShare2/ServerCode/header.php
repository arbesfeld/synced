<?php

$db = mysql_connect("localhost", "root", "1335238418081") or die("Failed to connect to database.");

mysql_select_db("airshare");

$upload_tmp_dir = "/tmp/";
$upload_table_name = "uploads";

?>
