package req nx

namespace eval StoryBoard {

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder 
nx::Class create StoryboardBuilder {

	:variable creationStack ""

	:forward video %self creator Video
	:forward timestamp %self creator Timestamp

	:method creator {class} {
	  	#puts "creator method with class:$class"
	
	  	# intersect create info of class with stack
	  	#puts slot:[$class getParameterOptions]
	  	set configInfo [$class info lookup syntax create]
		#puts info:[$class info lookup syntax create]
	  	set intersectLists [:intersectLists $configInfo ${:stack}]
		#puts final:$intersectLists

		# setup class new command with parameters
		#set creation [subst {$class new -childof [self] $intersectLists}]
		#set creation [subst {$class create ${:className} $intersectLists}]
		set creation [subst {$class new -id ${:className} $intersectLists}]
		puts creationCmd:$creation

		try {
			set :stack [eval $creation]
		} on error {msg} {
			puts "Error: $msg"
			lappend :creationStack $creation
		}

		#if [catch {set :stack [eval $creation]} errMsg] {
		#	puts "Error while creating ${:className}: $errMsg"
		#	# put creation command on a stack and try again later (at the end or after each iteration?)
		#	lappend :creationStack $creation
		#}
		#puts stack:${:stack}

		#switch -glob -- $class {
		#  "Video"
		#  {
		#	puts "matched a video class"
		#	#puts stacklength[llength ${:stack}]:${:stack}
		#	#puts dict:[dict keys ${:stack}]
		#	#puts [info class constructor nx::$class]
		#  	#set configInfo [[$class new] info lookup syntax configure]
		#	#puts configInfo:$configInfo	
		#	
		#	# use list to assign parameters
		#	#lassign ${:stack} a videoID b videoLink c title d length
		#	#set :stack [$class new -childof [self] $intersectLists]
		#  }
		#  "Highlight"
		#  {
		#	puts "matched a highlight class"
		#	lassign ${:stack} a videoref b title c starttime d endtime
		#	set :stack [$class new -childof [self] -starttime $starttime -endtime $endtime -title $title]
		#  } 
		#  default
		#  {
		#	puts "matched nothing"
		#  }
		# }
	}
	
	###
	### intersectLists
	###
	# input: a (a list containing create parameters e.g.: from [$class info lookup syntax create])
	# input: b (a list which is intersected with input a e.g.: a list of parsed parameters)
	# return: a string containing the elements found in input a and b coded with a preceeding dash (-)
	#
	# functionality:
	# compares input a (create parameters) with input b (a curated dict) and returns an intersection. 
	# if they match (input b is found in input a), the following pattern is created "-parameter value"
	#
	# Q: Geht das anders auch? Im NS Tutorial steht etwas von nx::Slot und nx::ObjectParameterSlot
	:method intersectLists {a b} {
		set propertyList {}
		set dash "-"
		#puts a:$a
		#puts b:$b
		foreach i $a {
		  	set parameter [string trim $i "?-"]
			if { $parameter in [dict keys $b] } {
			  #puts "matched parameter:$parameter in b:$b"
			  lappend propertyList $dash$parameter [dict get $b $parameter]
			}
		}
		return $propertyList
	}

	###
	### matchClass
	###
	# input: id (token)
	# input: ns (namespace)
	#
	# functionality:
	# trim id from trailing numbers
	# compare id case insensitive to classes in given namespace (ns) e.g. ::StoryBoard::*
	# if they match (e.g. video1 --> trimmed to video --> found in ::StoryBoard::Video) use it
	# set return to matched class (e.g. video or Video)
	#
	# TODO: also match other variants e.g. videoIntro, videopart, videoIOT425
	:method matchClass {id ns} {
	  set matchedClass ""
	  # trim id from trailing numbers
	  regsub -all {[0-9]+} $id {} id
	  #puts trimmed:$id
	  set availableClasses [info commands $ns]
	  if {[regexp -nocase "$id" $availableClasses match]} {
		#puts "found id:$id in commands:$availableClasses matched:$match"
		# Note: i could also pass $match (which is e.g. Video) instead of $id (which is video) and then remove the forward method and call :creator [:matchClass ...] directly (design question)
		set matchedClass $id
	  } else {
		set e ""
	  }
	  return $matchedClass
	}

	# DYNAMIC RECEPTION
	#:method unknown {v args} {
	#  lappend :stack $v
	#}

	:public method from {storyboard} {
	  foreach id [dict keys $storyboard] {
		foreach el [dict get $storyboard $id] {
		  # fill the stack with all elements (el) of key (id)
		  #:$el
		  lappend :stack $el
		}
		#puts "calling:$id with stack:${:stack}"
		set :className $id
		:[:matchClass $id ::StoryBoard::*]
		#:creator $e
		unset :stack
		unset :className
	  }

	  if {[llength ${:creationStack}] > 0} {
	  	puts creationStack:${:creationStack}
		foreach cmd ${:creationStack} {
			puts "retrying $cmd"
			try {
				eval $cmd
			} on error {msg} {
				puts "Error: $msg"
			}
		}
	  } else {
		puts "No creation stack to retry"
	  }
	}
}

namespace export StoryboardBuilder 
}
