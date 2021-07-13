<?php

include_once ('DbOperations.class.lib.php');

class flowspecrules {
    public function __construct() {

    }

    public static function allRules($customerid, $adminid) {
        $dbObj = new DbOperations();
        if ($_SESSION['role'] == 1 || $_SESSION['role'] == 5){
            $sql = "SELECT ddps.admins.adminid, ddps.admins.adminname, ddps.flowspecrules.flowspecruleid, ddps.flowspecrules.validfrom, ddps.flowspecrules.validto, ddps.flowspecrules.isactivated, ddps.flowspecrules.thenaction, ddps.flowspecrules.uuid_administratorid
                    FROM ddps.flowspecrules
                    LEFT JOIN ddps.admins
                    ON ddps.admins.adminid = ddps.flowspecrules.uuid_administratorid";

            $result = $dbObj->getRows($sql, $data=array());
            return $result;
        } else {
            $sql = "SELECT ddps.admins.adminid, ddps.admins.adminname, ddps.flowspecrules.flowspecruleid, ddps.flowspecrules.validfrom, ddps.flowspecrules.validto, ddps.flowspecrules.isactivated, ddps.flowspecrules.thenaction, ddps.flowspecrules.uuid_administratorid
                    FROM flowspecrules
                    LEFT JOIN admins
                    ON admins.adminid = flowspecrules.uuid_administratorid
                    WHERE flowspecrules.uuid_administratorid ='$adminid' AND flowspecrules.uuid_customerid = '$customerid' ";

            $result = $dbObj->getRows($sql, $data=array());
            return $result;
        }
    }

    public static function insertRule($data) {
        $dbObj = new DbOperations();
        $customer_id = $_SESSION['customerid'];
        $adminid = $_SESSION['adminid'];

        if(empty($data[srcaddress])){
            $srcAddress = 'NULL';
        } else {
           $srcAddress = trim($data[srcaddress]);
           $srcAddress = "'".$srcAddress."'";
        }

        if(!empty($data[dstport1])){
            $data[dstport1] = trim($data[dstport1]);
            $data[dstport2] = trim($data[dstport2]);

            if ($data[dstopt]=='-'){ // Handles the range part. But it is disabled for now. We may intriduce it later so keeping the code
                $dstValue = ">=".$data[dstport1]."&<=".$data[dstport2];
            }else{
                $dstValue = $data[dstopt].$data[dstport1];
            }
        }
        if(!empty($data[srcport1])){
            $data[srcport1] = trim($data[srcport1]);
            $data[srcport2] = trim($data[srcport2]);

            if ($data[srcopt]=='-'){// Handles the range part. But it is disabled for now. We may intriduce it later so keeping the code
                $srcValue = ">=".$data[srcport1]."&<=".$data[srcport2];
            }else{
                $srcValue = $data[srcopt].$data[srcport1];
            }
        }
        if (!empty($data[protocol])) {
            if ($data[protocol] == "555"){
                $protocol = "";
            } else {
                $protocol = "=".$data[protocol];
            }

        }
        if (!empty($data[pnumber])) {
            $protocol = "=".$data[pnumber];
        }

        $sql = "INSERT INTO ddps.flowspecrules(
	            flowspecruleid, description, validfrom, validto, isactivated, isexpired, direction, destinationprefix, sourceprefix, ipprotocol, destinationport, sourceport, tcpflags, packetlength, fragmentencoding, thenaction, uuid_customerid, uuid_administratorid, sourceapp, notification, createdon)
	            VALUES (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '$protocol', '$dstValue', '$srcValue', '$data[tcpflag]', '$data[pklenght]', '$data[frgtype]', '$data[thenaction]', '$customer_id','$adminid', 'GUI', 'Pending', now())";
        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function expireRule($ruleid) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.flowspecrules
                SET notification='Pending', validto=current_timestamp
                WHERE flowspecruleid = '$ruleid'";

        $result = $dbObj->deleteRow($sql, $data=array());
        return $result;
    }

    public static function countRules($customerid) {
        $dbObj = new DbOperations();
        $sql = "SELECT count(*) from ddps.flowspecrules
                WHERE ddps.flowspecrules.uuid_customerid = '$customerid'
                AND ddps.flowspecrules.isactivated
                OR ddps.flowspecrules.notification = 'Pending'
                AND NOT ddps.flowspecrules.isexpired";
        $result = $dbObj->getRow($sql, $data=array());
        return $result['count'];
    }


    public static function showRule($ruleid) {
        $dbObj = new DbOperations();
        $sql = "Select *, to_char(validto, 'YYYY-MM-DD HH24:MI') AS validto, to_char(validfrom, 'YYYY-MM-DD HH24:MI') AS validfrom
                FROM ddps.flowspecrules
                WHERE flowspecruleid = '$ruleid'";

        $result = $dbObj->getRow($sql, $data=array());
        return $result;
    }

    public static function updateRule($data) {
        $dbObj = new DbOperations();
        $sql = "UPDATE ddps.flowspecrules
                SET notification='Pending', validto='$data[expdate1]'
                WHERE flowspecruleid = '$data[ruleid]'";

        $result = $dbObj->getRow($sql, $data=array());
        return $result;
    }
    public static function ruleStats() {
        $dbObj = new DbOperations();
        //$sql = " SELECT trim(from to_char(createdon, 'DAY')) AS days, count(DISTINCT createdon) FROM ddps.flowspecrules
        $sql = "SELECT EXTRACT(dow FROM createdon) as days, count(DISTINCT createdon) FROM ddps.flowspecrules
                WHERE createdon > now() - interval '6 days'
                GROUP BY days ORDER BY days";
        $result = $dbObj->getRows($sql, $data=array());
        return $result;
    }
}