 $(document).ready(function() {
    $("#tcp").hide();
    $("#icmp").hide();
    $("#other").hide();
    $("#tcpflag").hide();
    $("#chkdstadress").hide();

    $("#protocol").change(function () {
        var value = $(this).find('option:selected').attr("id");
        if (value == "6"){
             $("#tcp").show();
             $("#tcpflag").show();
             $("#icmp").hide();
             $("#other").hide();
        }
        else if (value == "17"){
            $("#tcp").show();
            $("#icmp").hide();
            $("#other").hide();
            $("#tcpflag").hide();
        }
        else if (value == "1"){
             $("#icmp").show();
             $("#other").hide();
             $("#tcpflag").hide();
             $("#tcp").hide();
        }
        else if (value == "555"){
             $("#other").show();
             $("#tcp").hide();
             $("#icmp").hide();
             $("#tcpflag").hide();
        }
        else if (value == ""){
             $("#tcp").hide();
             $("#tcpflag").hide();
             $("#icmp").hide();
             $("#other").hide();
        } else {
            $("#tcp").hide();
            $("#icmp").hide();
            $("#other").hide();
            $("#tcpflag").hide();
            $("#chkdstadress").hide();
        }
    });

    $(function(){
        var d = new Date();
        var time = d.getMinutes()+10;
        var hour;
        var dt;
        var dom;
        if (time > 59) {
            time = time%60;
            hour = d.getHours()+1;
            if (hour > 23) {
                dom =  d.getDate()+1;
            } else {
                dom =  d.getDate();
            }
            dt = d.getFullYear()  + "-" + (d.getMonth()+1) + "-" + dom + " " + hour + ":" + time;
        } else {
            dt = d.getFullYear()  + "-" + (d.getMonth()+1) + "-" + d.getDate() + " " +d.getHours() + ":" + time;
        }
        $("#expdate").datetimepicker({}).val(dt);
        $("#expdate1").datetimepicker({})
    });

    $(function(){
        var d = new Date();
        var dt = d.getFullYear()  + "-" + (d.getMonth()+1) + "-" + d.getDate() + " " +d.getHours() + ":" + d.getMinutes();
        $('#fromdate').datetimepicker({}).val(dt);
    });

    $("#srcopt").change(function () {
       var value = $("#srcopt").val();
       if (value == "-"){
             $("#srcport2").removeAttr("readonly");
             $("#srcport2").removeClass("readonly");
       }else{
             $("#srcport2").attr("readonly",true);
             $("#srcport2").addClass("readonly");
       }
    });

    $("#dstopt").change(function () {
       var value = $("#dstopt").val();
       if (value == "-"){
             $("#dstport2").removeAttr("readonly");
             $("#dstport2").removeClass("readonly");
       }else{
             $("#dstport2").attr("readonly",true);
             $("#dstport2").addClass("readonly");
       }
    });
    $("#ruleform").submit(function(e){
        // Check If Date and Time is correct Add Rule
        var fromDate = $('#fromdate').val();
        fromDate = Date.parse(fromDate);
        var expDate = $('#expdate').val();
        expDate = Date.parse(expDate);

        if (fromDate >= expDate) {
            //alert("Expiry Date must be greater then From Date");
            Swal.fire({
                icon: 'error',
                title: 'Error...',
                text: 'Expiry Date must be greater then From Date!'
            })
            e.preventDefault();
        }

         var srcVal = $("#srcaddress").val();
         srcVal = jQuery.trim(srcVal);
            if (srcVal){
                var flag = validateCidr(srcVal);
                 if (flag==false) {
                    //alert('Invalid CIDR or IP in Source Address');
                    Swal.fire({
                        icon: 'error',
                        title: 'Error...',
                        text: 'Invalid CIDR or IP in Source Address'
                    })
                    e.preventDefault();
                }
            }

        var dstVal = $("#dstaddress").val();
        dstVal = dstVal.trim();
        if (dstVal){
            var flag=validateCidr(dstVal);
                var matched=false;
                if (flag==false) {
                    //alert("Invalid CIDR");
                    Swal.fire({
                        icon: 'error',
                        title: 'Error...',
                        text: 'Invalid CIDR!'
                    })
                    e.preventDefault();
                }
         }

        var srcport2 = $("#srcport2").val();
        if (srcport2){
             var srcport1 = $("#srcport1").val();
            if (parseInt(srcport1) > parseInt(srcport2)){
                //alert("SourcePort Value2 should be greater then SourcePort Value1");
                Swal.fire({
                    icon: 'error',
                    title: 'Error...',
                    text: 'SourcePort Value2 should be greater then SourcePort Value1!'
                })
                $("#srcport2").val("");
                e.preventDefault();
            }
        }

        var dstport2 = $("#dstport2").val();
        if (dstport2){
            var dstport1 = $("#dstport1").val();
            if (parseInt(dstport1) > parseInt(dstport2)){
                //alert("DestPort Value2 should be greater then DestPort Value1");
                Swal.fire({
                    icon: 'error',
                    title: 'Error...',
                    text: 'DestPort Value2 should be greater then DestPort Value1!'
                })
                $("#dstport2").val("");
                e.preventDefault();
            }
        }
    });

    var protocolVal = $('#protocol1').val();
    var typeVal = $('#icmptype1').val();
    var codeVal = $('#icmpcode1').val();
    if (protocolVal == "=1" && typeVal == "" && codeVal == ""){
        $('#icmptype1').val("All ICMPTypes INCLUDED");
        $('#icmpcode1').val("All ICMPCodes INCLUDED");
    }

});

function validateCidr(cidr){
    var temp = new RegExp('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$');
    var flag = temp.test(cidr);
    return flag;
}

function checkNetwork() {
    jQuery.ajax({
    url: "../libs/checknetwork.php",
    data:'cidr='+$("#cidr").val(),
    type: "POST",
    success:function(data){
    $("#network-availability-status").html(data);
    },
    error:function (){

    }
    });
}