#!/usr/bin/env tclsh
package require Tcl 8.6
package require nx

source language_model.tcl
source expression_builder.tcl
source worker.tcl
source visitor.tcl
source step_definitions.tcl

namespace import StoryBoard::*

namespace eval ::seb::tests {

  package req tcltest
  namespace import ::tcltest::*
  set ::argv [lassign $argv f]
  ::tcltest::configure {*}$::argv
  ::tcltest::loadTestedCommands

  namespace import ::StoryBoard::*

  ::proc ? {script expected} {
    set ctr [incr [namespace current]::counter]
    uplevel [list test test-$ctr "" -body $script -result $expected \
                 -returnCodes {0 1 2}]
  }

  set storyboardFile ""

  if { $argc != 1 } {
    puts stderr "[info script] requires a storyboard as input"
    puts stderr "For example, tclsh nl_tester.tcl storyboards/syntax_B_natural"
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

  # // Definition Builder and Step Definitions //
  # create a definition builder (dictBuilder) with step definitions
  set dictBuilder [StepDefinitions setup]
  set storyboardDict [$dictBuilder get $sbdata]
  puts "\n--- Result\n$storyboardDict"

  # // Expression Builder //
  set internalBuilder [StoryboardBuilder new -notation natural-language]
  set module [$internalBuilder from $storyboardDict]

  # // Visitor //
  puts "\n--- Visitor call on module object: $module"
  set visitor [HTMLVisitor new]
  set r [$visitor evaluate $module]
  puts "\n rResult from visitor:\n[$r asHTML]"

  #
  # Tests
  #
  puts "\nnl_tester.tcl:  ContentFragments  [llength [ContentFragment info instances -closure]]    Elements  [llength [Element info instances -closure]]"

  # TODO
  # - make these tests generic
  # - don't work yet
  #
  # foreach i [info commands ::StoryBoard::*] {
  #   puts "\n$i"
  # 	foreach el [$i info instances -closure] {
  #     ? {$el info class} $i
  #   }
  #   cleanupTests
  # }

  #puts "\nElements"
  #foreach el [Element info instances -closure] {
  #	? {$el info class} ::StoryBoard::Element
  #}
  #cleanupTests
  
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
