REBOL [
	Title: "Run benchmarks"
	Author: "Gabriele Santilli"
]

time*: func [n block /local start] [
	start: now/precise
	loop n block
	difference now/precise start
]
time: func [count block /local time result] [
	time: 0:00
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

change-dir %../
do %mezz/module.r
load-module/from what-dir

run-benchmark: func [file /local benchs name blk results cnt] [
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
			set name word! set cnt integer! set blk block! (
				insert insert tail results name time cnt blk
			)
		]
	]
	save-results join %benchs/results/ [current-version %/ file] results
]

save-results: func [file results] [
	make-dir/deep first split-path file
	save file results
]

show-results: func [file /local lay results r max-speed] [
	lay: compose [
		Across
		Banner white (join "Results for " file) Return
		Text "Longer bar means faster" Return
	]
	results: copy [ ]
	max-speed: 0
	foreach version read %benchs/results/ [
		repend results [version r: load join %benchs/results/ [version file]]
		foreach [name result] r [
			max-speed: max 1 / result max-speed
		]
	]
	foreach [version results] results [
		append lay compose [
			Text (join "Version " version) Return
		]
		foreach [name result] results [
			append lay compose [
				Text 150 (form name)
				Box red (as-pair 600 / (result * max-speed) 22) Return
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
