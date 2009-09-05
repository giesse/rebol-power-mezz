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
halt
