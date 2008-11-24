REBOL [
	Title: "Run tests"
	Author: "Gabriele Santilli"
]

test-file?: func [file] [
	%.tests = skip tail file -6
]

form-error:
    func [
        "Forms an error message"
        errobj [object!] "Disarmed error"
        /all "Use the same format as the REBOL console"
        
        /local errtype text
    ] [
        errtype: get in system/error get in errobj 'type
        text: get in errtype get in errobj 'id
        if block? text [text: reform bind/copy text in errobj 'self]
        either all [
            rejoin [
                "** " get in errtype 'type ": " text newline
                either get in errobj 'where [join "** Where: " [mold get in errobj 'where newline]] [""]
                either get in errobj 'near [join "** Near: " [mold/only get in errobj 'near newline]] [""]
            ]
        ] [
            text
        ]
    ]

run-test-file: func [file force /local results results-file result type human passed failed disp] [
	print file
	file: clean-path join %tests/ file
	passed: failed: 0
	results-file: append copy/part file skip tail file -6 %.results
	if all [exists? results-file (modified? file) > modified? results-file] [force: true]
	file: load/header file
	results: either exists? results-file [
		if get in file/1 'Tests [
			foreach source get in file/1 'Tests [
				if (modified? source) > modified? results-file [
					force: true
				]
			]
		]
		load results-file
	] [
		force: true
		copy [ ]
	]
	either force [
		until [
			file: next file
			human: copy ""
			; trick to determine if there was a throw: human is unique at this point and
			; there is no way file/1 would accidentally throw it
			either same? human catch [type: type?/word set/any 'result try file/1 human] [
				result: switch/default type [
					error! [human: form-error/all disarm :result]
					unset! ['unset!]
					string! binary! [
						human: copy/part result 20 * 1024
						if binary? human [human: mold human]
						either 255 < length? result [
							checksum/secure result
						] [
							result
						]
					]
				] [
					human: mold/all :result
					:result
				]
				either any [tail? results results/1 <> type :result <> pick results 2] [
					view layout [
						area 600x200 (mold/only file/1)
						text "For string results, only the first 20k are shown."
						disp: area 600x400 human
						across
						text "Do:" field 500 [
							disp/text: mold/all do value
							clear face/text
							show [face disp]
						] return
						button "Browse" [
							write %test.html human
							browse %test.html
						]
						button green "PASS" [
							passed: passed + 1
							change results reduce [type :result]
							unview/all
						]
						button red "FAIL" [
							failed: failed + 1
							change results [fail fail]
							unview/all
						] return
					]
				] [
					passed: passed + 1
				]
			] [
				; there has been a throw
				print "^-UNCATCHED THROW!"
				print mold/only file/1
				failed: failed + 1
				change results [throw throw]
			]
			results: skip results 2
			tail? next file
		]
		save/all results-file head results
		print [tab "PASSED:" passed newline tab "FAILED:" failed]
	] [
		print "^-Nothing new to test."
	]
	reduce [passed failed]
]

change-dir base-dir: clean-path %../
total-passed: total-failed: 0
foreach file read %tests/ [
	if test-file? file [
        change-dir base-dir
		set [passed failed] run-test-file file all [string? system/script/args find system/script/args "force"]
		total-passed: total-passed + passed
		total-failed: total-failed + failed
	]
]
print ["TOTAL PASSED:" total-passed]
print ["TOTAL FAILED:" total-failed]
