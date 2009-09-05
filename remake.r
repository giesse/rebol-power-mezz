REBOL [
	Title: "Generate the Makefile"
	Author: "Gabriele Santilli"
]

conf: context [
	rebol: rebview: none
]

if exists? %.conf [
	attempt [conf: construct/with load %.conf conf]
]

.hgignore: {.*~$
.*\.swp$
^^index.(rlp|html)$
^^Makefile$
^^output.r$
^^test.html$
^^.conf$
^^tools/last-file.tmp$
^^tests/data/[ab]$
^^benchs/results
}

ask-default: func [question default] [
	question: ask join question [" [" default "]: "]
	either empty? question [default] [question]
]

unless conf/rebol [
	conf/rebol: ask "Path to REBOL: "
]
unless conf/rebview [
	conf/rebview: ask-default "Path to REBOL/View" conf/rebol
]

files: [ ]

collect-rlps: func [dir] [
    foreach file read dir [
        file: dir/:file
        either dir? file [
            collect-rlps file
        ] [
            if %.rlp = suffix? file [append files copy/part file skip tail file -4]
        ]
    ]
]

foreach dir read %./ [
	if dir? dir [
		collect-rlps dir
	]
]
foreach file sort files [
	repend .hgignore [
		#"^^" file ".html$" newline
		#"^^" file ".r$" newline
	]
]
write %.hgignore .hgignore

makefile: {# Makefile generated by remake.r
}
repend makefile [
	{REBOL = "} conf/rebol {"} newline
	{REBVIEW = "} conf/rebview {"} newline
	"WETAN = ${REBVIEW} -qws tools/wetan-test.r" newline
	newline
]

append makefile {all:}
foreach file files [append makefile reduce [#" " file %.r]]
append makefile { index.html

Makefile: */*.rlp */*/*.rlp remake.r
	${REBOL} -qws remake.r

index.html: index.rlp
	${WETAN} `pwd`/index.rlp

index.rlp: */*.rlp */*/*.rlp mkindex.r index-template.rlp
	${REBOL} -qws mkindex.r

tests: all
	${REBVIEW} -qws tests/run.r

all-tests: all
	${REBVIEW} -qws tests/run.r force

benchs: all
	${REBVIEW} -qws benchs/run.r

}
foreach file files [
	append makefile reduce [
		file {.r: } file {.rlp} newline
		tab {${WETAN} `pwd`/} file {.rlp} newline
		newline
	]
]

write %Makefile makefile
save/all %.conf third conf
