<?php
include "header.php";

$id = $_GET["id"];
$sessionid = $_GET["sessionid"];

if (isset($id) && isset($sessionid)) {
    $query = "SELECT name, type, size FROM $upload_table_name WHERE id = '$id' AND sessionid='$sessionid';";

    $result = mysql_query($query) or die("Error when querying by ID.");
    if (mysql_num_rows($result) == 0) {
        echo "Requested file not found.";
        exit;
    }
    list($name, $type, $size) = mysql_fetch_array($result);

    $s3Loc = $id . "." . $sessionid;
    $obj = $s3->getObject($bucketName, $s3Loc);

    header("Content-length: $size");
    header("Content-type: $type");
    header("Content-Disposition: attachment; filename = $name");
    echo $obj->body;
} else {
    echo "Did not attempt to download anything.";
}

$end = microtime(true);
$totaltime = $end - $start;

add_data('download', $totaltime);

include "footer.php";
?>
