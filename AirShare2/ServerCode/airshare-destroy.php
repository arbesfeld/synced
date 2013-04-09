<?php
include "header.php";

if (isset($_GET["id"]) && isset($_GET["sessionid"])) {
    $fileID = $_GET["id"];
    $fileSessionID = $_GET["sessionid"];
    $query = "DELETE FROM $upload_table_name WHERE id = '$fileID' AND sessionid = '$fileSessionID';";

    $result = mysql_query($query) or die("Error when deleting by ID.");
    echo "Success!";
} elseif (isset($_GET["sessionid"])) {
    $fileSessionID = $_GET["sessionid"];
    $query = "DELETE FROM $upload_table_name WHERE sessionid = '$fileSessionID';";

    $result = mysql_query($query) or die("Error when deleting by session ID.");
    echo "Success!";
} else {
    echo "Did not attempt to delete anything.";
}

$query = "DELETE FROM $upload_table_name WHERE timestamp < (UNIX_TIMESTAMP() - 600);";
$result = mysql_query($query) or die("Error when automatically deleting old files.");

include "footer.php";
?>
