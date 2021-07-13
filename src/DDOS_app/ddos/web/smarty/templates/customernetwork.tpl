<div class = "page">
<form method ="POST" action="">
    <div>
        <label class = "labelclass">Name</label>
        <input type="text" name="name" id = "name"  class="myInputBox" required>
    </div>
    <div>
        <label class = "labelclass">CIDR</label>
        <input type="text"name="cidr" id="cidr" class="myInputBox" required>
    </div>
    <div>
        <label class = "labelclass">Description</label>
        <input type="text" name="desc" id = "desc"  class="myInputBox" required>
    </div>
    <div>
    <label class = "labelclass">Network Type</label>
        <select name="networktype" id = "networktype" class = "select" >
            {foreach from=$nettype item=item}
                <option value={$item.id}>{$item.familytype}</option>
            {/foreach}
        </select>
    </div>
     <div>
        <label class = "labelclass">Select Admin</label>
        <select name="customer" id = "customer" class = "select" >
            {foreach from=$allcustomers item=item}
                <option value={$item.customerid}>{$item.customername}</option>
            {/foreach}
        </select>
    </div>
    <div>
        <label class = "labelclass">Select Customer</label>
        <select name="customer" id = "customer" class = "select" >
            {foreach from=$allcustomers item=item}
                <option value={$item.customerid}>{$item.customername}</option>
            {/foreach}
        </select>
    </div>

    <div>
        <input type="submit" name="createbasicnet" id="createbasicnet" value="Create" class = "mybutton"/>
    </div>
</form>
</div>
<div class = "footerdiv">
    {include file="footer.tpl"}
</div>

