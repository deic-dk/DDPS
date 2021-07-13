<?php

include_once ('DbOperations.class.lib.php');

class ruletemplate {
    public $config = array();

    public function __construct() {
         $this->config =  [
             'webserver' => [
                 'action_1' => 'discard',
                 'pnumber' => '<=5&>=7',
                 'action_2' => 'discard',
                 'action_3' => 'discard',
                 'destport' => '<=79 >=81&<=442 >=444',
                 'fencoding' => 'is-fragment dont-fragment first-fragment last-fragment'
             ],
             'smtpserver' => [
                 'action_1' => 'discard',
                 'pnumber' => '<=5&>=7',
                 'action_2' => 'discard',
                 'action_3' => 'discard',
                 'destport' => '<=23 >=26',
                 'fencoding' => 'is-fragment dont-fragment first-fragment last-fragment'
             ],
             'dnsdomainserver' => [
                 'action_1' => 'discard',
                 'pnumber' => '<=16&>=18',
                 'action_2' => 'discard',
                 'action_3' => 'discard',
                 'destport' => '<=52 >=54',
                 'fencoding' => 'is-fragment dont-fragment first-fragment last-fragment'
             ],
              'ntptimeserver' => [
                 'action_1' => 'discard',
                 'pnumber' => '<=16&>=18',
                 'action_2' => 'discard',
                 'action_3' => 'discard',
                 'destport' => '<=122 >=124',
                 'fencoding' => 'is-fragment dont-fragment first-fragment last-fragment'
            ],
        ];
    }

