<?php
include "header.php";

$id = $_GET["id"];
$sessionid = $_GET["sessionid"];

if (isset($id) && isset($sessionid)) {
    $s3Loc = $id . "." . $sessionid;
    $obj = $s3->getObject($bucketName, $s3Loc);
    $info = $s3->getObjectInfo($bucketName, $s3Loc);
    $size = $info['size'];
    $type = $info['type'];
    header("Content-length: $size");
    header("Content-type: $type");
    $name = $id.".m4a";
    header("Content-Disposition: attachment; filename = $name");
    echo $obj->body;
} else {
    echo "Did not attempt to download anything.";
}

include "footer.php";
?>
