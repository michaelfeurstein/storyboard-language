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
		:property {scriptNode empty}
		:property {jsAnswer empty}
		:property {tsNode empty}

	  	:public method evaluate {element:object,type=Element} {
			puts "HTMLVisitor::evaluate start"
			$element accept [self]
			puts "HTMLVisitor::evaluate end"
			try {
				set outfile [open "storyboards/result/html/generated.html" w+]
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
			set :scriptNode ""
			set :jsAnswer ""

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

			${:bodyNode} appendFromScript {
				script {
					t "${:scriptNode}"
				}
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
				button -type "button" -onclick "display[$e id get]()" {
					t Submit
				}
				a -id "showanswer1"
			}

			set :scriptNode "${:scriptNode}
			function display[$e id get]() {
				${:jsAnswer}
			}"

			#${:bodyNode} appendFromScript {
			#	script {
			#		t "${:scriptNode}"
			#	}
			#}
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

			if {[$e correct get]} {
				set color "limegreen"
				set innerHTML "Correct!"
				# IF NEEDED: if its correct add showCorrectAnswer javascript
			} else {
				set color "red"
				set innerHTML "Incorrect!"
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

			set :jsAnswer "${:jsAnswer}
			if (document.getElementById('$id-option').checked) {
			document.getElementById('$id-block').style.border = '2px solid $color'
			document.getElementById('$id-result').style.color = '$color'
			document.getElementById('$id-result').innerHTML = '$innerHTML'}"
		}

		:method "traverse TextPage" {e} {
			puts "HTMLVisitor::traverse TextPage on $e [:id $e]"

			${:bodyNode} appendFromScript {
				h3 {
					t [$e title get]
				}
				p {
					t [$e body get]
				}
			}
		}

		:method "traverse Video" {e} {
			puts "HTMLVisitor::traverse Video on $e [:id $e]"

			if {[llength [$e info children]] eq 0} {
				${:bodyNode} appendFromScript {
					iframe -src [$e URL get] {
					}
				}
			} else {
				${:bodyNode} appendFromScript {
					iframe -src [$e URL get] {
					}
					p {
						t Timestamps:
					}
				}

				set :tsNode [${:bodyNode} appendChild [${:doc} createElement ul]]
			}

			# Design question: use timestamp slot instead of children
			# currently timestamp slot is not of type=Timestamp
			# therefore I am now resorting to info children
			# instead of [$e timestamp get]
			foreach i [$e info children] {
				$i accept [self]
			}
		}

		:method "traverse Timestamp" {e} {
			puts "HTMLVisitor::traverse Timestamp on $e [:id $e]"

			# TODO create a correct href
			# involves js to reference iframe
			#  - update src of iframe
			#  - reload iframe without page refresh
			#
			${:tsNode} appendFromScript {
				li {
					a -href "[[$e info parent] URL get]?start=[$e time get]" {
						t [$e title get]
					}
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
			dom createNodeCmd elementNode li
			dom createNodeCmd elementNode a
			dom createNodeCmd textNode t
		}
	}

namespace export Visitor HTMLVisitor
}
