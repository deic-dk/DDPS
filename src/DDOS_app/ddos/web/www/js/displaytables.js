$(document).ready(function() {
    var table;
    $("#statustable").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            if (aData[1].toLowerCase() == "ok") {
                $(nRow).css('color', 'green');
            } else if (aData[1].toLowerCase() == "host up") {
                $(nRow).css('color', 'green');
            } else {
                 $(nRow).css('color', 'red');
            }
        },
		"language": {
            "infoFiltered": ""
        },
        "ajax" : "../libs/statusJson.php"
    });

    $("#customertable").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"order": [[ 4, 'desc' ]],
		"columns"    : [
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': false,  "visible": false , "targets": [4]},
                { 'searchable': false }
            ],
		"language": {
            "infoFiltered": ""
        },
        "ajax" : "../libs/customerJson.php"
    });
     $("#customertableReader").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"order": [[ 4, 'desc' ]],
		"columns"    : [
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': false,  "visible": false , "targets": [4]}
            ],
		"language": {
            "infoFiltered": ""
        },
        "ajax" : "../libs/customerJson.php"
    });

    $("#usertable").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"order": [[ 4, 'desc' ]],
		"columns"    : [
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': false,  "visible": false , "targets": [4]},
                { 'searchable': false }
            ],
		"language": {
            "infoFiltered": ""
        },
        "ajax" : "../libs/usersJson.php"
    });
    $("#usertableReader").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"order": [[ 4, 'desc' ]],
		"columns"    : [
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': false,  "visible": false , "targets": [4]}
            ],
		"language": {
            "infoFiltered": ""
        },
        "ajax" : "../libs/usersJson.php"
    });

    $("#networktable").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"language": {
            "infoFiltered": ""
        },
        "ajax" : "../libs/networksJson.php"
    });

    var ruleTable = $("#ruletableReader").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"order": [[ 5, 'desc' ]],
		"language": {
            "infoFiltered": ""
        },
       /* "createdRow": function( row, data, dataIndex ) {
             if ( data[2] == "Pending" ) {
                    $(row).addClass('active');
                }
        },*/
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            if (aData[2].toLowerCase() == "pending") {
                $(nRow).css('color', 'orange');
            }
            else if (aData[2].toLowerCase() == "active") {
                $(nRow).css('color', 'green');
            } else if (aData[2].toLowerCase() == "expired"){
                $(nRow).css('color', 'grey');
            } else {
                 $(nRow).css('color', 'red');
            }
        },
		"columns"    : [
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': false,  "visible": false , "targets": [5]}
            ],
        "ajax" : "../libs/rulesJson.php",
    });

    var ruleTable1 = $("#ruletable").DataTable({
        "processing" : true,
		"serverSide" : true,
		"stateSave": true,
		"order": [[ 5, 'desc' ]],
		"language": {
            "infoFiltered": ""
        },
        /*"createdRow": function( row, data, dataIndex ) {
             if ( data[2] == "Pending" ) {
                    $(row).addClass('active');
                }
        },*/
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
            if (aData[2].toLowerCase() == "pending") {
                $(nRow).css('color', 'orange');
            }
            else if (aData[2].toLowerCase() == "active") {
                $(nRow).css('color', 'green');
            } else if (aData[2].toLowerCase() == "expired"){
                $(nRow).css('color', 'grey');
            } else {
                 $(nRow).css('color', 'red');
            }
        },
		"columns"    : [
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': true },
                { 'searchable': false,  "visible": false , "targets": [5]},
                { 'searchable': false }
            ],
        "ajax" : "../libs/rulesJson.php"
    });

    setInterval(function () {
        ruleTable.ajax.reload (null, false );
    }, 10000);
    setInterval(function () {
        ruleTable1.ajax.reload (null, false );
    } , 10000);

    var table = $('#searchruletable').DataTable({
        "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
                if (aData[2].toLowerCase() == "pending") {
                    $(nRow).css('color', 'orange');
                } else if (aData[2].toLowerCase() == "active") {
                    $(nRow).css('color', 'green');
                } else if (aData[2].toLowerCase() == "expired"){
                    $(nRow).css('color', 'grey');
                } else {
                    $(nRow).css('color', 'red');
                }
        },
        "ajax": {
            "url": "../libs/searchRuleJson.php",
            "type": "POST",
            "data": {
                thenaction: function() { return $('#thenaction').val() },
                startdate: function() { return $('#startdate').val() },
                enddate: function() { return $('#enddate').val() },
            },
        },
    });

    $('#thenaction').change(function() {
        table.ajax.reload();
    });

    $('#enddate').change(function() {
        table.ajax.reload();
    });

    $('#startdate').change(function() {
        table.ajax.reload();
    });

    $('#filter').change(function() {
        var filter = $('#filter').val();
        if (!filter){
            $('#thenaction').val("");
            $('#startdate').val("");
            $('#enddate').val("");
        }
        if (filter == "1"){
            $('#startdate').val("");
            $('#enddate').val("");
        }
        if (filter == "2"){
            $('#thenaction').val("");
        }
        table.ajax.reload();
    });

    $(function() {
        $.ajax({
            "url": "../libs/rulestatsJson.php",
            type: 'GET',
            success: function(data) {
                chartData = data;
                var chartProperties = {
                    "caption": "Announced rules/day",
                    "xAxisName": "Days of the Week",
                    "yAxisName": "Announced rules",
                    "rotatevalues": "1",
                    "theme": "zune"
                };

                apiChart = new FusionCharts({
                    type: 'column3d',
                    renderAt: 'chart-container',
                    width: '1000',
                    height: '500',
                    dataFormat: 'json',
                    dataSource: {
                        "chart": chartProperties,
                        "data": chartData
                    }
                });
                apiChart.render();
            }
        });
    });

});