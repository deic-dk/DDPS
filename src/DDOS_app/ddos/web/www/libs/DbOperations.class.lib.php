<?php

include_once('DbConnection.class.lib.php');

class DbOperations extends PDO {
    protected $dbConnect;
    public function __construct() {
        $con = new DbConnection();
        $this->dbConnect = $con->dbCon();
    }

    public function Disconnect() {
        $this->dbConnect = null;
        $this->isConnected = false;
    }

    public function getRow($query, $params=array()) {
        try {
            $stmt = $this->dbConnect->prepare($query);
            $stmt->execute($params);
            return $stmt->fetch();
        } catch(PDOException $e) {
                throw new Exception($e->getMessage());
        }
    }

    public function getRows($query, $params=array()) {
        try {
            $stmt = $this->dbConnect->prepare($query);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch(PDOException $e) {
            echo $e->getMessage();
        }
    }

    public function insertRow($query, $params=array()) {
        try{
            $stmt = $this->dbConnect->prepare($query);
            if ($stmt->execute($params)){
                return TRUE;
            }
            //return $stmt->fetch();
        } catch(PDOException $e) {
			return FALSE;
		}
    }

    public function insertRowCustom($query, $params=array()) {
        $stmt = $this->dbConnect->prepare($query);
        if ($stmt->execute($params)) {
            $adminid = $stmt->fetchColumn();
            return $adminid;
        } else {
            return FALSE;
        }
    }

    public function updateRow($query, $params) {
        return $this->insertRow($query, $params);
    }

    public function deleteRow($query, $params) {
        return $this->insertRow($query, $params);
    }

}

?>