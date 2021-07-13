<?php
session_start();
$table = "ddps.customers";
$primaryKey = "customerid";

$role = $_SESSION['role'];

if ($role != 4 && $role != 5) {
    $columns = array(
        array( 'db' => 'customername', 'dt' => 0 ),
        array( 'db' => 'mainmail',  'dt' => 1 ),
        array( 'db' => 'cvr',   'dt' => 2 ),
        array( 'db' => 'ean',     'dt' => 3 ),
        array( 'db' => 'createdon',     'dt' => 4 ),
        array( 'db' => 'customerid', 'dt' => 5,
            'formatter' => function( $d, $row ) {
            return  '<a class="btnEditAction" href="index.php?action=customer-edit&id=' . $d . '"><img src="/image/icon-edit.png" /></a>
                    <a class="btnEditAction" href="index.php?action=customer-delete&id=' . $d . '"><img src="/image/icon-delete.png" /></a>';
        })
    );
} else {
    $columns = array(
        array( 'db' => 'customername', 'dt' => 0 ),
        array( 'db' => 'mainmail',  'dt' => 1 ),
        array( 'db' => 'cvr',   'dt' => 2 ),
        array( 'db' => 'ean',     'dt' => 3 ),
        array( 'db' => 'createdon',     'dt' => 4 )
    );
}

require( 'Ssp.class.lib.php' );
echo json_encode(
    SSP::simple( $_GET, $table, $primaryKey, $columns )
);

?>