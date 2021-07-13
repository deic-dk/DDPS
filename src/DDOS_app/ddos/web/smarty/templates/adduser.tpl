<div class = "page">
    <div class = "userdiv">
        <form method ="POST" action="" name = "adduserform" id = "adduserform">
            <div>
                <label class = "labelclass">Full Name*</label>
                <input type="text" name="name" id = "name"  class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Username*</label>
                <input type="text"name="username" id="username" class="myInputBox" onBlur="checkAvailability()" required></br>
                <label class = "labelclass"></label><span id="user-availability-status"></span>
            </div>

            <div>
                <label class = "labelclass">Password*</label>
                <input type="password" name="pass" id="pass" class="myInputBox" minlength="8" required>
            </div>

            <div>
                <label class = "labelclass">Confirm Password*</label>
                <input type="password" name="conpass" id="conpass" class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Email*</label>
                <input type="email" name="email" id="email" class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Organization*</label>
                <input type="text" name="org" id = "org"  class="myInputBox" required>
            </div>

<!--        <div>
                <label class = "labelclass">Edupersonprincipalname*</label>
                <input type="text" name="eppn" id = "eppn"  class="myInputBox" >
            </div>

            <div>
                <label class = "labelclass">Schachomeorganization*</label>
                <input type="text" name="shacorg" id = "shacorg"  class="myInputBox" >
            </div>
-->
            <div>
                <label class = "labelclass">Select Customer*</label>
                <select name="customer" id = "customer" class = "select" >
                    <option></option>
                    {foreach from=$allcustomers item=item}
                        <option value={$item.customerid}>{$item.customername}</option>
                    {/foreach}
                </select>
            </div>

            <div>
             <label class = "labelclass">Admin Role*</label>
                <select name="admintype" id = "admintype" class = "select"  >
                    {foreach from=$options item=item}
                        <option value={$item.roleid}>{$item.rolename}</option>
                    {/foreach}
                </select>
            </div>

            <div id="assignNetwork">
        	    <label class = "labelclass">Assign Networks </label>
        		<select name="listboxto" id="listboxto" size="6" multiple="multiple" class="listBox">

        		</select>
        		<input type="button" value=" >> " id="moveRight" class = "listboxBtn">
        	    <input type="button" value=" << " id="moveLeft" class = "listboxBtn">

        		<select name="listboxfrom[]" id="listboxfrom" size="6" multiple="multiple" class="listBox">
        		</select>
        	</div>

            <div class="userbuttondiv">
                <input type="submit" name="createuser" id="createuser" value="Create" class = "mybutton"/>
            </div>

        </form>
    </div>

    <div class = "userhelpdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>

