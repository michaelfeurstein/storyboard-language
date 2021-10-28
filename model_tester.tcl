#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source parser.tcl
source visitor.tcl
source worker.tcl
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

set id "question1"
set title "Information Systems"
set type "multipleChoice"
set question "Explain the concept of an information system"
set feedback "General feedback on this question"
set a1 "Just some answer test text"
set bv 1

set cmd [subst [list [QuestionBuilder new] question {
	:setAttributes $id {$title} {$type} {$question} {$feedback}

	:answer {
		:text set "$a1"
		:correct set $bv
	}

	:answer {
		:text set {Answer 2}
		:correct set 0
	}

	:answer {
		:text set {Answer 3}
		:correct set 1
	}
}]]

puts $cmd
{*}$cmd



#puts "q1:$q1"

#Module new -id testModule

#Module new -id mySecondImpossibleModule

#Video new -id video1

# Create a testVideo and add 2 timestamps
#Video create testVideo -URL {http://www.link.com}
#testVideo createTimestamp -time 0123 -title "first"
#testVideo createTimestamp -time 4567 -title "second"

# Create a timestamp which is associated with the video above
#Timestamp create anotherTimestamp -time 4321 -title "third" -video [testVideo]

# Create a timestamp with no video association and add association later
#Timestamp create soloTimestamp -time 8910 -title "fourth"
#testVideo addTimestamp -ts [soloTimestamp]

# Create multiple timestamps with no video association and add all timestamps as list later
#set listofts ""
#lappend listofts [Timestamp create oneTimestamp -time 8910 -title "one"]
#lappend listofts [Timestamp create twoTimestamp -time 1112 -title "two"]
#lappend listofts [Timestamp create threeTimestamp -time 1314 -title "three"]
#lappend listofts [Timestamp new]
#puts listofts:$listofts

#testVideo addTimestampList -tslist $listofts

# a module
#Module create testModule -title "My first module" -structure {element1, element2, element3}

# end

#puts "\nModule: [llength [Module info instances -closure]] title: [[Module info instances -closure] id get]"


#puts "[testVideo info class]::[testVideo info name] URL:[testVideo URL get]"
#puts "children:[testVideo info children]"
#foreach x [testVideo info children] {
#	puts "found timestamp title:[$x title get] with time:[$x time get] "
#}

#? {llength [ContentFragment info instances -closure]} 6
#puts Videos:[llength [Video info instances -closure]]
#puts Timestamp:[llength [Timestamp info instances -closure]]
#puts Module:[llength [Module info instances -closure]]

#[testVideo] destroy

puts "\n--- Instantiations from storyboard file:$storyboardFile\n"

# Setup Parser
set internalParser [StoryboardParser new -storyboardFile $storyboardFile]

# Setup Expression Builder
set internalBuilder [StoryboardBuilder new]
puts "internalBuilder $internalBuilder"

# Call method from with a storyboard
set module [$internalBuilder from [$internalParser storyboardDict get]]
puts "\nModule Object: $module"

#// visitor //
puts "\n--- Visitor call on module object: $module"
set visitor [HTMLVisitor new]
set r [$visitor evaluate $module]
#// end //

puts "\nQuestionBuilder: [llength [QuestionBuilder info instances -closure]]"

puts "\nModule: [llength [Module info instances -closure]]"
puts " - id: [[Module info instances -closure] id get]"
puts " - title: [[Module info instances -closure] title get]"
puts " - structure: [[Module info instances -closure] structure get]"

puts "\nVideos: [llength [Video info instances -closure]]"
foreach x [Video info instances -closure] {
	puts "found class $x with id:[$x id get] timestamp:[$x timestamp get] or children:[$x info children]"
	foreach el [$x info children] {
		puts child:[$el id get]
	}
}
puts "\nTimestamp:[llength [Timestamp info instances -closure]]"
foreach x [Timestamp info instances -closure] {
	puts "found class $x with id:[$x id get]"
	foreach el [$x info parent] {
		puts parent:$el
	}
}
