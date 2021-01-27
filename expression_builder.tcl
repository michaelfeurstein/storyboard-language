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
			#puts stacklength[llength ${:stack}]:${:stack}
			#puts dict:[dict keys ${:stack}]
			#puts [info class constructor nx::$class]
		  	#set configInfo [[$class new] info lookup syntax configure]
		  	set configInfo [$class info lookup syntax create]
			#puts configInfo:$configInfo	
			
			set intersectLists [:intersectLists $configInfo ${:stack}]
			puts final:$intersectLists
			
			# use list to assign parameters
			#lassign ${:stack} a videoID b videoLink c title d length
			set creation [subst {$class new -childof [self] $intersectLists}]
			puts creationCmd:$creation
			set :stack [eval $creation]
			#set :stack [$class new -childof [self] $intersectLists]
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

	# compare create parameters with dict 
	# if they match, use them
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
		if {[regexp {video|highlight} $id matched]} {
			set e $matched		  
		} else {
			set e ""
		}
		#puts "from:$id matched:$e"
		
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
