<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="">
            <div>
                <label class = "labelclass">Name</label>
                <input type="text" name="name" id = "name"  class="myInputBox" value = "{$result.name}" required>
            </div>

            <div>
                <label class = "labelclass">CIDR</label>
                <input type="text"name="cidr" id="cidr" class="myInputBox" value = "{$result.net}" onBlur="checkNetwork()" required>
                <label class = "labelclass"></label><span id="network-availability-status"></span>
            </div>

            <div>
                <label class = "labelclass">Description</label>
                <input type="text" name="desc" id = "desc"  class="myInputBox" value = "{$result.description}" required>
            </div>

            <div>
            <label class = "labelclass">Network Type</label>
                <select name="networktype" id = "networktype" class = "select" >
                    {foreach from=$nettype item=item}
                        {if $item.id == $result.addressfamily}
                            <option value={$item.id} selected>{$item.familytype}</option>
                        {else}
                            <option value={$item.id}>{$item.familytype}</option>
                        {/if}
                    {/foreach}
                </select>
            </div>

            <div>
            <input type="hidden" name="networkid" id = "networkid"  class="myInputBox" value = "{$result.networkid}" required>
            <label class = "labelclass">Select Customer</label>
                <select name="customer" id = "customer" class = "select" >
                    {foreach from=$allcustomers item=item}
                        {if $item.customerid == $result.uuid_networkcustomerid}
                            <option value={$item.customerid} selected>{$item.customername}</option>
                        {else}
                            <option value={$item.customerid}>{$item.customername}</option>
                        {/if}
                    {/foreach}
                </select>
            </div>

            <div>
                <input type="submit" name="updatebasicnetwork" id="updatebasicnetwork" value="Update" class="mybutton" />
            </div>

        </form>
    </div>

    <div class = "rightdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
