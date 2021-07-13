<div class = "page">
    <div class = "leftdiv">
        <div>
            <label class = "labelclass">Max active rules</label>
            <input type="text" name="maxrule" id = "maxrule"  class="myInputBox readonly" value = "{$mrules}" readonly>
        </div>
        <div>
            <label class = "labelclass">Current active rules</label>
            <input type="text"name="activerules" id="activerules" class="myInputBox readonly" value = "{$crules}" readonly>
        </div>
        <div>
            <label class = "labelclass">Rule fluctuations/min</label>
            <input type="text" name="rulefluc" id = "rulefluc"  class="myInputBox readonly" value = "{$frules}" readonly>
        </div>
        <div>
            <label class = "labelclass">Current fluctuation</label>
            <input type="text" name="curfluc" id = "curfluc"  class="myInputBox readonly" value = "{$cfrule}" readonly>
        </div>
    </div>
    <div class = "rightdiv">
        <h4> Master Data Info </h4>
            <p>The system has an upper limit on the total amount of active rules and another limit on fluctuations - the number of rules announced and withdrawn per minute.</p>
            <p>When the value are exceeded your organisation will not be able to add new rules. </p>
            <p>If you feel any need for exceeding your current rules. Please contact DDPS support.</p>
    </div>
</div>
<div class = "footerdiv">
    {include file="footer.tpl"}
</div>

