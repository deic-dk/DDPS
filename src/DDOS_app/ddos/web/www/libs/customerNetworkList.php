<?php

session_start();
require( 'Network.class.lib.php' );

$objNetwork = new Network();
$custID = $_POST['custid'];
$custNetworks = $objNetwork->customernetworks($custID);
echo json_encode($custNetworks);

?>