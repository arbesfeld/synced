<?php

include "header.php";

/*
Actions:
1) num_users++
2) num_songs++
3) num_movies++
4) num_youtube++
5) num_skips++
6) num_upvotes++
7) num_downvotes++
8) num_partymode++
*/

error_reporting(E_ALL);

if (isset($_GET["sessionid"]) && isset($_GET["action"])) {
    $sessionid = $_GET["sessionid"];
    $action = $_GET["action"];

    // add row with sessionid if not already existent
    $query = "SELECT * FROM $allstats_table_name WHERE sessionid = '$sessionid';";
    $result = mysql_query($query) or die("Failed to count rows.");
    if (mysql_num_rows($result) == 0) {
        $query = "INSERT INTO $allstats_table_name VALUES ('$sessionid', '0', '0', '0', '0', '0', '0', '0', '0', '0');";
        mysql_query($query) or die("Failed to insert new row into allstats table.");
    }

    $array = array(
            "1" => "num_users",
            "2" => "num_songs",
            "3" => "num_movies",
            "4" => "num_youtube",
            "5" => "num_skips",
            "6" => "num_upvotes",
            "7" => "num_downvotes",
            "8" => "num_partymode",
            "9" => "num_sync"
        );
    print_r($array);
    $action = $array[$action];

    $query = "UPDATE $allstats_table_name SET $action = $action + 1 WHERE sessionid = '$sessionid';";
    mysql_query($query) or die("Failed to update table with given action.");
} else if (isset($_GET["sessionid"])) {
    $sessionid = $_GET["sessionid"];

    $query = "SELECT * FROM $allstats_table_name WHERE sessionid = '$sessionid';";
    $result = mysql_query($query) or die("Failed to get row.");
    $row = mysql_fetch_row($result);
    $num_users = $row["1"];
    $num_songs = $row["2"];
    $num_movies = $row["3"];
    $num_youtube = $row["4"];
    $num_skips = $row["5"];
    $num_upvotes = $row["6"];
    $num_downvotes = $row["7"];
    $num_partymode = $row["8"];
    $num_sync = $row["9"];
    echo "Results for sessionid = $sessionid<br />";
    echo "num_users = $num_users<br />";
    echo "num_songs = $num_songs<br />";
    echo "num_movies = $num_movies<br />";
    echo "num_youtube = $num_youtube<br />";
    echo "num_skips = $num_skips<br />";
    echo "num_upvotes = $num_upvotes<br />";
    echo "num_downvotes = $num_downvotes<br />";
    echo "num_partymode = $num_partymode<br />";
    echo "num_sync = $num_sync<br />";
}

include "footer.php";

?>
