package req nx

namespace eval StoryBoard {

	nx::Class create Visitor {
		:public method visit args {
			error "Visitor: Implement in subclass!"
		}
	}

	nx::Class create HTMLVisitor -superclasses Visitor {

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
			foreach i [$e structure get] {
				$i accept [self]
			}
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
	}

namespace export Visitor HTMLVisitor
}
