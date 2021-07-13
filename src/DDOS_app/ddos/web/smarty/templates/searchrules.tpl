<div class = "page">
    <div class = "tablediv">
        <div class = "leftdiv">
             <div>
                <label class = "labelclass">Filter By</label>
                <select name="filter" id = "filter" class = "select" >
                    <option></option>
                    <option value = "1">thenaction</option>
                    <option value="2">Dates</option>
                </select>
             </div>
    <form id = "searchform">
            <div id = "byaction">
                <label class = "labelclass">Then Actions*</label>
                <select name="thenaction" id = "thenaction" class = "select"  >
                    <option></option>
                         {foreach from=$thenActions item=item}
                             <option value="{$item.thenvalue}">{$item.thenvalue}</option>
                         {/foreach}
                </select>
            </div>
            <div id = "date">
                <div>
                    <label class = "labelclass">From Date</label>
                    <input type="text" name="startdate" id = "startdate"  class="myInputBox" >
                </div>
                <div>
                    <label class = "labelclass">To Date</label>
                    <input type="text" name="enddate" id = "enddate"  class="myInputBox" >
                </div>
            </div>
            <div id = "searchbutton">
             <!--   <input type="submit" name="searchrule" id="searchrule" value="Search" class = "mybutton"/>-->
            </div>
        </div>
        </form>
            <div>
                <table cellpadding="10" cellspacing="1" id = "searchruletable" class="display" width="100%">
                    <thead>
                        <th>Description</th>
                        <th>Then action</th>
                        <th>Status</th>
                        <th>Expires on</th>
                        <th class = "othertd">Created by</th>
                        {if $smarty.session.role != 4 && $smarty.session.role != 5}
                            <th class = "actiontd">Action</th>
                        {/if}
                    </thead>
                </table>
            </div>
    </div>
    {include file="footer.tpl"}
</div>