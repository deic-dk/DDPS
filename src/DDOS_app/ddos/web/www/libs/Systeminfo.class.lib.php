<?php
include_once ('DbOperations.class.lib.php');

class systeminfo {

    public function __construct() {

    }

    public static function getSystemInfo($statusid) {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.hosts
                LEFT JOIN ddps.hostsinfo
                ON ddps.hosts.id = ddps.hostsinfo.host_id
                WHERE hosts.id = $statusid ";
        $result = $dbObj->getRow($sql, $data=array());
        return $result;
    }

    public static function updateDate($date, $id) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.hostsinfo
                SET systemmaintenance = '$date'
                WHERE host_id = $id";
        $result = $dbObj->insertRow($sql, $data=array());
        return $result;
    }

    public static function updateDesc($desc, $id) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.hostsinfo
                SET description = '$desc'
                WHERE host_id = $id";
        $result = $dbObj->insertRow($sql, $data=array());
        return $result;
    }
}
?>