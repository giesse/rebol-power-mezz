REBOL [
    Title: "Hardball test server"
]

rsa-key: load %hardball-test-server-key.r
client-public-key: get in load %hardball-test-client-key.r 'n
change-dir %../../
do %mezz/module.r
load-module/from what-dir

module [
    Imports: [%schemes/hardball.r]
] [
    serve-modules [
        modules: [%mezz/text-encoding.r %mezz/imap.r]
        public-key: rsa-key/n
        private-key: rsa-key
        allowed-peers: reduce [client-public-key]
        logging: [all to %tests/data/test.log]
    ]
]

quit
