<?php
include "header.php";

if (isset($_GET["sessionid"])) {
    $fileSessionID = $_GET["sessionid"];

    $query = "SELECT * FROM $analytics_table_name WHERE sessionid = '$fileSessionID';";
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

    $num_uploads_str = strval($num_uploads);
    $num_downloads_str = strval($num_downloads);
    $num_beats_str = strval($num_beats);

    echo "Number of uploads: $num_uploads_str<br />";
    echo "Number of downloads: $num_downloads_str<br />";
    echo "Number of beat requests: $num_beats_str<br />";
    $first_action = date("Y-m-d-H:i:s", $first_action);
    echo "First action: $first_action<br />";
    $last_action = date("Y-m-d-H:i:s", $last_action);
    echo "Last action: $last_action<br />";
    if ($num_uploads > 0) {
        $uploads_time /= $num_uploads * 1000000.0;
        $uploads_time_str = strval($uploads_time);
        echo "Average upload time: $uploads_time_str<br />";
    }
    if ($num_downloads > 0) {
        $downloads_time /= $num_downloads * 1000000.0;
        $downloads_time_str = strval($downloads_time);
        echo "Average download time: $downloads_time_str<br />";
    }
    if ($num_beats > 0) {
        $beats_time /= $num_beats * 1000000.0;
        $beats_time_str = strval($beats_time);
        echo "Average beats time: $beats_time_str<br />";
    }
} else {
    echo "Did not attempt to perform analytics.";
}

include "footer.php";
?>
