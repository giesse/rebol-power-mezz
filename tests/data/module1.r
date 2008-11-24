REBOL [
    Title: "Test module 1"
    Type: module
    Globals: [module1?]
    Imports: [%module2.r]
    Exports: [f]
]

module1?: yes
print "^-Module 1 being loaded..."
f: func [a] [a * 2 + g]
