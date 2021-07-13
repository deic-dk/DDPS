<?php
session_start();

$table = <<<EOT
 (
    SELECT
      a.description,
      a.flowspecruleid,
      a.thenaction,
      a.notification,
      a.createdon,
      to_char(a.validto, 'YYYY-MM-DD HH24:MI') AS validto,
      a.uuid_administratorid,
      a.uuid_customerid,
      b.adminname,
      b.adminid
    FROM ddps.flowspecrules a
    LEFT JOIN ddps.admins b ON a.uuid_administratorid = b.adminid
 ) temp
EOT;

$primaryKey = 'flowspecruleid';
$customerid = $_SESSION['customerid'];
$role = $_SESSION['role'];

if ($role != 4 && $role != 5) {
    $columns = array(
        array( 'db' => 'description', 'dt' => 0 ),
        array( 'db' => 'thenaction', 'dt' => 1 ),
        array( 'db' => 'notification', 'dt' => 2 ),
        array( 'db' => 'validto', 'dt' => 3 ),
        array( 'db' => 'adminname', 'dt' => 4 ),
        array( 'db' => 'createdon', 'dt' => 5 ),
        array( 'db' => 'flowspecruleid', 'dt' => 6,
                'formatter' => function( $d, $row ) {
                return  '<a class="btnEditAction" href="index.php?action=rule-edit&id=' . $d . '"><img src="/image/eye.png" /></a>
                        <a class="btnEditAction" href="index.php?action=rule-deactivate&id=' . $d . '"><img src="/image/icon-delete.png" /></a>';
        })
    );
} else {
    $columns = array(
        array( 'db' => 'description', 'dt' => 0 ),
        array( 'db' => 'thenaction', 'dt' => 1 ),
        array( 'db' => 'notification', 'dt' => 2 ),
        array( 'db' => 'validto', 'dt' => 3 ),
        array( 'db' => 'adminname', 'dt' => 4 ),
        array( 'db' => 'createdon', 'dt' => 5 )
    );
}
if ($role == 1 || $role == 5) {
   $whereCustom = "";
} else {
    $whereCustom = "uuid_customerid = '$customerid'";
}

require( 'Ssp.class.lib.php' );
echo json_encode(
    SSP::simpleCustom( $_GET, $table, $primaryKey, $columns, $whereCustom )
   // SSP::simple( $_GET, $table, $primaryKey, $columns)
);

?>