    public static function webserver($data) {
        $dbObj = new DbOperations();
        $customer_id = $_SESSION['customerid'];
        $adminid = $_SESSION['adminid'];
        if(empty($data[srcaddress])){
            $srcAddress = 'NULL';
        } else {
           $srcAddress = trim($data[srcaddress]);
           $srcAddress = "'".$srcAddress."'";
        }

        $objTemplRule = new Ruletemplate();
        $thenaction_1 = $objTemplRule->config['webserver']['action_1'];
        $thenaction_2 = $objTemplRule->config['webserver']['action_2'];
        $thenaction_3 = $objTemplRule->config['webserver']['action_3'];
        $destport = $objTemplRule->config['webserver']['destport'];
        $pnumber = $objTemplRule->config['webserver']['pnumber'];
        $fencoding = $objTemplRule->config['webserver']['fencoding'];

        $sql = "INSERT INTO ddps.flowspecrules(
	            flowspecruleid, description, validfrom, validto, isactivated, isexpired, direction, destinationprefix, sourceprefix, ipprotocol, destinationport, sourceport, tcpflags, packetlength, fragmentencoding, thenaction, uuid_customerid, uuid_administratorid, sourceapp, notification, createdon)
	            VALUES
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '', '', '', '', '$fencoding', '$thenaction_1', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '$pnumber', '', '', '', '', '', '$thenaction_2', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '$destport', '', '', '', '', '$thenaction_3', '$customer_id','$adminid', 'ruletemplate', 'Pending', now())";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function smtpserver($data) {
        $dbObj = new DbOperations();
        $customer_id = $_SESSION['customerid'];
        $adminid = $_SESSION['adminid'];
        if(empty($data[srcaddress])){
            $srcAddress = 'NULL';
        } else {
           $srcAddress = trim($data[srcaddress]);
           $srcAddress = "'".$srcAddress."'";
        }

        $objTemplRule = new Ruletemplate();
        $thenaction_1 = $objTemplRule->config['smtpserver']['action_1'];
        $thenaction_2 = $objTemplRule->config['smtpserver']['action_2'];
        $thenaction_3 = $objTemplRule->config['smtpserver']['action_3'];
        $destport = $objTemplRule->config['smtpserver']['destport'];
        $pnumber = $objTemplRule->config['smtpserver']['pnumber'];
        $fencoding = $objTemplRule->config['smtpserver']['fencoding'];

        $sql = "INSERT INTO ddps.flowspecrules(
	            flowspecruleid, description, validfrom, validto, isactivated, isexpired, direction, destinationprefix, sourceprefix, ipprotocol, destinationport, sourceport, tcpflags, packetlength, fragmentencoding, thenaction, uuid_customerid, uuid_administratorid, sourceapp, notification, createdon)
	            VALUES
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '', '', '', '', '$fencoding', '$thenaction_1', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '$pnumber', '', '', '', '', '', '$thenaction_2', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '$destport', '', '', '', '', '$thenaction_3', '$customer_id','$adminid', 'ruletemplate', 'Pending', now())";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function dnsdomainserver($data) {
        $dbObj = new DbOperations();
        $customer_id = $_SESSION['customerid'];
        $adminid = $_SESSION['adminid'];
        if(empty($data[srcaddress])){
            $srcAddress = 'NULL';
        } else {
           $srcAddress = trim($data[srcaddress]);
           $srcAddress = "'".$srcAddress."'";
        }

        $objTemplRule = new Ruletemplate();
        $thenaction_1 = $objTemplRule->config['dnsdomainserver']['action_1'];
        $thenaction_2 = $objTemplRule->config['dnsdomainserver']['action_2'];
        $thenaction_3 = $objTemplRule->config['dnsdomainserver']['action_3'];
        $destport = $objTemplRule->config['dnsdomainserver']['destport'];
        $pnumber = $objTemplRule->config['dnsdomainserver']['pnumber'];
        $fencoding = $objTemplRule->config['dnsdomainserver']['fencoding'];

        $sql = "INSERT INTO ddps.flowspecrules(
	            flowspecruleid, description, validfrom, validto, isactivated, isexpired, direction, destinationprefix, sourceprefix, ipprotocol, destinationport, sourceport, tcpflags, packetlength, fragmentencoding, thenaction, uuid_customerid, uuid_administratorid, sourceapp, notification, createdon)
	            VALUES
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '', '', '', '', '$fencoding', '$thenaction_1', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '$pnumber', '', '', '', '', '', '$thenaction_2', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '$destport', '', '', '', '', '$thenaction_3', '$customer_id','$adminid', 'ruletemplate', 'Pending', now())";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public static function ntptimeserver($data) {
        $dbObj = new DbOperations();
        $customer_id = $_SESSION['customerid'];
        $adminid = $_SESSION['adminid'];
        if(empty($data[srcaddress])){
            $srcAddress = 'NULL';
        } else {
           $srcAddress = trim($data[srcaddress]);
           $srcAddress = "'".$srcAddress."'";
        }

        $objTemplRule = new Ruletemplate();
        $thenaction_1 = $objTemplRule->config['ntptimeserver']['action_1'];
        $thenaction_2 = $objTemplRule->config['ntptimeserver']['action_2'];
        $thenaction_3 = $objTemplRule->config['ntptimeserver']['action_3'];
        $destport = $objTemplRule->config['ntptimeserver']['destport'];
        $pnumber = $objTemplRule->config['ntptimeserver']['pnumber'];
        $fencoding = $objTemplRule->config['ntptimeserver']['fencoding'];

        $sql = "INSERT INTO ddps.flowspecrules(
	            flowspecruleid, description, validfrom, validto, isactivated, isexpired, direction, destinationprefix, sourceprefix, ipprotocol, destinationport, sourceport, tcpflags, packetlength, fragmentencoding, thenaction, uuid_customerid, uuid_administratorid, sourceapp, notification, createdon)
	            VALUES
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '', '', '', '', '$fencoding', '$thenaction_1', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '$pnumber', '', '', '', '', '', '$thenaction_2', '$customer_id','$adminid', 'ruletemplate', 'Pending', now()),
	            (gen_random_uuid(), '$data[ruledesc]', '$data[fromdate]', '$data[expdate]', false, false, 'in', '$data[cidr]', $srcAddress, '', '$destport', '', '', '', '', '$thenaction_3', '$customer_id','$adminid', 'ruletemplate', 'Pending', now())";

        $result = $dbObj->insertRow($sql, $data=array());
        return  $result;
    }

    public function getAllPnumbers ($configstr) {
        $str = explode("&", $configstr);
        $temp = preg_replace("/[^0-9]/", '', $str[0]);
        $temp1 = preg_replace("/[^0-9]/", '', $str[1]);
        $allPnumbers =  "";
        for ($i = 1; $i <= $temp; $i++) {
            $allPnumbers .= "=".$i." ";
        }
        for ($i = $temp1; $i < 255; $i++) {
            $allPnumbers .= "=".$i." ";
        }
        return $allPnumbers;
    }

}