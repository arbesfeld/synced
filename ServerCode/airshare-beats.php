<?php
include "header.php";

if (isset($_GET["id"]) && isset($_GET["sessionid"])) {
    $id = $_GET["id"];
    $sessionid = $_GET["sessionid"];

    $s3Loc = $id . "." . $sessionid . ".beats";
    $obj = $s3->getObject($bucketName, $s3Loc);

    echo $obj->body;
} else {
    echo "Did not attempt to do anything.\n";
}

include "footer.php";
?>
