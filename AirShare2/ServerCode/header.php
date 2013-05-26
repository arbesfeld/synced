<?php

//ini_set("display_errors", '1');

$start = microtime(true);

$db = mysql_connect("localhost", "root", "passwordhere") or die("Failed to connect to database.");

mysql_select_db("airshare");

$upload_table_name = "uploads";
$analytics_table_name = "stats";
$allstats_table_name = "allstats";

$ds = disk_free_space("/");

if ($ds < 1000000000) {
    die("Not enough space on server to proceed.");
}

function delete_directory_exclusive($dir) { // doesn't delete dir itself
    if (!file_exists($dir)) {
        return true;
    }
    if (!is_dir($dir)) {
        return unlink($dir);
    }
    foreach (scandir($dir) as $item) {
        if ($item == '.' || $item == '..') {
            continue;
        }
        if (!delete_directory($dir.DIRECTORY_SEPARATOR.$item)) {
            return false;
        }
    }
    return true;
}

function delete_directory($dir) {
    if (!file_exists($dir)) {
        return true;
    }
    if (!is_dir($dir)) {
        return unlink($dir);
    }
    foreach (scandir($dir) as $item) {
        if ($item == '.' || $item == '..') {
            continue;
        }
        if (!delete_directory($dir.DIRECTORY_SEPARATOR.$item)) {
            return false;
        }
    }
    return rmdir($dir);
}

function add_data($type, $nexttime) {
    $analytics_table_name = "stats";
    if (isset($_GET["sessionid"]) || isset($_POST["sessionid"])) {
        if (isset($_GET["sessionid"])) {
            $sessionID = $_GET["sessionid"];
        } else {
            $sessionID = $_POST["sessionid"];
        }
        
        $query = "SELECT * FROM $analytics_table_name WHERE sessionid = '$sessionID';";
        $result = mysql_query($query) or die("Failed to count rows.");
        if (mysql_num_rows($result) == 0) {
            $num_uploads = 0;
            $num_downloads = 0;
            $num_beats = 0;
            $first_action = 0;
            $last_action = 0;
            $uploads_time = 0;
            $downloads_time = 0;
            $beats_time = 0;

            $query = "INSERT INTO $analytics_table_name VALUES ('$sessionID', '0', '0', '0', '0', '0', '0', '0', '0');";
            mysql_query($query) or die("Failed to insert new row into analytics table.");
        } else {
            $row = mysql_fetch_row($result);
            $num_uploads = $row[1];
            $num_downloads = $row[2];
            $num_beats = $row[3];
            $first_action = $row[4];
            $last_action = $row[5];
            $uploads_time = $row[6];
            $downloads_time = $row[7];
            $beats_time = $row[8];
        }

        $curtime = time();
        if ($first_action == 0) {
            $first_action = $curtime;
        }
        $last_action = $curtime;
        $query = "UPDATE $analytics_table_name SET first_action = '$first_action', last_action = '$last_action' WHERE sessionid = '$sessionID';";
        mysql_query($query) or die("Failed to update times in stats.");

        $nexttime = round($nexttime * 1000000);
        if ($type == "upload") {
            $num_uploads += 1;
            $uploads_time += $nexttime;
            $query = "UPDATE $analytics_table_name SET num_uploads = '$num_uploads', uploads_time = '$uploads_time' WHERE sessionid = '$sessionID';";
        } else if ($type == "download") {
            $num_downloads += 1;
            $downloads_time += $nexttime;
            $query = "UPDATE $analytics_table_name SET num_downloads = '$num_downloads', downloads_time = '$downloads_time' WHERE sessionid = '$sessionID';";
        } else if ($type == "beats") {
            $num_beats += 1;
            $beats_time += $nexttime;
            $query = "UPDATE $analytics_table_name SET num_beats = '$num_beats', beats_time = '$beats_time' WHERE sessionid = '$sessionID';";
        } else {
            die("In header: nvalid action.");
        }

        mysql_query($query) or die("Failed to update row with new data.");
    }
}

?>
