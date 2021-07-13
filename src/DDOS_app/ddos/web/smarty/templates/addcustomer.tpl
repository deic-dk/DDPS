<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="">
            <div>
                <label class = "labelclass">Customer Name*</label>
                <input type="text" name="name" id = "name"  class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Address*</label>
                <input type="text"name="address" id="address" class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Email*</label>
                <input type="email" name="email" id="email" class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Phone*</label>
                <input type="text" name="phone" id = "phone"  class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">CVR*</label>
                <input type="text" name="cvr" id = "cvr"  class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">EAN*</label>
                <input type="text" name="ean" id = "ean"  class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Max active rules*</label>
                <input type="number" name="maxactiverule" id = "maxactiverule"  class="myInputBox" required>
            </div>

            <div>
                <label class = "labelclass">Max rules changes/min*</label>
                <input type="number" name="maxrulechange" id = "maxrulechange"  class="myInputBox" required>
            </div>

            <div>
                <input type="submit" name="createcustomer" id="createcustomer" value="Create" class = "mybutton"/>
            </div>

        </form>
    </div>

    <div class = "rightdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>

