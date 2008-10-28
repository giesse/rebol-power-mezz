REBOL [
    Title: "Generate the Power Mezz index file"
    Author: "Gabriele Santilli"
]

template: read %index-template.rlp

dirs: [
    %dialects/ "Dialects" {
This directory contains a collection of useful dialects.
}
    %mezz/ "Mezzanine functions" {
This directory contains a collection of useful mezzanine functions.
}
    %parsers/ "Parsers" {
This directory contains a collection of parsers for common formats, such as HTML and XML and so on.
}
    %schemes/ "Port schemes" {
This directory contains a collection of useful port schemes implementations (handlers).
}
]

foreach [dir title description] dirs [
    repend template [
        newline
        "===" title newline
        newline
        description
        newline
    ]
    foreach file sort read dir [
        if %.rlp = skip tail file -4 [
            parse/all read dir/:file [
                copy title thru newline
                thru "===Introduction" newline
                newline
                copy intro to "==="
            ]
            file: copy/part file: dir/:file skip tail file -4
            repend template [
                "---" title
                newline
                intro
                {== <p><a href="} file {.r">Download script</a> | <a href="} file {.html">Read documentation</a></p>} newline
                newline
            ]
        ]
    ]
]

write %index.rlp template
