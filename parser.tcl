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
		if {[file isfile [:storyboard get]]} {
			puts "parser -- storyboard is regular file"
			set sbfile [open [:storyboard get] r]
			set sbdata [read -nonewline $sbfile]
			close $sbfile
		} else {
			puts "parser -- storyboard is not a file"
			set sbdata [:storyboard get]
		}

		if {[string is space $sbdata]} {
			error "storyboard is empty"
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

			puts line:$line
			lappend :storyboardLinesList $line
		}

		#puts "storyboardLinesList:${:storyboardLinesList}"
		#puts "storyboardLinesList length:[llength ${:storyboardLinesList}]"

		# TODO check each line
		# - check for overwritings e.g. time defined twice in timestamp - see case 11

		:createDictFromList ${:storyboardLinesList}
		puts "\nparser -- storyboardDict:\n${:storyboardDict}"
		}

	:method createDictFromList {l} {
		foreach ele $l {
			#puts "element:[string trim $ele]"
			#puts "element: $ele"
			# create a dict based on the line elements
			# this depends on the final syntax of storyboardfile
			# for now - until syntax variant a is decided on - .
			dict set :storyboardDict {*}$ele
		}
	}
}

namespace export StoryboardParser
}
