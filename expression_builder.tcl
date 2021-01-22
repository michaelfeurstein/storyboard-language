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
			# schreckliches mapping aber it gets the job done. alternativen?
			lassign ${:stack} a videoID b videoLink c title d length
			set :stack [$class new -childof [self] -title $title -videoSource $videoLink -length $length]
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

	# DYNAMIC RECEPTION
	:method unknown {v args} {
	  puts "unknown $args:$v"
	  lappend :stack $v
	}

	:public method from {storyboard} {
	  #set i 0
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
