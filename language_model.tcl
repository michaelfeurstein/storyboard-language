package req nx

namespace eval StoryBoard {

#
# Video 
#

nx::Class create Video {
  	# TODO make the id not callable via DSL
  	:property -accessor public {id empty}
	:property -accessor public {URL empty}
	:property -accessor public {timestamp empty}
	:property {timestampClass ::Timestamp}
	:property {prefix timestamp}

	#:require method autoname

	:method init {} {
		if {${:timestamp} ne "empty"} {
			# check if timestamps are available already
		  	set success 0
		    set tslist [Timestamp info instances -closure]
			if {[llength $tslist] > 0} {
			  	foreach x $tslist {
					puts "timestamp id:[$x id get] looking for ${:timestamp}"
					if {${:timestamp} eq [$x id get]} {
				  		puts "timestamp:${:timestamp} available [$x info has type ${:timestampClass}]"
				  		:addTimestamp -ts $x
						set success 1
						break
					} else {
				  		puts "timestamp ${:timestamp} not found"
				 	}
				}
				if {!$success} {
					[self] timestamp set empty
				  	error "no matching timestamps found"
				}
			} else {
				[self] destroy
				error "no timestamps available"
			}
		}
	}

	:method createTimestamp {args} {
		#${:timestampClass} create [:]::[:autoname ${:prefix}] {*}$args
		${:timestampClass} new -childof [current] {*}$args
	  	# puts "is [:] the same as [self]"
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
		  	# check if video is available
		  	set success 0
			set vlist [Video info instances -closure]
			if {[llength $vlist] > 0} {
				foreach x $vlist {
					if {${:video} eq [$x id get]} {
					  	# create timestamp again within video container
						#${:video} createTimestamp -time ${:time} -title ${:title}
		    			puts "x:$x self:[[self] id get]"
					  	$x addTimestamp -ts [self]
						set success 1
						break
					} else {
						puts "video ${:video} not found"
					}
				}
				if {!$success} {
					[self] destroy
					error "no matching video found, deleting timestamp"
				}
			} else {
				[self] destroy
				error "no video available"
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

namespace export Video Timestamp Module
}

