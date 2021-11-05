package req nx

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
}

namespace export Helper
}
