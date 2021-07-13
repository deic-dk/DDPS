<?php

include_once ('Systeminfo.class.lib.php');
session_start();

$objSys = new Systeminfo();
if(!empty($_POST["mdate"]) && !empty($_POST["systemid"])) {
    $status = $objSys->updateDate($_POST["mdate"], $_POST["systemid"]);
    if($status) {
        echo "<span class='status-available'> Date Updated Successfully.</span>";
    } else {
        echo "<span class='status-not-available'> Problem occured while updating.</span>";
    }
}

if(!empty($_POST["systemdesc"]) && !empty($_POST["systemid"])) {
    $status = $objSys->updateDesc($_POST["systemdesc"], $_POST["systemid"]);
    if($status) {
        echo "<span class='status-available'> Description Updated Successfully.</span>";
    } else {
        echo "<span class='status-not-available'> Problem occured while updating.</span>";
    }
}

?>