<div class = "page">
        <form method ="POST" action="" id="ruleform">
            <div class = "systeminfo">
                <h2> {$sysInfo.hostname}</h2>
                <div>
                    <label class = "labelclass">Description*</label>
                    <textarea rows="5" cols="30" name="systemdesc" id = "systemdesc"  class="ruleDescBox" maxlength="50" onBlur="updateDescription()" required>{$sysInfo.description}</textarea><br>
                    <label class = "labelclass"></label><span id="desc-status"></span>
                </div>

                 <div>
                    <label class = "labelclass">Maintenance Date*</label>
                    <input type="text" name="mdate" id = "mdate"  class="myInputBox" value = "{$sysInfo.systemmaintenance}"  onBlur="updateDate()"required><br>
                    <label class = "labelclass"></label><span id="date-status"></span>
                    <input type="hidden" name="systemid" id = "systemid"  class="myInputBox" value = "{$sysInfo.id}" required>
                </div>
            </div>
    </form>
</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
