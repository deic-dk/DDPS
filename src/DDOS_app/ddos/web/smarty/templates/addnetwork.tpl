<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="" id = "addnetwork">
            <div>
                <label class = "labelclass">Name*</label>
                <input type="text" name="name" id = "name"  class="myInputBox" required>
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
                <label class = "labelclass">CIDR*</label>
                <input type="text" name="cidr" id="cidr" class="myInputBox" onBlur="checkNetwork()" required>
                <label class = "labelclass"></label><span id="network-availability-status"></span>
            </div>

            <div>
                <label class = "labelclass">Description*</label>
                <input type="text" name="desc" id = "desc"  class="myInputBox" required>
            </div>

            <div>
            <label class = "labelclass">Network Type*</label>
                <select name="networktype" id = "networktype" class = "select" >
                    {foreach from=$nettype item=item}
                        <option value={$item.id}>{$item.familytype}</option>
                    {/foreach}
                </select>
            </div>

            <div>
                <label class = "labelclass">Select Customer*</label>
                <select name="customer" id = "customer" class = "select" >
                    {foreach from=$allcustomers item=item}
                        <option value={$item.customerid}>{$item.customername}</option>
                    {/foreach}
                </select>
            </div>

            <div>
                <input type="submit" name="createnetwork" id="createnetwork" value="Create" class = "mybutton"/>
            </div>

        </form>
    </div>

    <div class = "rightdiv">
        <h2> Adding a Network </h2>
        <h3>CIDR</h3>
        <ul>
            <li><p> CIDR should be part of or a subnet of your assigned networks. Otherwise you are not allowed to add any Networks. </p></li>
        </ul>
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
