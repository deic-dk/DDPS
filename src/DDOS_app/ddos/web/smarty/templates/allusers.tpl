<div class = "page">
    <div class = "tablediv">
        {if $smarty.session.role != 4 && $smarty.session.role != 5}
        <div style="text-align: center; margin: 20px 0px 10px;">
            <a id="btnAddAction" href="index.php?action=user-add"><img src="/image/icon-add.png" />Add User</a>
        </div>
        {/if}
        <div>
            {if $smarty.session.role != 4 && $smarty.session.role != 5}
                <table cellpadding="10" cellspacing="1" id="usertable" class="display" width="100%">
            {else}
                <table cellpadding="10" cellspacing="1" id="usertableReader" class="display" width="100%">
            {/if}
                <thead>
                    <tr>
                        <th>Full Name</th>
                        <th>User Name</th>
                        <th>Organisation</th>
                        <th>Email</th>
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


