 $(document).ready(function() {
 $('#startdate').datetimepicker();
 $('#enddate').datetimepicker();

    $("#byaction").hide();
    $("#date").hide();

    $("#filter").change(function () {
        var value = $("#filter").val();
        if (value == "1"){
             $("#byaction").show();
             $("#date").hide();
             $('#enddate').val("");
             $('#startdate').val("");
        }
        if (value == "2"){
            $("#byaction").hide();
            $("#date").show();
        }
        if (value == ""){
            $("#byaction").hide();
            $("#date").hide();
            $('#enddate').val("");
            $('#startdate').val("");
            ('#thenaction').val("");
        }
    });
});