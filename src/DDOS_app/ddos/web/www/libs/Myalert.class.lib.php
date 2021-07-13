<?php

class myalert {

    public function __construct() {

    }

    public function notification($message, $type) {
        echo '<script type="text/javascript">
                $(document).ready(function(){
                    Swal.fire({
                        position: "center",
                        icon: "'.$type.'",
                        title: "'.$message.'",
                        showConfirmButton: false,
                        timer: 3000
                    })
                });
            </script>';
    }
    public function simpleNotify($message, $type) {
        echo '<script type="text/javascript">
                $(document).ready(function(){
                    Swal.fire({
                        position: "center",
                        icon: "'.$type.'",
                        title: "'.$message.'",
                    })
                });
            </script>';
    }
}

?>