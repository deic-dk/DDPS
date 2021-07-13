
<div class = "page">
    <div class = "indexdiv">
        <h3 class = "heading">System Status<h3>
    </div>
    <div class = "tablediv">
        <table cellpadding="10" cellspacing="1" id = "statustable" class="display" width="100%">
            <thead>
                <th>Hosts</th>
                <th>Status</th>
                <th>Announced Rules</th>
                <th>System Maintenance</th>
                <th>Description</th>
                {if $smarty.session.role == 1}
                    <th class = "actiontd">Action</th>
                {/if}
            </thead>
        </table>
    </div>
    <div id="chart-container" class = "chartdiv">FusionCharts will render here</div>
</div>
    {include file="footer.tpl"}
</div>



