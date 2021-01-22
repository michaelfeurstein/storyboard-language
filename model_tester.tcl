#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source parser.tcl
source expression_builder.tcl

set storyboardFile ""

if { $argc != 1 } {
  	puts "model_tester.tcl requires a storyboard as input"
	puts "For example, tclsh model_tester.tcl storyboard_example_A_01_blank"  
	exit
} else {
	set storyboardFile [lindex $argv 0]
}

puts "storyboardFile:$storyboardFile"

# Direct instantiations of model:

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

#? {llength [ContentFragment info instances -closure]} 6
puts ContentFragments:[llength [ContentFragment info instances -closure]]
puts Highlights:[llength [Highlight info instances -closure]]

# Setup Parser
set internalParser [StoryboardParser new -storyboardFile $storyboardFile]

# Internal DSL (indirect instantiation)

# begin

set internalBuilder [StoryboardBuilder new]
$internalBuilder from [$internalParser storyboardDict get]

# end
puts ContentFragments:[llength [ContentFragment info instances -closure]]
puts Highlights:[llength [Highlight info instances -closure]]
