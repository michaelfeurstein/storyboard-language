#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source expression_builder.tcl
source worker.tcl

namespace import StoryBoard::*

namespace eval ::se {

  nx::Class create Interp {

    :variable interp

    :method init {} {
      set :interp [interp create -safe [self]::box]
      ${:interp} eval {namespace delete ::}
    }

    :public method register {tgtPrefix srcPrefix} {
      interp alias ${:interp} $srcPrefix {} {*}$tgtPrefix
      return
    }

    :public method eval {script} {
      ${:interp} eval $script
    }

  }

  nx::Class create Builder {

    :variable result:object

    :property {sentences:substdefault {[dict create]}}
	:property -accessor public {stackDict:substdefault {[dict create]}}


    :method getMatchVars {regExprStr} {
      # Trick the regex to match the empty string, so we can count the
      # number of matching groups in a robust manner.
      append regExprStr "|"
      set nParens [expr {[llength [regexp -inline $regExprStr ""]] - 1}]
      set vars [list]
      for {set i 0} {$i<$nParens} {incr i} {lappend vars $i}
      return $vars
    }

    :method polish {script} {
      # TODO: Here one can manipulate the passed script string before
      # being processed as a Tcl script.
	  puts "polish script:$script"
      return $script
    }

    :public method get {storyboardScript} {
      set interp [Interp new]
      $interp register [list [self] handleUnknown] ::unknown
      set storyboardScript [:polish $storyboardScript]
      puts "--- Calling eval storyboardScript"
	  $interp eval $storyboardScript
      # TODO: At this point, one can decide what the result or kind of
      # post-processing (e.g., lazy instantiation to reverse
      # syntax-induced declaration order) needs to be performed.
	  #
	  # Create the class commands here or inside define.
      puts "\n--- After eval storyboardScript"

	  # prepare dict
	  puts "\nchecking stackDict"
	  if {[info exists :stackDict]} {
		puts "stackDict size:[dict size ${:stackDict}]"
		puts stackDict:${:stackDict}
		foreach id [dict keys ${:stackDict}] {
			puts keys:$id
		}
		set r ${:stackDict}
	  } else {
		puts "no result for stackDict"
		set r ""; # TODO: compensation action required?
	  }

	  # prepare result
	  #if {[info exists :result]} {
      #   foreach el ${:result} {
	  #		puts el:$el
	  #  }
	  #  set r ${:result}
      # } else {
	  #  puts "no result for result"
      #   set r ""; # TODO: anything useful as a compensation action?
      # }

      return $r
    }

    :public method handleUnknown {firstWord args} {
      if {[dict exists ${:sentences} $firstWord]} {
        foreach s [dict get ${:sentences} $firstWord] {
		  lassign $s regExpr script
		  lassign $regExpr r vars
          set body [list if "\[regexp \$re \$str _ $vars\]" $script]
          #puts BODY='$body'
          apply [list {re str} $body ::] $r [concat $args]
        }
      } else {
        puts stderr "handleUnknown: $firstWord (no match sentence!)"
      }
    }

    :public method define {firstWord regExpr script} {
      set regExprArgs [list $regExpr [:getMatchVars $regExpr]]
      set sentence [list $regExprArgs $script]
      dict lappend :sentences $firstWord $sentence
    }

	# check if video v has timestamp set in dict d
	# dict sample structure:
	# 1) no timestamp:
	#	video1 {id myVideo URL ...}
	#
	# 2) with timestamp:
	#	video1 {id myVideo URL ... timestamp intro}
	#
	# 3) with timestamps:
	#	video1 {id myVideo URL ... timestamp {intro, content, end}}
	#
	:method checkTimestamp {d v} {
		set vdict [dict get $d $v]
		#puts "getting content of vdict --> $vdict"
		set tsdict [dict filter $vdict key "timestamp"]
		#puts "tsdict:$tsdict"
		if {$tsdict eq ""} {
			puts "no timestamp defined in video $v"
			return 0
		} else {
			puts "timestamp found --> tsdict:$tsdict in video $v"
			return 1
		}
	}

	# get main key (=return value) of key value pair k v in dict d
	# dict sample structure: mk {k v a b ... ...}
	#
	:method getMainKey {d k v} {
		#puts "looking for $k $v"
		set rd [lreverse $d]
		#puts rd:$rd
		foreach e [dict keys $rd] {
			if {[dict get $e $k] eq $v} {
			  #puts "$k: [dict get $e $k] --> [dict get $rd $e]"
			  return [dict get $rd $e]
			} else {
				# not found / do nothing / continue
			}
		}
	}

	# append value v to subkey sk in dict d for key
	#
	:method appendValue {d k sk v} {
		dict update $d $k $k {
			dict lappend $k $sk $v
		}
	}

	# count occurences of main keys k in dict d
	# key could be video - match it with video1
	#
	:method countKeys {d k} {
		#puts "keys:[dict keys $d [subst -nocommands -nobackslashes {$k*}]]"
		if {[dict size $d] > 0} {
			return [llength [dict keys $d [subst -nocommands -nobackslashes {$k*}]]]
		} else {
			puts "no key:$k found"
			return 0
		}
	}

	# module creator
	#
	:method createModule {title} {
		set type [Helper matchClass module ::StoryBoard::*]
		set no_of_keys [:countKeys ${:stackDict} $type]
		if {$no_of_keys ne 0} {
			puts stderr "There seems to be a module already"
			exit 1
		} else {
			set ele "module title $title"
			puts ele:$ele
			dict set :stackDict {*}$ele
		}
	}
  }

