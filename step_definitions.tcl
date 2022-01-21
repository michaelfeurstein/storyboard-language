namespace eval StoryBoard {

  nx::Class create StepDefinitions {

	##
	## setup step definitions 
	##
	#
	# create DefinitionBuilder
	# setup step definitions
	# return instance of DefinitionBuilder
	#

	:public object method setup {} {
	  set seBuilder [DefinitionBuilder new]

	  ########################
	  ########################
	  ###
	  ### Info Stefan
	  ###
	  #
	  # In the below scripts,
	  # ... one can use $0 - $n to positionally access the regex matches
	  # ... one can use [self] to access the responsible builder object implicitly
	  #
	  # Note: There can be multiple match sentences per first word (first defined, first processed)!
	  # Note: the return value of these scripts are discarded if 'result' object variable exists !
	  #
	  ###

	  # A fresh start fresh on 25.12.2021
	  #
	  # Regex cheatsheet
	  # source: https://www.fon.hum.uva.nl/praat/manual/Regular_expressions.html
	  #
	  # ^		-- match the (following) regex at the beginning of the string
	  # (.+?)	-- match:
	  #			()	= grouping
	  #			.	= matches any character except the newline symbol
	  #			+	= match the preceding regex 1 or * times
	  #			?	= match preceding regex 0 or 1 time
	  #
	  # (\d+)	-- match:
	  #			\d	= matches a digit: [0-9]
	  # (.+)	-- match:
	  #			()	= grouping
	  #			.	= matches any character except the newline symbol
	  #			+   = match the preceding regex 1 or * times
	  # (.*)
	  # ([^\s]*)-- match:
	  #			[]	= define a character class to match a single character
	  #			^	= negation if used inside square brackets
	  #			\s	= match whitespace
	  #			*	= match the preceding regex 0 or * times
	  #
	  # $		-- match the (following) regex at the end of the string
	  #
	  ########################
	  ########################

	  ###
	  ### Step Definitions
	  ###
	  #
	  # Concept:
	  # - define a keyword to match and call the sentence
	  # - use a regex for the remaining part of the sentence
	  # - convert sentence into dict structure for StoryboardBuilder (expression_builder.tcl)
	  #
	  # Keywords:
	  # CREATE: used to create an object with an id for referencing
	  # SET: used to set properties of created object
	  # ADD timestamp(s): add 1 or * objects (timestamp) to a video
	  #
	  ###
	  #
	  # TODO
	  # - possibly already check inside Add timestamp if we are adding to a video
	  #
	  ###

	  $seBuilder define Create {^([^\s]*) with id ([^\s]*)$} {
		# Approach:
		# check stackDict for created references (e.g. video1)
		# if there are videos (e.g. video1, video2 etc.) count them
		# then set a new incremented id correctly e.g. video3
		#
		# Pseudo:
		# 1) match $0 against classes in StoryBoard namespace as in expression builder
		# 2) generate a main key such as video2 depending on previous counts of this type (incr)

		puts "---\nstep definition 01 CREATE"
		puts "0:$0 1:$1"

		set type [::StoryBoard::Helper matchClass $0 ::StoryBoard::*]
		set no_of_keys [:countKeys ${:stackDict} $type]
		incr no_of_keys
		set keyName $type$no_of_keys
		#puts "type:$type found $no_of_keys time(s)"
		set ele "$keyName id $1"
		puts ele:$ele
		dict set :stackDict {*}$ele
	  }

	  $seBuilder define Create {^([^\s]*) with id ([^\s]*) and URL ([^\s]*)$} {
		puts "---\nstep definition 01a CREATE with URL"
		puts "0:$0 1:$1 2:$2"

		if {$0 eq "video"} {
			set type [::StoryBoard::Helper matchClass $0 ::StoryBoard::*]
			set no_of_keys [:countKeys ${:stackDict} $type]
			incr no_of_keys
			set keyName $type$no_of_keys

			# id
			set ele "$keyName id $1"
			dict set :stackDict {*}$ele

			# URL
			set ele "$keyName URL $2"
			dict set :stackDict {*}$ele
		} else {
			puts stderr "Creating $0 with URL \"$2\" is not allowed. Use Set URL."
			exit 1
		}
	  }

	  $seBuilder define Create {^(.*?)\s*(?:[cC]hoice)? question with id ([^\s]*)$} {
		# regex source: https://stackoverflow.com/questions/5254804/regex-optional-word-match
		puts "---\nstep definition 01b CREATE <type of> question with id"
		puts "[self] 0:$0 1:$1"

		set errMsg "\n\nSentence formulation: Create <type of> question with id <id>\n\nSupported question types and formulations are:\n\n- single choice / singleChoice\n- multiple choice / multipleChoice"

		set no_of_keys [:countKeys ${:stackDict} question]
		incr no_of_keys
		set keyName "question$no_of_keys"

		switch -glob -- $0 {
			"single" {
				puts "single choice question"

				# id
				set ele "$keyName id $1"
				dict set :stackDict {*}$ele

				# type singleChoice
				set ele "$keyName type singleChoice"
				dict set :stackDict {*}$ele
			}
			"multiple" {
				puts "multiple choice question"

				# id
				set ele "$keyName id $1"
				dict set :stackDict {*}$ele

				# type multipleChoice
				set ele "$keyName type multipleChoice"
				dict set :stackDict {*}$ele
			}
			"single*" {
				puts stderr "question type: $0 seems misspelled. Try Create single choice question with id $1. $errMsg"
				exit 1
			}
			"multiple*" {
				puts stderr "question type: $0 seems misspelled. Try Create multiple choice question with id $1. $errMsg"
				exit 1
			}
			default {
				puts stderr "question type: \"$0\" not supported. $errMsg"
				exit 1
			}
		}
	  }

	  $seBuilder define Create {^module with title (.+)$} {
		puts "---\nstep definition 01c CREATE module with title <title of module>"
		puts "0:$0"

		:createModule $0
	  }

	  $seBuilder define Create {^module titled (.+)$} {
		puts "---\nstep definition 01d CREATE module titled <title of module>"
		puts "0:$0"

		:createModule $0
	  }

	  $seBuilder define Set {^([^\s]*) of ([^\s]*) to (.+)$} {
		# dict structure:
		# video1 {id videoABC URL http://www.videolink.com} video2 {id videoDEF ...}
		#
		# pseudo:
		# 1) find key value pair "id $1" (e.g. id videoABC)
		# 2) get mainkey of this pair e.g. video1
		# 3) depending on what is set act (switch)

		puts "---\nstep definition 02 SET"
		puts "0:$0 1:$1 2:$2"

		if {$1 eq "module"} {
			# check if there is a module
			set no_of_modules [:countKeys ${:stackDict} [::StoryBoard::Helper matchClass module ::StoryBoard::*]]
			if {$no_of_modules ne 0} {
				set keyName "module"
				# polishing only here, because I want to
				# reduce the risk of a regular sentence
				# to get polished where it shouldn't
				set 2 [string map {\( "{" \) "}"} $2]
				set 2 [string map {, ""} $2]
				puts "new 2:$2"
			} else {
				puts stderr "No module available. Use Create command first."
				exit 1
			}
		} else {
			set keyName [::StoryBoard::Helper getMainKey ${:stackDict} "id" $1]
		}

		if {$keyName eq ""} {
			puts stderr "Cannot set $0 of \"$1\" because it has not been defined yet. Use Create command first."
			exit 1
		} else {
			switch -glob -- $0 {
				"timestamp"
				{
					puts stderr "Adding timestamp via Set command is not allowed. Use \"Add timestamp\" command instead."
					exit 1
				}
				"answer"
				{
					puts "setting an answer --> additional regex for: $2"
					# source: https://www.tcl.tk/man/tcl8.5/tutorial/Tcl20.html
					set result [regexp {{(.+)} which is ([wrong|correct]+)} $2 match sub1 sub2]
					if {!$result} {
						puts stderr "Parts of your sentence are not formulated correctly.\nPlease review the following part:\n$2\nUse:\n\"<answer>\" which is wrong\n\"<answer>\" which is correct"
						exit 1
					} else {
						# add or append answers
						puts "Result: $result Match: $match 1: $sub1 2: $sub2"
						set answerPair "\"$sub1\" $sub2"
						puts "adding answer to $keyName"
						:appendValue :stackDict $keyName answers $answerPair
					}
				}
				default
				{
					puts "default"
					set ele "$keyName $0 $2"
					puts ele:$ele
					dict set :stackDict {*}$ele
				}
			};# -- end switch
		};# -- end else
	  }

	  $seBuilder define Add {^timestamp ([^\s]*) to (.*)$} {
		# Approach:
		# When adding a timestamp to a video the following can happen:
		# - the video has no timestamp therefore simply add it
		# - the video already has 0 or * timestamps therefore append to this list
		#
		# pseudo:
		# 1) get main key of video id you want to add to (main key of $1)
		# 2) check if this mainkey has timestamps
		# 3) if it has no timestamps set it and if it has timestamps append it

		puts "---\nstep definition 03 ADD TIMESTAMP"
		puts "0:$0 1:$1"

		set keyName [::StoryBoard::Helper getMainKey ${:stackDict} "id" $1]
		if {$keyName eq ""} {
			puts stderr "Cannot add timestamp to \"$1\" because it has not been defined yet. Use Create command first."
			exit 1
		} else {
			if {[:checkTimestamp ${:stackDict} $keyName]} {
				puts "appending timestamp $0 to timestamp of $keyName"
				:appendValue :stackDict $keyName timestamp $0
			} else {
				puts "setting timestamp of $keyName to $0"
				set ele "$keyName timestamp $0"
				dict set :stackDict {*}$ele
			}
		}
	  }

	  $seBuilder define Add {^timestamps \((.+)\) to ([^\s]*)$} {
			puts "---\nstep definition 03.a ADD TIMESTAMP plural"
			puts "0:$0 1:$1"

			# polishing
			set timestamps [string map {, ""} $0]
			puts timestamps:$timestamps

			set keyName [::StoryBoard::Helper getMainKey ${:stackDict} "id" $1]
			set ele "$keyName timestamp {$timestamps}"
			puts ele:$ele
			dict set :stackDict {*}$ele
	  }
	  
	  return $seBuilder
	}
  }

namespace export StepDefinitions
}
