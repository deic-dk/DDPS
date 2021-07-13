<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="" id="ruleform">
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
                <input type="text" name="cidr" id="cidr" class="myInputBox" onBlur="checkNetwork()"  required>
                <label class = "labelclass"></label><span id="network-availability-status"></span>
            </div>

            <div>
                <label class = "labelclass">Protocols</label>
                <select name="protocol" id = "protocol" class = "select"  >
                 <option></option>
                    {foreach from=$protocols item=item}
                        <option id="{$item.protocolnumber}" value={$item.protocolnumber} >{$item.protocolvalue}</option>
                    {/foreach}
                </select>
            </div>

            <div id="tcp">
                <div>
                    <label class = "labelclass">Src. Ports</label>
                    <select name="srcopt" id ="srcopt" class="ruleselect" >
                        <option></option>
                        <option value="=">=</option>
                        <option value=">=">>=</option>
                        <option value="<="><=</option>
                       <option value="-">Range</option>
                    </select>
                    <input type="number" name="srcport1" id = "srcpor1t"  class="ruleInputBox" min="0" max="65535"> -
                    <input type="number" name="srcport2" id = "srcport2"  class="ruleInputBox readonly" min="0" max="65535" readonly>
                </div>
                <div>
                    <label class = "labelclass">Dest. Ports</label>
                     <select name="dstopt" id="dstopt"  class="ruleselect">
                        <option></option>
                        <option value="=">=</option>
                        <option value=">=">>=</option>
                        <option value="<="><=</option>
                        <option value="-">Range</option>
                    </select>
                    <input type="number" name="dstport1" id = "dstport1"  class="ruleInputBox" min="0" max="65535"> -
                    <input type="number" name="dstport2" id = "dstport2"  class="ruleInputBox readonly" min="0" max="65535" readonly>
                </div>
            </div>

            <div id="tcpflag">
                <label class = "labelclass">Tcp Flags</label>
                    <select name="tcpflag" id = "tcpflag" class = "select"  >
                        <option></option>
                        {foreach from=$tcpflags item=item}
                            <option value={$item.tcpflagvalue}>{$item.tcpflagvalue}</option>
                        {/foreach}
                    </select>
            </div>

            <div id="icmp">
                <div>
                    <label class = "labelclass">ICMP Type</label>
                    <input type="text" name="icmptype" id = "icmptype"  class="myInputBox readonly" value="All ICMPTypes included" readonly>
                </div>
                <div>
                    <label class = "labelclass">ICMP Codes</label>
                    <input type="text" name="icmpcode" id = "icmpcode"  class="myInputBox readonly" value="All ICMPCodes included" readonly>
                </div>
            </div>

            <div id="other">
                <div>
                    <label class = "labelclass">Protocol No</label>
                    <input type="number" min="0" max="255" name="pnumber" id = "pnumber"  class="myInputBox" >
                </div>
            </div>

            <div>
                <label class = "labelclass">Packet Length</label>
                <input type="number" name="pklenght" id = "pklenght"  class="myInputBox" min="64" max="9000" >
            </div>

            <div>
                <label class = "labelclass">Fragment Type </label>
                <select name="frgtype" id = "frgtype" class = "select"  >
                     <option></option>
                    {foreach from=$fragments item=item}
                        <option value={$item.fragvalue}>{$item.fragvalue}</option>
                    {/foreach}
                </select>
            </div>

            <div>
                <label class = "labelclass">Then Actions*</label>
                 <select name="thenaction" id = "thenaction" class = "select"  required>
                    <option></option>
                    {foreach from=$thenActions item=item}
                        <option value="{$item.thenvalue}">{$item.thenvalue}</option>
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
                <input type="submit" name="createrule" id="createrule" value="Create" class = "mybutton"/>
            </div>

        </form>
    </div>

    <div class = "rightdiv">
        <h2> GUI rule creation </h2>
            <p> Rules made for being implemented as <a href = "https://tools.ietf.org/html/rfc5575">BGP Flowspec</a> differs from traditional firewall implementations, so </p>
                <ul>
                <li>The rule order is not always predictable.</li>
                <li>The rules are for volumetric mitigation.</li>
                <li>Try to match as precis as possible.</li>
                <li>Rules are not permanent but volatile and will always expire.</li>
                <li>Please describe the motivation of the rule.</li>
            </ul>
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
