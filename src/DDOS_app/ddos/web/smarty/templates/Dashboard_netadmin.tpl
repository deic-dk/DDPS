<div class = "pagehead">
{include file="header.tpl"}
{include file="logout.tpl"}
{include file="menu_netadmin.tpl"}
{if $smarty.server.REQUEST_URI =="/index.php" || $smarty.server.REQUEST_URI =="/"}
   {include file="index.tpl"}
{/if}
</div>
