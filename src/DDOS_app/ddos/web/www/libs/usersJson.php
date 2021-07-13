<?php

session_start();

$table = "ddps.admins";
$primaryKey = 'adminid';
$customerid = $_SESSION['customerid'];
$role = $_SESSION['role'];

if ($role != 4 && $role != 5) {
    $columns = array(
        array( 'db' => 'adminname', 'dt' => 0 ),
        array( 'db' => 'username',  'dt' => 1 ),
        array( 'db' => 'organization',   'dt' => 2 ),
        array( 'db' => 'email',     'dt' => 3 ),
        array( 'db' => 'createdon',     'dt' => 4 ),
        array( 'db' => 'adminid', 'dt' => 5,
                'formatter' => function( $d, $row ) {
                return  '<a class="btnEditAction" href="index.php?action=user-edit&id=' . $d . '"><img src="/image/icon-edit.png" /></a>
                        <a class="btnEditAction" href="index.php?action=user-delete&id=' . $d . '"><img src="/image/icon-delete.png" /></a>';
        })
    );
} else {
    $columns = array(
        array( 'db' => 'adminname', 'dt' => 0 ),
        array( 'db' => 'username',  'dt' => 1 ),
        array( 'db' => 'organization',   'dt' => 2 ),
        array( 'db' => 'email',     'dt' => 3 ),
        array( 'db' => 'createdon',     'dt' => 4 )
    );
}

if ($role == 1 || $role == 5) {
   $whereCustom = "";
} else {
    $whereCustom = "customerid = '$customerid'";
}

require( 'Ssp.class.lib.php' );
echo json_encode(
    SSP::simpleCustom( $_GET, $table, $primaryKey, $columns, $whereCustom )
    //SSP::simple( $_GET, $table, $primaryKey, $columns )
);

?>