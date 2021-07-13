<div class = "page">
    <div class = "tablediv">
        {if $smarty.session.role != 4 && $smarty.session.role != 5}
        <div style="text-align: right; margin: 20px 0px 10px;">
            <a id="btnAddAction" href="index.php?action=customer-add"><img src="/image/icon-add.png" />Add Customer</a>
        </div>
        {/if}
            <div>
            {if $smarty.session.role != 4 && $smarty.session.role != 5}
                <table cellpadding="10" cellspacing="1" id="customertable" class="display" width="100%">
            {else}
                <table cellpadding="10" cellspacing="1" id="customertableReader" class="display" width="100%">
            {/if}
                    <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>CVR</th>
                        <th>EAN</th>
                        {if $smarty.session.role != 4 && $smarty.session.role != 5}
                            <th>Created on</th>
                            <th class = "actiontd">Actions</th>
                        {/if}
                    </tr>
                    </thead>
                </table>
            </div>
    </div>
    {include file="footer.tpl"}
</div>
