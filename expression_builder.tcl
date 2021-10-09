package req nx

namespace eval StoryBoard {

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder
nx::Class create StoryboardBuilder {

	:variable retryFlag 0
	:variable creationStack ""
	:variable creationBacklogStack ""
	:variable storyboardKeyStack ""
	:variable storyboardRevDict ""

	:forward video %self creator Video
	:forward timestamp %self creator Timestamp

	:method creator {class} {
		#puts "creator method with class:$class"

		# intersect create info of class with stack
		set configInfo [$class info lookup syntax create]
		set intersectLists [:intersectLists $configInfo ${:stack}]

		# setup class new command with parameters
		set creation [list $class new -id ${:className} {*}$intersectLists]
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
					set :stack [{*}$c]
				} on 5 {msg options} {
					puts "STATUS:5 --> from VIDEO instance msg: $msg "
					if {[dict exists $options customOptions]} {
						set caller [dict get [dict get $options customOptions] "caller"]
						set notFound [dict get [dict get $options customOptions] "not found"]

						# is notFound (e.g. timestamp7) in storyboard key list
						set idx [lsearch ${:storyboardKeyStack} $notFound]
						if {$idx ne "-1"} {
							# case 1 e.g. timestamp1 was referenced early but is in storyboard
							$caller destroy
							:removeCmdFromStack $c :creationStack
							lappend :creationBacklogStack $c
							puts "STATUS:BACKLOG"
						} else {
							# case 2 e.g. timestamp7 was referenced and is NOT in storyboard
							puts "case 2"
							set makeEmpty [dict get [dict get $options customOptions] "makeEmpty"]
							set command [list $caller {*}$makeEmpty]
							{*}$command
							:removeCmdFromStack $c :creationStack
						}
					}

				} on 6 {msg options} {
					puts "STATUS:6 --> from TIMESTAMP instance msg: $msg"
					if {[dict exists $options customOptions]} {
						set key [dict get [dict get $options customOptions] "key"]
						set caller [dict get [dict get $options customOptions] "caller"]
						set found 0

						# Find timestamp reference in storyboard
						# TODO refine for future list of timestamps
						foreach e [dict keys ${:storyboardRevDict}] {
							set idxe [lsearch $e $key]
							if {[lindex $e $idxe] eq $key} {
								set ne [incr idxe]
								if {[lindex $e $ne] eq [$caller id get]} {
									# found element / go ahead and create the timestamp
									#puts "found [lindex $e $ne] is [$caller id get]"
									set found 1
									continue
								}
							}
						}

						if {$found} {
							# found
							$caller destroy
							lappend :creationBacklogStack $c
							:removeCmdFromStack $c :creationStack
							puts "STATUS:BACKLOG"
						} else {
							# not found
							$caller destroy
							:removeCmdFromStack $c :creationStack
							puts "STATUS:DELETED"
						}
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
		puts "Stack size: [llength ${:creationBacklogStack}]"
		puts "Backlog stack: ${:creationBacklogStack}"
		#set count 0
		#set maxTries [llength ${:creationBacklogStack}]
		while {[llength ${:creationBacklogStack}] > 0} {
			foreach c ${:creationBacklogStack} {
				#puts "trying c: $c"
				try {
					# try cmd from backlog stack
					set :stack [{*}$c]
				} on 5 {msg options} {
					puts "(@[current method]) STATUS:5 --> from VIDEO instance msg: $msg"
					set caller [dict get [dict get $options customOptions] "caller"]
					set notFound [dict get [dict get $options customOptions] "not found"]
					set idx [lsearch ${:storyboardKeyStack} $notFound]
					if {$idx ne "-1"} {
						# case 1 e.g. timestamp1 was referenced early but is in storyboard
						$caller destroy
						:removeCmdFromStack $c :creationBacklogStack; # remove from backlog
						lappend :creationBacklogStack $c; # and put it at the end of backlog
					} else {
						$caller destroy
						:removeCmdFromStack $c :creationBacklogStack
					}
					# do something if error
					# keep on stack
					# try ${:stack} destroy
					# if (++count == maxTries) throw e;
				} on 6 {msg options} {
					puts "(@[current method]) STATUS:6 --> msg: $msg"
					:removeCmdFromStack $c :creationBacklogStack
				} on error {msg} {
					puts "STATUS:ERROR: $msg"
					error $msg
				} on ok {} {
					puts "(@[current method]) STATUS:OK"
					# on success remove cmd from backlog stack
					:removeCmdFromStack $c :creationBacklogStack
				}
			}
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
		set propertyList ""
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
	# match any variant of e.g. video1, videoIntro, videopart, video3a to video
	# get available classes in ns
	# tail each class (::StoryBoard::Video --> Video)
	# compare id case insensitive to tailed class
	# if they match (e.g. id:video1 --> tailed namespace:Video --> matches video) use it
	# set return to matched class (e.g. video)
	#
	###
	:method matchClass {id ns} {
	  set matchedClass ""
	  set availableClasses [info commands $ns]
	  #puts availableClasses:$availableClasses

	  foreach ns $availableClasses {
	  	set tail [namespace tail $ns]
		if {[regexp -nocase "^$tail" $id match]} {
			#puts "found $match1 in $id"
			set matchedClass $match
			break
		}
	  }

	  if {$matchedClass eq ""} {
		error "ERROR: matchClass could not match $id in $ns"
	  }

	  return $matchedClass
	}

	# DYNAMIC RECEPTION
	#:method unknown {v args} {
	#  lappend :stack $v
	#}

	:public method from {storyboard} {
	  # storyboardKeyStack stores all objects to be created
	  foreach id [dict keys $storyboard] {
		lappend :storyboardKeyStack $id
	  }

	  # storyboardRevDict allows for easier searching of object attributes
	  set :storyboardRevDict [lreverse $storyboard]

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
		set :stack ""
		set :className ""
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
