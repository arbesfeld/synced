<?php
include "header.php";

if (isset($_GET["id"]) && isset($_GET["sessionid"])) {
    $fileID = $_GET["id"];
    $fileSessionID = $_GET["sessionid"];
    $query = "SELECT name, type, size, content FROM $upload_table_name WHERE id = '$fileID' AND sessionid='$fileSessionID';";

    $result = mysql_query($query) or die("Error when querying by ID.");
    if (mysql_num_rows($result) == 0) {
        echo "Requested file not found.";
        exit;
    }
    list($name, $type, $size, $content) = mysql_fetch_array($result);

    header("Content-length: $size");
    header("Content-type: $type");
    header("Content-Disposition: attachment; filename = $name");
    echo $content;
} else {
    echo "Did not attempt to download anything.";
}

include "footer.php";
?>
