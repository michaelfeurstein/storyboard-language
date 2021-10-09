package req nx

namespace eval StoryBoard {

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
			#puts "(@[current method]) $class instances available"
			foreach i $instlist {
				#puts "(@[current method]) [current] is looking for $class:$id comparing to [$i info class]:[$i id get]"
				if {$id eq [$i id get]} {
					# class instance with id found
					puts "(@[current method]) found instance [$i info class] with id: [$i id get]"
					return $i
				}
			}
			# no matching instance of class with id found
			puts "(@[current method]) no matching instance $id of $class found"
			return 0
		} else {
			# no instance of this class available
			puts "(@[current method]) instances of $class not available"
		    return 0
		}
	}
}


#
# Video
#

nx::Class create Video {
	:property -accessor public {id empty}
	:property -accessor public {URL empty}
	:property -accessor public {timestamp empty}
	:property {timestampClass ::Timestamp}
	:property {prefix timestamp}

	:public object method new {args} {
		set idxID [lsearch $args -id]
		incr idxID
		set videoID [lindex $args $idxID]

		#set vi [Helper isInstanceAvailable ::Video $videoID]

		#if {$vi ne 0} {
		#	error "A video instance with id: [$vi id get] already exists: please review your storyboard"
		#}
		next
	}

	:method init {} {
		# handle -timestamp parameter
		if {${:timestamp} ne "empty"} {
		  	puts "find out if timestamp is a list or not"
			# handle list
			puts "timestamp length: [llength ${:timestamp}]"
			puts "timestamp: ${:timestamp}"
			foreach i ${:timestamp} {
			  	# CONTINUE HERE: either handle seperate or with single handler below. Hoever return breaks the foreach.
				puts i:$i
			}

			# handle single timestamp
			set ti [Helper isInstanceAvailable ${:timestampClass} ${:timestamp}]
			if {$ti ne 0} {
				#puts "(@[current method]) timestamp:[[self] timestamp get]"
				:addTimestamp -ts $ti
			} else {
				# case 1: timestamp not found - return code 5 - handle details in expression builder
				dict set returnOptions customOptions "makeEmpty" "timestamp set empty"
				dict set returnOptions customOptions "not found" "${:timestamp}"
				dict set returnOptions customOptions "caller" [self]
				return -code 5 -options $returnOptions "${:timestampClass}:${:timestamp} not found"
			}
		}
		next
	}

	:method createTimestamp {args} {
		${:timestampClass} new -childof [current] {*}$args
	}

	:public method addTimestamp {
		-ts:object,type=Timestamp
	} {
	  # puts "adding timestamp $ts"
	  set a [$ts id get]
	  set b [$ts time get]
	  set c [$ts title get]
	  if {${:timestamp} eq "empty"} {
		[self] timestamp set $a
	  } else {
	  	set l "{${:timestamp} $a}"
		puts l:$l
		[self] timestamp set $l	
	  }
	  $ts destroy
	  :createTimestamp -id $a -time $b -title $c -video [self]
	}

	:public method addTimestampList {
		-tslist:object,type=Timestamp,1..n
	} {
		# args should allow list of one to many items of only timestamps
		# check if list objects are timestamps
		# foreach timestamp in list createTimestamp
		foreach el $tslist {
		  :addTimestamp -ts $el
		}
	}
}

#
# Timestamp
#

nx::Class create Timestamp {
	:property -accessor public {id empty}
	:property -accessor public {time:integer 0}
	:property -accessor public {title empty}
	:property -accessor public {video empty}


	:public object method new {args} {
		set idxID [lsearch $args -id]
		incr idxID
		set timestampID [lindex $args $idxID]

		#set ti [Helper isInstanceAvailable ::Timestamp $timestampID]

		#if {$ti ne 0} {
		#	error "A timestamp instance with id: [$ti id get] already exists: please review your storyboard"
		#}
		next
	}

	:method init {} {
		#puts "Current: [current callingclass] [current callingobject] [current class]:[current methodpath]"
		if {[current callingclass] ne "::StoryBoard::Video"} {
			if {${:video} ne "empty"} {
				set y [Helper isInstanceAvailable ::Video ${:video}]
				if {$y ne 0} {
					$y addTimestamp -ts [self]
				} else {
					return -code 6 "::Video:${:video} not found"
				}
			} elseif {${:video} eq "empty"} {
				dict set returnOptions customOptions "key" "timestamp"
				dict set returnOptions customOptions "caller" [self]
				return -code 6 -options $returnOptions "Timestamp requires a video reference. Checking storyboard."
			}
		}
	}
}

#
# Module
#

nx::Class create Module {
	:property -accessor public {title}
	:property -accessor public {structure}
}

namespace export Video Timestamp Module Helper
}

