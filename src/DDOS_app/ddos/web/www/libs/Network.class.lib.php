<?php

include_once ('DbOperations.class.lib.php');

class network {
    public function __construct() {

    }

    public static function insertbasicnetwork($data) {
        $dbObj = new DbOperations();
        $sql = "INSERT INTO ddps.networks(
            	name, addressfamily, net, description, networkid, uuid_networkcustomerid)
	            VALUES ('$data[name]', $data[networktype], '$data[basiccidr]', '$data[desc]', gen_random_uuid(), '$data[customer]')";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function insertnetwork($data) {
        $dbObj = new DbOperations();
        $sql = "INSERT INTO ddps.networks(
            	name, addressfamily, net, description, networkid, uuid_networkcustomerid)
	            VALUES ('$data[name]', $data[networktype], '$data[cidr]', '$data[desc]', gen_random_uuid(), '$data[customer]')";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function allbasicnetworks($customerid, $role, $adminid) {
        $dbObj = new DbOperations();
        if ($role == 1 || $role == 5) {
            $sql = "Select *
                    FROM ddps.networks";

            $result = $dbObj->getRows($sql, $data=array());
            return  $result;
        } else if ($role == 2 || $role == 4) {
            $sql = "Select *
                    FROM ddps.networks
                    WHERE uuid_networkcustomerid = '$customerid'";

            $result = $dbObj->getRows($sql, $data=array());
            return  $result;
       } else {
            $sql = "Select *
                    FROM ddps.networks
                    RIGHT JOIN ddps.accessrights
                    ON ddps.accessrights.network_id = ddps.networks.networkid
                    WHERE uuid_networkcustomerid = '$customerid' AND admin_id = '$adminid'";

            $result = $dbObj->getRows($sql, $data=array());
            return  $result;
        }
    }

    public static function customernetworks($customerid) {
        $dbObj = new DbOperations();
        $sql = "Select *
                FROM ddps.networks
                WHERE uuid_networkcustomerid = '$customerid'";

        $result = $dbObj->getRows($sql, $data=array());
        return  $result;
    }

    public static function getbasicnetwork($networkid) {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.networks
                LEFT JOIN ddps.networktype
                ON      ddps.networks.addressfamily = ddps.networktype.id
                WHERE networkid = '$networkid'";

        $result = $dbObj->getRow($sql, $data=array());
        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function updatebasicnetwork($data) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.networks
	                SET name='$data[name]', addressfamily=$data[networktype], net='$data[cidr]', description='$data[desc]', uuid_networkcustomerid='$data[customer]'
	                WHERE networkid='$data[networkid]'";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function deletebasicnetwork($networkid) {
        $dbObj = new DbOperations();
        $sql = "DELETE
                FROM ddps.networks
                WHERE networkid = '$networkid'";

        $result = $dbObj->deleteRow($sql, $data=array());
        return $result;
    }

    public static function checkNetworkPermission($cidr) {
        $dbObj = new DbOperations();
        $customerid = $_SESSION['customerid'];
        $adminid = $_SESSION['adminid'];
        $role = $_SESSION['role'];

        if ($role == 1) {
            $sql = "SELECT ddps.networks.net
                    FROM ddps.networks
                    WHERE inet '$cidr' <<= ddps.networks.net";

            $result = $dbObj->getRows($sql, $data=array());
            return count($result);
        } else if ($role == 2) {
            $sql = "SELECT ddps.networks.net
                    FROM ddps.networks
                    WHERE inet '$cidr' <<= ddps.networks.net AND uuid_networkcustomerid = '$customerid'";

            $result = $dbObj->getRows($sql, $data=array());
            return count($result);
       } else {
            $sql = "SELECT ddps.networks.net
                    FROM ddps.networks
                    RIGHT JOIN ddps.accessrights
                    ON ddps.accessrights.network_id = ddps.networks.networkid
                    WHERE inet '$cidr' <<= ddps.networks.net  AND uuid_networkcustomerid = '$customerid' AND admin_id = '$adminid'";

            $result = $dbObj->getRows($sql, $data=array());
            return count($result);
        }

    }

}