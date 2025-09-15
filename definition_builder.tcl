###
#
# DefinitionBuilder
#
# used for controlled-natural language syntax
#
###

namespace eval StoryBoard {

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

  nx::Class create DefinitionBuilder {

    #:variable result:object

    :property {sentences:substdefault {[dict create]}}
    :property -accessor public {stackDict:substdefault {[dict create]}}
    :property storyboardLinesList

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
      # Here one can manipulate the passed script string before
      # being processed as a Tcl script.
      puts "---polish script:$script"
      set lines [split $script "\n"]
      set :storyboardLinesList [list]
      foreach line $lines {
        set line [string map {\' "\""} $line]; # replace single quotes with double quotes
        append :storyboardLinesList "$line\n"
      }
      return ${:storyboardLinesList}
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
	  #puts "\nchecking stackDict"
	  if {[dict size ${:stackDict}] ne 0 && ${:stackDict} ne "" && ![string is space ${:stackDict}]} {
		#puts "stackDict size:[dict size ${:stackDict}]"
		#puts stackDict:${:stackDict}
		#foreach id [dict keys ${:stackDict}] {
		#	puts keys:$id
		#}
		set r ${:stackDict}
	  } else {
		set r "";# TODO: compensation action required?
		[::StoryBoard::ErrorHandler emptyStoryboard]
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
		[::StoryBoard::ErrorHandler handle_unknown_first_word $firstWord]
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
	:method createModule {title sentence} {
		set type [::StoryBoard::Helper matchClass module ::StoryBoard::*]
		set no_of_keys [:countKeys ${:stackDict} $type]
		if {$no_of_keys ne 0} {
			[::StoryBoard::ErrorHandler duplicate_module $sentence]
		} else {
			set ele "module title $title"
			puts ele:$ele
			dict set :stackDict {*}$ele
		}
	}
  }

  namespace export DefinitionBuilder
}
