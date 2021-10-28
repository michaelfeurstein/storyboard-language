package req nx

namespace eval StoryBoard {

# dummy class for visitor pattern
nx::Class create Element {
	:public method accept {visitor} {
		error "Element: Implement in subclass"
	}
}

#
# ContentFragment
#
# Based on ALOCoM: a generic content model for learning objects (Verbet & Duval, 2008)
#
  
nx::Class create ContentFragment {
	:property -accessor public {id empty}
}

#
# TextPage
#

nx::Class create TextPage -superclasses {ContentFragment Element} {
	:property -accessor public {id empty}
	:property -accessor public {title empty}
	:property -accessor public {body empty}

	:public method accept {visitor} {
		puts "TextPage::visit"
		$visitor visit [self]
	}
}

#
# Question
#
# Question new -id question1 -type multipleChoice -title "Information Systems" -question "Explain the concept of an information system" -answers ("", 1, ...) -feedback "Find more information in Wirtschaftsinformatik 1"
#

nx::Class create Question -superclasses {ContentFragment Element} {
	:property -accessor public {title empty}
	:property -accessor public {type multipleChoice}
	:property -accessor public {question empty}
	:property -accessor public {answers:1..*,object,type=Answer}
	:property -accessor public {feedback empty}

	:public method accept {visitor} {
		puts "Question::visit"
		$visitor visit [self]
	}
}

nx::Class create Answer -superclasses Element {
	:property -accessor public {text empty}
	:property -accessor public {correct:boolean 0}

	:public method accept {visitor} {
		puts "Answer::visit"
		$visitor visit [self]
	}
}

#
# Video
#

nx::Class create Video -superclasses {ContentFragment Element} {
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

	:public method accept {visitor} {
		puts "Video::visit"
		$visitor visit [self]
	}
}

#
# Timestamp
#

nx::Class create Timestamp -superclasses Element {
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

	:public method accept {visitor} {
		puts "Timestamp::visit"
		$visitor visit [self]
	}
}

#
# Module
#
nx::Class create Module -superclasses Element {
	:property -accessor public {id empty}
	:property -accessor public {title empty}
	:property -accessor public {structure:1..*,object,type=ContentFragment}
	:property -accessor public {pagination:boolean 0}

	:variable instance:object

	# expression builder's intersectList
	# the call [$class lookup syntax create] with class being Module only returns: ?/arg .../?
	# instead of a long list of args defined above (incl.: id, title, structure, pagination)
	#
	:public object method create {args} {
		puts "create call"
		return [expr {[info exists :instance] ? ${:instance} : [set :instance [next]]}]
		next
	}

	:public method accept {visitor} {
		puts "Module::visit"
		$visitor visit [self]
	}
}

namespace export Element ContentFragment TextPage Video Timestamp Module Question Answer Feedback
}

