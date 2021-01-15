package req nx

# In Anlehnung an djdsl/tutorials/intro.tcl:129 AleBuilder (sollte es nicht LeaBuilder heissen, laut Buch?)
nx::Class create StoryboardBuilder {

	:forward video %self creator Video

	:method creator {class} {
	  	puts "hello from creator method with $class"
		set :opds [$class new -childof [self]]
		# @Stefan: bis hier hin bin ich mal gekommen diese woche.
		# leider für meinen kopf ein bisschen ein overload aber ich glaube ansätze davon zu vestehen - betonung auf glauben
		#
	} 

	# DYNAMIC RECEPTION
	# ohne wirklich zu wissen was dynamic reception ist: überschreibe/hijacke ich da die interne tcl methode "unkown"?
	:method unknown {v args} {
	  # hier müsste ich dann parameter wie title, length fangen
	  # aber ich glaube da kopiere ich zu viel, bzw. habe ich das gefühl das anders zu machen.
	  # nach deinem beispiel müsste ich dann eigentlich auch alle parameter (wie title, length) als nx::Class definieren?
	  # 
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
