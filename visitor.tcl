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

	  	:public method evaluate {element:object,type=Element} {
			puts "HTMLVisitor::evaluate"
			$element accept [self]
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

			puts "doc: [${:doc} asXML]"
		}

		:method "traverse Question" {e} {
			puts "HTMLVisitor::traverse Question on $e [:id $e]"
			foreach i [$e answers get] {
				$i accept [self]
			}
		}

		:method "traverse Answer" {e} {
			puts "HTMLVisitor::traverse Answer on $e [$e text get]"
		}

		:method "traverse TextPage" {e} {
			puts "HTMLVisitor::traverse TextPage on $e [:id $e]"
		}

		:method "traverse Video" {e} {
			puts "HTMLVisitor::traverse Video on $e [:id $e]"

			#set iframeNode [${:bodyNode} appendChild [${:doc} createElement iframe]]
			#$iframeNode setAttribute src [$e URL get]
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
			${:bodyNode} appendFromScript {
				a -href [$e id get] {
					t [$e time get]
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
			dom createNodeCmd elementNode p
			dom createNodeCmd elementNode iframe
			dom createNodeCmd elementNode a
			dom createNodeCmd textNode t
		}
	}

namespace export Visitor HTMLVisitor
}
