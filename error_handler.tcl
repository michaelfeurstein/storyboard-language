namespace eval StoryBoard {

#
# ErrorHandler
#

nx::Class create ErrorHandler {
	
	:public object method raise_generic_error {msg} {
		error "ERROR: $msg"
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
		error "handleUnknown: $firstWord (no match sentence!)"
	}
}

namespace export ErrorHandler
}
