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

		:public method evaluate {element:object,type=::StoryBoard::Element} {
			puts "HTMLVisitor::evaluate start"
			$element accept [self]
			puts "HTMLVisitor::evaluate end"
			try {
				######
				# Commented out for use with xowfstoryboard
				# -- think of a way to handle this
				# -- a) a preview visitor (?)
				# -- b) a html visitor exporting generated.html
				#
				#set outfile [open "storyboards/result/html/generated.html" w+]
				#puts $outfile [${:doc} asHTML]
				#close $outfile

				# leave only next line for xowfstoryboard
				set res ${:doc}
			} on error msg {
				error "Preparing HTML document failed: '$msg'."
			} on ok res {
				return $res
			} finally {
				unset :doc
			}
		}

		:public method visit {element:object,type=::StoryBoard::Element} {
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
				html::head {
					html::title {
						html::t $moduleTitle
					}
				}
			}

			set :bodyNode [$root appendChild [${:doc} createElement body]]
			${:bodyNode} appendFromScript {
				html::h1 {
					html::t $moduleTitle
				}
			}

			foreach i [lreverse [$e structure get]] {
				$i accept [self]
			}

			${:bodyNode} appendFromScript {
				html::script {
					html::t "${:scriptNode}"
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
				html::div {
					html::h3 {
						html::t [$e title get]
					}
					html::p {
						html::t [$e question get]
					}
					html::p {
						html::t $prompt
					}
				}
			}

			foreach i [$e answers get] {
				$i accept [self]
			}

			${:bodyNode} appendFromScript {
				html::button -type "button" -onclick "display[$e id get]()" {
					html::t Submit
				}
				html::a -id "showanswer1"
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
				html::div -id "$id-block" {
					html::label -for "$id-option" {
						html::input -type $type -name "option" -id "$id-option" {
							html::t [$e text get]
						}
					}
					html::span -id "$id-result"
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
				html::h3 {
					html::t [$e title get]
				}
				html::p {
					html::t [$e body get]
				}
			}
		}

		:method "traverse Video" {e} {
			puts "HTMLVisitor::traverse Video on $e [:id $e]"

			if {[llength [$e info children]] eq 0} {
				${:bodyNode} appendFromScript {
					html::iframe -src [$e URL get] {
					}
				}
			} else {
				${:bodyNode} appendFromScript {
					html::p {
						html::iframe -src [$e URL get] {
						}
					}
					html::p {
						html::t Timestamps:
					}
				}

				set :tsNode [${:bodyNode} appendChild [${:doc} createElement ul]]

				## a hacky way of sorting the timestamps
				## but it works
				#
				# pseudo:
				# 1) go through timestamps and create new list with <timestamp index> pair
				# 2) sort this list based on index with lsort
				# 3) go through sorted list and continue traverse only for Timestamp objects
				#
				set ts_sort [list]
				foreach i [$e timestamp get] {
					set ts_index [$i index get]
					lappend ts_sort $i $ts_index
				}

				# sort timestamps here
				set sorted_ts [lsort -stride 2 -index 1 -integer $ts_sort]
				foreach i $sorted_ts {
					if {![catch {[$i info class]} e]} {
						$i accept [self]
					}
				}
			}


		}

		:method "traverse Timestamp" {e} {
			puts "HTMLVisitor::traverse Timestamp on $e [:id $e]"

			# TODO create a correct href
			# involves js to reference iframe
			#  - update src of iframe
			#  - reload iframe without page refresh
			#
			#set oldp [namespace path]
			#namespace path [self class]::Markup
			${:tsNode} appendFromScript {
				html::li {
					html::a -href "[[$e info parent] URL get]?start=[$e time get]" {
						html::t [$e title get]
					}
				}
			}
			#namespace path $oldp

		}

		:method id {e} {
			return [$e id get]
		}

		:method setupHTMLNodes {} {
			namespace eval [namespace current]::html {
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
	}

namespace export Visitor HTMLVisitor
}
