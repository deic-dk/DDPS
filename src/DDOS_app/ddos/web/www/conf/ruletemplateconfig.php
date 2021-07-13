<?php

$config =  [
    'webserver' => [
        'action_1' => 'discard',
        'pnumber' => '<=5&>=7',
        'action_2' => 'discard',
        'destport' => '<=79,>81&<=442,>444'
    ],
    'smtpserver' => [
        'action_1' => 'discard',
        'pnumber' => '<=5&>=7',
        'action_2' => 'discard',
        'destport' => '<=23,>26'
    ],
    'dnsdomainserver' => [
        'action_1' => 'discard',
        'pnumber' => '<=16&>=18',
        'action_2' => 'discard',
        'destport' => '<=52,>54'
    ],
     'ntptimeserver' => [
        'action_1' => 'discard',
        'pnumber' => '<=16&>=18',
        'action_2' => 'discard',
        'destport' => '<=122,>124'
    ],
];

?>