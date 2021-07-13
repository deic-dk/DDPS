<?php

include_once ('User.class.lib.php');
session_start();

$objUser = new User();
if(!empty($_POST["username"])) {
  $user_count = $objUser->checkUserAvailability($_POST["username"]);
  if($user_count>0) {
      echo "<span class='status-not-available'> Username Not Available</span>";
      ?>
        <script type="text/javascript">
            var input = document.getElementById('username');
            input.value="";
        </script>
    <?php
  } else {
      echo "<span class='status-available'> Username Available</span>";
  }
}

?>