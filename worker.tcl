namespace eval StoryBoard {

#
# Helper
#

nx::Class create Helper {

	##
	## isInstanceAvailable
	##
	# input: class (the class of which an instance is to be searched e.g. ::Timestamp or ::Video)
	# input: id (the id of the class instance we are looking for e.g.: timestamp7 or video2)
	#
	# returns:
	#  - in case the instance is found the instance is returned (return $x)
	#  - in case there are no matching instances found return code 0 is returned
	#    this could also mean that there are instances available but not the one with instance id
	#

	:public object method isInstanceAvailable {class id} {
		set instlist [$class info instances -closure]
		if {[llength $instlist] > 0} {
			# instances available
			foreach i $instlist {
				# looking for class with id"
				if {$id eq [$i id get]} {
					# class instance with id found
					return $i
				}
			}
			# no matching instance of class with id found
			return 0
		} else {
			# no instance of class available
		    return 0
		}
	}

	###
	### matchClass
	###
	# input: id (token)
	# input: ns (namespace)
	#
	# functionality:
	# match any variant of e.g. video1, videoIntro, videopart, video3a to video
	# get available classes in ns
	# tail each class (::StoryBoard::Video --> Video)
	# compare id case insensitive to tailed class
	# if they match (e.g. id:video1 --> tailed namespace:Video --> matches video) use it
	# set return to matched class (e.g. video)
	#
	###

	:public object method matchClass {id ns} {
	  set matchedClass ""
	  set availableClasses [info commands $ns]

	  foreach ns $availableClasses {
		set tail [namespace tail $ns]
		if {[regexp -nocase "^$tail" $id match]} {
			#puts "found $match in $id"
			set matchedClass $match
			break
		}
	  }

	  if {$matchedClass eq ""} {
		# ALSO CONTINUE HERE: refine error response - only warning and continue empty ?
		error "ERROR: matchClass could not match $id in $availableClasses"
	  }

	  return $matchedClass
	}

	###
	### getMainKey
	###
	# get main key (=return value) of key value pair k v in dict d
	# dict sample structure: mk {k v a b ... ...}
	#
	:public object method getMainKey {d k v} {
		set rd [lreverse $d]
		#puts rd:$rd
		foreach e [dict keys $rd] {
			try {
			  set value [dict get $e $k]
			} on error {msg} {
				continue
			}
			if {[dict get $e $k] eq $v} {
			  #puts "$k: [dict get $e $k] --> [dict get $rd $e]"
			  return [dict get $rd $e]
			} else {
				# not found / do nothing / continue
			}
		}
	}
}

namespace export Helper
}
