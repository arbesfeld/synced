<?php

require 'vendor/autoload.php';

if (!class_exists('S3')) require_once 'S3.php';

// AWS access info
if (!defined('awsAccessKey')) define('awsAccessKey', 'AKIAIJ7LXAYTVVVAJ6IQ');
if (!defined('awsSecretKey')) define('awsSecretKey', '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');

// Check for CURL
if (!extension_loaded('curl') && !@dl(PHP_SHLIB_SUFFIX == 'so' ? 'curl.so' : 'php_curl.dll'))
    exit("\nERROR: CURL extension not loaded\n\n");

// Instantiate the class
$s3 = new S3(awsAccessKey, awsSecretKey);
$bucketName = "synced.musicbucket";

if (!$s3->putBucket($bucketName, S3::ACL_PUBLIC_READ)) {
    die("S3::putBucket(): Unable to create bucket (it may already exist and/or be owned by someone else)");
}

?>
