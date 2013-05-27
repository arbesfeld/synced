<?php

include "header.php";

$query = "SELECT id, sessionid, name FROM $upload_table_name";
$result = mysql_query($query);

while ($row = mysql_fetch_row($result)) {
    echo $row[0] . " " . $row[1] . " " . $row[2] . "<br />";
}

include "footer.php";

?>
