package req nx

namespace eval StoryBoard {

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder 
nx::Class create StoryboardBuilder {

  	:variable retryFlag 0
	:variable creationStack ""
	:variable creationBacklogStack ""
	:variable storyboardKeyStack ""

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
		puts "\ncreationCmd: $creation"
		lappend :creationStack $creation
		:tryCmdStack

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
	#
	# functionality:
	# execute cmd or list of commands from :creationStack
	# if an error is raised add command to :creationBacklogStack
	#
	###
	:method tryCmdStack {} {
		puts "Stack size: [llength ${:creationStack}]"
		puts "Stack: ${:creationStack}"
		while {[llength ${:creationStack}] > 0} {
			foreach c ${:creationStack} {
				try {
					set :stack [eval $c]
				} on 5 {msg options} {
					puts "STATUS:5 --> msg: $msg with stack: ${:stack} and command: $c"

					# is  
					puts "options: $options"
					if {[dict exists $options customOptions]} {
						puts "dict customOptions exists: [dict get $options customOptions]"
						set caller [dict get [dict get $options customOptions] "caller"]
						set notFound [dict get [dict get $options customOptions] "not found"]
						puts "caller: $caller"
						puts "notFound: $notFound"
						
						# is notFound in storyboard key list
						set idx [lsearch ${:storyboardKeyStack} $notFound]
						if {$idx ne "-1"} {
							# case 1 e.g. timestamp1 was referenced early but is in storyboard
						  	$caller destroy
							:removeCmdFromStack $c :creationStack
							lappend :creationBacklogStack $c
						} else {
							# case 2 e.g. timestamp7 was referenced and is NOT in storyboard
						  	puts "not in storyboard"
						  	set makeEmpty [dict get [dict get $options customOptions] "makeEmpty"]
							
							#### - question start
							# i want to setup this command "$caller timestamp set empty"
							# $caller being the object which threw the return code (e.g.: video instance with id video1)
							puts "caller info: [$caller info class]:[$caller id get]"
							puts "caller: $caller"
							puts "makeEmpty: $makeEmpty"

							# this works
							$caller timestamp set something
							puts "$caller timestamp is: [$caller timestamp get]"
							
							# however, i prefer it more generic within expression builder
							# tried subst $caller $makeEmpty
							# tried eval [subst $caller $makeEmpty]
							# tried $caller $makeEmpty
							# tried subst $caller [list $makeEmpty]
							set command [subst $caller $makeEmpty]
							eval $command; # throws bad option must be -nobackslashes, -nocommands etc.
							puts "$caller timestamp is: [$caller timestamp get]"
							
							#### - question end
						}
						puts "keys $key --> [dict get [dict get $options customOptions] $key]"
						}
				
					
			   	} on error {msg} {
					puts "STATUS:ERROR: $msg"
					error $msg
				} on ok {msg} {
					puts "STATUS:OK --> msg:$msg stack:${:stack}"
					:removeCmdFromStack $c :creationStack
				}
		  	}
		}

		puts "creationStack empty: ${:creationStack}"
	}

	###
	### removeCmdFromStack
	###
	#
	# input: c (the command to remove = list element)
	# input: s (the stack to operate on = the list)
	#
	# functionality:
	# removes element c from stack s
	#
	# original code:
	# set idx [lsearch ${:creationBacklogStack} $c]
	# set :creationBacklogStack [lreplace ${:creationBacklogStack} $idx $idx]
	# puts creationBacklogStack:${:creationBacklogStack}
	#
	###
	:method removeCmdFromStack {c s} {
		set d "$"
	  	set idx [eval [subst {lsearch $d{$s} {$c}}]]
		if {$idx ne -1} {
			set scmd [subst {lreplace $d{$s} {$idx} {$idx}}]
			set $s [eval [subst {lreplace $d{$s} {$idx} {$idx}}]]
		}
	}

	:method handleBacklogStack {} {
	  	# CONTINUE HERE: maybe think of structuring the backlog as a dict with structure 
	  	# dict set backlog call1 command $c
	  	# dict set backlog call1 instance ${value from customOptions dict = [self], which is the instance of $c} 
	  	# dict set backlog call1 error ${value from customOptions dict = timestamp7}
	  	# dict set backlog call1 errorClass ${value from customOptions dict = ::Timestamp}		
		# explicitly handle the backlog
	  	# 
	  	# logic
	  	# try cmd
	  	# check if instance is already there
	  	puts "Stack size: [llength ${:creationBacklogStack}]"
		puts "Backlog stack: ${:creationBacklogStack}"
		set count 0
		set maxTries [llength ${:creationBacklogStack}]
		while {[llength ${:creationBacklogStack}] > 0} {
			foreach c ${:creationBacklogStack} {
				try {
					# try cmd from backlog stack
					set :stack [eval $c]
				} on 5 {msg options} {
					puts "return msg: $msg"
					# do something if error
					# keep on stack
					# try ${:stack} destroy
					# if (++count == maxTries) throw e;
				} on error {msg} {
					puts "unknown error: $msg"
					# do something
					:removeCmdFromStack $c :creationBacklogStack
				} on ok {} {
					# on success remove cmd from backlog stack
					:removeCmdFromStack $c :creationBacklogStack
				}
			}
		}

		puts "creationBacklogStack empty: ${:creationBacklogStack}"
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
	  # run through the storyboard keys
	  foreach id [dict keys $storyboard] {
		lappend :storyboardKeyStack $id
	  }

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
	  }
	
	  # after running through the storyboard handle backlog 
	  puts "\nReached end of storyboard - trying again with creationBacklogStack"
	  :handleBacklogStack

	  unset :stack
	  unset :className
	}
}

namespace export StoryboardBuilder 
}
