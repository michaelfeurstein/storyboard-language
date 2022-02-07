namespace eval StoryBoard {

#
# ErrorHandler
#

nx::Class create ErrorHandler {
	
	:public object method raise_generic_error {msg} {
		error "ERROR: $msg"
	}

	:public object method emptyStoryboard {} {
		error "ERROR: Your storyboard seems to be empty"
	}

	:public object method handle_no_matching_class {no_match} {
		set avail_cmds [::StoryBoard::StoryBoardElement info subclasses]
		set avail [list]
		foreach c $avail_cmds {
			set tc [string trimleft $c ::StoryBoard::]
			set lt [string tolower $tc]
			lappend avail $lt
		}
		# TODO: provide more feedback (merge with handle_unknown_first_word)
		error "ERROR: unknown \"$no_match\".\n\nAvailable classes: $avail"
	}	  

	:public object method no_module args {
		if {[[current callingobject] notation get] eq "key-value"} {
			set moduleExample "module title \"My module\"\nmodule structure (textpage1, video1, question1)"
		} elseif {[[current callingobject] notation get] eq "natural-language"} {
			set moduleExample "Create module titled \"My module\"\nSet structure of module to (textpage1, video1, question1)"
		}
		error "It seems you haven't defined a module yet.\n\nExample:\n$moduleExample"
	}

  	:public object method parameter_not_found {parameter command} {
		switch -glob -- [lindex $command 0] {
			"Module" {
				switch -glob -- $parameter {
					"-structure" {
						if {[[current callingobject] notation get] eq "key-value"} {
							set paramErrMsg "is missing parameter structure.\n\nExample:\nmodule structure (textpage1, video1, question1)"
						} elseif {$notation eq "natural-language"} {
							set paramErrMsg "is missing parameter structure.\n\nExample:\nSet structure of module to (textpage1, video1, question1)"
						}
					}
					"-title" {
						if {[[current callingobject] notation get] eq "key-value"} {
							set paramErrMsg "is missing parameter title.\n\nExample:\n\nmodule title \"My first module\""
						} elseif {$notation eq "natural-language"} {
							set paramErrMsg "is missing parameter title.\n\nExample:\nCreate module titled \"My first module\""
						}
					}
				}
				error "[string tolower [lindex $command 0]] $paramErrMsg"
			}
			default {
				error "parameter [string trimleft $parameter "-"] not found in [string tolower [lindex $command 0]]"
			}
		}
  	}


	#
	# NL-specific
	#
	
	:public object method handle_unknown_first_word {firstWord} {
		# TODO: provide more feedback (merge with handle_no_matching_class)
		error "ERROR: unknown \"$firstWord\" (no match sentence!)"
	}
}

namespace export ErrorHandler
}
