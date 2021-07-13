<?php
session_start();

$role = $_SESSION['role'];
$customerid = $_SESSION['customerid'];
$adminid = $_SESSION['adminid'];
if ($role == 3) {
$table = <<<EOT
 (
    SELECT
      a.name,
      a.net,
      a.description,
      a.addressfamily,
      a.networkid,
      a.uuid_networkcustomerid,
      b.id,
      b.familytype,
      c.network_id,
      c.admin_id
    FROM ddps.networks a
    LEFT JOIN ddps.networktype b ON a.addressfamily = b.id
    RIGHT JOIN ddps.accessrights c ON a.networkid = c.network_id
 ) temp
EOT;
} else {
$table = <<<EOT
 (
    SELECT
      a.name,
      a.net,
      a.description,
      a.addressfamily,
      a.networkid,
      a.uuid_networkcustomerid,
      b.id,
      b.familytype
    FROM ddps.networks a
    LEFT JOIN ddps.networktype b ON a.addressfamily = b.id
 ) temp
EOT;
}
$primaryKey = 'networkid';


if ($role != 3 && $role != 4 && $role != 5) {
    $columns = array(
        array( 'db' => 'name', 'dt' => 0 ),
        array( 'db' => 'net',  'dt' => 1 ),
        array( 'db' => 'description',   'dt' => 2 ),
        array( 'db' => 'familytype',     'dt' => 3 ),
        array( 'db' => 'networkid', 'dt' => 4,
                'formatter' => function( $d, $row ) {
                return  '<a class="btnEditAction" href="index.php?action=network-edit&id=' . $d . '"><img src="/image/icon-edit.png" /></a>
                        <a class="btnEditAction" href="index.php?action=network-delete&id=' . $d . '"><img src="/image/icon-delete.png" /></a>';
        })
    );
} else {
     $columns = array(
        array( 'db' => 'name', 'dt' => 0 ),
        array( 'db' => 'net',  'dt' => 1 ),
        array( 'db' => 'description',   'dt' => 2 ),
        array( 'db' => 'familytype',     'dt' => 3 )
    );
}

if ($role == 1 || $role == 5) {
    $whereCustom = "";
} else if ($role == 3) {
    $whereCustom = "uuid_networkcustomerid = '$customerid' AND admin_id = '$adminid'";
} else {
     $whereCustom = " uuid_networkcustomerid = '$customerid'";
}

require( 'Ssp.class.lib.php' );
echo json_encode(
    SSP::simpleCustom( $_GET, $table, $primaryKey, $columns, $whereCustom )
);

?>