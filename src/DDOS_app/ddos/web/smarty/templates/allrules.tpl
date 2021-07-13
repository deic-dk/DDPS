<div class = "page">
    <div class = "tablediv">
        {if $smarty.session.role != 4 && $smarty.session.role != 5 && $smarty.session.role != 3 }
            <div style="text-align: center; margin: 20px 0px 10px;">
                <a id="btnAddAction" href="index.php?action=rule-add"><img src="/image/icon-add.png" />Add Rule</a>
            </div>
        {/if}
        {if $smarty.session.role == 3 && count($allNetworks) > 0}
            <div style="text-align: right; margin: 20px 0px 10px;">
                <a id="btnAddAction" href="index.php?action=rule-add"><img src="/image/icon-add.png" />Add Rule</a>
            </div>
            {/if}
            <div>
            {if $smarty.session.role != 4 && $smarty.session.role != 5}
                <table cellpadding="10" cellspacing="1" id = "ruletable" class="display" width="100%">
            {else}
                <table cellpadding="10" cellspacing="1" id = "ruletableReader" class="display" width="100%">
            {/if}
                    <thead>
                        <th>Description</th>
                        <th>Then action</th>
                        <th>Status</th>
                        <th data-sort='YYYYMMDD'>Expires on</th>
                        <th class = "othertd">Created by</th>
                        {if $smarty.session.role != 4 && $smarty.session.role != 5 }
                            <th>Created on</th>
                            <th class = "actiontd">Actions</th>
                        {/if}
                    </thead>
                </table>
            </div>
    </div>
    {include file="footer.tpl"}
</div>
