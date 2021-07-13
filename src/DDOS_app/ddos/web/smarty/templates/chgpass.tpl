<div class = "page">
    <div class = "userdiv">
        <form method ="POST" action="" name = "adduserform" id = "adduserform">

            <div>
                <label class = "labelclass">Password*</label>
                <input type="password" name="pass" id="pass" class="myInputBox" minlength="8" required>
            </div>

            <div>
                <label class = "labelclass">Confirm Password*</label>
                <input type="password" name="conpass" id="conpass" class="myInputBox" required>
            </div>

            <div class="userbuttondiv">
                <input type="submit" name="updatepass" id="updatepass" value="UPDATE" class = "mybutton"/>
            </div>
                 <input type="hidden" name="adminid" id = "adminid"  class="myInputBox" value = "{$userid}" >
        </form>
    </div>


    <div class = "userhelpdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>