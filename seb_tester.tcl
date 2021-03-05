#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source expression_builder.tcl

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
      return $script
    }
    
    :public method get {storyboardScript} { 
      set interp [Interp new]
      $interp register [list [self] handleUnknown] ::unknown
      set storyboardScript [:polish $storyboardScript]
      puts "Calling eval storyboardScript"
	  $interp eval $storyboardScript
      # TODO: At this point, one can decide what the result or kind of
      # post-processing (e.g., lazy instantiation to reverse
      # syntax-induced declaration order) needs to be performed.
	  #
	  # Create the class commands here or inside define. 
      puts "\nAfter eval storyboardScript"

	  # just checking if the stackDict is filled correctly
	  puts "stackDict size:[dict size ${:stackDict}]"
	  puts stackDict:${:stackDict}
	  foreach id [dict keys ${:stackDict}] {
	  	puts keys:$id
	  }
	  
	  if {[info exists :result]} {
        foreach el ${:result} {
			puts el:$el
		}
		set r ${:result}
      } else {
		puts "no result"
        set r ""; # TODO: anything useful as a compensation action?
      }
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
  
  # Note: There can be multiple match sentences per first word (first defined, first processed)!
  
  # CONTINUE HERE: problem is that define 01 and define 02 are triggered. This could either be by design or I may want to keep track of what was triggered.
  $seBuilder define There {^is a video with the (.+?) (.*) and the (.+?) (.*) and the (.+?) (.*) and the (.+?) (.*)$} {
	# define 01
	#
	#Matches the following
	# There is a <name-of-class> with the <name-of-parameter> "Name with spaces, characters and numbers" and <name-of-parameter> "..." repeated.
	puts "define 01 - Video 0:$0 1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7"
	set parameterList "-$0 $1 -$2 $3 -$4 $5 -$6 $7"
	set creation [subst {::StoryBoard::Video new -childof [self] $parameterList}]
	puts "creationCmd: $creation"
    lappend :result [eval $creation]; # to be returned by get!
  }

  $seBuilder define There {^is a (.+) with the (.+?) (.*)$} {
  	# define 02
	#
	# old {^is a (.+) with the (.+?) {?(.+?)}?$}
    # Matches the following:
	# There is a <name-of-class> with the <name-of-parameter> "Name with spaces, characters and numbers"
	# There is a <name-of-class> with the <name-of-parameter> UsingNoQuotesORaDigitInOneWord
	#
	# append the matches to a dict
	
	# In these scripts,
    # ... one can use $0 - $n to positionally access the regex matches
    #puts "Video: $0" ; 
    #puts "Video title: $1"
    # ... one can access the responsible builder object implicitly
    #puts "builder (implicit): [self]"
    # Note: the return value of the script is discarded if 'result' object variable exists !
	#
	# Q: is there a way to report if the regex didn't match
	
	if {$1 eq "type" && $2 eq "360"} {
		set 1 is360Video
		set 2 true
	} elseif {$1 eq "type" && $2 eq "regular"} {
		set 1 is360Video
		set 2 false
	}

	puts "define 02 - Creating dict with 0:$0 1:$1 2:$2"
	# create a dict from the matches stacking it
	set ele "$0 $1 $2"
	puts ele:$ele
	dict set :stackDict {*}$ele
	lappend :result "Element 0:$0 1:$1 2:$2"
  }


  $seBuilder define This {^(.+) is a (.*) video$} {
	if { $1 eq 360 } {
	  puts "it's a 360 video"
	} else {
	  puts "it's a regular video"
	}
	set ele "$0 is360Video $1"
	dict set :stackDict {*}$ele
	lappend :result "Class:$0 type:$1"
  }

  $seBuilder define This {^(.+) is located at (.*)$} {
	puts "Location $0 and $1"
	set ele "$0 videoSource $1"
	dict set :stackDict {*}$ele
	lappend :result "Class:$0 location:$1"
  }
  
  # Beware! Right now, at this stage, the string following the first
  # word (e.g., Scene) will habve been processed as a Tcl command
  # (e.g., double quotes etc. will been transformed to curly
  # braces). One would have to polish the input script further to
  # avoid this interpretation.
  
  $seBuilder define Highlight {^(\d+) is called {(.+)}$} {
    #puts "Highlight: $0"
    #puts "Highlight title: $1"
    lappend :result [::StoryBoard::Video new -title $1]; # to be returned by get!
	#puts define:${:result}
  }
 
  set r [$seBuilder get $sbdata]
  
  set iBuilder [StoryboardBuilder new]
  $iBuilder from [$seBuilder stackDict get]

  puts ContentFragments:[llength [ContentFragment info instances -closure]]

  foreach el $r {
  	? {$el info class} ::StoryBoard::Video
	}
  cleanupTests
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
