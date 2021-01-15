#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source expression_builder.tcl

# Direct instantiation of model:

# begin

# @Stefan: in djdsl/tutorials/intro.tcl verwendest Du new. Worin liegt der Unterschied zu create - einfach nur, dass ich keinen 'name' angeben muss (laut https://www.tcl.tk/man/tcl8.6/TclCmd/class.htm#M9) ?

Text new
Image new
Video new

Text create testText
Image create testImage

Video create testVideo -title {Test Video} -videoSource {http://www.youtube.com/12345} -length 12345

# end

puts [testVideo::highlight crop get]
puts [testVideo::highlight title get]
puts [testVideo::highlight starttime get]
puts [testVideo::highlight endtime get]

# @Stefan: in djdsl/tutorials/intro.tcl:329 (und anderswo auch) verwendest Du ? {llength [Expr info instances -closure]} 3
# nur bekomme ich da invalid command name "?"
# ist das ein single-line conditional statement?
# übertragen aus deinem source müsste ich hier 6 instances haben
#? {llength [ContentFragment info instances -closure]} 6
puts [llength [ContentFragment info instances -closure]]

# Internal DSL (indirect instantiation)

# begin

# Read storyboard file
# @Stefan: hier stehe ich gerade an bezüglich tcl kenntnisse list,dict einlesen auslesen... vom verständnis her lese ich hier die syntax aus einer verschachtelten tcl-list oder dict oder json ein (siehe auch dein punkt a in mail vom 29.10.20).
set sbfile [open "storyboard_test_list" r]
set sbdata [read $sbfile]
set data_list [split $sbdata]
puts $data_list

set internalBuilder [StoryboardBuilder new]
$internalBuilder from {video {manual title} length 54321}
close $sbfile
# end
