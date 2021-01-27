package req nx

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder 
nx::Class create StoryboardBuilder {

	#:property {theElement}

	#:forward [regexp {(video)} ${:theElement}] %self creator Video
	:forward video %self creator Video
	:forward highlight %self creator Highlight

	:method creator {class} {
	  	#puts :${:theElement}
	  	#puts "creator method with class:$class"
		switch -glob -- $class {
		  "Video"
		  {
			puts "matched a video class"
			# mapping is hard coded - TODO - make this more dynamic 
			# the order of elements in the stack will not always be this way - account for that
			# maybe regsub through the stack
			# go thorugh stack and match corresponding parameters
			# stacklength should be even as paired key:value elements
			# unsure what to do i uneven ... is there a case?
			# parse through keys and match with class parameters
			# if key and class parameter match set it up
			puts stacklength[llength ${:stack}]:${:stack}
			puts dict:[dict keys ${:stack}]
			# folgendes klappt nur wenn ich keine required parameter habe
			#puts [info class constructor nx::$class]
		  	#set configInfo [[$class new] info lookup syntax configure]
		  	set configInfo [$class info lookup syntax create]
			puts configInfo:$configInfo	
			puts matchLists:[:matchLists $configInfo [dict keys ${:stack}]]
			
			#foreach x $configInfo {
			  # hier dann die parameter matchen mit dem stac
			  # setzt voraus dass ich sie richtig setze
			#  puts x:[string trim $x "-?"]
#
#			}

			lassign ${:stack} a videoID b videoLink c title d length
			set :stack [$class new -childof [self] -$b $title -videoSource $videoLink -length $length]
		  }
		  "Highlight"
		  {
			puts "matched a highlight class"
			lassign ${:stack} a videoref b title c starttime d endtime
			set :stack [$class new -childof [self] -starttime $starttime -endtime $endtime -title $title]
		  } 
		  default
		  {
			puts "matched nothing"
		  }
		 }
	}

	# CONTINUE HERE: not there yet
	# compare create parameters with dict 
	# if they match, use them
	:method matchLists {a b} {
		set r {}
		foreach i $a {
		  	set e [string trim $i "?-"]
			puts "match:e:$e b:$b i:$i"
			if { [lsearch -glob $b $e]==1 } {
			  puts "matched:b:$b with e:$e"	
			  lappend r $e
			}
		}
		return $r
	}	  

	# DYNAMIC RECEPTION
	:method unknown {v args} {
	  puts "unknown $args:$v"
	  lappend :stack $v
	}

	:public method from {storyboard} {
	  foreach id [dict keys $storyboard] {
		
		# schafft man das schöner via ternary operator?
		if {[regexp {video|highlight} $id matched]} {
			set e $matched		  
		} else {
			set e ""
		}
		puts "from:$id matched:$e"
		
		foreach el [dict get $storyboard $id] {
		  puts el:$el
		  :$el
		}

		:$e
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
