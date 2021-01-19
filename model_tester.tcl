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

set internalBuilder [StoryboardBuilder new]

# Read storyboard file
set sbfile [open "storyboard_example_A_02_yaml" r]
set sbdata [read -nonewline $sbfile]
close $sbfile

#set data_list [split $sbdata]
puts $sbdata
set splitCont [split $sbdata "\n"]
puts $splitCont
puts [llength $splitCont]

# CONTINUE HERE: proper passing of input data & clarify data content structure
foreach ele $splitCont {
	puts "element:[string trim $ele]"
	#$internalBuilder from {$ele}
}



#$internalBuilder from {$sbdata}
#$internalBuilder from {video {manual title} length 54321}

# end
