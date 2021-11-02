package req nx
package req tdom

namespace eval StoryBoard {

	nx::Class create Visitor {
		:public method visit args {
			error "Visitor: Implement in subclass!"
		}
	}

	nx::Class create HTMLVisitor -superclasses Visitor {
		:property {doc:substdefault {[dom createDocument html]}}
		:property {bodyNode empty}
		:property {jsNode empty}

	  	:public method evaluate {element:object,type=Element} {
			puts "HTMLVisitor::evaluate start"
			$element accept [self]
			puts "HTMLVisitor::evaluate end"
			try {
				set outfile [open "storyboards/result/generated.html" w+]
				puts $outfile [${:doc} asHTML]
				close $outfile
				set res ${:doc}
			} on error msg {
				error "Preparing HTML document failed: '$msg'."
			} on ok res {
				return $res
			} finally {
				unset :doc
			}
		}

		:public method visit {element:object,type=Element} {
			puts "HTMLVisitor::visit element:$element"
			:traverse [namespace tail [$element info class]] $element
		}

		:method "traverse Module" {e} {
			puts "HTMLVisitor::traverse Module on $e [:id $e]"

			set moduleTitle [$e title get]

			set root [${:doc} documentElement]
			:setupHTMLNodes

			$root appendFromScript {
				head {
					title {
						t $moduleTitle
					}
				}
			}

			set :bodyNode [$root appendChild [${:doc} createElement body]]
			${:bodyNode} appendFromScript {
				h1 {
					t $moduleTitle
				}
			}

			foreach i [lreverse [$e structure get]] {
				$i accept [self]
			}

			#puts "doc: [${:doc} asXML]"
		}

		:method "traverse Question" {e} {
			puts "HTMLVisitor::traverse Question on $e [:id $e]"

			if {[$e type get] eq "singleChoice"} {
				set prompt "Choose one answer"
			} elseif {[$e type get] eq "multipleChoice"} {
				set prompt "Choose one or more answers"
			}

			${:bodyNode} appendFromScript {
				div {
					h3 {
						t [$e title get]
					}
					p {
						t [$e question get]
					}
					p {
						t $prompt
					}
				}
			}

			foreach i [$e answers get] {
				$i accept [self]
			}

			${:bodyNode} appendFromScript {
				button -type "button" -onclick "displayAnswer1()" {
					t Submit
				}
				a -id "showanswer1"
			}

			${:bodyNode} appendFromScript {
				script {
					t "s"
				}
			}
		}

		:method "traverse Answer" {e} {
			puts "HTMLVisitor::traverse Answer on $e [$e id get]-block"
			set a [$e id get]
			set b [[$e info parent] id get]
			set id $b-$a

			if {[[$e info parent] type get] eq "singleChoice"} {
				set type "radio"
			} elseif {[[$e info parent] type get] eq "multipleChoice"} {
				set type "checkbox"
			}

			${:bodyNode} appendFromScript {
				div -id "$id-block" {
					label -for "$id-option" {
						input -type $type -name "option" -id "$id-option" {
							t [$e text get]
						}
					}
					span -id "$id-result"
				}
			}

			# CONTINUE HERE: generate javascript code
		}

		:method "traverse TextPage" {e} {
			puts "HTMLVisitor::traverse TextPage on $e [:id $e]"
		}

		:method "traverse Video" {e} {
			puts "HTMLVisitor::traverse Video on $e [:id $e]"

			# TODO if no timestamps don't add <p>Timestamps:</p>
			#
			${:bodyNode} appendFromScript {
				iframe -src [$e URL get] {
				}
				p {
					t Timestamps:
				}
			}

			# Design question: use timestamp slot instead of children
			# currently timestamp slot is not of type=Timestamp
			# therefore I am no resorting to info children
			foreach i [$e info children] {
				$i accept [self]
			}
		}

		:method "traverse Timestamp" {e} {
			puts "HTMLVisitor::traverse Timestamp on $e [:id $e]"

			#set linkNodes [${:bodyNode} appendChild [${:doc} createElement a]]
			#$linkNodes setAttribute href [$e id get]
			#$linkNodes appendChild [${:doc} createTextNode [$e time get]]
			#
			# TODO create a correct href
			#
			${:bodyNode} appendFromScript {
				a -href [$e id get] {
					t [$e title get]
				}
			}

		}

		:method id {e} {
			return [$e id get]
		}

		:method setupHTMLNodes {} {
			dom createNodeCmd elementNode head
			dom createNodeCmd elementNode title
			dom createNodeCmd elementNode body
			dom createNodeCmd elementNode h1
			dom createNodeCmd elementNode h3
			dom createNodeCmd elementNode p
			dom createNodeCmd elementNode div
			dom createNodeCmd elementNode label
			dom createNodeCmd elementNode input
			dom createNodeCmd elementNode button
			dom createNodeCmd elementNode span
			dom createNodeCmd elementNode iframe
			dom createNodeCmd elementNode script
			dom createNodeCmd elementNode a
			dom createNodeCmd textNode t
		}
	}

namespace export Visitor HTMLVisitor
}
