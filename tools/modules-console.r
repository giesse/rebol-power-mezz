REBOL [
    Title: {Allows "importing" modules at the console}
    Author: "Gabriele Santilli"
]

; only meant for testing
; makes exported words global so that modules can be used easily at the console
do %../mezz/module.r
load-module/from clean-path %../

import: func [module] [
    module: load-module module
    foreach word first module/export-ctx [
        set in system/words word get in module/export-ctx word
    ]
]
load-hardball: does [
    module [
        Imports: [%schemes/hardball.r]
    ] [
        rsa-key: load %../tests/data/hardball-test-client-key.r
        server-public-key: get in load %../tests/data/hardball-test-server-key.r 'n
        configure-hardball [
            public-key: rsa-key/n
            private-key: rsa-key
            allowed-peers: reduce [server-public-key]
        ]
    ]
]
halt
