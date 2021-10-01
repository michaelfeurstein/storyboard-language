package req nx

namespace eval StoryBoard {

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder 
nx::Class create StoryboardBuilder {

  	:variable retryFlag 0
	:variable creationStack ""
	:variable creationBacklogStack ""

	:forward video %self creator Video
	:forward timestamp %self creator Timestamp

	:method creator {class} {
	  	#puts "creator method with class:$class"
	
	  	# intersect create info of class with stack
	  	#puts slot:[$class getParameterOptions]
	  	set configInfo [$class info lookup syntax create]
	  	set intersectLists [:intersectLists $configInfo ${:stack}]

		# setup class new command with parameters
		#set creation [subst {$class new -childof [self] $intersectLists}]
		#set creation [subst {$class create ${:className} $intersectLists}]
		set creation [subst {$class new -id ${:className} $intersectLists}]
		puts creationCmd:$creation
		lappend :creationStack $creation
		:tryCmdStack ${:creationStack}

		#if [catch {set :stack [eval $creation]} errMsg] {
		#	puts "Error while creating ${:className}: $errMsg"
		#	# put creation command on a stack and try again later (at the end or after each iteration?)
		#	lappend :creationStack $creation
		#}
		#puts stack:${:stack}	
	}

	###
	### tryCmd
	###
	# input: cmd (a single creationCmd or a creationStack)
	#
	# functionality:
	# execute cmd or list of commands from creationStack
	# if an error is raised add command to creationBacklogStack
	#
	###
	:method tryCmdStack {cmd} {
	  	#set cmd [list $command]
	  	puts "\nstacksize:[llength $cmd]"
		if {[llength $cmd] > 0} {
		  	puts "Stack passed:$cmd"
			foreach c $cmd { 
				puts "trying $c"
				try {
					set :stack [eval $c]
				  	#[eval $c]
				} on error {msg} {
					puts "class:[$msg info class] instance:[$msg id get] stacksize:[llength $cmd]" 
					puts "c: $c"
					if {${:retryFlag}} {
						puts "retrying a second time, don't destroy, remove from stack"
						set idx [lsearch ${:creationBacklogStack} $c]
						set :creationBacklogStack [lreplace ${:creationBacklogStack} $idx $idx]
						if {[llength ${:creationBacklogStack}] == 0} {
					  		set :retryFlag 0
						}
					} elseif {${:retryFlag} == 0} {
						puts destroying:$msg
						$msg destroy
				  		puts "putting it on backlog - try again later, raising retryFlag"
						lappend :creationBacklogStack $c
						set idx [lsearch ${:creationStack} $c]
						set :creationStack [lreplace ${:creationStack} $idx $idx]
					}
					puts creationStack:${:creationStack}
					puts creationBacklogStack:${:creationBacklogStack}
					#:removeCmdFromStack $c :creationStack
				} on ok {msg} {
					puts "STATUS:OK msg:$msg"
			  		set idx [lsearch ${:creationStack} $c]
					set :creationStack [lreplace ${:creationStack} $idx $idx]
					puts creationStack:${:creationStack}
					set idx [lsearch ${:creationBacklogStack} $c]
					set :creationBacklogStack [lreplace ${:creationBacklogStack} $idx $idx]
					puts creationBacklogStack:${:creationBacklogStack}
					if {[llength ${:creationBacklogStack}] == 0} {
					  set :retryFlag 0
					}
				}
		  	}
		} else {
			puts "nothing to try/retry cmd:$cmd"
		}
	}

	:method removeCmdFromStack {c s} {
	  	puts "c:$c and s:$s"
		set d "$"
		set lscmd [subst {lsearch $d{$s} $c}]
		puts lscmd:$lscmd
	  	$lscmd
		#set idx [lsearch ${:$s} $c]
		set :$s [lreplace ${:$s} $idx $idx]
		puts $s:${:$s}
	}

	:method handleBacklog {backlog} {
		# explicitly handle the backlog
	  	puts backlog_:$backlog
		while {[llength $backlog] > 0} {
			
		}

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
	#
	###
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
	  # run through the storyboard
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
	
	  # after running through the storyboard handle backlog 
	  puts "\nReached end of storboard - trying again with creationBacklogStack"
	  set :retryFlag 1
	  :tryCmdStack ${:creationBacklogStack}
	}
}

namespace export StoryboardBuilder 
}
