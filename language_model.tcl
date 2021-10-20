package req nx

namespace eval StoryBoard {

#
# ContentFragment
#
# Based on ALOCoM: a generic content model for learning objects (Verbet & Duval, 2008)
#
  
nx::Class create ContentFragment {

}  

#
# Video
#

nx::Class create Video -superclass ContentFragment {
	:property -accessor public {id empty}
	:property -accessor public {URL empty}
	:property -accessor public {timestamp:0..* empty}
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
		if {${:timestamp} ne "empty" && [llength ${:timestamp}] eq 1} {
			# handle single timestamp
			puts "handling single timestamp ${:timestamp}, llength: [llength ${:timestamp}]"
			set ti [Helper isInstanceAvailable ${:timestampClass} ${:timestamp}]
			if {$ti ne 0} {
				#puts "(@[current method]) timestamp:[[self] timestamp get]"
				:addTimestamp -ts $ti
			} else {
				# case 1: timestamp not found - return code 5 - handle details in expression builder
				#dict set returnOptions customOptions "makeEmpty" "timestamp set empty"
				puts "handling timestamp ${:timestamp}, llength: [llength ${:timestamp}]"
				dict set returnOptions customOptions "tslist" "${:timestamp}"
				dict set returnOptions customOptions "caller" [self]
				return -code 5 -options $returnOptions "process timestamp: ${:timestamp}"
			}
		} elseif {${:timestamp} ne "empty" && [llength ${:timestamp}] > 1} {
			# handle a list of timestamps
			puts "handling list of timestamp ${:timestamp}, llength: [llength ${:timestamp}]"
			dict set returnOptions customOptions "tslist" "${:timestamp}"
			dict set returnOptions customOptions "caller" [self]
			return -code 5 -options $returnOptions "process list of timestamps: ${:timestamp}"
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
		puts "adding $a"
		[self] timestamp set $a
	  } else {
		[self] timestamp add $a
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

	#
	# incorrectyl overloading create
	# will corrupt the return from lookup syntax create
	# expression_builder uses lookup syntax create to build commands
	#
	#:public object method create {-id -time -title -video} {
	#	puts "Timestamp --> create call"
	#	next
	#}

	:method init {} {
		#puts "Current: [current callingclass] [current callingobject] [current class]:[current methodpath]"
		if {[current callingclass] ne "::StoryBoard::Video"} {
			if {${:video} ne "empty"} {
				set y [Helper isInstanceAvailable ::Video ${:video}]
				if {$y ne 0} {
					$y addTimestamp -ts [self]
				} else {
					dict set returnOptions customOptions "key" "timestamp"
					dict set returnOptions customOptions "caller" [self]
					return -code 6 -options $returnOptions "::Video:${:video} not found"
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
# CONTINUE HERE: module befüllen mit constraints
nx::Class create Module {
	:property -accessor public {id empty}
	:property -accessor public {title empty}
	:property -accessor public structure:1..*,object,type=ContentFragment
	:property -accessor public {pagination:boolean 0}

	#:variable instance:object

	:public object method new {args} {
		puts "new call"
		next
	}

	# expression builder's intersectList
	# the call [$class lookup syntax create] with class being Module only returns: ?/arg .../?
	# instead of a long list of args defined above (incl.: id, title, structure, pagination)
	#
	#:public object method create {args} {
	#  	puts "create call"
	#	return [expr {[info exists :instance] ? ${:instance} : [set :instance [next]]}]
	#	next
	#}

	:method init {} {
		puts "init call"
		if {${:structure} ne "empty"} {
			puts "structure not empty"
			dict set returnOptions customOptions "structure" "${:structure}"
			dict set returnOptions customOptions "caller" [self]
			return -code 8 -options $returnOptions "process module structure: ${:structure}"
			
			# CONTIUNE HERE: after the storyboard is complete use a ModuleBuilder based on 
			# https://github.com/mrcalvin/djdsl/blob/3520e7ac72185629f8be61ac48f1bca3a826e079/tutorials/patterns.tcl#L690 

			#set ti [Helper isInstanceAvailable ${:timestampClass} ${:timestamp}]
			#if {$ti ne 0} {
				#puts "(@[current method]) timestamp:[[self] timestamp get]"
				#puts "ti:"
			#} else {
			#
			#}	
		}
	}

	:public method addObject {
		-obj:object,type=ContentFragment
	} {
	  set a [$obj id get]
	  puts a:$a
	}
}

namespace export ContentFragment Video Timestamp Module
}

