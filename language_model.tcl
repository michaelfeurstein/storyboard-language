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
  	:method isInstanceAvailable {class id} {
	  	set instlist [$class info instances -closure]
	  	if {[llength $instlist] > 0} {
			foreach x $instlist {
				puts "[current callingclass]:[[current object] id get] is looking for $class:$id"
				if {$id eq [$x id get]} {
					# class instance with id found
					return $x
				}
			}
			# no matching instance of class with id found
			return 0
		} else {
		  	# no instances of class available
		    return 0
		}
	}	
}


#
# Video 
#

nx::Class create Video -mixins Helper {
  	# TODO make the id not callable via DSL
  	:property -accessor public {id empty}
	:property -accessor public {URL empty}
	:property -accessor public {timestamp empty}
	:property {timestampClass ::Timestamp}
	:property {prefix timestamp}

	#:require method autoname

	:method init {} {
		if {${:timestamp} ne "empty"} {
		  	set y [:isInstanceAvailable ${:timestampClass} ${:timestamp}]
		  	if {$y ne 0} {
			  	puts timestamp:[[self] timestamp get]
				:addTimestamp -ts $y
			} else {
				#[self] timestamp set empty
				dict set returnOptions customOptions "${:timestampClass}" "${:timestamp}"
				dict set returnOptions customOptions "destroy" [self]
				return -code 5 -options $returnOptions "${:timestampClass}:${:timestamp} not found"
			}
		}
	}

	:method createTimestamp {args} {
		#${:timestampClass} create [:]::[:autoname ${:prefix}] {*}$args
	  	# puts "is [:] the same as [self]"
		${:timestampClass} new -childof [current] {*}$args
	}

	:public method addTimestamp {
		-ts:object,type=Timestamp
	} {
	  # puts "adding timestamp $ts"
	  :createTimestamp -id [$ts id get] -time [$ts time get] -title [$ts title get]
	  $ts destroy
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
	
	:method init {} {
		if {${:video} ne "empty"} {
		  	set y [:isInstanceAvailable ::Video ${:video}]
		  	if {$y ne 0} {
			  	puts video:[[self] video get]
				$y :addTimestamp -ts [self]
			} else {
			  	puts "video ${:video} not found. Raising error"
				return -code 5 -options $returnOptions "::Video:${:video} not found"
			}
		} elseif {${:video} eq "empty"} {
		  	puts "A timestamp cannot be created without a video" 
		}



#		if {${:video} ne "empty"} {
#		  	# check if video is available
#		  	set success 0
#			set vlist [Video info instances -closure]
#			if {[llength $vlist] > 0} {
#				foreach x $vlist {
#					if {${:video} eq [$x id get]} {
#					  	# create timestamp again within video container
#						#${:video} createTimestamp -time ${:time} -title ${:title}
#		    			puts "x:$x self:[[self] id get]"
#					  	$x addTimestamp -ts [self]
#						set success 1
#						break
#					} else {
#						puts "video ${:video} not found"
#					}
#				}
#				if {!$success} {
#					[self] destroy
#					error "no matching video found, deleting timestamp"
#				}
#			} else {
#				[self] destroy
#				error "no video available"
#			}
#		}
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

