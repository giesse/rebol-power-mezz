REBOL [
    Title: "Hardball test client"
]

rsa-key: load %hardball-test-client-key.r
server-public-key: get in load %hardball-test-server-key.r 'n
change-dir %../../
do %mezz/module.r
load-module/from what-dir

wait 2 ; give time to the server to start

module [
    Imports: [%schemes/hardball.r %mezz/messages.r %mezz/logging.r %mezz/form-error.r]
] [
    setup-logging [all to %tests/data/test.log]
    config: make-hardball-configuration [
        public-key: rsa-key/n
        private-key: rsa-key
        allowed-peers: reduce [server-public-key]
    ]
    port: open-hardball-connection config tcp://localhost:1025
    append-log 'debug ["List response:" mold/all/only list-exported-modules port]
    append-log 'debug [
        "List %mezz/text-encoding.r response:" mold/all/only list-exported-functions port %mezz/text-encoding.r
    ]
    append-log 'debug [
        "Call response:" mold/all/only call-remote-function port %mezz/text-encoding.r [
            encode-text "Is a < b?" 'html none none
        ]
    ]
    append-log 'debug [
        "Call response:" form-error disarm try [
            call-remote-function port %mezz/text-encoding.r [encode-text none none none none]
        ]
    ]
    send-message port port/locals/session [Quit]
]

quit
