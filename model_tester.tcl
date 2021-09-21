#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source parser.tcl
source expression_builder.tcl

namespace import StoryBoard::*

set storyboardFile ""

if { $argc != 1 } {
  	puts "model_tester.tcl requires a storyboard as input"
	puts "For example, tclsh model_tester.tcl storyboard_example_A_01_blank"  
	exit
} else {
	set storyboardFile [lindex $argv 0]
}

#puts storyboardFile:$storyboardFile

puts "\n--- Direct instantiations from model_tester.tcl\n"
# begin

# Create a testVideo and add 2 timestamps 
Video create testVideo -URL {http://www.link.com}
testVideo createTimestamp -time 0123 -title "first"
testVideo createTimestamp -time 4567 -title "second"

# Create a timestamp which is associated with the video above
Timestamp create anotherTimestamp -time 4321 -title "third" -video [testVideo]

# Create a timestamp with no video association and add association later
Timestamp create soloTimestamp -time 8910 -title "fourth"
testVideo addTimestamp -ts [soloTimestamp]

# a module
#Module create testModule -title "My first module" -structure {element1, element2, element3}

# end

puts "[testVideo info class]::[testVideo info name] URL:[testVideo URL get]"
puts "children:[testVideo info children]"
foreach x [testVideo info children] {
	puts "found timestamp title:[$x title get] with time:[$x time get] "
	
}


#? {llength [ContentFragment info instances -closure]} 6
puts Videos:[llength [Video info instances -closure]]
puts Timestamp:[llength [Timestamp info instances -closure]]
puts Module:[llength [Module info instances -closure]]

[testVideo] destroy

puts "\n--- Instantiations from storyboard file:$storyboardFile\n"

# Setup Parser
set internalParser [StoryboardParser new -storyboardFile $storyboardFile]

# Internal DSL (indirect instantiation)

# begin

set internalBuilder [StoryboardBuilder new]
$internalBuilder from [$internalParser storyboardDict get]

puts Videos:[llength [Video info instances -closure]]
puts Timestamp:[llength [Timestamp info instances -closure]]
# end
