<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="" id="ruleform">
            <div >
            <label class = "labelclass">Select Template*</label>
                <select name="templatetype" id = "templatetype" class = "select"  required>
                    <option></option>
                    <option value="1">Standard Web Server</option>
                    <option value="2">SMTP Server</option>
                    <option value="3">DNS Domain Server</option>
                    <option value="4">NTP Time Server</option>
                </select>
            </div>
            <div>
                <label class = "labelclass">Applier*</label>
                <input type="text"name="Applier" id="Applier" class="myInputBox readonly" value = "{$smarty.session.username}"required readonly>
            </div>

             <div>
                <label class = "labelclass">Description*</label>
                <textarea rows="5" cols="30" name="ruledesc" id = "ruledesc"  class="ruleDescBox" maxlength="50" required></textarea>
            </div>

             <div>
                <label class = "labelclass">Source Address</label>
                <input type="text" name="srcaddress" id="srcaddress" class="myInputBox" >
            </div>

            <div>
                <label class = "labelclass">Destination Address*</label>
                <input type="text" name="cidr" id="cidr" class="myInputBox" onBlur="checkNetwork()" required>
                <label class = "labelclass"></label><span id="network-availability-status"></span>
            </div>

            <div id = "chkdstadress">
                <select name="chkdstadress" id = "chkdstadress" class = "select"  >
                 <option></option>
                    {foreach from=$allNetworks item=item}
                        <option value={$item.net}>{$item.net}</option>
                    {/foreach}
                </select>
            </div>

            <div>
                <label class = "labelclass">From Date*</label>
                <input type="text" name="fromdate" id = "fromdate"  class="myInputBox" required>
            </div>

             <div>
                <label class = "labelclass">Expiry Date*</label>
                <input type="text" name="expdate" id = "expdate"  class="myInputBox" required>
            </div>

            <div>
                <input type="submit" name="tplrule" id="tplrule" value="Create" class = "mybutton"/>
            </div>

        </form>
    </div>

    <div class = "rightdiv">
        <h2> GUI Template rule  </h2>
        <h3>Destination Address</h3>
            <ul>
                <li><p> Destination CIDR should be part of or a subnet of your assigned networks. Otherwise you are not allowed to create rules. </p></li>
            </ul>
        <h3>Dates</h3>
            <ul>
                <li><p> Expiry date should always be greater then From date. </p></li>
                <li>Further information see <a href = "https://github.com/deic-dk/DDPS/blob/master/docs/gui-rules-help.md"> link </a>
            </ul>
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
