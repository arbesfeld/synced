<?php

include "header.php";

$query = "TRUNCATE $upload_table_name";
mysql_query($query) or die("Failed to clear all.");

include "footer.php";

?>
