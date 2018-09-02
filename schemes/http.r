REBOL [
    Title: "Better HTTP"
    File: %http.r
    Type: 'Module
    Purpose: {
        This program replaces the HTTP protocol scheme with a better
        implementation that supports HTTP/1.1 and chunked encoding.
    }
    Author: "Gabriele Santilli"
    License: {
        =================================
        A message from Silent Software about this source code:

        We have selected the MIT license because it is the closest “standard”
        license to our intent.  If we had our way, we would declare this source
        as public domain, with absolutely no strings attached, not even the
        string that says you have to have strings.  We want to help people, so
        please feel free to contact us if you have questions.
         

        (you only need to include the standard license text below in your
        homage to this source code)
        =================================

        Copyright 2012 Silent Software, Inc.

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    }
    Version: 1.0.0
    Imports: [
        %parsers/common-rules.r
    ]
    Exports: [
    ]
]

make Root-Protocol [
    open: func [port] [
        port/locals: context [
            method: 'GET 
            headers: [] 
            content: none 
            response-line: none 
            response-parsed: none 
            response-headers: none 
            chunked?: no 
            chunked-buffer: none
        ] 
        parse-custom-data port 
        open-sub-port port 
        do-request port 
        parse-response port 
        port/size: any [attempt [to integer! port/locals/response-headers/Content-Length] 0] 
        port/date: attempt [parse-header-date port/locals/response-headers/Last-Modified] 
        port/status: 'file
    ] 
    query: func [port] [
        if not port/locals [
            port/state/custom: [HEAD] 
            open port 
            attempt [close port]
        ] 
        reduce [
            port/locals/response-parsed 
            port/size 
            port/locals/response-headers/content-type
        ]
    ] 
    close: func [port] [
        close-sub-port port
    ] 
    read: func [port data /local result desired chunk-size] [
        either port/locals/chunked? [
            desired: port/state/num 
            if port/locals/chunked-buffer [
                desired: min desired length? port/locals/chunked-buffer 
                insert/part tail data port/locals/chunked-buffer desired 
                remove/part port/locals/chunked-buffer desired 
                if empty? port/locals/chunked-buffer [port/locals/chunked-buffer: none] 
                return desired
            ] 
            chunk-size: pick port/sub-port 1 
            parse/all chunk-size [some hexdigit | (net-error [access protocol "Invalid chunked encoding"])] 
            chunk-size: to integer! to issue! chunk-size 
            either chunk-size = 0 [
                while ["" <> pick port/sub-port 1] [] 0
            ] [
                result: read-io port/sub-port data min desired chunk-size 
                chunk-size: chunk-size - result 
                if chunk-size > 0 [port/locals/chunked-buffer: make binary! chunk-size + 10] 
                while [chunk-size > 0] [
                    chunk-size: chunk-size - read-io port/sub-port port/locals/chunked-buffer chunk-size
                ] 
                result
            ]
        ] [
            read-io port/sub-port data port/state/num
        ]
    ] 
    net-utils/net-install HTTP self 80 
    net-utils/net-install HTTPS self 443
] 
open-sub-port: func [port /local sub-protocol secure?] [
    sub-protocol: either port/scheme = 'https [secure?: yes ['ssl]] [['tcp]] 
    port/sub-port: open/lines compose [
        scheme: (sub-protocol) 
        host: port/host 
        port-id: port/port-id
    ] 
    port/sub-port/timeout: port/timeout 
    if secure? [set-modes port/sub-port [secure: true]]
] 
close-sub-port: func [port] [
    close port/sub-port
] 
do-request: func [
    "Perform an HTTP request" 
    port [port!] 
    /local headers target
] [
    headers: make context [
        Accept: "*/*" 
        Accept-Charset: "utf-8" 
        Host: either port/port-id <> either port/scheme = 'https [443] [80] [
            rejoin [form port/host #":" port/port-id]
        ] [
            form port/host
        ] 
        User-Agent: "REBOL" 
        Connection: "close"
    ] port/locals/headers 
    if port/locals/content [
        headers: make headers [
            Content-Length: form length? port/locals/content
        ]
    ] 
    headers: third headers 
    target: copy %/ 
    if port/path [append target port/path] 
    if port/target [append target port/target] 
    insert port/sub-port rejoin [
        uppercase form port/locals/method #" " 
        next mold target 
        " HTTP/1.1"
    ] 
    foreach [word string] headers [
        insert port/sub-port rejoin [mold word #" " string]
    ] 
    insert port/sub-port "" 
    if port/locals/content [
        write-io port/sub-port port/locals/content length? port/locals/content
    ]
] 
parse-custom-data: func [port /local method headers content] [
    if block? port/state/custom [
        parse port/state/custom [
            opt [set method word!] 
            opt [set headers block!] 
            opt [set content any-string!]
        ] 
        if content [
            unless method [method: 'POST] 
            either headers [
                unless find headers [Content-Type:] [
                    append headers [Content-Type: "application/x-www-form-urlencoded"]
                ]
            ] [
                headers: [Content-Type: "application/x-www-form-urlencoded"]
            ]
        ] 
        if method [port/locals/method: method] 
        if headers [port/locals/headers: headers] 
        if content [port/locals/content: content]
    ]
] 
parse-response: func [port /local line header] [
    port/locals/response-line: pick port/sub-port 1 
    parse/all port/locals/response-line [
        "HTTP/1." [#"0" | #"1"] some #" " [
            #"1" (port/locals/response-parsed: 'info) 
            | 
            #"2" [["04" | "05"] (port/locals/response-parsed: 'no-content) 
                | (port/locals/response-parsed: 'ok)
            ] 
            | 
            #"3" [
                "03" (port/locals/response-parsed: 'see-other) 
                | 
                "04" (port/locals/response-parsed: 'not-modified) 
                | 
                "05" (port/locals/response-parsed: 'use-proxy) 
                | (port/locals/response-parsed: 'redirect)
            ] 
            | 
            #"4" [
                "01" (port/locals/response-parsed: 'unauthorized) 
                | 
                "07" (port/locals/response-parsed: 'proxy-auth) 
                | (port/locals/response-parsed: 'client-error)
            ] 
            | 
            #"5" (port/locals/response-parsed: 'server-error)
        ] 
        | (port/locals/response-parsed: 'version-not-supported)
    ] 
    port/locals/response-headers: copy [] 
    while ["" <> line: pick port/sub-port 1] [
        parse/all line [
            some space-char line: (append last port/locals/response-headers line) 
            | 
            copy header name #":" any space-char copy line to end (
                append port/locals/response-headers reduce [
                    to set-word! header line
                ]
            )
        ]
    ] 
    port/locals/response-headers: construct/with port/locals/response-headers http-response-headers 
    switch port/locals/response-parsed [
        ok [
            if port/locals/response-headers/transfer-encoding = "chunked" [
                port/locals/chunked?: yes
            ]
        ] 
        redirect see-other [
            net-error reduce ['access 'protocol "Redirects not supported yet"]
        ] 
        unauthorized client-error server-error proxy-auth use-proxy proxy-auth [
            net-error reduce ['access 'protocol port/locals/response-line]
        ] 
        info [
            parse-response port
        ] 
        version-not-supported [
            net-error reduce ['access 'protocol "HTTP version not supported"]
        ]
    ]
] 
http-response-headers: context [
    Content-Type: 
    Content-Length: 
    Transfer-Encoding: 
    Last-Modified: none
] 
parse-header-date: func [date] [
    parse/all date [
        opt [["Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun"] #","] 
        any space-char date:
    ] 
    to date! date
]