<?php

include_once ('Network.class.lib.php');
include_once ('Myalert.class.lib.php');

session_start();

$objNetwork = new Network();
$objAlert = new MyAlert();

if(!empty($_POST["cidr"])) {
    $valid = $objNetwork->checkNetworkPermission($_POST["cidr"]);
    if( $valid == 0 ) {
        echo "<span class='status-not-available'></span>";
        $objAlert->simpleNotify("You do not have permissions for the destination CIDR; it is not part of or a subnet of your assigned networks.!", "error");
        ?>
            <script type="text/javascript">
                var input = document.getElementById("cidr");
                input.value="";
            </script>
        <?php
    }
}

?>