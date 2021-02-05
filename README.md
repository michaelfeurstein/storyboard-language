# storyboard-language

tclsh model_tester.tcl storyboards/dict_structure_A

## Structure

| Syntax                | parser.tcl     |              | expression_builder.tcl     |                |
| :---------------------|:---------------| :------------| :--------------------------|:---------------|
| Syntax A / B          | creates dict   | --> dict --> | reads dict and instantiates| ---> instances |

---

## A Language for Authoring Video-based Learning Units

The idea of creating a language for video editing in general is not new. There are multiple projects available which tackle this challenge in different ways and details.

### Context: Video

- [MoviePy]: a python based language for video editing. It helps with basic functions such as cutting, concatenating, title insertions, compositing (non-linear editing), effects and video processing.

     Excerpts from a script compositing two videos into a picture-in-picture composition. Example Script can be found [here](https://zulko.github.io/moviepy/examples/ukulele_concerto.html)

```
ukulele = VideoFileClip("../../videos/moi_ukulele.MOV", audio=False).\
               subclip(60+33, 60+50).\
               crop(486, 180, 1196, 570)
               
piano = (VideoFileClip("../../videos/douceamb.mp4",audio=False).
         subclip(30,50).
         resize((w/3,h/3)).    # one third of the total screen
         margin( 6,color=(255,255,255)).  #white margin
         margin( bottom=20, right=20, opacity=0). # transparent
         set_pos(('right','bottom')) )

---------%<---------

final = CompositeVideoClip([ukulele,txt_mov,piano])
final.subclip(0,5).write_videofile("../../ukulele.avi",fps=24,codec='libx264')
```

- [AviSynth]: a *nonlinear scripting language for video*

    AviSynth does not provide a GUI but fully relies on a script system. However the resource seems old and unmaintained. There is however a new fork [AviSynth+](https://avs-plus.net/) aiming to modernize AviSynth to meet present day needs.
    
    Excerpts from an AviSynth script. Example Scripts can be found [here](http://avisynth.nl/index.php/Script_examples)
    
```
AVISource("somevideo.avi")

# TemporalSoften is one of many noise-reducing filters
TemporalSoften(4, 4, 8, scenechange=15, mode=2)

# increase the gamma (relative brightness) of the video
Levels(0, 1.2, 255, 0, 255)

# fade-in the first 15 frames from black
FadeIn(15)

# fade-out the last 15 frames to black
FadeOut(15)
```

- [Functional Pearl]:Video: a user-facing DSL implemented with [Racket] named Video for editing video. (Andersen et al. 2017)[11]

    This functional pearl focusses on the production of video processing for conference proceedings. 
    
    Excerpt froma video script. Example Scripts can be found in the publication by Andersen et al. (2017)[11]:
    
```
#lang video

(image "splash.png" #:length 100) 04
(fade-transition #:length 50)

-----%<-----

; where
(define slides
(clip"slides05.MTS"#:start2900#:end80000))

(define presentation
(playlist(clip"vid01.mp4")
(clip "vid02.mp4")
#:start 3900 #:end 36850))

(fade-transition #:length 50)

(image "splash.png" #:length 100)
```

- [SMIL]: Synchronized Multimedia Integration Language - a W3C recommended extensible markup language to author multimedia presentation (video, audio, image, text).

    SMIL has been used to implement an educational digital video library. See publication by Milrad et al. (2005) [13]. Bulterman and Rutledge (2004) [14] published a book on SMIL, which has been well perceived by academia (King, 2007) [15]. SMIL itself seems deprecated, based on [this article](https://css-tricks.com/smil-is-dead-long-live-smil-a-guide-to-alternatives-to-smil-features/), however W3C shows a [SMIL 3.0](https://www.w3.org/TR/SMIL/).
    
    Excerpts from a SMIL file: Examples can be found [here](https://www.w3.org/AudioVideo/RA-examples.html) and [here](https://homepages.cwi.nl/~media/SMIL/Tutorial/SMILTut.html)
    
    ```
    <smil><!--The SMIL file must start with a <smil> tag and end with the </smil> closing tag.-->
    <head> <!-- SMIL file header, specify meta information in the multimedia presentation-->
                <meta name="author" content="Jane Morales"/>
                <meta name="title" content="Multimedia My Way"/>
                <meta name="copyright" content="(c)1998 Jane Morales"/>
    </head>
    <body>
                <seq> <!-- To play clips in sequence, use the <seq> ("sequence") SMIL tag.-->
                  <audio src="audio/newsong.wav"/>
                  <audio src="audio/oldsong.snd"/>
                </seq>
    </body>
    </smil>
    ```

- [Prose-Storyboard-Language]: Ronfard et al. (2013) [10] created the Prose-Storyboard Language, a natural language approach to describe camera movement and direction information for a movie.
    
    Excerpts from an [srt file](https://files.inria.fr/imagine/PSLV3/BackToTheFuture_subtitles.srt) describing the storyboard behind the Cafe scene from Back to the Future (1985) by Robert Zemeckis:

```
1
00:00:47 --> 00:00:48
cut to high angle CU Lou 34backleft 

2
00:00:48 --> 00:00:55
then as Marty crosses under Lou hold to high angle MS Marty CU Lou 34backleft
3
00:00:55 --> 00:00:60
cut to CU Marty 34backright MCU Lou 34left 
4
00:00:60 --> 00:01:07
cut to high angle MS Marty front CU Lou 34backleft 

5
00:01:07 --> 00:01:14
cut to CU Marty 34backright MCU Lou 34left

6
00:01:14 --> 00:01:16
cut to high angle MS Marty front CU Lou 34backleft
```

Other examples with no further details include:
  * [VAML] (Video Annotation Markup Language)
  
  * [Markup-based Video Editing](https://www.learntechlib.org/p/10096/)

The above examples are all focussed on video first. They use one of the following approaches:

1. (functional) programming / scripting ([MoviePy], [AviSynth], Video DSL [11])

2. markup ([SMIL], [Markup-based Video Editing](https://www.learntechlib.org/p/10096/), [VAML])

3. natural language ([Prose-Storyboard-Language])

---

### Context: Education

In terms of an educationl context, it is harder to identify true languages, which have been designed for authoring a video-based learning unit. There are several tools, modules and frameworks primarily providing a GUI-approach to author video-based learning units ([DIVER Project](http://diver.stanford.edu/home.html), [TED Ed Lesson Creator](https://ed.ted.com/educator), [Vivista](https://github.com/Saticmotion/Vivista/tree/master)).

A general overview of domain specific languages in an educational context:

- [COSTLy] a language for defining CSCL-Scripts

     Papasalouros (2018) [17] initially introduced this language in a paper on *Formalizing CSCL Scripts with Logi and Constraints*. The language uses Java and Prolog to create a constraints logic programs which is run with a constraint solver. In a followup publication by Papasalouros & Chatzimichalis (2020) [18] an authoring platform has been introduced which builds on COSTLy and integrates the whole user (lecturer & instructional designer) process. It also provides a visual script editor based on [Google: Blockly] in the style of a *if this then that (ITTT)*, which enables the creator to get visual support during the script editing process. The authoring platform was evaluated towards its expressiveness (expressed 4 scripts) and its usability (students n=31).
     
   Excerpt of a generic group definition from Papasalouros & Chatzimichalis (2020) [18]:
    
   ```
   phase EG: create-partition P for S,Tasks with |Tasks| groups .
    forall T in Tasks exists! Gr in P
     forall St in Gr
      ASSERT(performs(St,T))
   ```
   
   Excerpt of a textual definition of the UniverSante CSCL Script by Papasalouros & Chatzimichalis (2020) [18]:
   
   ```
   define script UniverSante:
    phase MNT:
     create-partition Un1 for S,Countries with |S|/|Countries|
     groups .
      forall Group in Un1 
       forall Nationality in Countries exists! P in Group
        country(P,Nationality).
    
    phase SNT:
     create-partition Un2 for S,Countries with |Countries|
     groups .
      forall Nationality in Countries exists! Group in Un2
       forall P in Group
        country(P,Nationality).
    ```
   
   Visual Excerpt showing a visual definition of the Jigsaw CSCL Script using [COSTLy] and [Google: Blockly] (Papasalouros & Chatzimichalis, 2020) [18]:
   
   ![COSTLy visual example][costly-visual-example]
 
- **LISL** a Learner Interaction Scripting Language (Mödritscher et al., 2008) [19] for building (Mashup) Personal Learning Environments (MUPPLE)

     Mödritscher et al. (2008) [19] used this language to demonstrate the use of a domain-specific language to create a mashed up learning environment consisting of different modules (or tools, so to say). The language is implemented in Tcl, precisely in XoTcl and is part of the [MUPPLE](https://sourceforge.net/projects/icamp/) package.
     
     Excerpt from Mödritscher et al. (2008) [19]:
     
     ```
     define action Compose with url http://[...]?action=create
     define action Browse
     define action Bookmark
     define object 'self-description'
     define object ‘self-descriptions of peers’ with url http://[...]/peers
     define object ‘selected self-descriptions’
     define tool VideoWiki with url http://videowiki.icamp.eu
     define tool Scuttle with url http://scuttle.icamp.eu
     connect tool VideoWiki with tool Scuttle
     Compose ‘self-description’ using VideoWiki
     Browse ‘self-descriptions of peers’ using VideoWiki
     Bookmark ‘selected self-descriptions’ using VideoWiki
     drag tool VideoWiki
     ```

The following come close to being a *language-based approach* and combining *video-based learning*:

- [VI-TWO] a framework for authoring interactive videos and [VI-LAB], a CSCL-system for video-based CSCL-Scripts

    However, there is for example work by Seidel (2018) [1] who created [VI-TWO], a framework for authoring interactive videos and [VI-LAB], a CSCL-system for video-based CSCL-Scripts. He builds on [Custom Elements] and [Wikitext] to author video-based learning units.
    
- VCML Video-based Correction Markup Language: https://doi.org/10.1076/call.15.4.387.8273

- L.IVE an integrated interactive video-based learning environment: http://dx.doi.org/10.1145/2556288.2557368 





## Syntax Variants (Authoring Tools)

Seidel (2018) [1] (p.232) differentiates between three authoring appproaches specifically for video-based learning (with cscl-scripts). This is in line with more generic classifications by Rabin and Burns (1996) [2] who categorize multimedia authoring tools into five approaches: script-based, card-based, icon-based, timeline-based and object-based. Or Fenrich (2005), who differentiates between: authoring systems, object-based systems and programming languages.

1. Markup:

   > "Script-based tools depend primarily on a scripting language for programming, though they may be menu-driven. They are often faster for experts than tools with graphical interfaces." (Rabin & Burns, p. 380)
   
   An example for a script-based tool would be standard or extended HTML-Code and also Wiki Markup. Fenrich (2005) [3] .

2. Direct Authoring:

   > "Object-based systems consist of objects that are programmed to do things." (Fenrich, 2005, p.42)
   
   Editing in user interface showing the player with dedicated interface buttons (+) popping up related dialogs (for specific authoring tasks e.g.: dialog to add an annotation). Rabin and Burns (1996) [2] name two categories which together form this approach: card-based and icon-based. Fenrich (2005) calls this object-based. Seidel (2018) uses the term direct authoring.

3. Timeline (translated: Zeitleiste)

   > "In timeline-based tools, media elements and events are organized along a time-line. This allows precise control of temporal characteristics of the application." (Rabin & Burns, 1996, p. 381)
   
   Classic editing via a timeline based video editing interface view (example: Mozilla Popcorn Maker). Fenrich (2005) calls this authoring systems. Seidel (2018) uses the term "Zeitleiste".

Table 1: Overview of applicability of authoring approaches for video-based learning (cscl-scripts) (Seidel, 2018, S. 234)
|                       | Markup        | Direct Authoring  | Timeline |
| ----------------------|:-------------:| :----------------:| :-------:|
| Scalability           | high          | low               | high     |
| Efficient Editing     | high          | middle            | middle   |
| Simple Usability      | low           | high              | middle   |

### Syntax Variant A (Markup Approach)

In Seidel's work on authoring support for video-based cscl-script two tools were developed: [VI-TWO], a framework for authoring interactive videos and [VI-LAB]: a CSCL-system for video-based CSCL-Scripts. [VI-TWO] offers the three authoring approaches named above, one of which is a markup-based approach. This approach builds on using Custom Elements for HTML 5 documents and extending the MediaWiki markup specification.

Some examples of markup in connection with video-based learning or multimedia development:

1. Markup example of the use of [Custom Elements] HTML by Seidel (2018, p.233):

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

2. Markup extension based on MediaWiki, specifically [Wikitext] by Seidel (2018, p.233):

```
<hypervideo>
[[ Video : http : / / example .com/ video .webm myVideo | 200px ]]
[[ Main Page | Startseite ] #10 | 20 | 26% | 26% ]
[[ http://www.video−wiki−example.org/ Click me ] #80 | 120 | 50% | 50% ]
[[ Video: demo.ogv anotherVideo | 200px ]]
[[ Some Page | see here ] #10 | 20 | 26% | 26% ]
</hypervideo>
```

3. Markup-based DSL \<e-Game\> developed in the context of video game development by Moreno-Ger et al. (2006) [11]:

```
<conversation, Foreman,
<<speak-char, "Well José, did you measure the
scaffold">,
                     <<response,
                      <<"No sir, not yet",
<<speak-char, "And what are you waiting for, boy?">, <<speak-player, "At once, sir">, <end-conversation,<>>>>>,
<<"Yes sir, it's ready", <<speak-char, "And...">, <<response,
... >,
{{SecondTaskInitiated, UsedMeasureTapeScaffold},∅}>
```

#### Markup-languages (wiki) used in higher education

When looking at the question "what kind of authoring tools do lecturers use in higher education", then one authoring approach is rooted in the area of markup languages, hence wiki-based markup. Some references showing the use of wiki technology in higher eduaction: Ebner et al. (2008) [4]; Andergassen et al. (2015) [5]; Raitman et al. (2005) [6]; Augar et al. (2004) [7]; Neumann (2006) [8]. Based on these examples we can generally state that the notion of using wiki markup as such is known in higher education. Therefore a proposed syntax variant for the storyboard language is inspired by markup-languages.

Example from Seidel (2011) [9] "Vi-Wiki markup" showing a markup version for two sequential clips and hyperlinks:

```
<hypervideo>
[[Video:clip 1 clip 2]]
[[Video:clip 2 #10 | 140 clip_3 ]]
+[[Hyperlink: #clip_1] 120px 300px]
+[[Hyperlink: other page#b] #60 | 120]
</hypervideo>
```

Example from LEARN [5] showing markup using XoWiki [8] for an external video as a video highlight:

```
[[_OMar04NRZw||-class ::xowiki::Link::youtube -width 480 -height 270 -starttime 395 -endtime 460]]
```

Proposal: Markup variant for storyboard-language proposal

```
<storyboard>
[[Video:myVideoID] -title "Video Title" -videoSource "http://www..." -length 120]
[[Highlight:myHighlight] -videoref "myVideoID" -title "A samlpe Highlight" -starttime 5 -endtime 60]
</storyboard>
```

### Syntax Variant B (Natural Language Approach)

Ronfard et al. (2013) [10] created the [Prose-Storyboard-Language], a natural language approach was used to describe camera movemenet and direction information for a movie. Syntax variant b leans towards this natural language descritpion in order to structure a video-based learning unit into highlights with assessments and other interaction elements. The motivation behind this is that markup-language my not be easy to grasp and that the creation process for video-based learning unit builds on a storyboard, which is mainly done through informal text (citation needed).

Example from the [Prose-Storyboard-Language] describing the storyboard behind the Cafe scene from Back to the Future(1985) by Robert Zemeckis:

```
1
00:00:47 --> 00:00:48
cut to high angle CU Lou 34backleft 

2
00:00:48 --> 00:00:55
then as Marty crosses under Lou hold to high angle MS Marty CU Lou 34backleft
3
00:00:55 --> 00:00:60
cut to CU Marty 34backright MCU Lou 34left 
4
00:00:60 --> 00:01:07
cut to high angle MS Marty front CU Lou 34backleft 

5
00:01:07 --> 00:01:14
cut to CU Marty 34backright MCU Lou 34left

6
00:01:14 --> 00:01:16
cut to high angle MS Marty front CU Lou 34backleft
```

Prototypical example:

```
There are 3 scenes (videos)
First scene: “Overview of classroom”
Second scene: “At the optimal position”
Third scene: “Optimal position with class attendees”

We begin with an instruction at the beginning of the first scene.
After that information is shown and talked about on the optimal camera position in the middle of the video during the first scene.
At the end of scene one a short quiz is shown asking the user to choose the optimal position.
```

## End result

What should the outcome of the storyboard be (independent from syntax variant a or b) = instantiations of all elements for a video-based learning scenario e.g.: 1 video, 3 highlights, 2 annotations and ..., which can then be transformed into a xowiki environment or unity environment (?). More generally spoken the outcome should be a usable video-based learning unit for any given environment. 

A running example of a video-based learning unit can be found here: [TED-Ed Online Unit]

A generic example of the transformed instantiations with annotations describing the elements:

![Generic VBL Module Example][annotated-vbl-module]

## References 

[1] Seidel, N. (2018). Interaction Design Patterns und CSCL-Scripts für Videolernumgebungen [Dissertation, Technische Universität Dresden]. https://nbn-resolving.org/urn:nbn:de:bsz:14-qucosa-233756

[2] Rabin, M. D., & Burns, M. J. (1996). Multimedia authoring tools. Conference Companion on Human Factors in Computing Systems Common Ground - CHI ’96, 380–381. https://doi.org/10.1145/257089.257384

[3] Fenrich, P. (2005). Creating Instructional Multimedia Solutions: Practical Guidelines for the Real World. Informing Science.

[4] Ebner, M., Kickmeier-Rust, M., & Holzinger, A. (2008). Utilizing Wiki-Systems in higher education classes: A chance for universal access? Universal Access in the Information Society, 7(4), 199. https://doi.org/10.1007/s10209-008-0115-2

[5] Andergassen, M., Ernst, G., Guerra, V., Mödritscher, F., Moser, M., Neumann, G., & Renner, T. (2015). The Evolution of E-Learning Platforms from Content to Activity Based Learning. Proc. of 18th Intl. Conference on Interactive Collaborative Learning (ICL).

[6] Raitman, R., Augar, N., & Zhou, W. (2005). Employing wikis for online collaboration in the e-learning environment: Case Study. Proceedings of the Third International Conference on Information Technology and Applications, 2, 142–146. https://doi.org/10.1109/ICITA.2005.127

[7] Augar, N., Raitman, R., & Zhou, W. (2004). Teaching and learning online with wikis. In R. Atkinson, C. McBeath, D. Jonas-Dwyer, & R. Phillips (Hrsg.), Beyond the Comfort Zone: Proceedings of the 21st ASCILITE conference (S. 95–104).

[8] Neumann, G. (2006, November). XoWiki, An Experiment for an XOTcl based Content Management Infrastructure [Talk]. OpenACS Workshop, Harvard, MA. http://nm.wu-wien.ac.at/research/publications/b616.pdf

[9] Seidel, N. (2011). Enable Wikis for seamless hypervideo integration. Proceedings of the 29th Annual European Conference on Cognitive Ergonomics - ECCE ’11, 251. https://doi.org/10.1145/2074712.2074765

[10] Ronfard, R., Gandhi, V., & Boiron, L. (2013). The Prose Storyboard Language: A Tool for Annotating and Directing Movies. 2nd Workshop on Intelligent Cinematography and Editing, 9. HAL archives-ouvertes.fr. https://hal.inria.fr/hal-00814216

[11] Moreno-Ger, P., Martínez-Ortiz, I., Sierra, J. L., & Manjón, B. F. (2006). Language-Driven Development of Videogames: The Experience. In R. Harper, M. Rauterberg, & M. Combetto (Hrsg.), Entertainment Computing—ICEC 2006 (S. 153–164). Springer. https://doi.org/10.1007/11872320_19

[12] Andersen, L., Chang, S., & Felleisen, M. (2017). Super 8 languages for making movies (functional pearl). Proceedings of the ACM on Programming Languages, 1(ICFP), 30:1-30:29. https://doi.org/10.1145/3110274

[13] Milrad, M., Rossmanith, P., & Scholz, M. (2005). Implementing an Educational Digital Video Library Using MPEG-4, SMIL and Web Technologies. Educational Technology & Society, 8, 120–127.

[14] Bulterman, D. C. A., & Rutledge, L. (2004). SMIL 2.0: Interactive Multimedia for Web and Mobile Devices. Springer X.media.publishing. https://books.google.at/books?id=XTyWkvpLZVwC

[15] King, P. (2007). Book Review: SMIL 2.0 Interactive Multimedia for Web and Mobile Devices by C. A. Dick Bulterman and Lloyd Rutledge. Journal of Functional Programming, 17(3), 423–424. https://doi.org/10.1017/S0956796807006260

[16] Monserrat, T.-J. K. P., Li, Y., Zhao, S., & Cao, X. (2014). L.IVE: An Integrated Interactive Video-based Learning Environment. Proceedings of the SIGCHI Conference on Human Factors in Computing Systems, 3399–3402. https://doi.org/10.1145/2556288.2557368

[17] Papasalouros, A. (2018). Formalizing CSCL Scripts with Logic and Constraints. In V. Pammer-Schindler, M. Pérez-Sanagustín, H. Drachsler, R. Elferink, & M. Scheffel (Hrsg.), Lifelong Technology-Enhanced Learning (S. 660–663). Springer International Publishing. https://doi.org/10.1007/978-3-319-98572-5_68

[18] Papasalouros, A., & Chatzimichalis, G. (2020). An Authoring Platform for CSCL Script Definition. In P. Zaphiris & A. Ioannou (Hrsg.), Learning and Collaboration Technologies. Human and Technology Ecosystems (S. 625–640). Springer International Publishing. https://doi.org/10.1007/978-3-030-50506-6_43

[19] Mödritscher, F., Wild, F., & Sigurdarson, S. (2008). Language Design for a Personal Learning Environment Design Language. 1st International Workshop on Mashup Personal Learning Environments (MUPPLE08, 10.




[VI-TWO]: https://github.com/nise/vi-two 

[VI-LAB]: https://github.com/nise/vi-lab 

[Custom Elements]: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements

[Wikitext]: https://en.wikipedia.org/wiki/Help:Wikitext

[TED-Ed Online Unit]: https://ed.ted.com/on/wSKIdmQE

[Prose-Storyboard-Language]: https://team.inria.fr/anima/prose-storyboard-language/

[example-vbl-module]: https://github.com/michaelfeurstein/storyboard-language/blob/main/images/example-vbl-module.png "Generic VBL Module"

[annotated-vbl-module]: https://github.com/michaelfeurstein/storyboard-language/blob/main/images/annotated-vbl-module.png "Annotated VBL Module"

[MoviePy]: https://zulko.github.io/moviepy/index.html

[AviSynth]: http://avisynth.nl/index.php/Main_Page

[Functional Pearl]: https://wiki.haskell.org/Research_papers/Functional_pearls

[Racket]: https://racket-lang.org/sfc.html

[SMIL]: https://www.w3.org/TR/SMIL/

[VAML]: https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.119.2847&rep=rep1&type=pdf

[COSTLy]: https://its2020.iis-international.org/wp-content/uploads/4.-54-Towards-CSCL-Scripting-By-Example.pdf

[costly-visual-example]: https://github.com/michaelfeurstein/storyboard-language/blob/main/images/visual-jigsaw-cscl-blocky__Papasalouros_Chatzimichalis.png "A visual definition of the Jigsaw script"
