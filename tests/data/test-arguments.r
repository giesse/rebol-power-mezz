REBOL [
    Title: "Test the arguments module"
]

do %../../mezz/module.r
load-module/from %../../

module [
    Imports: [%mezz/arguments.r]
] [
    probe parse-arguments/env [
        title "IMAP proxy daemon"
        port-number integer! default 1025 help "Port number to listen to"
        "config" config-file file! default %.conf help "Specify alternate configuration file name"
        "pid" pid-file file! default %.pid help "Specify alternate PID file name"
    ] [
        port-number "MAIL_PROXY_PORT"
        config-file "MAIL_PROXY_CONFIG"
        pid-file    "MAIL_PROXY_PID"
    ]
]
