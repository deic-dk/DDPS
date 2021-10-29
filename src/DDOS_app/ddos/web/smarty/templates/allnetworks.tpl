<div class = "page">
    <div class = "tablediv">
        {if $smarty.session.role != 3 && $smarty.session.role != 4 && $smarty.session.role != 5}
            <div style="text-align: right; margin: 20px 0px 10px;">
             <a id="btnAddAction" href="index.php?action=network-add"><img src="/image/icon-add.png" />Add Subnet</a>
            {if $smarty.session.role ==1 }
                <a id="btnAddActionExt" href="index.php?action=basicnetwork-add"><img src="/image/icon-add.png" />Add New Network</a>
            {/if}
            </div>
        {/if}
        <div>
            <table cellpadding="10" cellspacing="1" id="networktable" class ="display" width="100%">
                <thead>
                    <th>Name</th>
                    <th>CIDR</th>
                    <th>Description</th>
                    <th>Type</th>
                    {if $smarty.session.role != 3 && $smarty.session.role != 4 && $smarty.session.role != 5}
                        <th class = "actiontd">Actions</th>
                    {/if}
                </thead>
            </table>
         </div>
    </div>
    {include file="footer.tpl"}
</div>
