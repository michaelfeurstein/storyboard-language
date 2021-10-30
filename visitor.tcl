package req nx
package req tdom

namespace eval StoryBoard {

	nx::Class create Visitor {
		:public method visit args {
			error "Visitor: Implement in subclass!"
		}
	}

	nx::Class create HTMLVisitor -superclasses Visitor {
		:property {doc empty}
		:property {root empty}

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

			# setting up tdom usage
			# testing around and getting to know it
			# CONTINUE HERE:
			# create outside of methods
			set :doc [dom createDocument html]
			set :root [${:doc} documentElement]
			:setupHTMLNodes

			${:root} appendFromScript {
				head {
					title {
						t $moduleTitle
					}
				}
			}

			foreach i [lreverse [$e structure get]] {
				$i accept [self]
			}

			${:root} appendFromScript {
				body {
					h1 {
						t $moduleTitle
					}
				}
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

			# idea would be to get the body node
			# and append the relevant html tags into the body tag
			set bodyNode [${:doc} getElementsByTagName "body"]
			puts $bodyNode

			#$bodyNode appendFromScript {
			#	iframe -src [$e URL get] {
			#	}
			#}

			# this will insert iframe above body
			#${:root} insertBeforeFromScript {
			#		iframe -src [$e URL get] {
			#		}
			#} body

			# Design question: use timestamp slot instead of children
			# currently timestamp slot is not of type=Timestamp
			# therefore I am no resorting to info children
			foreach i [$e info children] {
				$i accept [self]
			}
		}

		:method "traverse Timestamp" {e} {
			puts "HTMLVisitor::traverse Timestamp on $e [:id $e]"
		}

		:method id {e} {
			return [$e id get]
		}

		:method setupHTMLNodes {} {
			dom createNodeCmd elementNode head
			dom createNodeCmd elementNode title
			dom createNodeCmd elementNode body
			dom createNodeCmd elementNode h1
			dom createNodeCmd elementNode iframe
			dom createNodeCmd elementNode a
			dom createNodeCmd textNode t
		}
	}

namespace export Visitor HTMLVisitor
}
