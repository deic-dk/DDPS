<div class = "page">
    <div class = "leftdiv">
        <form method ="POST" action="" id="ruleform">
            <div>
                <label class = "labelclass">Applier*</label>
                <input type="text"name="Applier" id="Applier" class="myInputBox readonly" value = "{$smarty.session.username}" readonly>
            </div>

             <div>
                <label class = "labelclass">Description*</label>
                <input type="hidden" name="ruleid" id = "ruleid"  class="myInputBox readonly"  value = "{$result.flowspecruleid}" readonly >
                <textarea rows="5" cols="38" name="ruledesc" id = "ruledesc"  class="ruleDescBox readonly" maxlength="50" required readonly>{$result.description}</textarea>
            </div>

             <div>
                <label class = "labelclass">Source Address</label>
                <input type="text" name="srcaddress1" id="srcaddress1" class="myInputBox readonly" value ="{$result.sourceprefix}" readonly>
            </div>

            <div>
                <label class = "labelclass">Destination Address</label>
                <input type="text" name="dstaddress1" id="dstaddress1" class="myInputBox readonly" value ="{$result.destinationprefix}" readonly>
            </div>

            <div>
                <label class = "labelclass">Protocols*</label>
                <input type="text" name="protocol1" id = "protocol1" class = "select readonly"  value="{$result.ipprotocol}" readonly>
            </div>

            <div >
                <label class = "labelclass">Src. Ports</label>
                <input type="text" name="srcopt" id = "srcopt" class = "myInputBox readonly" value="{$result.sourceport}" readonly>
            </div>

            <div>
                <label class = "labelclass">Dest. Ports</label>
                <input type="text" name="dstopt" id = "dstopt" class = "myInputBox readonly" value="{$result.destinationport}" readonly>
            </div>

            <div>
                <label class = "labelclass">Tcp Flags</label>
                <input type="text" name="tcpflag1" id = "tcpflag1" class = "select readonly" value="{$result.tcpflags}" readonly>
            </div>

            <div>
                <label class = "labelclass">ICMP Type</label>
                <input type="text" name="icmptype1" id = "icmptype1"  class="myInputBox readonly" value="{$result.icmptype}" readonly>
            </div>

            <div>
                <label class = "labelclass">ICMP Codes</label>
                <input type="text" name="icmpcode1" id = "icmpcode1"  class="myInputBox readonly" value="{$result.icmpcode}" readonly>
            </div>

            <div>
                <label class = "labelclass">Protocol No</label>
                <input type="text" name="pnumber" id = "pnumber"  class="myInputBox readonly" value="{$result.ipprotocol}" readonly>
            </div>

            <div>
                <label class = "labelclass">Packet Length*</label>
                <input type="text" name="pklenght" id = "pklenght"  class="myInputBox readonly" min="64" max="9000" value="{$result.packetlength}"  readonly>
            </div>

            <div>
                <label class = "labelclass">Fragment Type* </label>
                <input type="text" name="frgtype" id = "frgtype" class = "myInputBox readonly" value="{$result.fragmentencoding}"  readonly>
            </div>

            <div>
                <label class = "labelclass">Then Actions*</label>
                 <input type="text" name="thenaction" id = "thenaction" class = "myInputBox readonly"  value="{$result.thenaction}"  readonly>
            </div>

            <div>
                <label class = "labelclass">From Date*</label>
                <input type="text"  class="myInputBox readonly" value ="{$result.validfrom}"  readonly>
            </div>

            <div>
                <label class = "labelclass">Status*</label>
                <input type="text" name="fromdate1" id = "fromdate1"  class="myInputBox readonly" value ="{if $result.isactivated == 'true'}Active{else}Deactive{/if}"  readonly>
            </div>

             <div>
                <label class = "labelclass">Expiry Date*</label>
                <input type="text"   class="myInputBox readonly" value ="{$result.validto}"  readonly>
            </div>

            <div>
               <!-- <input type="submit" name="updaterule" id="updaterule" value="Update Rule" class = "mybutton"/>-->
            </div>
        </form>
    </div>

    <div class = "rightdiv">
    </div>

</div>

<div class = "footerdiv">
    {include file="footer.tpl"}
</div>
