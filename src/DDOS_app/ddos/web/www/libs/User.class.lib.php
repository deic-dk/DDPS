<?php

include_once ('DbOperations.class.lib.php');

class user {
    public function __construct() {

    }
    public static function validateUser($username, $pass) {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.admins
                WHERE username = '$username' AND password = crypt('$pass', password)"; //crypt('$pass', password) // password = '$pass'

        $result = $dbObj->getRow($sql, $data=array());

        if (!empty($result)) {
            $_SESSION['role'] = $result['adminroleid'];
            $_SESSION['name'] = $result['adminname'];
            $_SESSION['username'] = $result['username'];
            $_SESSION['customerid'] = $result['customerid'];
            $_SESSION['adminid'] = $result['adminid'];
            return $_SESSION;
        } else {
            return false;
        }
    }

    public static function checkUserAvailability($username) {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.admins
                WHERE username = '$username'"; //crypt('$pass', password)

        $result = $dbObj->getRows($sql, $data=array());
        return count($result);
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

    public static function insertUser($data) {
        $dbObj = new DbOperations();
        if (!empty($data['listboxfrom'])) {
            $networkArray = $data['listboxfrom'];
        }
        $sql = "INSERT INTO ddps.admins(
	            adminroleid, adminname, username, organization, email, password, lastlogin, lastpasswordchange, status, edupersonprincipalname, schachomeorganization, adminid, customerid)
	            VALUES ($data[admintype], '$data[name]', '$data[username]', '$data[org]','$data[email]', crypt('$data[pass]', gen_salt('bf', 10)), current_timestamp, current_timestamp, TRUE, '$data[eppn]', '$data[shacorg]', gen_random_uuid(), '$data[customer]') RETURNING adminid";

        $result = $dbObj->insertRowCustom($sql, $data=array());

        if (!empty($networkArray) && !empty($result)) {
            $adminid = $result;
            foreach ($networkArray as $key => $value){
                $sql = "INSERT INTO ddps.accessrights(network_id, admin_id, rights)
                	        VALUES ('$value', '$adminid', true)";
                $res = $dbObj->insertRow($sql, $data=array());
            }
        }
        return  $result;
    }

    public static function updatePassUser($data) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.admins
                SET password =  crypt('$data[pass]', gen_salt('bf', 10))
                WHERE adminid = '$data[adminid]'";

        $result = $dbObj->getRows($sql, $data=array());
        return count($result);
    }

    public static function allUsers($customerid, $role) {
        $dbObj = new DbOperations();
        if ($role == 1 || $role == 5){
            $sql = "SELECT adminid, adminname, username, organization, email, status
                    FROM ddps.admins
                    WHERE adminroleid > 1";

            $result = $dbObj->getRows($sql, $data=array());
            return $result;
        } else {
            $sql = "SELECT adminid, adminname, username, organization, email, status
                    FROM ddps.admins
                    WHERE adminroleid > 1 AND customerid = '$customerid' ";

            $result = $dbObj->getRows($sql, $data=array());
            return $result;
        }
    }

    public static function insertCustomer($data) {
        $dbObj = new DbOperations();
        $sql = "INSERT INTO ddps.customers(
	            customername, customeraddress1, mainmail, mainphone, cvr, ean, valid, customerid)
	            VALUES ('$data[name]', '$data[address]', '$data[email]', '$data[phone]','$data[cvr]', '$data[ean]', TRUE, gen_random_uuid())";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }


    public static function deleteuser($userid) {
        $dbObj = new DbOperations();
        $sql = "DELETE
                FROM ddps.admins
                WHERE adminid = '$userid'";

        $result = $dbObj->deleteRow($sql, $data=array());
        return $result;
    }


    public static function getuser($userid) {
        $dbObj = new DbOperations();
    // echo   $sql = "SELECT * FROM admins WHERE adminid = '$userid'";
        $sql = "SELECT *
                FROM ddps.admins
                LEFT JOIN ddps.accessrights
                ON ddps.admins.adminid = ddps.accessrights.admin_id
                LEFT JOIN ddps.networks
                ON ddps.networks.networkid = ddps.accessrights.network_id
                WHERE ddps.admins.adminid = '$userid'";

        $result = $dbObj->getRows($sql, $data=array());
        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function updateUser($data) {
        $dbObj = new DbOperations();
        $networkArray = array();
        $adminid = $data['adminid'];
        $adminid1 = $data['adminid'];

        if (!empty($data['listboxfrom'])){
            $networkArray = $data['listboxfrom'];
            count($networkArray);
        }

        $sql = "UPDATE ddps.admins
                SET adminroleid = $data[admintype], adminname = '$data[name]', username =  '$data[username]', organization = '$data[org]', email = '$data[email]', edupersonprincipalname = '$data[eppn]', customerid = '$data[customer]', schachomeorganization = '$data[shacorg]' WHERE adminid = '$data[adminid]'";
        $result = $dbObj->updateRow($sql, $data=array());
        $sqlDel = "DELETE
                   FROM ddps.accessrights
                   WHERE admin_id = '$adminid'";

        $result = $dbObj->deleteRow($sqlDel, $data=array());
        if (!empty($networkArray)) {
            $adminid = $result['adminid'];
            foreach ($networkArray as $key => $value){
                $sql = "INSERT INTO ddps.accessrights(network_id, admin_id, rights)
                	    VALUES ('$value', '$adminid1', true)";
                $res = $dbObj->insertRow($sql, $data=array());
            }
        }
        return  $result;
    }

}