<html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DeiC DDPS</title>
            <link href="/css/style.css" type="text/css" rel="stylesheet" />

           <!--  <script src="https://code.jquery.com/jquery-3.3.1.js" type="text/javascript"></script>-->
            <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
           <script src="../js/fusioncharts-dist/fusioncharts.js"></script>
            <script src="../js/fusioncharts-dist/fusioncharts.charts.js"></script>
            <script src="../js/fusioncharts-dist/themes/fusioncharts.theme.zune.js"></script>
          <!--  <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>-->
            <script src="https://cdn.jsdelivr.net/npm/sweetalert2@9"></script>

            <!--<script src="https://code.jquery.com/jquery-2.1.1.min.js" type="text/javascript"></script>-->
            <script src="../js/jquery.datetimepicker.js"></script>
            <script src="../js/rules.js" type="text/javascript"></script>
            <script src="../js/user.js" type="text/javascript"></script>
            <script src="../js/addnetwork.js" type="text/javascript"></script>
            <script src="../js/displaytables.js" type="text/javascript"></script>
            <script src="../js/searchrules.js" type="text/javascript"></script>
            <script src="../js/systeminfo.js" type="text/javascript"></script>
            <script src="../js/alert.js" type="text/javascript"></script>

            <script src="../js/jquery.dataTables.min.js" type="text/javascript"></script>
            <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>

            <link rel="stylesheet" href="/css/jquery.dataTables.min.css">
            <link rel="stylesheet" href="/css/alert.css">

            <link rel="stylesheet" href="//code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">


            <link rel="stylesheet" type="text/css" href="/css/jquery.datetimepicker.min.css"/>

     </head>
<body>
    <div class = "head" >
        <div class = "logo" >
            <div class = "left">
                <h2>DDPS</h2>
            </div>
            <div class = "right">
    	        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 390 145.86" height="40">
	                <title>DeiC</title>
	                <path d="M204.77,127.44C203.2,120,195.63,115,186.62,115c-8.71,0-15.57,4.86-18,12.43ZM187.34,158a21.53,21.53,0,0,0,17.66-9.9l16.64,10.18c-7.42,10.32-18.3,16.86-34,16.86-24.15,0-40.15-15.86-40.15-39.29,0-22.57,17.57-37.71,40.57-37.71s38.15,17.14,38.15,41.57v2.57H168.06C169.48,152,177.48,158,187.34,158Z" transform="translate(-15.25 -29.3)" style="fill:#000"/>
	                <path d="M329.47,175.16c-29.86,0-54.14-24.43-54.14-54.72s24.28-54.72,54.14-54.72A54.18,54.18,0,0,1,376,92.3L356.9,103.58A32.75,32.75,0,0,0,329.47,88c-17.14,0-32.14,15.14-32.14,32.43s15,32.43,32.14,32.43A31.87,31.87,0,0,0,356.9,137l19.29,11.43A54.38,54.38,0,0,1,329.47,175.16Z" transform="translate(-15.25 -29.3)" style="fill:#000"/>
	                <path d="M86.06,68.58H44.49V89H86.92c17.43,0,29.72,13,29.72,31.58,0,20.28-12.43,31.57-30,31.57H66.35V98.74H44.49v73.85H86.06c32.72,0,52.86-22.15,52.86-52C138.92,90,118.92,68.58,86.06,68.58Z" transform="translate(-15.25 -29.3)" style="fill:#000"/>
	                <rect x="224.22" y="39.28" width="22.08" height="20.44" style="fill:#000"/>
	                <rect x="224.22" y="69.44" width="22.08" height="73.85" style="fill:#000"/>
	                <path d="M213.55,72.22C212,71,183.66,59.49,156.28,74.44c-11.87-14.75-41.89-53.52-141-38.1,0,0,98.5-28.71,143.21,29.82a66.34,66.34,0,0,1,50.33-2.23S214,44.53,237,36.63c24.94-8.57,45.25,9.76,45.25,9.76.66-.46,60.13-43.89,123,14.64,0,0-62.81-51.41-123.73-5.74,0,0-16-20.33-41.37-12.84C218.06,49,213.81,70.3,213.55,72.22Z" transform="translate(-15.25 -29.3)" style="fill:#a3cd39"/>
                </svg>
            </div>
            {if $smarty.session.name}
                <div class = "loginMessage">Welcome {$smarty.session.name}</div>
             {/if}
        </div>
    </div>



