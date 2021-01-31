# storyboard-language

tclsh model_tester.tcl storyboards/dict_structure_A

## Syntax Variants (Authoring Tools)

Seidel (2018) [1] (p.232) differentiates between three authoring appproaches specifically for video-based learning (with cscl-scripts). This is in line with more generic classifications by Rabin and Burns (1996) [2] who categorize multimedia authoring tools into five approaches: script-based, card-based, icon-based, timeline-based and object-based.

1. Markup:

   > "Script-based tools depend primarily on a scripting language for programming, though they may be menu-driven. They are often faster for experts than tools with graphical interfaces." (Rabin & Burns, p. 380)
   
   An example for a script-based tool would be standard or extended HTML-Code and also Wiki Markup. Seidel calls this markup.

2. Direct Authoring:

   Editing in user interface showing the player with dedicated interface buttons (+) popping up related dialogs (e.g. dialog to add an annotation). Rabin and Burns (1996) [2] name two categories which together form this approach: card-based and icon-based.

3. Timeline (translated: Zeitleiste)

   > "In timeline-based tools, media elements and events areorganized along a time-line. This allows precise control of temporal characteristics of the application." (Rabin & Burns, 1996, p. 381)
   
   Classic editing via a timeline based video editing interface view (example: Mozilla Popcorn Maker).

Table 1: Overview of applicability of authoring approaches for video-based learning (cscl-scripts) (Seidel, 2018, S. 234)
|                       | Markup        | Direct Authoring  | Timeline |
| ----------------------|:-------------:| :----------------:| :-------:|
| Scalability           | high          | low               | high     |
| Efficient Editing     | high          | middle            | middle   |
| Simple Usability      | low           | high              | middle   |

### Syntax Variant A (Markup)

In Seidel's work on authoring support for video-based cscl-script two tools were developed: [VI-TWO], a framework for authoring interactive videos and [VI-LAB]: a CSCL-system for video-based CSCL-Scripts. [VI-TWO] offers the three authoring approaches named above, one of which is a markup-based approach. This approach builds on using Custom Elements for HTML 5 documents and extending the MediaWiki markup specification.

The following is an example of the use of [Custom Elements] HTML (Seidel, 2018, p.233):

```html
<vi2-video      data−src="http://ww.videos.com/clip.webm">
<vi2-chapter    data-start=9080>
                data-content="Summary"/>
<vi2-comment    data-start=34.4>
                data-author="John"
                data-date="2015-06-28, 12:37"
                data-content="I agree on that."/>
<vi2-link       data-start=435
                data-duration=20
                data-target="#!/video/123/4556"
                data-target-start=30
                data-target-duration=180 />
</vi2-video>
```

Here is another markup example based on MediaWiki, or more specifically [Wikitext] (Seidel, 2018, p.233):

```
<hypervideo>
[[ Video : http : / / example .com/ video .webm myVideo | 200px ]]
[[ Main Page | Startseite ] #10 | 20 | 26% | 26% ]
[[ http://www.video−wiki−example.org/ Click me ] #80 | 120 | 50% | 50% ]
[[ Video: demo.ogv anotherVideo | 200px ]]
[[ Some Page | see here ] #10 | 20 | 26% | 26% ]
</hypervideo>
```



### Syntax Variant B (Natural Language)

[1] Seidel, N. (2018). Interaction Design Patterns und CSCL-Scripts für Videolernumgebungen [Dissertation, Technische Universität Dresden]. https://nbn-resolving.org/urn:nbn:de:bsz:14-qucosa-233756

[2] Rabin, M. D., & Burns, M. J. (1996). Multimedia authoring tools. Conference Companion on Human Factors in Computing Systems Common Ground - CHI ’96, 380–381. https://doi.org/10.1145/257089.257384

[VI-TWO]: https://github.com/nise/vi-two 

[VI-LAB]: https://github.com/nise/vi-lab 

[Custom Elements]: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements

[Wikitext]: https://en.wikipedia.org/wiki/Help:Wikitext
