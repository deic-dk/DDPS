<?php
//$hostName = "localhost"; // Host name
//$userName="postgres"; // PGsql username
//$dbName="netflow";
//$dbPass="root"; // Database name*/
 //$db = pg_connect('host=91.221.207.210 dbname=sigmaoprisk user=bluepipe ');
/*try {
	$dbConnect = new PDO("pgsql:dbname=$dbName; host=$hostName", "$userName ");
	//echo "PDO connection object created";
    }catch(PDOException $e){
	echo $e->getMessage();
    }*/
    /*

    include ('dboperations.php');
    $dbObj= new db($hostName,$dbName,$userName);
	$sqlBusinessLine = "SELECT  *  FROM  listbusinessline";

	//$businessline = pg_query($db,$sqlBusinessLine);
  $result = $dbObj->getRows($sqlBusinessLine,$data=array());
  if ($result){
	echo "Success ful";
foreach ($result as $val) {
		echo $val['businessline'];
}
  }else{

  }
	/*while($row = pg_fetch_array($result)) { //Loop all the options retrieved from the query
		 echo $row['businessline'];
	}*/



?>
