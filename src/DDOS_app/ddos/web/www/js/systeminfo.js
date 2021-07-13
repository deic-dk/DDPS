$(document).ready(function() {
    $( function() {
        $("#mdate").datetimepicker({dateFormat: 'yy-mm-dd'});
    });
});

function updateDate() {
    jQuery.ajax({
    url: "../libs/updatesysinfo.php",
    data:'mdate='+$("#mdate").val()+'&systemid='+$("#systemid").val(),
    type: "POST",
    success:function(data){
        $("#date-status").html(data);
    },
    error:function (){}
    });
}

function updateDescription() {
    jQuery.ajax({
    url: "../libs/updatesysinfo.php",
    data:'systemdesc='+$("#systemdesc").val()+'&systemid='+$("#systemid").val(),
    type: "POST",
    success:function(data){
        $("#desc-status").html(data);
    },
    error:function (){}
    });
}