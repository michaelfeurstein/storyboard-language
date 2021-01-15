#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source expression_builder.tcl

# Direct instantiation of model:

# begin

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
# die ::proc ? definierst Du oben auf djdsl/tutorials/intro.tcl:40  
# versuche da noch alles drum herum im code bereich 5-55 zu verstehen. ist das eine art test umgebung?
#? {llength [ContentFragment info instances -closure]} 6
puts [llength [ContentFragment info instances -closure]]

# Internal DSL (indirect instantiation)

# begin

# Read storyboard file
set sbfile [open "storyboard_test_list" r]
set sbdata [read $sbfile]
set data_list [split $sbdata]
puts $data_list

set internalBuilder [StoryboardBuilder new]
# $internalBuilder from {$data_list}
$internalBuilder from {video {manual title} length 54321}
close $sbfile
# end
