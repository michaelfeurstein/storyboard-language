# storyboard-language

**Key-Value Notation:**

`tclsh kv_tester.tcl storyboards/key-value/tester_module`

**Call Structure**

| Notation              | parser.tcl     |              | expression_builder.tcl     |                | visitor.tcl                               |
| :---------------------|:---------------| :------------| :--------------------------|:---------------|:------------------------------------------|
| Key-Value             | creates dict   | --> dict --> | reads dict and instantiates| --> instances --> | transforms into *HTML*                    |

**Natural-Language Notation:**

`tclsh cnl_tester.tcl storyboards/natural-language/syntax_B_module`

**Call Structure**

| Notation              | definition_builder.tcl     | step_definitions.tcl             | |expression_builder.tcl     |                | visitor.tcl                               |
| :---------------------|:---------------------------| :--------------------------------|:----- |:--------------------------|:---------------|:------------------------------------------|
| Natural-Language      | creates Interpreter        | defines regular expressions      | --> dict --> | reads dict and instantiates| --> instances --> | transforms into *HTML*                    |

---

## A Language for Authoring Video-based Learning Content

[Related Work](docs/RELATED_WORK.md)

[Language Foundations](docs/languages.md)

