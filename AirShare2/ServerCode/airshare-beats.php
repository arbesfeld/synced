<?php
include "header.php";

function xcopy($src,$dest)
{
    foreach (scandir($src) as $file) {
        if (!is_readable($src.'/'.$file)) continue;
        if (is_dir($file) && ($file!='.') && ($file!='..') ) {
            mkdir($dest . '/' . $file);
            xcopy($src.'/'.$file, $dest.'/'.$file);
        } else {
            copy($src.'/'.$file, $dest.'/'.$file);
        }
    }
}

if (isset($_GET["id"]) && isset($_GET["sessionid"])) {
    exec("mktemp -d -p /tmp/airshare-beats", $output, $retval);
    if ($retval != 0) {
        die("Something went wrong when creating a temp folder: $retval");
    }
    $tmp = $output[0];

    xcopy("/usr/share/nginx/www/beattracker/", $tmp);
    chmod("$tmp/vamp-simple-host", 0777);

    $fileID = $_GET["id"];
    $fileSessionID = $_GET["sessionid"];
    exec("python $tmp/beats.py $fileID $fileSessionID $tmp 2>&1", $output, $retval);

    if ($retval != 0) {
        die("Something went wrong when converting formats: $retval");
    }

    exec("$tmp/vamp-simple-host qm-vamp-plugins.dylib:qm-barbeattracker $tmp/beats.wav -o $tmp/beats.out", $output, $retval);

    if ($retval != 0) {
        die("Something went wrong when finding beats: $retval");
    } else {
        echo file_get_contents("$tmp/beats.out");

        $res = delete_directory($tmp);
        if (!$res) {
            die("Failed to delete temporary files.");
        }
    }
} else {
    echo "Did not attempt to do anything.";
}

$end = microtime(true);
$totaltime = $end - $start;

add_data('beats', $totaltime);

include "footer.php";
?>
