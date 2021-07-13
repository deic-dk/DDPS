$(document).ready(function () {

    $('#updateuser').click(function() {
		 $("#listboxfrom").find("option").each(function() {
            $(this).attr('selected', true);
        });
	});

    $("edituserform").submit(function(){
        $("#listboxfrom").find("option").each(function() {
            $(this).attr('selected', true);
        });
    });

   $("#moveLeft").click(function(){
		$("#listboxfrom > option:selected").each(function(){
			$(this).remove().appendTo("#listboxto");
			$("#listboxfrom").find('option').attr('selected',true);
		});
	});

	$("#moveRight").click(function(){
		$("#listboxto > option:selected").each(function(){
			$(this).remove().appendTo("#listboxfrom");
		});
	});

	$("#assignNetwork").hide();

	$("#admintype").change(function () {
        var value = $("#admintype").val();
        if (value == 3){
            $("#assignNetwork").show();
        } else{
            $("#assignNetwork").hide();
        }
    });

    $('#createuser').click(function() {
		$("#listboxfrom").find('option').attr('selected',true);
	});

    var value = $("#admintype").val();
    if (value == 3){
        $("#assignNetwork").show();
    }else{
        $("#assignNetwork").hide();
    }

    $("#customer").change(function () {
        var custid = $("#customer").val();
        $.ajax({
			type:"post",
			url:"../libs/customerNetworkList.php",
			data:"custid="+custid,
			success:function(data){
                var opts = $.parseJSON(data);
                $('#listboxto').empty();
			    $.each(opts, function(index, value) {
                       $('#listboxto').append('<option value="' + value.networkid + '">' + value.net + '</option>');
                });
			}
		});
    });
   $("#conpass").change(checkPasswordMatch);
});


function checkAvailability() {
    jQuery.ajax({
    url: "../libs/checkuser.php",
    data:'username='+$("#username").val(),
    type: "POST",
    success:function(data){
        $("#user-availability-status").html(data);
    },
    error:function (){
        $("#username").val("");
        }
    });
}

function checkPasswordMatch() {
    var password = $("#pass").val();
    var confirmPassword = $("#conpass").val();
    if (password != confirmPassword){
        alert("Passwords does not match!");
        $("#conpass").val("");
    }
}
