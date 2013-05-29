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
    // exec("mktemp -d -p /tmp/airshare-beats", $output, $retval);
    // if ($retval != 0) {
    //     die("Something went wrong when creating a temp folder: $retval");
    // }
    // $tmp = $output[0];

    $fileID = $_GET["id"];
    $fileSessionID = $_GET["sessionid"];

    $path = "/tmp/airshare-uploads/".$fileSessionID."/";
    $inFile = $path.$fileID;
    $outFileWav = $path.$fileID.".wav";
    $outFileBeats = $path.$fileID.".out";

    $cmd = "/usr/local/bin/faad -o ".$outFileWav." ".$inFile;
    // echo $cmd."\n";
    // exec("python /opt/app/current/beattracker/beats.py $fileID $fileSessionID $path 2>&1", $output, $retval);                     
    exec($cmd, $ouput, $retval);
    if ($retval != 0) {
        die("Something went wrong when converting song: $output, $retval");
    } 
    $vamp = "/opt/app/current/beattracker/vamp-simple-host";
    $cmd = $vamp." qm-vamp-plugins.so:qm-barbeattracker ".$outFileWav." -o ".$outFileBeats;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         " qm-vamp-plugins.so:qm-barbeattracker ".$outFileWav." -o ".$outFileBeats;
    // echo $cmd."\n";
    exec($cmd, $output, $retval);
    if ($retval != 0) {
        die("Something went wrong when finding beats: $output, $retval");
    } else {
        echo file_get_contents($outFileBeats);

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
