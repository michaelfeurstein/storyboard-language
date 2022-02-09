namespace eval StoryBoard {

#
# ErrorHandler
#

#
# Encoding error messages for user
#
# Needed in order for ad_text_to_html to encode correctly
# \n\n --> <p>
# \n --> <br>
#
# Error message should be structured the following way
# "\n\nERROR: <error message in one line>\n\n<help guidance text in one line>\n\n<example title>\n<example code>"
#

nx::Class create ErrorHandler {

	:public object method raise_generic_error {msg} {
		error "\n\nERROR: $msg"
	}

	:public object method emptyStoryboard {} {
		error "\n\nERROR: Your storyboard seems to be empty."
	}

	:public object method line_not_formed_well {line} {
		error "\n\nERROR: Line \"$line\" is not formed well.\n\nUse the following structure:\n\nExample Video:\nvideo1 URL https://www.youtube.com/embed/0siisFJUKh4"
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
		error "\n\nERROR: unknown keyword \"$no_match\".\n\nYou need to use one of the following keywords.\n\nAvailable keywords:\n$avail"
	}

	:public object method no_module args {
		#puts "caller:[uplevel 1 {current callingclass}]"
		set moduleExampleKV "module title \"My module\"\nmodule structure (textpage1, video1, question1)"
		set moduleExampleNL "Create module titled \"My module\"\nSet structure of module to (textpage1, video1, question1)"

		if {[uplevel 1 {current callingclass}] ne "::StoryBoard::DefinitionBuilder"} {
			if {[[current callingobject] notation get] eq "key-value"} {
				set moduleExample $moduleExampleKV
			} elseif {[[current callingobject] notation get] eq "natural-language"} {
				set moduleExample $moduleExampleNL
			}
		} else {
			set moduleExample $moduleExampleNL
		}
		error "\n\nERROR: no module defined.\n\nCreate a module to solve this error.\n\nExample Module:\n$moduleExample"
	}

	:public object method parameter_not_found {parameter command} {
		switch -glob -- [lindex $command 0] {
			"Module" {
				switch -glob -- $parameter {
					"-structure" {
						set structure_help "is missing parameter structure.\n\nYou need to set the parameter structure."
						if {[[current callingobject] notation get] eq "key-value"} {
							set paramErrMsg "$structure_help\n\nExample:\nmodule structure (textpage1, video1, question1)"
						} elseif {[[current callingobject] notation get] eq "natural-language"} {
							set paramErrMsg "$structure_help\n\nExample:\nSet structure of module to (textpage1, video1, question1)"
						}
					}
					"-title" {
						set title_help "is missing parameter title.\n\nYou need to set the parameter title."
						if {[[current callingobject] notation get] eq "key-value"} {
							set paramErrMsg "$title_help\n\nExample:\n\nmodule title \"My first module\""
						} elseif {[[current callingobject] notation get] eq "natural-language"} {
							set paramErrMsg "$title_help\n\nExample:\nCreate module titled \"My first module\""
						}
					}
				}
				error "\n\nERROR: [string tolower [lindex $command 0]] $paramErrMsg"
			}
			default {
				error "\n\nERROR: parameter [string trimleft $parameter "-"] not found in [string tolower [lindex $command 0]]."
			}
		}
	}


	#
	# NL-specific
	#

	:public object method handle_unknown_first_word {firstWord} {
		# TODO: provide more feedback (merge with handle_no_matching_class)
		error "\n\nERROR: unknown keyword \"$firstWord\""
	}
}

namespace export ErrorHandler
}
