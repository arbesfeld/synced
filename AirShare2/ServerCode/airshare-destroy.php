<?php
include "header.php";

function rstrpos ($haystack, $needle) {
    $size = strlen ($haystack);
    $pos = strpos (strrev($haystack), $needle, 0);
    
    if ($pos === false) {
        return false;
    }
    
    return $size - $pos;
}

if (isset($_GET["id"]) && isset($_GET["sessionid"])) {
    $fileID = $_GET["id"];
    $fileSessionID = $_GET["sessionid"];
    $query = "SELECT location FROM $upload_table_name WHERE id = '$fileID' AND sessionid = '$fileSessionID';";
    $result = mysql_query($query) or die("Error when querying by ID.");
    while ($row = mysql_fetch_row($result)) {
        delete_directory(substr($row[0], 0, rstrpos($row[0], "/") - 1));
    }

    $query = "DELETE FROM $upload_table_name WHERE id = '$fileID' AND sessionid = '$fileSessionID';";

    $result = mysql_query($query) or die("Error when deleting by ID.");
    echo "Success!";
} elseif (isset($_GET["sessionid"])) {
    $fileSessionID = $_GET["sessionid"];
    $query = "SELECT location FROM $upload_table_name WHERE sessionid = '$fileSessionID';";
    $result = mysql_query($query) or die("Error when querying by session ID.");
    while ($row = mysql_fetch_row($result)) {
        delete_directory(substr($row[0], 0, rstrpos($row[0], "/") - 1));
    }

    $query = "DELETE FROM $upload_table_name WHERE sessionid = '$fileSessionID';";

    $result = mysql_query($query) or die("Error when deleting by session ID.");
    echo "Success!";
} else {
    echo "Did not attempt to delete anything.";
}

include "footer.php";
?>
