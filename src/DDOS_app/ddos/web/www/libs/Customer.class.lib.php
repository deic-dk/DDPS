<?php

include_once ('DbOperations.class.lib.php');

class customer {
    public function __construct() {

    }

    public static function allCustomers($customerid, $role) {
        $dbObj = new DbOperations();
        if ($role == 1 || $role == 5) {
            $sql = "SELECT customerid, customername, mainmail, cvr, ean
                    FROM ddps.customers";
            $result = $dbObj->getRows($sql, $data=array());
            return $result;
        } else {
            $sql = "SELECT customerid, customername, mainmail, cvr, ean
                    FROM ddps.customers
                    WHERE customerid = '$customerid'";

            $result = $dbObj->getRows($sql, $data=array());
            return $result;
        }
    }

    public static function insertCustomer($data) {
        $dbObj = new DbOperations();
        $sql = "INSERT INTO ddps.customers(
	            customername, customeraddress1, mainmail, mainphone, cvr, ean, valid, max_active_rules, max_rule_fluctuation_time_window, customerid, createdon)
	            VALUES ('$data[name]', '$data[address]', '$data[email]', '$data[phone]','$data[cvr]', '$data[ean]', TRUE, $data[maxactiverule], $data[maxrulechange], gen_random_uuid(), now())";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function getcustomer($customerid) {
        $dbObj = new DbOperations();
        $sql = "SELECT *
                FROM ddps.customers
                WHERE customerid = '$customerid'";

        $result = $dbObj->getRow($sql, $data=array());
        if (!empty($result)) {
            return $result;
        } else {
            return false;
        }
    }

    public static function updateCustomer($data) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.customers
                SET customername = '$data[name]', customeraddress1 = '$data[address]', mainmail = '$data[email]', mainphone = '$data[phone]', cvr = '$data[cvr]', ean = '$data[ean]', max_rule_fluctuation_time_window = $data[maxrulechange], max_active_rules = $data[maxactiverule]
                WHERE customerid = '$data[customerid]'";

        $result = $dbObj->updateRow($sql, $data=array());
        return  $result;
    }

     public static function deletecustomer($customerid) {
        $dbObj = new DbOperations();
        $sql = "DELETE
                FROM ddps.customers
                WHERE customerid = '$customerid'";

        $result = $dbObj->deleteRow($sql, $data=array());
        return $result;
    }

    public static function maxRules($customerid) {
        $dbObj = new DbOperations();
        $sql = "SELECT max_active_rules
                FROM ddps.customers
                WHERE customerid = '$customerid'";

        $result = $dbObj->getRow($sql, $data=array());
        return $result['max_active_rules'];
    }

    public static function getRuleFluc($customerid) {
        $dbObj = new DbOperations();
        $sql = "SELECT max_rule_fluctuation_time_window
                FROM ddps.customers
                WHERE customerid = '$customerid'";

        $result = $dbObj->getRow($sql, $data=array());
        return $result['max_rule_fluctuation_time_window'];
    }
    public static function getCurrFluc($customerid) {
        $dbObj = new DbOperations();
        $sql = " SELECT count(*) AS currfluc
                FROM ddps.flowspecrules
                WHERE ddps.flowspecrules.uuid_customerid = '$customerid'
                AND ddps.flowspecrules.createdon >= now() - interval '1 minute'";

        $result = $dbObj->getRow($sql, $data=array());
        return $result['currfluc'];
    }


}