<?php

require('/usr/local/lib/php/smarty/libs/Smarty.class.php');
include ('libs/User.class.lib.php');
include ('libs/Customer.class.lib.php');
include ('libs/Network.class.lib.php');
include ('libs/Flowspecrules.class.lib.php');
include ('libs/Lists.class.lib.php');
include ('libs/Myalert.class.lib.php');
include ('libs/Systeminfo.class.lib.php');
include ('libs/Ruletemplate.class.lib.php');

openlog("myScriptLog", LOG_PID | LOG_PERROR, LOG_LOCAL0);

session_start();
$smarty = new Smarty();
$objUser = new User();
$objCustomer = new Customer();
$objNetwork = new Network();
$objFlowSpecRule = new Flowspecrules();
$objSysInfo = new Systeminfo();
$objList = new Lists();
$objAlert = new Myalert();
$objTemplRule = new Ruletemplate();

$smarty->setTemplateDir('../smarty/templates');
$smarty->setCompileDir('../smarty/templates_c');
$smarty->setCacheDir('../smarty/cache');
$smarty->setConfigDir('../smarty/configs');

$countNetworks = count($objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid'])); // Keep Track of networks assigned to NetAdmin

if (isset($_POST['logout'])) {
	syslog(LOG_WARNING, "DDOS_app: Successful logout: remote ip: {$_SERVER['REMOTE_ADDR']} agent: ({$_SERVER['HTTP_USER_AGENT']})");
    session_unset();
    session_destroy ();
    header("Location: index.php");
}

if (isset($_POST['username']) && isset($_POST['pass']) && !isset($_SESSION['role']) ) {
    $username = $_POST['username'];
    $pass = $_POST['pass'];
    $result = $objUser->validateUser($username, $pass);
    if (!$result) {
		syslog(LOG_WARNING, "DDOS_app: Failed Login: username: '$username' password: '$pass' remote ip: {$_SERVER['REMOTE_ADDR']} agent: ({$_SERVER['HTTP_USER_AGENT']})");
    } else {
		syslog(LOG_WARNING, "DDOS_app: Successful Login: username: '$username' password: 'XXXXXXXXXX' remote ip: {$_SERVER['REMOTE_ADDR']} agent: ({$_SERVER['HTTP_USER_AGENT']})");
        header("Location: index.php");
    }
}

if (!isset($_SESSION['role'])) {
    $smarty->display('dashboard_login.tpl');
} else {
    if ($_SESSION['role'] == 1) {
        $smarty->display('Dashboard_gadmin.tpl');
    }
    if($_SESSION['role'] == 2) {
        $smarty->display('Dashboard_locadmin.tpl');
    }
    if ($_SESSION['role'] == 3) {
        $smarty->display('Dashboard_netadmin.tpl');
    }
    if ($_SESSION['role'] == 4) {
        $smarty->display('Dashboard_reader.tpl');
    }
    if ($_SESSION['role'] == 5) {
        $smarty->display('Dashboard_greader.tpl');
    }

    if (isset($_POST['createuser'])) {
        $result = $objUser->insertUser($_POST);
        if ($result == TRUE) {
            $objAlert->notification("User Created Successfully", "success");
            $smarty->display('allusers.tpl');
            exit();
        }
    }
    if (isset($_POST['updateuser'])) {
        $result = $objUser->updateUser($_POST);
        if ($result == TRUE) {
            $objAlert->notification("User Updated Successfully", "success");
        }
    }

     if (isset($_POST['updatepass'])) {
        $result = $objUser->updatePassUser($_POST);
        if ($result == TRUE) {
                $objAlert->notification("Password Updated Successfully", "success");
                $smarty->display('allusers.tpl');
                exit();
        }
    }

    if (isset($_POST['createcustomer'])) {
        $result = $objCustomer->insertCustomer($_POST);
        if ($result == TRUE) {
            $objAlert->notification("Customer Created Successfully", "success");
            $smarty->display('allcustomers.tpl');
            exit();
        }
    }
    if (isset($_POST['updatecustomer'])) {
        $result = $objCustomer->updateCustomer($_POST);
        if ($result == TRUE) {
            $objAlert->notification("Customer Updated Successfully", "success");
        }
    }

    if (isset($_POST['createbasicnet'])) {
        $result = $objNetwork->insertbasicnetwork($_POST);
        if ($result == TRUE) {
            $objAlert->notification("Basic Network Created Successfully", "success");
            $smarty->display('allnetworks.tpl');
            exit();
        }
    }
    if (isset($_POST['createnetwork'])) {
        $result = $objNetwork->insertnetwork($_POST);
        if ($result == TRUE) {
            $objAlert->notification("Network Created Successfully", "success");
            $smarty->display('allnetworks.tpl');
            exit();
        }
    }

    if (isset($_POST['updatebasicnetwork'])) {
        $result = $objNetwork->updatebasicnetwork($_POST);
        if ($result == TRUE) {
            $objAlert->notification("Network Updated Successfully", "success");
        }
    }

    if (isset($_POST['createrule'])) {
        $mrules = $objCustomer->maxRules($_SESSION['customerid']);
        $crules = $objFlowSpecRule->countRules($_SESSION['customerid']);
        if ($crules < $mrules) {
            $result = $objFlowSpecRule->insertRule($_POST);
            if ($result == TRUE) {
                $objAlert->notification("Rule Created Successfully", "success");
                $smarty->display('allrules.tpl');
                exit();
            } else {
                $objAlert->notification("Error Unable to Create rule. Try again", "error");
            }
        } else {
            $objAlert->notification("You are exceeding Max Rule Limit of ".$mrules.". Either expire some rules or contact Global Admin", "error");
            $smarty->display('allrules.tpl');
            exit();
        }
    }

    if (isset($_POST['tplrule'])) {
        if ($_POST['templatetype'] == 1) {
            $mrules = $objCustomer->maxRules($_SESSION['customerid']);
            $crules = $objFlowSpecRule->countRules($_SESSION['customerid']);
            $crules = $crules+2;
            if ($crules < $mrules) {
                $result = $objTemplRule->webserver($_POST);
                if ($result == TRUE) {
                    $objAlert->notification("Rules added to Block Webserver", "success");
                    $smarty->display('allrules.tpl');
                    exit();
                } else {
                    $objAlert->notification("Error Unable to Create rule. Try again", "error");
                }
            } else {
                $objAlert->notification("You are exceeding Max Rule Limit of ".$mrules.". Either expire some rules or contact Global Admin", "error");
                $smarty->display('allrules.tpl');
                exit();
            }
        }
        if ($_POST['templatetype'] == 2) {
            $mrules = $objCustomer->maxRules($_SESSION['customerid']);
            $crules = $objFlowSpecRule->countRules($_SESSION['customerid']);
            $crules = $crules+2;
            if ($crules < $mrules) {
                $result = $objTemplRule->smtpserver($_POST);
                if ($result == TRUE) {
                    $objAlert->notification("Rules added to Block SMTP Server", "success");
                    $smarty->display('allrules.tpl');
                    exit();
                } else {
                    $objAlert->notification("Error Unable to Create rule. Try again", "error");
                }
            } else {
                $objAlert->notification("You are exceeding Max Rule Limit of ".$mrules.". Either expire some rules or contact Global Admin", "error");
                $smarty->display('allrules.tpl');
                exit();
            }
        }
        if ($_POST['templatetype'] == 3) {
            $mrules = $objCustomer->maxRules($_SESSION['customerid']);
            $crules = $objFlowSpecRule->countRules($_SESSION['customerid']);
            $crules = $crules+2;
            if ($crules < $mrules) {
                 $result = $objTemplRule->dnsdomainserver($_POST);
                if ($result == TRUE) {
                    $objAlert->notification("Rules added to Block DNS Domain Server", "success");
                    $smarty->display('allrules.tpl');
                    exit();
                } else {
                    $objAlert->notification("Error Unable to Create rule. Try again", "error");
                }
            } else {
                $objAlert->notification("You are exceeding Max Rule Limit of ".$mrules.". Either expire some rules or contact Global Admin", "error");
                $smarty->display('allrules.tpl');
                exit();
            }
        }
        if ($_POST['templatetype'] == 4) {
            $mrules = $objCustomer->maxRules($_SESSION['customerid']);
            $crules = $objFlowSpecRule->countRules($_SESSION['customerid']);
            $crules = $crules+2;
            if ($crules < $mrules) {
                 $result = $objTemplRule->ntptimeserver($_POST);
                if ($result == TRUE) {
                    $objAlert->notification("Rules added to Block NTP time Server", "success");
                    $smarty->display('allrules.tpl');
                    exit();
                } else {
                    $objAlert->notification("Error Unable to Create rule. Try again", "error");
                }
            } else {
                $objAlert->notification("You are exceeding Max Rule Limit of ".$mrules.". Either expire some rules or contact Global Admin", "error");
                $smarty->display('allrules.tpl');
                exit();
            }
        }

    }

    if (!empty($_GET["action"])) {
        $action = $_GET["action"];
        switch ($action) {
            case "show-rules":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 4 ||  $_SESSION['role'] == 5 || $_SESSION['role'] == 3 && $countNetworks > 0) {
                    $result = $objFlowSpecRule->allRules($_SESSION['customerid'], $_SESSION['adminid']);
                    $allNetworks = $objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid']);
                    $smarty->assign("allNetworks", $allNetworks);
                    $smarty->assign("result", $result);
                    $smarty->display('allrules.tpl');
                }
                break;

            case "rule-add":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 3 && $countNetworks > 0) {
                    $tcpflags=$objList->listTcpFlags();
                    $smarty->assign("tcpflags", $tcpflags);
                    $protocols = $objList->listProtocols();
                    $smarty->assign("protocols", $protocols);
                    $fragments = $objList->listFragments();
                    $smarty->assign("fragments", $fragments);
                    $thenActions = $objList->listThenActions();
                    $smarty->assign("thenActions", $thenActions);
                    $allNetworks = $objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid']);
                    $smarty->assign("allNetworks", $allNetworks);
                    $smarty->display('addrules.tpl');
                } else {
                   header("Location: index.php");
                }
                break;

            case "rule-deactivate":
                $ruleid = $_GET["id"];
                $result = $objFlowSpecRule->expireRule($ruleid);
                if ($result == TRUE) {
                    $objAlert->notification("Rule Expired Successfully", "success");
                    $result = $objFlowSpecRule->allRules($_SESSION['customerid'], $_SESSION['adminid']);
                    $smarty->assign("result", $result);
                    $smarty->display('allrules.tpl');
                } else {
                    $objAlert->notification("Error Unable to Expire rule. Try again", "error");
                    $result = $objFlowSpecRule->allRules($_SESSION['customerid'], $_SESSION['adminid']);
                    $smarty->assign("result", $result);
                    $smarty->display('allrules.tpl');
                    header("Location: index.php?action=show-rules");
                    $objAlert->notification("Rule Expired Successfully", "success");
                }
                break;

            case "rule-edit":
                $ruleid = $_GET["id"];
                $result = $objFlowSpecRule->showRule($ruleid);
                $smarty->assign("result", $result);
                $smarty->display('editrule.tpl');
                break;

            case "search-rules":
                $thenActions = $objList->listThenActions();
                $smarty->assign("thenActions", $thenActions);
                $smarty->display('searchrules.tpl');
                break;

            case "show-users":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2) {
                    $smarty->display('allusers.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "user-add":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2) {
                    $allcustomers = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                    $smarty->assign("allcustomers", $allcustomers);
                    $options = $objList->listOptions();
                    $smarty->assign("options", $options);
                    $networks = $objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid']);
                    $smarty->assign("networks", $networks);
                    $smarty->display('adduser.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "user-edit":
                $temp = array();
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2) {
                    $userid = $_GET["id"];
                    $result = $objUser->getuser($userid);
                    $smarty->assign("result", $result);
                    $allcustomers = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                    $smarty->assign("allcustomers", $allcustomers);
                    $options = $objList->listOptions();
                    $smarty->assign("options", $options);
                    $networks = $objNetwork->customernetworks($result[0]['customerid']);
                    for ($i = 0; $i < count($result); $i++ ) {
                       foreach ($networks as $key=>$value) {
                         if ($result[$i]['network_id']) {
                                if (in_array($result[$i]['network_id'], $value)) {
                                    array_push ($temp, $value);
                                    unset($networks[$key]);
                                }
                            }
                        }
                    }
                    $smarty->assign("networks", $networks);
                    $smarty->display('edituser.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "user-changepass":
                $temp = array();
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2) {
                    $userid = $_GET["id"];
                    $smarty->assign("userid", $userid );
                    $smarty->display('chgpass.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "user-delete":
                $userid = $_GET["id"];
                $result = $objUser->deleteuser($userid);
                if ($result == TRUE) {
                    $objAlert->notification("User Deleted", "success");
                } else {
                    $objAlert->notification("Error Unable to Delete the user", "error");
                }
                $result = $objUser->allUsers($_SESSION['customerid'], $_SESSION['role']);
                $smarty->assign("result", $result);
                $smarty->display('allusers.tpl');
                break;

            case "show-customers":
                if ($_SESSION['role'] == 1) {
                    $smarty->display('allcustomers.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "customer-add":
                if ($_SESSION['role'] == 1) {
                    $smarty->display('addcustomer.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "customer-edit":
                if ($_SESSION['role'] == 1) {
                    $customerid = $_GET["id"];
                    $result = $objCustomer->getcustomer($customerid);
                    $smarty->assign("result", $result);
                    $smarty->display('editcustomer.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "customer-delete":
                $customerid = $_GET["id"];
                $result = $objCustomer->deletecustomer($customerid);
                if ($result == TRUE) {
                    $objAlert->notification("Customer deleted", "success");
                } else {
                    $objAlert->notification("Error Unable to delete the customer", "error");
                }
                $result = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                $smarty->assign("result", $result);
                $smarty->display('allcustomers.tpl');
                break;

            case "show-networks":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 4 ||  $_SESSION['role'] == 5  || $_SESSION['role'] == 3 && $countNetworks > 0) {
                    $smarty->display('allnetworks.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "network-add":
                 if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 3 && $countNetworks > 0) {
                     $allcustomers = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                     $smarty->assign("allcustomers", $allcustomers);
                     $nettype = $objList->getnetworktype();
                     $smarty->assign("nettype", $nettype);
                     $allNetworks = $objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid']);
                     $smarty->assign("allNetworks", $allNetworks);
                     $smarty->display('addnetwork.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "basicnetwork-add":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 3 && $countNetworks > 0) {
                    $allcustomers = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                    $allcustomers = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                    $smarty->assign("allcustomers", $allcustomers);
                    $nettype = $objList->getnetworktype();
                    $smarty->assign("nettype", $nettype);
                    $smarty->display('addbasicnetwork.tpl');
                } else{
                     header("Location: index.php");
                }
                break;

            case "network-edit":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 3 && $countNetworks > 0) {
                    $networkid = $_GET["id"];
                    $result = $objNetwork->getbasicnetwork($networkid);
                    $smarty->assign("result", $result);
                    $allcustomers = $objCustomer->allCustomers($_SESSION['customerid'], $_SESSION['role']);
                    $smarty->assign("allcustomers", $allcustomers);
                    $nettype = $objList->getnetworktype();
                    $smarty->assign("nettype", $nettype);
                    $smarty->display('editbasicnetwork.tpl');
                } else {
                    header("Location: index.php");
                }
                break;

            case "network-delete":
                $networkid = $_GET["id"];
                $result = $objNetwork->deletebasicnetwork($networkid);
                if ($result == TRUE) {
                    $objAlert->notification("Network deleted", "success");
                } else {
                    $objAlert->notification("Error Unable to delete the network", "error");
                }
                $result = $objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid']);
                $smarty->assign("result", $result);
                $smarty->display('allnetworks.tpl');
                break;

            case "systeminfo-edit":
                $statusid = $_GET["id"];
                $sysInfo = $objSysInfo->getSystemInfo($statusid);
                $smarty->assign("sysInfo", $sysInfo);
                $smarty->display('systeminfo.tpl');
                break;

            case "master-data":
               // $sysInfo = $objSysInfo->getMasterData($statusid);
                $mrules = $objCustomer->maxRules($_SESSION['customerid']);
                $crules = $objFlowSpecRule->countRules($_SESSION['customerid']);
                $frules = $objCustomer->getRuleFluc($_SESSION['customerid']);
                $cfrule = $objCustomer->getCurrFluc($_SESSION['customerid']);
                $smarty->assign("mrules", $mrules);
                $smarty->assign("crules", $crules);
                $smarty->assign("frules", $frules);
                $smarty->assign("cfrule", $cfrule);
                //$smarty->assign("masterdata", $masterdata);
                $smarty->display('masterdata.tpl');
                break;

            case "template-rules":
                if ($_SESSION['role'] == 1 ||  $_SESSION['role'] == 2 || $_SESSION['role'] == 3 && $countNetworks > 0) {
                    $allNetworks = $objNetwork->allbasicnetworks($_SESSION['customerid'], $_SESSION['role'], $_SESSION['adminid']);
                    $smarty->assign("allNetworks", $allNetworks);
                    $smarty->display('templaterules.tpl');
                } else {
                    header("Location: index.php");
                }
                break;
        }
    }
}
//print_r($_SESSION);
closelog();

?>
