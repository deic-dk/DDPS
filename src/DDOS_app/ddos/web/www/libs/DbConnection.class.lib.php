<?php

Class DbConnection {
    private $userName ;
    private $hostname;
    private $dbUser ;
    private $dbName;

    public function __construct() {
        /*$this->userName = "postgres";
        $this->hostName = "localhost";
        $this->dbPass = "1qazxsw2";
        $this->dbName = "flows";*/
        $ini_array = parse_ini_file("/opt/db2bgp/etc/ddps.ini", true /* will scope sectionally */);
        $this->userName = $ini_array['general']['dbuser'];
        $this->hostName = $ini_array['general']['dbhost'];
        $this->dbPass   = $ini_array['general']['dbpassword'];
        $this->dbName   = $ini_array['general']['dbname'];
    }

    public function dbCon() {
        $dbConnect = new PDO("pgsql:dbname=$this->dbName; host=$this->hostName", $this->userName, $this->dbPass);
        return $dbConnect;
    }
}

?>