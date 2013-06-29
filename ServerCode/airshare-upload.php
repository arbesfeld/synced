<?php
include "header.php";

$fidx = "musicfile";
$tmpName = $_FILES[$fidx]["tmp_name"];
$fileName = $_FILES[$fidx]["name"];
$fileType = $_FILES[$fidx]["type"];
$fileSize = $_FILES[$fidx]["size"];
$nl = "<br />";

$id = $_POST["id"];
$sessionid = $_POST["sessionid"];

if (file_exists($tmpName) && is_uploaded_file($tmpName) && isset($id) && isset($sessionid)) {
    if (!get_magic_quotes_gpc()) {
        $fileName = addslashes($fileName);
    }

    $s3Loc = $id . "." . $sessionid;
    if ($s3->putObjectFile($tmpName, $bucketName, $s3Loc, S3::ACL_PUBLIC_READ)) {
        echo "S3::putObjectFile(): File copied to {$bucketName} is {$fileName} with temp name {$tmpName}\n";

        $path = "/tmp/airshare-uploads/".$sessionid."/";
        mkdir($path, 0777, true);
        chmod("$path/", 0777);
        if(!move_uploaded_file($tmpName, "$path/$fileName")) {
            echo("Error moving file.\n");
        }

        $inFile = $path.$fileName;
        $outFileWav = $path.$fileName.".wav";
        $outFileBeats = $path.$fileName.".out";

        $cmd = "/usr/local/bin/faad -o ".$outFileWav." ".$inFile;                     
        while( exec($cmd, $ouput, $retval) ) { /* wait */ } ;
        if ($retval != 0) {
            echo("Something went wrong when converting song: $output, $retval\n");
        } 
        $vamp = "/opt/app/current/beattracker/vamp-simple-host";
        $cmd = $vamp." qm-vamp-plugins.so:qm-barbeattracker ".$outFileWav." -o ".$outFileBeats;                   
        while( exec($cmd, $ouput, $retval) ) { /* wait */ } ;

        $beatsLoc = $s3Loc . ".beats";
        if ($s3->putObjectFile($outFileBeats, $bucketName, $beatsLoc, S3::ACL_PUBLIC_READ)) {
            echo("Put beats.\n");
        } else {
            echo("Could not put beats.\n");
        }
        $cmd = "rm -f ".$inFile." ".$outFileWav." ".$outFileBeats;
        exec($cmd, $output, $retval);
    } else {
        die("S3::putObjectFile(): Failed to copy file");
    }
    echo $id. "success\n";
} else {
    die("Did not attempt to upload file.");
}

include "footer.php";
?>
