<?php

include_once ('DbOperations.class.lib.php');

class lists {
    public function __construct() {

    }

    public static function listUsers($customerid) {
        $dbObj = new DbOperations();
        $sql = "SELECT adminid, adminname
                FROM ddps.admins
                WHERE customerid='$customerid'";

        $result = $dbObj->getRows($sql, $data=array());
        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function listTcpFlags() {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.tcpflags";

        $result = $dbObj->getRows($sql, $data=array());

        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function listProtocols() {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.protocols";

        $result = $dbObj->getRows($sql, $data=array());

        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function listFragments() {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.fragment";

        $result = $dbObj->getRows($sql, $data=array());

        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function listThenActions() {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.thenaction";

        $result = $dbObj->getRows($sql, $data=array());

        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function listOptions() {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.roles
                WHERE roleid > 1 AND roleid < 5";
        $result = $dbObj->getRows($sql, $data=array());

        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function getnetworktype() {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.networktype
                WHERE id = 1";

        $result = $dbObj->getRows($sql, $data=array());

        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }
}