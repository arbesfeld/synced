<?php

date_default_timezone_set('UTC');

$mil = microtime();
echo date("Y-m-d-H:i:s", substr($mil, strpos($mil, " ") + 1)) . substr($mil, 1, 4);

?>
