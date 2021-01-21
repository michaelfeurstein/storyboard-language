package req nx

# Based on djdsl/tutorials/intro.tcl:129 AleBuilder 
nx::Class create StoryboardBuilder {

	:forward video1 %self creator Video
	:forward highlight %self creator Highlight

	:method creator {class} {
	  	puts "creator method with class:$class"
		switch -glob -- $class {
		  "Video" {
		  		puts "matched a video class"
			} 
			default {
				puts "got nothing"
			}
		 }
		
		set :opds [$class new -childof [self]]
	} 

	# DYNAMIC RECEPTION
	:method unknown {v args} {
	  # hier müsste ich dann parameter wie title, length fangen
	  # lappend :opds [Parameter new -childof [self] -value $v]
		puts "unknown $args:$v"
	}

	:public method from {storyboard} {
		set i 0
		  foreach element $storyboard {
			puts "element no$i:$element"
			:$element
			incr i
		  }
		  #set r [lindex ${:opds} 0]
		  #unset :opds
		  #return $r	
	}
}
