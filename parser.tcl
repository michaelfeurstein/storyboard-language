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

		#set data_list [split $sbdata]
		#puts $sbdata
		set :storyboardLinesList [split $sbdata "\n"]
		puts "storyboardLinesList:${:storyboardLinesList}"
		puts "storyboardLinesList length:[llength ${:storyboardLinesList}]"

		:createDictFromList ${:storyboardLinesList}
		}

	:method createDictFromList {l} {
		foreach ele $l {
			puts "element:[string trim $ele]"
			# TODO create a dict based on the line elements
			# this depends on the final syntax of storyboardfile
			# for now - until syntax variant a is decided on - I create a dummy dict with a video and a highlight hardcoded here.
			
		}	  
		
		# creating a hardcoded nested dict as an example
		# the video
		dict set :storyboardDict video1 videoID "myVideoID"
	   	dict set :storyboardDict video1 videoLink "videoLinkPlaceholder"
		dict set :storyboardDict video1 title "A sample video"
		dict set :storyboardDict video1 length "60"
		# the highlight
		dict set :storyboardDict highlight1 videoref "myVideoID"
		dict set :storyboardDict highlight1 title "A sample highlight"
		dict set :storyboardDict highlight1 starttime "5"
		dict set :storyboardDict highlight1 endtime "50"

		puts "dict size:[dict size ${:storyboardDict}]"
		puts ${:storyboardDict}

		foreach id [dict keys ${:storyboardDict}] {
    		puts "$id"
		}
	
	}
}
