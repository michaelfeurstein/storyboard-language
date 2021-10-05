package req nx

# Parser
# reads a storyboard file with a given syntax variant
# outputs a dict which is readable by expression builder

nx::Class create StoryboardParser {
	:property -accessor public {storyboardFile:required}
	:property storyboardLinesList
	:property -accessor public {storyboardDict:substdefault {[dict create]}}

	:method init {} {
		:readStoryboard
	}

	:method readStoryboard {} {
		#puts "storyboardFile [:storyboardFile get]"
	  	#puts "storyboardFile ${:storyboardFile} or [[self] storyboardFile get] or [:storyboardFile get]"
	  	set sbfile [open [:storyboardFile get] r]
		set sbdata [read -nonewline $sbfile]
		close $sbfile

		set lines [split $sbdata "\n"]
		foreach line $lines {
			# remove comments
		  	regsub -all -line "#.*$" $line "" line

			# remove leading and trailing spaces
			set line [string trim $line]

			# remove empty lines
			if {$line eq ""} {continue}

			#puts line:$line
			lappend :storyboardLinesList $line
		} 
		
		#puts "storyboardLinesList:${:storyboardLinesList}"
		#puts "storyboardLinesList length:[llength ${:storyboardLinesList}]"

		:createDictFromList ${:storyboardLinesList}
		}

	:method createDictFromList {l} {
		foreach ele $l {
			#puts "element:[string trim $ele]"
			# create a dict based on the line elements
			# this depends on the final syntax of storyboardfile
			# for now - until syntax variant a is decided on - .
			dict set :storyboardDict {*}$ele
		}
	}
}
