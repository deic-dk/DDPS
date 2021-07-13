<?php
session_start();
$table = <<<EOT
 (
   SELECT
      a.hostname,
      a.id,
      b.status,
      b.noofrules,
      b.host_id,
      b.description,
      to_char(b.systemmaintenance, 'YYYY-MM-DD HH24:MI') AS systemmaintenance
    FROM ddps.hosts a
    LEFT JOIN ddps.hostsinfo b ON a.id = b.host_id
    ORDER by id ASC
 ) temp
EOT;

$primaryKey = 'id';
$role = $_SESSION['role'];
$customerid = $_SESSION['customerid'];

if ($role == 1 ) {
    $columns = array(
        array( 'db' => 'hostname', 'dt' => 0 ),
        array( 'db' => 'status',  'dt' => 1 ),
        array( 'db' => 'noofrules',   'dt' => 2 ),
        array( 'db' => 'systemmaintenance',   'dt' => 3 ),
        array( 'db' => 'description',   'dt' => 4 ),
        array( 'db' => 'id', 'dt' => 5,
                'formatter' => function( $d, $row ) {
                return  '<a class="btnEditAction" style = "margin-left:18px;"href="index.php?action=systeminfo-edit&id=' . $d . '"><img src="/image/icon-edit.png" /></a>';
        })
    );
} else {
     $columns = array(
        array( 'db' => 'hostname', 'dt' => 0 ),
        array( 'db' => 'status',  'dt' => 1 ),
        array( 'db' => 'noofrules',   'dt' => 2 ),
        array( 'db' => 'systemmaintenance',   'dt' => 3 ),
        array( 'db' => 'description',   'dt' => 4 )
    );
}


require( 'Ssp.class.lib.php' );
echo json_encode(
    SSP::simple( $_GET, $table, $primaryKey, $columns)
);

?>