  namespace export Builder

}

namespace eval ::seb::tests {

  package req tcltest
  namespace import ::tcltest::*
  set ::argv [lassign $argv f]
  ::tcltest::configure {*}$::argv
  ::tcltest::loadTestedCommands


  namespace import ::StoryBoard::*
  namespace import ::se::*

  ::proc ? {script expected} {
    set ctr [incr [namespace current]::counter]
    uplevel [list test test-$ctr "" -body $script -result $expected \
                 -returnCodes {0 1 2}]
  }

  set storyboardFile ""

  if { $argc != 1 } {
    puts stderr "[info script] requires a storyboard as input"
    puts stderr "For example, tclsh seb_tester.tcl storyboards/syntax_B_natural"
    exit 1
  } else {
    set storyboardFile $f
    if {![file exists $storyboardFile] || ![file readable $storyboardFile]} {
      puts stderr "File '$storyboardFile' not present or accessible."
      exit 1
    }
  }

  set ch [open $storyboardFile r]
  try {
    set sbdata [read -nonewline $ch]
  } finally {
    catch {close $ch}
  }

  set seBuilder [Builder new]

  ###
  ### Info Stefan
  ###
  #
  # In the below scripts,
  # ... one can use $0 - $n to positionally access the regex matches
  #puts "Video: $0" ;
  #puts "Video title: $1"
  # ... one can access the responsible builder object implicitly
  #puts "builder (implicit): [self]"
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

	set type [Helper matchClass $0 ::StoryBoard::*]
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
		set type [Helper matchClass $0 ::StoryBoard::*]
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
		"single"
		{
			puts "single choice question"

			# id
			set ele "$keyName id $1"
			dict set :stackDict {*}$ele

			# type singleChoice
			set ele "$keyName type singleChoice"
			dict set :stackDict {*}$ele
		}
		"multiple"
		{
			puts "multiple choice question"

			# id
			set ele "$keyName id $1"
			dict set :stackDict {*}$ele

			# type multipleChoice
			set ele "$keyName type multipleChoice"
			dict set :stackDict {*}$ele
		}
		"single*"
		{
			puts "question type: $0 seems misspelled. Try Create single choice question with id $1. $errMsg"
			exit 1
		}
		"multiple*"
		{
			puts "question type: $0 seems misspelled. Try Create multiple choice question with id $1. $errMsg"
			exit 1
		}
		default
		{
			puts "question type: \"$0\" not supported. $errMsg"
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

	set keyName [:getMainKey ${:stackDict} "id" $1]

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

	set keyName [:getMainKey ${:stackDict} "id" $1]
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

		set timestamps [string map {, ""} $0]
		puts timestamps:$timestamps

		set keyName [:getMainKey ${:stackDict} "id" $1]
		set ele "$keyName timestamp {$timestamps}"
		puts ele:$ele
		dict set :stackDict {*}$ele
  }

  #$seBuilder define There {^is a (.+)$} {
  #	puts "define 02"
  # set ele "$0 id $0"
  # puts ele:$ele
  # dict set :stackDict {*}$ele
  #}

  #$seBuilder define This {^(.+) has the URL (.*)$} {
  #	puts "define 03"
  #	set ele "$0 URL $1"
  #	dict set :stackDict {*}$ele
  #}

  # Beware! Right now, at this stage, the string following the first
  # word (e.g., Scene) will habve been processed as a Tcl command
  # (e.g., double quotes etc. will been transformed to curly
  # braces). One would have to polish the input script further to
  # avoid this interpretation.

  #$seBuilder define Highlight {^(\d+) is called {(.+)}$} {
  #  #puts "Highlight: $0"
  #  #puts "Highlight title: $1"
  #  lappend :result [::StoryBoard::Video new -title $1]; # to be returned by get!
  #	#puts define:${:result}
  #}

  set r [$seBuilder get $sbdata]
  puts "\n--- Result\nr:$r"

  #set iBuilder [StoryboardBuilder new]
  #$iBuilder from $r

  #
  # Tests
  #
  puts "\n--- ContentFragments:[llength [ContentFragment info instances -closure]]"

  #foreach el $r {
  #	? {$el info class} ::StoryBoard::Video
  #}
  #cleanupTests
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
