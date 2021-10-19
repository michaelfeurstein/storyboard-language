package req nx

namespace eval StoryBoard {

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder
nx::Class create StoryboardBuilder {

	:variable creationStack ""
	:variable creationBacklogStack ""

	:variable storyboardDict ""
	:variable storyboardKeyStack ""
	:variable storyboardRevDict ""

	:forward video %self creator Video
	:forward timestamp %self creator Timestamp
	:forward module %self creator Module

	:method creator {class} {
		puts "\n ---- creator method with class:$class stack:${:stack}"

		# intersect create info of class with stack
		#set configInfo [$class info lookup syntax create]
		set configInfo [lmap slot [$class info variables] {$slot info name}]
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
					puts "STATUS:5 --> from VIDEO instance with TIMESTAMP msg: $msg "
					if {[dict exists $options customOptions]} {
						set caller [dict get [dict get $options customOptions] "caller"]
						set tslist [dict get [dict get $options customOptions] "tslist"]

						foreach i $tslist {
						set idx [lsearch ${:storyboardDict} $i]
						if {$idx ne "-1"} {
							# case 1 e.g. timestamp7 was referenced early but is in storyboard
							set idxo $idx
							set idxn [incr idx]
							set tsKey [lindex ${:storyboardDict} $idxo] ;# -> e.g. timestamp7
							set tsParam [lindex ${:storyboardDict} $idxn] ;# -> time 777 title Seven

							puts "tsKey: $tsKey"
							puts "tsParam: $tsParam"

							#set oldtsdata [dict get ${:storyboardDict} [lindex ${:storyboardDict} $idxo]]; # that's the timestamp data

							# update the storyboard
							#
							# based on: https://wiki.tcl-lang.org/page/dict+lappend
							# insert/append video [$caller id get] into timestampX
							# timestamp7 {time 777 title Seven} --> timestamp7 {time 777 title Seven video video8}
							#
							dict update :storyboardDict $tsKey $tsKey {
								dict lappend $tsKey video [$caller id get]
							}
							#set :storyboardDict ;# -> not sure what this does, leave commented

							puts new:[dict get ${:storyboardDict} [lindex ${:storyboardDict} $idxo]]; # that's the timestamp data
						} else {
							# case 2 e.g. timestamp7 was referenced and is NOT in storyboard
							# remove timestamp reference from video (i.e. set it to empty)
							puts "nothing to do here"
							#set makeEmpty [dict get [dict get $options customOptions] "makeEmpty"]
							#set command [list $caller {*}$makeEmpty]
							#{*}$command
							#:removeCmdFromStack $c :creationStack
							#puts "STATUS:OK - break"
							#break
						}
						};# - foreach ends here

						# Check Backlog
						# add -video videoX to reference timestamp in tslist
						if {[llength ${:creationBacklogStack}] > 0} {
							puts "checking backlog"
							foreach i ${:creationBacklogStack} {
								set idxID [lsearch $i "-id"]
								if {$idxID ne "-1"} {
									incr idxID -2
									if {[lindex $i $idxID] eq "Timestamp"} {
										incr idxID 3
										puts [lindex $i $idxID];# -> timestamp2
										set idxSE [lsearch $tslist [lindex $i $idxID]]
										if {$idxSE ne "-1"} {
											# found a timestamp  on backlog
											:removeCmdFromStack $i :creationBacklogStack
											lappend i "-video" [$caller id get]
											puts i_new:$i
											lappend :creationBacklogStack $i
											puts "STATUS:BACKLOG_READD - $i"
										}
									}
								}
							}
						}

						# we don't need the command with the timestamp list anymore, remove this parameter completely
						# the correct timestamps will be added through the backlog
						puts "removing timestamp parameter from video command"
						set idxts [lsearch $c "-timestamp"]
						set newC [lreplace $c $idxts [incr idxts]]
						## end - redundant code

						$caller destroy
						:removeCmdFromStack $c :creationStack
						lappend :creationBacklogStack $newC
						puts "STATUS:BACKLOG - $newC"
					};# -> if ends here
				} on 6 {msg options} {
					puts "STATUS:6 --> from TIMESTAMP instance msg: $msg"
					if {[dict exists $options customOptions]} {
						set key [dict get [dict get $options customOptions] "key"] ;# -> timestamp
						set caller [dict get [dict get $options customOptions] "caller"] ;# -> ::Timestamp
						set foundTS 0
						set foundV 0

						# Find timestamp reference in storyboard
						# works with single timestamp and timestamp list
						# for cases where timestamp is created without video reference
						foreach e [dict keys ${:storyboardRevDict}] {
							set idxe [lsearch $e $key] ;# -> search for key timestamp
							if {[lindex $e $idxe] eq $key} {
								# if timestamp key found incr into next element
								# this could be: "timestamp timestamp7" or "timestamp (ts1, ts2, ts3)"
								set ne [incr idxe]
								if {[lsearch [lindex $e $ne] [$caller id get]] ne "-1"} { ;# -> search for timestamp reference
									# found element / go ahead and create the timestamp
									puts "found: [$caller id get] in storyboard via: [lindex $e $ne]"
									set foundTS 1
									continue
								}
							}
						}

						# Find video in storyboard
						# for cases where timestamp is created first with video reference
						if {[$caller video get] ne "empty"} {
							set idx [lsearch ${:storyboardKeyStack} [$caller video get]]
							if {$idx ne "-1"} {
								puts "found referenced video: [lindex ${:storyboardKeyStack} $idx] in storyboard"
								set foundV 1
							}
						}

						if {$foundTS || $foundV} {
							$caller destroy
							lappend :creationBacklogStack $c
							:removeCmdFromStack $c :creationStack
							puts "STATUS:BACKLOG - $c"
						} else {
							$caller destroy
							:removeCmdFromStack $c :creationStack
							puts "STATUS:DELETED"
						}
					}
				} on 8 {msg options}  { 
					puts "STATUS:8 --> from MODULE msg: $msg"
					if {[dict exists $options customOptions]} {
						set structure [dict get [dict get $options customOptions] "structure"] ;# -> structure
						set caller [dict get [dict get $options customOptions] "caller"] ;# -> ::Module
						puts "structure: $structure"
						puts "caller: [$caller id get]"
						#[Helper isInstanceAvailable x y]
						:removeCmdFromStack $c :creationStack
					}
				} on error {msg} {
					puts "STATUS:ERROR: $msg"
					error $msg
				} on ok {msg} {
					puts "STATUS:OK --> msg:$msg"
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
	#	set d "$"
	# 	set ls [list "lsearch $d{$s} {$c}"]
	#	puts ls:$ls
	#	error idx:[$ls]
	  	
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
				try {
					set :stack [{*}$c]
				} on 5 {msg options} {
					puts "(@[current method]) STATUS:5 --> from VIDEO instance msg: $msg"
					set caller [dict get [dict get $options customOptions] "caller"]
					set notFound [dict get [dict get $options customOptions] "not found"]
					set idx [lsearch ${:storyboardKeyStack} $notFound]
					if {$idx ne "-1"} {
						# case 1 e.g. timestamp1 was referenced early but is in storyboard
						puts "case 1"

						#a
						#set makeEmpty [dict get [dict get $options customOptions] "makeEmpty"]
						#set command [list $caller {*}$makeEmpty]
						#{*}$command
						#:removeCmdFromStack $c :creationBacklogStack

						#b
						$caller destroy
						:removeCmdFromStack $c :creationBacklogStack; # remove from backlog
						lappend :creationBacklogStack $c; # and put it at the end of backlog

						puts "STATUS:BACKLOG_READD - $c"
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
					puts c:$c
					#:removeCmdFromStack $c :creationBacklogStack

					if {[dict exists $options customOptions]} {
						set key [dict get [dict get $options customOptions] "key"] ;# -> timestamp
						set caller [dict get [dict get $options customOptions] "caller"] ;# -> ::Timestamp
						set found 0

						# Find timestamp reference in storyboard
						# works with single timestamp and timestamp list
						foreach e [dict keys ${:storyboardRevDict}] {
							set idxe [lsearch $e $key] ;# -> search for key timestamp
							if {[lindex $e $idxe] eq $key} {
								# if timestamp key found incr into next element
								# this could be: "timestamp timestamp7" or "timestamp (ts1, ts2, ts3)"
								set ne [incr idxe]
								if {[lsearch [lindex $e $ne] [$caller id get]] ne "-1"} { ;# -> search for timestamp reference
									# found timestamp / timestamp referenced - put on backlog again
									puts "found: [$caller id get] in storyboard via: [lindex $e $ne]"
									set found 1
									continue
								}
							}
						}

						if {$found} {
							$caller destroy
							:removeCmdFromStack $c :creationBacklogStack
							lappend :creationBacklogStack $c
							puts "STATUS:BACKLOG_READD"
						} else {
							$caller destroy
							:removeCmdFromStack $c :creationBacklogStack
							puts "STATUS:DELETED"
						}
					}
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
		puts a:$a
		puts b:$b
		foreach i $a {
			set parameter [string trim $i "?-"]
			if { $parameter in [dict keys $b] } {
			  puts "matched parameter:$parameter in b:$b"
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
	#
	# reminder to self: not using dynamic reception
	# because some calls inside a line include known cmds
	#
	#:method unknown {v args} {
	#  lappend :stack $v
	#}

	:public method from {storyboard} {
	  # storyboardDict
	  set :storyboardDict $storyboard

	  # storyboardKeyStack stores all objects to be created
	  foreach id [dict keys ${:storyboardDict}] {
		lappend :storyboardKeyStack $id
	  }

	  # storyboardRevDict allows for easier searching of object attributes
	  set :storyboardRevDict [lreverse ${:storyboardDict}]

	  # run through the storyboard
	  foreach id [dict keys ${:storyboardDict}] {
		foreach el [dict get ${:storyboardDict} $id] {
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
