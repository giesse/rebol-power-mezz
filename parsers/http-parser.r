REBOL [
    Title: "HTTP Requests parser and Response generator"
    File: %http-parser.r
    Type: 'Module
    Purpose: {
        Parses HTTP requests, and generates HTTP responses.
    }
    Author: "Gabriele Santilli"
    License: {
        Copyright 2011 Gabriele Santilli

        Permission is hereby granted, free of charge, to any person obtaining
        a copy of this software and associated documentation files
        (the "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject
        to the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
        THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
        OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
        ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
        OTHER DEALINGS IN THE SOFTWARE.
    }
    Version: 1.3.0
    Imports: [
        %parsers/uri-parser.r
    ]
    Exports: [
        make-request-object 
        handle-data 
        handle-close 
        emit-response-header 
        emit-chunk 
        emit-trailer
    ]
]

make-request-object: func [
    {Create and initialize a request object to be used with handle-data} 
    user-data' "Will be available as request/user-data" 
    on-request [function!] {Called when request is complete - func [request] [...]} 
    on-error [function!] {Callen in case of error - func [request error [word!]] [...]}
] [
    context [
        user-data: user-data' 
        buffer: copy #{} 
        on-data: :on-header-data 
        on-request*: :on-request 
        on-error*: :on-error 
        finished?: no 
        method: resource: path: query: content-type: content-length: content: keep-alive: none
    ]
] 
handle-data: func [
    "Handle new data arriving from the HTTP client" 
    request [object!] "The request object (see make-request-object)" 
    data [any-string!]
] [
    append request/buffer data 
    request/on-data request
] 
handle-close: func [
    "Handle the HTTP client closing the connection" 
    request [object!] "The request object (see make-request-object)"
] [
    if all bind [
        method = "POST" resource content
    ] request [
        request/finished?: yes 
        request/on-request* request 
        request/method: none
    ]
] 
emit-response-header: func [
    "Emit a HTTP/1.1 response header" 
    output [port! any-string!] 
    code [integer!] "Response code (eg. 200)" 
    message [string!] {Response message (eg. "OK")} 
    headers [block!] {Response headers (set-word followed by expression that evaluates to string)}
] [
    insert tail output reduce [
        "HTTP/1.1 " code #" " message "^M^/"
    ] 
    while [not tail? headers] [
        insert tail output mold headers/1 
        set [message headers] do/next next headers 
        insert tail output reduce [#" " message "^M^/"]
    ] 
    insert tail output "^M^/"
] 
emit-chunk: func [
    "Emit a HTTP chunk for chunked transfer encoding" 
    output [port! any-string!] 
    data [any-string!]
] [
    either all [any-string? data 1000 < length? data] [
        emit-chunk* output chunk-buffer data
    ] [
        append chunk-buffer data 
        if 1000 < length? chunk-buffer [
            emit-chunk* output chunk-buffer "" 
            clear chunk-buffer
        ]
    ]
] 
emit-trailer: func [
    "Emit the HTTP chunked trailer (end of chunks)" 
    output [port! any-string!]
] [
    unless empty? chunk-buffer [
        emit-chunk* output chunk-buffer "" 
        clear chunk-buffer
    ] 
    emit-chunk* output "" ""
] 
space: charset " ^-" 
res-chars: complement space 
on-header-data: func [locals /local method resource path query rest] [
    parse/all locals/buffer [
        copy method ["GET" | "POST"] some space 
        copy resource some res-chars 
        some space "HTTP/1." [#"0" | #"1"] 
        any space "^M^/" rest: (
            remove/part locals/buffer as-binary rest 
            locals/on-data: :on-other-header-data 
            path: decode-uri-fields parse-uri/relative resource 
            query: path/query 
            path: path/path 
            foreach word [method resource path query] [
                set in locals word get word
            ] 
            unless empty? locals/buffer [locals/on-data locals]
        )
    ]
] 
on-other-header-data: func [locals /local type length rest done] [
    parse/all locals/buffer [
        some [
            "^M^/" (
                locals/on-data: :on-content-data 
                done: yes
            ) 
            break 
            | 
            "Content-Type:" any space copy type to "^M^/" 2 skip (
                locals/content-type: type
            ) 
            | 
            "Content-Length:" any space copy length to "^M^/" 2 skip (
                locals/content-length: attempt [to integer! length]
            ) 
            | 
            "Connection:" any space [
                "keep-alive" (locals/keep-alive: yes) 
                | 
                "close" (locals/keep-alive: no)
            ] thru "^M^/" 
            | 
            thru "^M^/"
        ] 
        rest: (
            remove/part locals/buffer as-binary rest 
            if done [
                locals/on-data locals
            ]
        )
    ]
] 
on-content-data: func [locals] [
    either locals/method = "POST" [
        either locals/content-length [
            locals/on-data: :on-content-data-by-length 
            locals/on-data locals
        ] [
            either locals/keep-alive [
                locals/finished?: yes 
                locals/on-error* locals 'invalid-request
            ] [
                locals/content: locals/buffer 
                locals/on-data: none
            ]
        ]
    ] [
        locals/finished?: not locals/keep-alive 
        locals/on-request* locals 
        if locals/keep-alive [
            restart locals
        ]
    ]
] 
restart: func [locals] [
    locals/on-data: :on-header-data 
    set bind [method resource query content-type content-length content keep-alive] locals none 
    unless empty? locals/buffer [locals/on-data locals]
] 
on-content-data-by-length: func [locals] [
    if (length? locals/buffer) >= locals/content-length [
        locals/content: take/part locals/buffer locals/content-length 
        locals/finished?: not locals/keep-alive 
        locals/on-request* locals 
        if locals/keep-alive [
            restart locals
        ]
    ]
] 
chunk-buffer: make binary! 1024 
emit-chunk*: func [port data1 data2] [
    insert tail port reduce [
        to-hex (length? data1) + length? data2 "^M^/" 
        as-string data1 as-string data2 "^M^/"
    ]
]