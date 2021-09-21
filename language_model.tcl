package req nx

namespace eval StoryBoard {

#
# Video 
#

nx::Class create Video {
	:property -accessor public {URL empty}

	:property {timestampClass ::Timestamp}
	:property {prefix timestamp}

	:require method autoname

	:public method createTimestamp {args} {
		set item [${:timestampClass} create [:]::[:autoname ${:prefix}] {*}$args]
		# puts "is [:] the same as [self]"
		return $item
	}

	:public method addTimestamp {
		-ts:object,type=Timestamp
	} {
	  # puts "adding timestamp $ts"
	  [:createTimestamp -time [$ts time get] -title [$ts title get]]
	  $ts destroy
	}
}

#
# Timestamp
#

nx::Class create Timestamp {
	:property -accessor public {time:integer 0}
	:property -accessor public {title empty}
	:property -accessor public {video empty}
	
	:method init {} {
		if {${:video} ne "empty"} {
			# create timestamp again within video container
			# delete this timestamp afterwards 
			[${:video} createTimestamp -time ${:time} -title ${:title}]
			[self] destroy
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

