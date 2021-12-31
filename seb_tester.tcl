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
#	  if {[info exists :result]} {
#        foreach el ${:result} {
#			puts el:$el
#		}
#		set r ${:result}
#      } else {
#		puts "no result for result"
#        set r ""; # TODO: anything useful as a compensation action?
#      }

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

	# find value v in dict d
	# e.g. timestamp xyz
	:method findValue {d v} {
		set rd [lreverse $d]
		foreach e [dict keys $rd] {
			set idx [lsearch $e $v]
			if {[lindex $e $idx] eq $v} {
				puts "found $v"
				return 1
			} else {
				return 0
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
	:method countKeys {d k} {
		#puts "keys:[dict keys $d [subst -nocommands -nobackslashes {$k*}]]"
		if {[dict size $d] > 0} {
			return [llength [dict keys $d [subst -nocommands -nobackslashes {$k*}]]]
		} else {
			puts "no key:$k found"
			return 0
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

  ### Info Stefan
  # In the below scripts,
  # ... one can use $0 - $n to positionally access the regex matches
  #puts "Video: $0" ;
  #puts "Video title: $1"
  # ... one can access the responsible builder object implicitly
  #puts "builder (implicit): [self]"
  #
  # Note: There can be multiple match sentences per first word (first defined, first processed)!
  # Note: the return value of these scripts are discarded if 'result' object variable exists !
  ###

  # CONTINUE HERE: start fresh (25.12.2021)
  #
  # Video Creation Definitions

  $seBuilder define Create {^(.+) with id ([^\s]*)$} {
    # Matches the following:
	# There is a <name-of-class> with the <name-of-parameter> "Name with spaces, characters and numbers"
	# There is a <name-of-class> with the <name-of-parameter> UsingNoQuotesORaDigitInOneWord
	#
	# append the matches to a dict

	puts "---\nstep definition 01 CREATE"
	puts "0:$0 1:$1"
	# create a dict from the matches stacking it
	#
	# check the stackDict for already created references (e.g. video1)
	# and if there are already some videos (e.g. video1, video2 etc.) count them
	# and set a new incremented id correctly e.g. video 3
	#
	# pseudo:
	# 1) match $0 against classes in StoryBoard namespace as in expression builder
	# 2) generate a main key such as video2 depending on previous counts of this type (incr)
	set type [Helper matchClass $0 ::StoryBoard::*]
	set no_of_keys [:countKeys ${:stackDict} $type]
	incr no_of_keys
	set keyName $type$no_of_keys
	#puts "type:$type found $no_of_keys time(s)"
	set ele "$keyName id $1"
	puts ele:$ele
	dict set :stackDict {*}$ele
  }

  $seBuilder define Set {^(.+?) of (.+?) to (.*)$} {
	puts "---\nstep definition 02 SET"
	puts "0:$0 1:$1 2:$2"
	set ele "$1 $0 $2"
	dict set :stackDict {*}$ele
  }

  $seBuilder define Add {^timestamp (.+?) to (.*)$} {
	puts "---\nstep definition 03 ADD TIMESTAMP"
	puts "0:$0 1:$1"
	set ele "$1 timestamp $0"
	puts "stackDict:${:stackDict}"
	# this will probably break if more videos with timestamps are there
	# i will need to fix by also checking the video reference $1 // fix later
	if {[:findValue ${:stackDict} timestamp]} {
		:appendValue :stackDict $1 timestamp $0
	} else {
		dict set :stackDict {*}$ele
	}

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
