namespace eval StoryBoard {

# Parser
# reads a storyboard file with a given syntax variant
# outputs a dict which is readable by expression builder

nx::Class create StoryboardParser {
	:property -accessor public {storyboard:required}
	:property storyboardLinesList
	:property -accessor public {storyboardDict:substdefault {[dict create]}}

	:method init {} {
		:readStoryboard
	}

	:method readStoryboard {} {
		#puts "storyboardFile [:storyboardFile get]"
		#puts "storyboardFile ${:storyboardFile} or [[self] storyboardFile get] or [:storyboardFile get]"
		set sbdata ${:storyboard}

		if {[string is space $sbdata] || $sbdata eq ""} {
			[::StoryBoard::ErrorHandler emptyStoryboard]
		}

		puts "parser -- sbdata:$sbdata"
		set lines [split $sbdata "\n"]
		set :storyboardLinesList [list]
		foreach line $lines {
			# remove comments
			regsub -all -line "#.*$" $line "" line

			# remove leading and trailing spaces
			set line [string trim $line]

			# remove empty lines
			if {$line eq ""} {continue}

			# substitute all (*) with {*}
			set line [string map {\( "{" \) "}"} $line]
			set line [string map {, ""} $line]

			#puts line:$line
			set line [:prepareLine $line]
			lappend :storyboardLinesList $line
		}

		#puts "storyboardLinesList:${:storyboardLinesList}"
		#puts "storyboardLinesList length:[llength ${:storyboardLinesList}]"

		# TODO check each line
		# - check for overwritings e.g. time defined twice in timestamp - see case 11

		:createDictFromList ${:storyboardLinesList}
		#puts "\nparser -- storyboardDict:\n${:storyboardDict}"
		}

	:method prepareLine {the_line} {
		set result ""

		# match the first word with available classes
		set type [::StoryBoard::Helper matchClass $the_line ::StoryBoard::*]

		if {$type eq "module"} {
			return $the_line
		}

		set result $type

		# trimleft away the type (2 times for whitespace)
		set the_line [string trimleft [string trimleft $the_line $type]]

		# add type with space (i know, this is hacky)
		append result $the_line
		return $result
	}

	:method createDictFromList {l} {
		foreach ele $l {
			#puts "element:[string trim $ele]"
			#puts "element: $ele"
			# create a dict based on the line elements
			# this depends on the final syntax of storyboardfile
			# for now - until syntax variant a is decided on - .
			try {
				dict set :storyboardDict {*}$ele
			} on error {errorMsg} {
				[::StoryBoard::ErrorHandler line_not_formed_well $ele]
			}
		}
	}
}

namespace export StoryboardParser
}
