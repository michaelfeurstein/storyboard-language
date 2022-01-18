package req nx

namespace eval StoryBoard {

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder
nx::Class create StoryboardBuilder {
	:property -accessor public {notation:required}
	:variable natural-language 0
	:variable key-value 0

	:property {sbModule:substdefault {[Module new]}}

	:variable creationStack ""
	:variable creationBacklogStack ""
	:variable moduleStack ""

	:variable storyboardDict ""
	:variable storyboardKeyStack ""
	:variable storyboardRevDict ""

	:forward video %self creator Video
	:forward timestamp %self creator Timestamp
	:forward module %self creator Module
	:forward textpage %self creator TextPage
	:forward question %self creator Question

	:public object method new {args} {
		puts "\nStoryboardBuilder::new call $args"
		next
	}

	:public object method create {args} {
		puts "\nStoryboardBuilder::create call $args"
		next
	}

	:method init {} {
		switch -glob -- ${:notation} {
			"key-value"
			{
				# ok
				puts "notation: key-value"
				set :key-value 1
			}
			"natural-language"
			{
				# ok
				puts "notation: natural-language"
				set :natural-language 1
			}
			default
			{
				# complain
				puts stderr "notation: ${:notation} not supported"
				exit 1
			}
		}
		next
	}

	:method creator {class} {
		puts "---- creator method with class:$class stack:${:stack}"

		# SETUP COMMAND
		#
		# Key-Value Notation: generates className based on key
		# Example: video4 URL http://www.video4.com
		#
		# CNL Notation: id is explicitly set for internal referencing
		# Example: Create video with id video4
		#
		# pseudo:
		# 1) look into :stack if an id set
		# 2) if id is set, use it and remove from :stack; if not, use :className
		#

		# -- BEGIN:NL-specific
		if {${:natural-language}} {
			set result [regexp {^id ([^\s]*)} ${:stack} match sub1]
			if {!$result} {
				puts "id not found in stack - using className:${:className}"
			} else {
				puts "Result: $result\nMatch:$match\nClass ID:$sub1"
				set start [expr [string length ${:stack}] - [string length $match]]
				set :stack [string range ${:stack} [expr [string length $match] + 1] end]
				#set :stack [string trimleft ${:stack} $match]
				puts stack:${:stack}
				set :className $sub1
			}
		}
		# -- END:NL-specific

		# configInfo: provide clean variable names of class
		set configInfo [lmap slot [$class info variables] {$slot info name}]
		set intersectLists [:intersectLists $configInfo ${:stack}]

		# Setup of actual class new command
		set creation [list $class new -id ${:className} {*}$intersectLists]
		puts "creationCmd: $creation"

		if {$class eq "Module"} {
			lappend :moduleStack $creation
		} elseif {$class eq "Question"} {
			:handleQuestionCmd $creation
		} else {
			lappend :creationStack $creation
			:tryCmdStack
		}
	}

	###
	### tryCmdStack
	###
	#
	# functionality:
	# execute cmd or list of commands from :creationStack
	# if an error is raised add command to :creationBacklogStack
	#
	###

	:method tryCmdStack {} {
		while {[llength ${:creationStack}] > 0} {
			foreach c ${:creationStack} {
				try {
					set :stack [{*}$c]
				} on 5 {msg options} {
					puts "STATUS:5 --> from VIDEO instance with TIMESTAMP(s) msg: $msg "
					if {[dict exists $options customOptions]} {
						set caller [dict get [dict get $options customOptions] "caller"]
						set tslist [dict get [dict get $options customOptions] "tslist"]

						foreach i $tslist {

							# -- BEGIN:NL-specific
							if {${:natural-language}} {
								puts "trying to find main key of $i\n\nstoryboardDict:\n${:storyboardDict}"
								set mainKey [Helper getMainKey ${:storyboardDict} "id" $i]
								puts "mainKey: $mainKey i:$i"
								if {$mainKey eq ""} {
									puts "mainkey not found - continue"
									continue
								} else {
									puts "old i is $i"
									set i $mainKey
									puts "new i is $i"
								}
							}
							# -- END:NL-specific

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
								puts "adding video parameter to timestamp $tsKey in storyboard"
								dict update :storyboardDict $tsKey $tsKey {
									dict lappend $tsKey video [$caller id get]
								}
								#set :storyboardDict ;# -> not sure what this does, leave commented

								#puts new:[dict get ${:storyboardDict} [lindex ${:storyboardDict} $idxo]]; # that's the timestamp data
							} else {
								# case 2 e.g. timestamp7 was referenced and is NOT in storyboard
								# remove timestamp reference from video (i.e. set it to empty)
								puts "nothing to do here"
							}
						};# - foreach ends here

						# Check Backlog
						# add -video videoX to reference timestamp in tslist
						if {[llength ${:creationBacklogStack}] > 0} {
							foreach i ${:creationBacklogStack} {
								set idxID [lsearch $i "-id"]
								if {$idxID ne "-1"} {
									incr idxID -2
									if {[lindex $i $idxID] eq "Timestamp"} {
										incr idxID 3
										puts [lindex $i $idxID];# -> timestamp2
										set idxSE [lsearch $tslist [lindex $i $idxID]]
										if {$idxSE ne "-1"} {
											# found a timestamp on backlog
											# -> manipulate timestamp to include video reference
											puts "adding video parameter to timestamp command(s) in backlog"
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
									puts "found: [$caller id get] is in storyboard via: [lindex $e $ne]"
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
								puts "found: [lindex ${:storyboardKeyStack} $idx] is in storyboard"
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
	### handleBacklogStack
	###

	:method handleBacklogStack {} {
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
						# timestampX was referenced early but is in storyboard
						$caller destroy
						:removeCmdFromStack $c :creationBacklogStack; # remove from backlog
						lappend :creationBacklogStack $c; # and put it at the end of backlog
						puts "STATUS:BACKLOG_READD - $c"
					} else {
						$caller destroy
						:removeCmdFromStack $c :creationBacklogStack
					}
				} on 6 {msg options} {
					puts "(@[current method]) STATUS:6 --> msg: $msg"
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
					puts "(@[current method]) STATUS:OK COMMAND: $c"
					:removeCmdFromStack $c :creationBacklogStack
				}
			}
		}
	}

	###
	### handleModuleStack
	###

	:method handleModuleStack {} {
		set moduleCmd [lindex ${:moduleStack} 0]

		# look into structure and find instances from structure
		set structure [:lget $moduleCmd "-structure"]

		foreach i $structure {
			set se [Helper isInstanceAvailable ContentFragment $i]
			if {$se ne 0} {
				puts "found instance $se of type [$se info class] for ${:sbModule}"
				${:sbModule} structure add $se; # why is this added in reverse order it seems?
			}
		}

		${:sbModule} id set [:lget $moduleCmd "-id"]
		${:sbModule} title set [:lget $moduleCmd "-title"]
	}

	###
	### handleQuestion
	###

	:method handleQuestionCmd {qcmd} {
		puts "handling Question CMD: $qcmd"

		# step 1: read each parameter as in handleModuleStack
		# setp 2: build up call for questionbuilder
		# step 3: call

		# step 1
		set id [:lget $qcmd "-id"]
		set title [:lget $qcmd "-title"]
		set type [:lget $qcmd "-type"]
		set question [:lget $qcmd "-question"]

		# handle multiple answers
		# prepare answerblock START
		set answers [:lget $qcmd "-answers"]
		# the following string map
		# polishes the answers list from curly brackets
		# these brackets are used during build up
		# in CNL syntax variant
		#
		# The correct format we need is:
		# "<answer text> <correct || wrong> "<answer text>" <correct || wrong> ..."
		set answers [string map {\{ "" \} ""} $answers]
		set counter 0
		set al [list]
		set answerBlock ""
		set ac 0; # answer counter
		foreach i $answers {
			lappend al $i
			incr counter
			puts counter:$counter
			if {$counter eq 2} {
				#puts "al: $al"
				incr ac
				set old $answerBlock
				set isCorrect [string map -nocase {wrong 0 correct 1} [lindex $al 1]]
				set answerBlock "$old\n[subst [list :answer {\n:id set answer$ac \n:text set {[lindex $al 0]} \n:correct set $isCorrect \n}]]"
				set counter 0
				set al [list]
				puts "ab: $answerBlock"
			}
		}
		set ac 0
		# prepare answerblock END

		set feedback [:lget $qcmd "-feedback"]

		# step 2
		# based on djdsl/tutorials/patterns.tcl:727 ComputerBuilder
		set cmd [subst [list [QuestionBuilder new] question {
			:setAttributes $id {$title} {$type} {$question} {$feedback}
			$answerBlock
		}]]

		# step 3
		{*}$cmd
	}

	###
	### lget
	###
	#
	# input: c (the command as a list)
	# input: p (the parameter to get)
	#
	# Example:
	# c = CommandCaller new -param1 value -param2 {multiple values of interest}
	# p = -param2
	# returns {multiple values of interest}
	#
	# if parameter not found (-1) it raises an error
	#
	###

	:method lget {c p} {
		set x [lsearch $c $p]
		if {$x eq -1} {
			error "parameter $p not found in [lindex $c 0]"
		}
		incr x
		return [lindex $c $x]
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

		# try to optimized based on this comment:
		# https://github.com/michaelfeurstein/storyboard-language/commit/cc3e06741bd9a88d511908dae3664329650747b2#r57534578
		# set d "$"
		# set ls [list "lsearch $d{$s} {$c}"]
		# puts ls:$ls
		# error idx:[$ls]

		set d "$"
		set idx [eval [subst {lsearch $d{$s} {$c}}]]
		if {$idx ne -1} {
			set scmd [subst {lreplace $d{$s} {$idx} {$idx}}]
			set $s [eval [subst {lreplace $d{$s} {$idx} {$idx}}]]
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
	# A: Ja mit lmap slot [Module info variables] {$slot info name}
	#
	###

	:method intersectLists {a b} {
		set propertyList ""
		set dash "-"

		foreach i $a {
			set parameter [string trim $i "?-"]
			if { $parameter in [dict keys $b] } {
			  #puts "matched parameter:$parameter in b:$b"
			  lappend propertyList $dash$parameter [dict get $b $parameter]
			}
		}
		return $propertyList
	}

	# DYNAMIC RECEPTION
	#
	# reminder to self: not using dynamic reception
	# because some calls inside a line include known cmds
	#
	#:method unknown {v args} {
	#  puts "unknown $v"
	#  lappend :moduleStack $v
	#}

	:public method from {storyboard} {
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
		  #:$el ; # dynamic reception
		  lappend :stack $el
		}
		puts "\nNEW CALL calling:$id with stack:${:stack}"
		set :className $id
		:[Helper matchClass $id ::StoryBoard::*]
		#:creator $e
		set :stack ""
		set :className ""
	  }

	  # after running through the storyboard handle backlog
	  puts "\nReached end of storyboard - trying again with creationBacklogStack"
	  :handleBacklogStack

	  # handle module via separate call here
	  # after running through storyboard + backlog
	  # - this assures all relevant ContentFragments are instantiated
	  # - the module will then be available for Visitor
	  puts "\nLast step: Module"
	  :handleModuleStack

	  unset :stack
	  unset :className

	  # return the final storyboard module
	  return ${:sbModule}
	}; # from end
}; # StoryboardBuilder end

# based on djdsl/tutorials/patterns.tcl:690 ComputerBuilder
nx::Class create QuestionBuilder {
	:property -accessor public result:object,type=Question

	:public method question {script} {
		:result set [Question new]
		puts "script: $script"
		:eval $script
		return [self]
	}

	:public method setAttributes {id title type question feedback} {
		${:result} id set $id
		${:result} title set $title
		${:result} type set $type
		${:result} question set $question
		${:result} feedback set $feedback
	}

	:public method answer {script} {
		set ans [Answer new -childof ${:result}]
		$ans eval $script
		${:result} answers add $ans
	}
}; # QuestionBuilder end

namespace export StoryboardBuilder QuestionBuilder
}
