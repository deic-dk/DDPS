<div class = "page">
    <div class = "userdiv">
        <form method ="POST" action="" enctype="multipart/form-data" name = "edituserform" id = "edituserform">
            <div>
                <label class = "labelclass">Full Name</label>
                <input type="text" name="name" id = "name"  class="myInputBox" value = "{$result[0].adminname}" required>
            </div>

            <div>
                <label class = "labelclass">Username</label>
                <input type="text"name="username" id="username" class="myInputBox" value = "{$result[0].username}" required>
            </div>
             <label class = "labelclass" style = "margin-left:5px;"></label><a href="index.php?action=user-changepass&id={$result[0].adminid}">Change password</a>
           <!-- <div>
                <label>Password</label>
                <input type="password" name="pass" id="pass" class="myInputBox" value = "{$result.password}" required>
            </div>-->
            <div>
                <label class = "labelclass">Email</label>
                <input type="email" name="email" id="email" class="myInputBox" value = "{$result[0].email}"required>
            </div>

            <div>
                <label class = "labelclass">Organization</label>
                <input type="text" name="org" id = "org"  class="myInputBox" value = "{$result[0].organization} ">
            </div>
<!--
            <div>
                <label class = "labelclass">Edupersonprincipalname</label>
                <input type="text" name="eppn" id = "eppn"  class="myInputBox" value = "{$result[0].edupersonprincipalname}" >
            </div>

            <div>
                <label class = "labelclass">Schachomeorganization</label>
                <input type="text" name="shacorg" id = "shacorg"  class="myInputBox" value = "{$result[0].schachomeorganization}" required>
            </div>
-->
            <div>
             <label class = "labelclass">Select Customer</label>
                <select name="customer" id = "customer" class = "select" >
                    {foreach from=$allcustomers item=item}
                        {if $item.customerid == $result[0].customerid}
                            <option value={$item.customerid} selected>{$item.customername}</option>
                        {else}
                            <option value={$item.customerid}>{$item.customername}</option>
                        {/if}
                    {/foreach}
                </select>
            </div>

            <div>
            <label class = "labelclass">Admin Role</label>
                <select name="admintype" id = "admintype" class = "select" >
                     {foreach from=$options item=item}
                        {if $item.roleid == $result[0].adminroleid}
                            <option value={$item.roleid} selected>{$item.rolename}</option>
                        {else}
                            <option value={$item.roleid}>{$item.rolename}</option>
                        {/if}
                     {/foreach}
                </select>
            </div>

            <div id="assignNetwork" >
        	    <label class = "labelclass">Assign Networks </label>
        		<select name="listboxto" id="listboxto" size="6" multiple="multiple" class="listBox">
        			{foreach from=$networks item=item}
                        <option value={$item.networkid}>{$item.net}</option>
                    {/foreach}
        		</select>
        		<input type="button" value=" >> " id="moveRight" class = "listboxBtn">
        	    <input type="button" value=" << " id="moveLeft" class = "listboxBtn">

        		<select name="listboxfrom[]" id="listboxfrom" size="6" multiple="multiple" class="listBox">
        		    {for $i = 0; $i < count($result); $i++ }
        		        <option value={$result[$i]['network_id']}>{$result[$i]['net']}</option>
        		    {/for}
        		</select>
        	</div>

                <input type="hidden" name="adminid" id = "adminid"  class="myInputBox" value = "{$result[0].adminid}" >

            <div class = "userbuttondiv">
                <input type="submit" name="updateuser" id="updateuser" value="Update" class="mybutton"/>
            </div>

        </form>
    </div>

    <div class = "rightdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
