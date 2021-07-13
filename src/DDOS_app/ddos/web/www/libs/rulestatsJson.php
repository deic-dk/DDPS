<?php

session_start();
require( 'Flowspecrules.class.lib.php' );
$objFlowSpecRule = new Flowspecrules();

$result = $objFlowSpecRule->ruleStats();

// Adding Missing days of week
if(in_array(2, array_column($result, 'days')) == false) { // search value in the array
    array_push($result, array("days" => 2, "count" => 0));
}
if (in_array(3, array_column($result, 'days')) == false) {
    array_push($result, array("days" => 3, "count" => 0));
}
if (in_array(4, array_column($result, 'days')) == false) {
   array_push($result, array("days" => 4, "count" => 0));
}
if (in_array(5, array_column($result, 'days')) == false) {
    array_push($result, array("days" => 5, "count" => 0));
}
if (in_array(6, array_column($result, 'days')) == false) {
    array_push($result, array("days" => 6, "count" => 0));
}
if (in_array(7, array_column($result, 'days')) == false) {
    array_push($result, array("days" => 7, "count" => 0));
}
if (in_array(1, array_column($result, 'days')) == false) {
    array_push($result, array("days" => 1, "count" => 0));
}

$startday = date('w');

// Sorting the array
usort($result, function($a, $b) {
    return $a['days'] - $b['days'];
});

// Sorting array according to day of the week.
$temp = array_slice($result, $startday);
$temp1 = array_slice($result, 0, $startday);
$sortedResults = array_merge($temp,$temp1);

$jsonArray = array();

// Converting numbers to days of week
if ($sortedResults) {
    foreach ($sortedResults as $row) {
        $jsonArrayItem = array();
         if ($row['days'] == 7){
            $row['days'] = "Sunday";
        }
        if ($row['days'] == 1){
            $row['days'] = 'Monday';
        }
        if ($row['days'] == 2){
            $row['days'] = 'Tuesday';
        }
        if ($row['days'] == 3){
            $row['days'] = 'Wednesday';
        }
        if ($row['days'] == 4){
            $row['days'] = 'Thursday';
        }
        if ($row['days'] == 5){
            $row['days'] = 'Friday';
        }
        if ($row['days'] == 6){
            $row['days'] = 'Saturday';
        }
        $jsonArrayItem['label'] = $row['days'];
        $jsonArrayItem['value'] = $row['count'];
        array_push($jsonArray, $jsonArrayItem);
    }
} else {
    $jsonArrayItem = array();
    $jsonArrayItem['label'] = "";
    $jsonArrayItem['value'] = 0;
    array_push($jsonArray, $jsonArrayItem);
}

//set the response content type as JSON
header('Content-type: application/json');
//output the return value of json encode using the echo function.
echo json_encode($jsonArray);
?>