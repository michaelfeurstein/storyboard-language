package req nx

#
# ContentFragment
# A content fragment resembles an atomic element of its own type (video, text, image).
# Multiple content fragments can be combined into content objects such as a website (text + image).
# Content objects form Learning Objects.
#

nx::Class create ContentFragment

nx::Class create Text -superclasses ContentFragment
nx::Class create Image -superclasses ContentFragment

#
# Video 
# A video is of type ContentFragment.
# A video may have multiple highlights.
#
# videoSource (file location or link)
# length in seconds (starttime=0s, endtime=length) 
#

nx::Class create Video -superclasses ContentFragment {
	:property -accessor public {title,required}
	:property -accessor public {videoSource,required}
	:property -accessor public {length:integer}

	# Every video per default is a highlight
	# @Stefan: schaffe es hier grad nicht title starttime und endtime von self zu übergeben
	:method init {} { Highlight create [self]::highlight -title [self]:title -starttime 0 -endtime 100} 
}

#
# Video Highlight (see AuthTask01)
# A highlight is associated with exactly one video / a video may have multiple highlights
# Another way to think of highlights is chapters or segments
# A highlight has a start time and an end time.
# It needs a textual title in order to provide a clickable link for a GUI.
# A highlight can be cropped, which means that only the time range is shown in the final result for the viewer
#

nx::Class create Highlight {
	:property -accessor public {starttime:integer}
	:property -accessor public {endtime:integer}
	:property -accessor public {title}
	:property -accessor public {crop:boolean false}
	
	:variable timeRange

	:public method getTimeRange {} {
  		set :timeRange [ $endtime - $starttime]
		return ${:timeRange}
	}	  
}


