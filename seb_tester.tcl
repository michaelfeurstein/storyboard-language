#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl

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
      $interp eval $storyboardScript
      # TODO: At this point, one can decide what the result or kind of
      # post-processing (e.g., lazy instantiation to reverse
      # syntax-induced declaration order) needs to be performed.
      if {[info exists :result]} {
        set r ${:result}
      } else {
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
          # puts BODY='$body'
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

  $seBuilder define There {^is (\d+) scene \((.+)\)$} {
    # In these scripts,
    # ... one can use $0 - $n to positionally access the regex matches
    puts "number: $0" ; 
    puts "type: $1"
    # ... one can access the responsible builder object implicitly
    puts "builder (implicit): [self]"
    # Note: the return value of the script is discarded if 'result' object variable exists !
    # Note: There can be multiple match sentences per first word (first defined, first processed)!
  }

  # Beware! Right now, at this stage, the string following the first
  # word (e.g., Scene) will habve been processed as a Tcl command
  # (e.g., double quotes etc. will been transformed to curly
  # braces). One would have to polish the input script further to
  # avoid this interpretation.
  
  $seBuilder define Scene {^(\d+) is called {(.+)}$} {
    puts "Scene: $0"
    puts "Scene title: $1"
    set :result [::StoryBoard::Video new -title $1]; # to be returned by get!
  }
  
  set r [$seBuilder get $sbdata]

  ? {$r info class} ::StoryBoard::Video
  
  cleanupTests
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
