REBOL [
	Title: "Run benchmarks"
	Author: "Gabriele Santilli"
]

time*: func [n block /local start] [
	start: now/precise
	loop n block
	difference now/precise start
]
time: func [block /local count time result] [
	time: 0:00
	count: 1
	while [time < 0:00:01] [
		time: time* count block
		result: divide to decimal! time count
		; multiply by two for faster convergence
		; (ie. aim for 2 seconds)
		count: 0:00:01 * count * 2 / time
	]
	result
]

current-version: has [hg] [
	call/output "hg parents --template {node}" hg: copy ""
	hg
]
version-info?: func [version /local hg] [
    version: copy/part version back tail version
    call/output rejoin [{hg log -r } version { --template "{rev} {desc|firstline}"}] hg: copy ""
    either all [not empty? hg hg: attempt [load/next hg] integer? first hg] [
        hg
    ] [
        version
    ]
]

change-dir %../
do %mezz/module.r
load-module/from what-dir

module [imports: [%mezz/profiling.r] globals: [run-benchmark]] [
    run-benchmark: func [file /local benchs name blk results] [
        reset-profiler
        benchs: load/header clean-path join %benchs/ file
        module benchs/1 reduce [benchs]
        results: copy [ ]
        parse benchs [
            object! ; skip the header
            opt [
                ; optional initialization
                'init set blk block! (do blk)
            ]
            some [
                set name word! set blk block! (
                    insert insert tail results name time blk
                )
            ]
        ]
        save-results join %benchs/results/ [current-version %/ file] results
        write join %benchs/results/ [current-version %/ file %.profile] show-profiler-results
    ]
]

save-results: func [file results] [
	make-dir/deep first split-path file
	save file results
]

show-results: func [file /local lay results r max-speed max-time] [
	lay: compose [
		Across
		Banner white (join "Results for " file) Return
		Text "Longer bar means faster" Return
	]
	results: copy [ ]
	max-speed: max-time: 0
	foreach version read %benchs/results/ [
		if exists? r: join %benchs/results/ [version file] [
			repend results [version-info? version version r: load r]
			foreach [name result] r [
				max-speed: max 1 / result max-speed
				max-time: max result max-time
			]
		]
	]
    sort/skip results 3
	foreach [title version results] results [
		append lay compose [
			Text (join "Version " title) Return
		]
		foreach [name result] results [
			append lay compose/deep [
				Text 150 (form name)
				Box red (as-pair 600 / (result * max-speed) 22) 
                Text font [size: 18 style: 'bold] (
                    join form round/to max-time / result 0.01 [
                        " (" round 1000 * to decimal! result "ms)"
                    ]
                ) [
                    if exists? r: join %benchs/results/ [(version) file %.profile] [
                        view/new layout [
                            area 600x400 font-name "Monospace" read r
                        ]
                    ]
                ] Return
			]
		]
	]
	view layout lay
]

bench-file?: func [file] [
	%.bench = skip tail file -6
]

files: [ ]
foreach file read %benchs/ [
	if bench-file? file [append files file]
]

view layout [
	Text "Select a benchmark to run:"
	l: Text-List data files
	Across
	Button "Run" [
		unless empty? l/picked [
			run-benchmark first l/picked
			show-results first l/picked
		]
	]
	Button "Quit" [quit]
]
