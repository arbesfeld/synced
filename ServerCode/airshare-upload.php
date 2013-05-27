<?php
include "header.php";

// TODO: add more security: maybe only certain users can upload to the server, or only if they have a password or something

function get_id() {
    // try the first ID that works
    for ($i = 0; $i < 10; $i++) {
        $query = "SELECT name FROM uploads WHERE id = '$i';";
        $result = mysql_query($query) or die("Error when querying by ID.");
        if (mysql_num_rows($result) == 0) {
            return $i;
        }
    }

    // did not find an unused ID, so find the oldest file and replace it
    $query = "SELECT id FROM uploads WHERE timestamp = (SELECT MIN(timestamp) FROM uploads);";
    $result = mysql_query($query) or die("Error when retrieving the oldest ID.");
    list($id) = mysql_fetch_array($result);
    return $id;
}

function clear_old() {
    $maxlen = 10;
    $query = "SELECT id FROM uploads;";
    $result = mysql_query($query) or die("Error when querying all.");
    $curlen = mysql_num_rows($result);
    for ($i = $maxlen; $i < $curlen; $i++) {
        $query = "SELECT id FROM uploads WHERE timestamp = (SELECT MIN(timestamp) FROM uploads);";
        $result = mysql_query($query) or die("Error when retrieving the oldest ID.");
        list($id) = mysql_fetch_array($result);
        $query = "DELETE FROM uploads WHERE id='$id';";
        mysql_query($query) or die("Error when deleting an old upload.");
    }
}

$fidx = "musicfile";
$tmpName = $_FILES[$fidx]["tmp_name"];
$fileName = $_FILES[$fidx]["name"];
$fileType = $_FILES[$fidx]["type"];
$fileSize = $_FILES[$fidx]["size"];
$nl = "<br />";

if (file_exists($tmpName) && is_uploaded_file($tmpName) && isset($_POST["id"]) && isset($_POST["sessionid"])) {
    if (!get_magic_quotes_gpc()) {
        $fileName = addslashes($fileName);
    }

    exec("mktemp -d -p /tmp/airshare-uploads", $output, $retval);
    if ($retval != 0) {
        die("Something went wrong when creating a temp folder: $retval");
    }
    $tmp = $output[0];
    move_uploaded_file($tmpName, "$tmp/$fileName");

    //$id = get_id();
    $id = $_POST["id"];
    $sessionid = $_POST["sessionid"];
    if (!ctype_alnum($id) || !ctype_alnum($sessionid)) {
        die("Cannot upload because id and sessionid must be numeric strings.");
    }

    $query = "DELETE FROM $upload_table_name WHERE id='$id' AND sessionid='$sessionid';";
    mysql_query($query) or die("Failed to clear duplicates from database: " . mysql_error());

    $query = "INSERT INTO $upload_table_name (id, sessionid, name, size, type, timestamp, location) VALUES ('$id', '$sessionid', '$fileName', '$fileSize', '$fileType', UNIX_TIMESTAMP(), '$tmp/$fileName');";

    mysql_query($query);// or die("Failed to add file to database: " . mysql_error());
    $tries = 0;
    while (mysql_affected_rows() < 0 && $tries < 100) {
        mysql_query($query);
        $tries++;
    }
    if (mysql_affected_rows() < 0) {
        mysql_query($query) or die("Failed to add file to database after many tries: " . mysql_error());
    }
    echo $id;

    //clear_old(); // don't use this later: instead have stuff naturally clear
} else {
    echo "Did not attempt to upload file.";
}

$end = microtime(true);
$totaltime = $end - $start;

add_data('upload', $totaltime);

include "footer.php";
?>
