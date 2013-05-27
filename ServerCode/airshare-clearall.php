<?php

include "header.php";

$query = "TRUNCATE $upload_table_name";
mysql_query($query) or die("Failed to clear all upload data.");

$query = "TRUNCATE $analytics_table_name";
mysql_query($query) or die("Failed to clear all analytics.");

if (!delete_directory_exclusive("/tmp/airshare-beats")) {
    die("Failed to clear all temporary beats data.");
}

if (!delete_directory_exclusive("/tmp/airshare-uploads")) {
    die("Failed to clear all temporary uploads data.");
}

include "footer.php";

?>
