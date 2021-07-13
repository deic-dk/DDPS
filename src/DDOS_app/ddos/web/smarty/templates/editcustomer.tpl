<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="">
            <div>
                <label class = "labelclass">Customer Name</label>
                <input type="text" name="name" id = "name"  class="myInputBox" value = "{$result.customername}" required>
            </div>

            <div>
                <label class = "labelclass">Address</label>
                <input type="text"name="address" id="address" class="myInputBox" value = "{$result.customeraddress1}" required>
            </div>

            <div>
                <label class = "labelclass">Email</label>
                <input type="email" name="email" id="email" class="myInputBox" value = "{$result.mainmail}"required>
            </div>

            <div>
                <label class = "labelclass">Phone</label>
                <input type="text" name="phone" id = "phone"  class="myInputBox" value = "{$result.mainphone}"required>
            </div>

            <div>
                <label class = "labelclass">CVR</label>
                <input type="text" name="cvr" id = "cvr"  class="myInputBox" value = "{$result.cvr}" required>
            </div>

            <div>
                <label class = "labelclass">EAN</label>
                <input type="text" name="ean" id = "ean"  class="myInputBox" value = "{$result.ean}" required>
            </div>

            <div>
                <label class = "labelclass">Max active rules*</label>
                <input type="number" name="maxactiverule" id = "maxactiverule"  class="myInputBox" value = {$result.max_active_rules} required>
            </div>

            <div>
                <label class = "labelclass">Max rules changes/min*</label>
                <input type="number" name="maxrulechange" id = "maxrulechange"  class="myInputBox" value = {$result.max_rule_fluctuation_time_window} required>
            </div>

            <input type="hidden" name="customerid" id = "customerid"  class="myInputBox" value = "{$result.customerid}" required>
            <div>
                <input type="submit" name="updatecustomer" id="updatecustomer" value="Update" class="mybutton" />
            </div>

        </form>
    </div>

    <div class = "rightdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
