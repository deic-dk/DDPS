<form name="calc" method ="POST" action="">
    <div>
        <label>Name</label>
        <input type="text" name="name" id = "name"  class="demoInputBox" value = "{$result.name}" required readonly>
    </div>
    <div>
        <label>Description</label>
        <input type="text" name="desc" id = "desc"  class="demoInputBox" value = "{$result.description}" required readonly>
    </div>
    <div>
        <label>Network Type</label>
        <input type="text" name="networktype" id = "networktype" class="demoInputBox"  value = "{$result.addressfamily}" readonly>
    </div>
      <input type="hidden" name="customer" id = "customer" class = "select" value= "{$result.uuid_networkcustomerid}" readonly>
     <div>
        <label>CIDR</label>
       <input type="text" name="cidr" id="cidr" class="demoInputBox" value = "{$result.net}" required readonly>
    </div>

    <div>
        <select name="allusers" id = "allusers" class = "select" style="visibility:hidden;">
            {foreach from=$allUsers item=item}
                <option value={$item.adminid}>{$item.adminname}</option>
            {/foreach}
        </select>
    </div>


<h1>Subnetting</h1>

<table class="calc" cellspacing="0" cellpadding="2">
<colgroup>
<col id="col_subnet">
<col id="col_useable">
</colgroup>
<thead>
<tr>
<td>Subnet address</td>
<td>Assign to</td>
<td>Access rights</td>
</tr>
</thead>
<tbody id="calcbody">
<!--tr>
<td>130.94.203.0/24</td>
<td>130.94.203.0 - 130.94.203.255</td>
<td>130.94.203.1 - 130.94.203.254 (254)</td>
<td>Divide</td>
</tr-->
</tbody>
</table>
    <div>
    <input type="text" name="count" id="count" >
        <input type="submit" name="savesubnet" id="savesubnet" value="Save" class="mybutton" />
    </div>
</form>