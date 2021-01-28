package req nx

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder 
nx::Class create StoryboardBuilder {

	#:forward [regexp {(video)} ${:theElement}] %self creator Video
	:forward video %self creator Video
	:forward highlight %self creator Highlight

	:method creator {class} {
	  	#puts "creator method with class:$class"
	
	  	# intersect create info of class with stack
	  	#puts slot:[$class getParameterOptions]
	  	set configInfo [$class info lookup syntax create]
	  	set intersectLists [:intersectLists $configInfo ${:stack}]
		puts final:$intersectLists

		# setup class new command with parameters
		set creation [subst {$class new -childof [self] $intersectLists}]
		puts creationCmd:$creation
		set :stack [eval $creation]

		#switch -glob -- $class {
		#  "Video"
		#  {
		#	puts "matched a video class"
		#	#puts stacklength[llength ${:stack}]:${:stack}
		#	#puts dict:[dict keys ${:stack}]
		#	#puts [info class constructor nx::$class]
		#  	#set configInfo [[$class new] info lookup syntax configure]
		#	#puts configInfo:$configInfo	
		#	
		#	# use list to assign parameters
		#	#lassign ${:stack} a videoID b videoLink c title d length
		#	#set :stack [$class new -childof [self] $intersectLists]
		#  }
		#  "Highlight"
		#  {
		#	puts "matched a highlight class"
		#	lassign ${:stack} a videoref b title c starttime d endtime
		#	set :stack [$class new -childof [self] -starttime $starttime -endtime $endtime -title $title]
		#  } 
		#  default
		#  {
		#	puts "matched nothing"
		#  }
		# }
	}

	# compare create parameters with dict 
	# if they match, create pattern "-property value"
	# Q: Geht das anders auch? Im NS Tutorial steht etwas von nx::Slot und nx::ObjectParameterSlot
	:method intersectLists {a b} {
		set r {}
		set d "-"
		puts a:$a
		puts b:$b
		foreach i $a {
		  	set e [string trim $i "?-"]
			#puts "match:e:$e b:$b"
			if { $e in [dict keys $b] } {
			  puts "matched:e:$e in b:$b"
			  lappend r $d$e [dict get $b $e]
			}
		}
		return $r
	  }

	# DYNAMIC RECEPTION
	:method unknown {v args} {
	  #puts "unknown $args:$v"
	  lappend :stack $v
	}

	:public method from {storyboard} {
	  foreach id [dict keys $storyboard] {

		# schafft man das schöner via ternary operator?
		#if {[regexp {video|highlight} $id matched]} {
		#	set e $matched		  
		#} else {
		#	set e ""
		#}
		#puts "from:$id matched:$e"

		# CONTINUE HERE: quick & dirty / refine
		# trim keys from trailing numbers
		# compare keys case insensitive to classes in namespace StoryBoard
		# if they match (e.g. video1 --> ::StoryBoard::Video) use it
		# set e to matched command (e.g. video or Video)	
		set oid $id
		puts from:$id
		set t [regsub -all {[0-9]+} $id {} id]
		puts trimmed:$id
		set classes [info commands ::StoryBoard::*]
		if {[regexp -nocase "$id" $classes match]} {
			puts "found:id:$id in classes:$classes match:$match"
			set e $id
		} else {
			set e ""
		}

		#puts current:[info method]
		#puts commands:[info commands [namespace current]]
		#puts namespace:[namespace current]
	
		foreach el [dict get $storyboard $oid] {
		  puts el:$el
		  :$el
		}

		:$e
		#:creator $e
		unset :stack
	  }
	  
	  #foreach element [lreverse $storyboard] {
	  #	puts "element no$i:$element"
	  #	foreach subelement [lreverse $element] {
	  #	  	puts "subelement of $element:$subelement"
	  #	}
	  #	set :theElement :$element
	  #	:$element
	  #	incr i
	  #	}
	  # set r [lindex ${:opds} 0]
	  # unset :opds
	  # return $r	
	}
}
