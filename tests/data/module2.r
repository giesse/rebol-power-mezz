REBOL [
    Title: "Test module 2"
    Type: module
    Globals: [module2?]
    Exports: [g]
]

module2?: yes
print "^-Module 2 being loaded..."
g: 2
