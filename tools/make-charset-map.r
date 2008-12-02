REBOL [
    Title: "Create charset maps"
    Author: "Gabriele Santilli"
]

encode-utf8: func [
    "Encode a code point in UTF-8 format"
    char [integer!] "Unicode code point"
] [
    if char <= 127 [
        return as-string to binary! reduce [char]
    ]
    if char <= 2047 [
        return as-string to binary! reduce [
            char and 1984 / 64 + 192
            char and 63 + 128
        ]
    ]
    if char <= 65535 [
        return as-string to binary! reduce [
            char and 61440 / 4096 + 224
            char and 4032 / 64 + 128
            char and 63 + 128
        ]
    ]
    if char > 2097151 [return ""]
    as-string to binary! reduce [
        char and 1835008 / 262144 + 240
        char and 258048 / 4096 + 128
        char and 4032 / 64 + 128
        char and 63 + 128
    ]
]

parse-hex: func [h] [to integer! debase/base next next h 16]

make-charset-map: func [url /local map] [
    url: read/lines url
    remove-each line url [any [empty? line line/1 = #"#"]]
    forall url [
        url/1: parse/all url/1 "^-"
        url/1/1: parse-hex url/1/1
        url/1/2: either empty? url/1/2 [63] [parse-hex url/1/2]
    ]
    map: array 256
    foreach line url [poke map line/1 + 1 as-binary encode-utf8 line/2]
    map
]

make-all: [
    write %charsets.txt ""
    foreach url [
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-2.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-3.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-4.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-5.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-6.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-7.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-8.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-9.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-10.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-11.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-13.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-14.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-15.TXT
        http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-16.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP874.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1250.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1252.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1253.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1254.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1255.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1256.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1257.TXT
        http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1258.TXT
    ] [
        name: second split-path url
        name: copy/part name find/last name #"."
        prin "."
        write/append %charsets.txt rejoin [
            name ": make-encoding " mold make-charset-map url
            newline newline
        ]
    ]
    print ""
]

halt
