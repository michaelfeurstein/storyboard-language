# log

## 15.01.2021

Ok, also das ist der initial commit. Ein erster Versuch.
'tclsh model_tester.tcl' ist das was ich verwende um mal ein Gefühl zu bekommen ob was klappt. Angelehnt an djdsl/tutorials/intro.tcl

Im Sinne deiner Notion eines "Roten Fadens":

(a) file:storyboard_test_list - input als 'interne DSL Syntax' mit tcl-liste (siehe Frage 1), eine von 2 Syntaxvarianten.
 |
(b) file:expression_builder.tcl - EXPRESSION BUILDER um aus language_model.tcl instanzen zu generieren. Im derzeitigen stand wird eine nackte video instanz erzeugt ohne title, length. So verstehe ich es zumindest. (siehe Frage 2) 
 |
(c) TODO.tcl - noch unsicher wie es da weiter geht. VISITOR in xowf-Artefakte - also ein code generator? (Buch Abschnitt 1.4.3)

Fragen:
(1) file:model_tester.tcl:46
Übergabe von tcl list die ich aus file einlese klappt nicht bzw. steh ich da an? Kann ich eine liste an eine proc übergeben? Vom verständnis her lese ich hier die syntax aus einer verschachtelten tcl-list oder dict oder json ein (siehe auch dein punkt a in mail vom 29.10.20) die ein nutzer geschrieben hat - das wäre auch eine variante im experiment - wahrscheinlich sollte ich mir da eher im klaren werden ob tcl-list, dict, JSON-doc oder tDOM-script im Abgleich mit einer Story zur Syntax Variante.

(2) file:expression_builder.tcl
line:6 - :forward - nur zur sicherheit vom verständnis her ist das eine forwarder methode (listing 23 vom nx tutorial)? Heisst das dann, dass ich zum Beispiel alle keywords hier quasi mappe auf die richtigen Klassen?

line:16 - dynamic reception - auch hier nochmal nachgefragt, überschreibe/hijacke ich da die interne tcl methode "unkown"? zumindest verstehe ich das so, wie du es auf S.170 in deinem buch in der tabelle beschreibst.

eigentliche frage 2: wenn ich jetzt die klasse video hier mit title und length mal instanzieren will müsste ich dann auch title und length als nx::Class definieren? Ich glaub da kopiere ich zu viel, bzw. habe ich das gefühl, dass ich das anders machen sollte (= einlesen, abfangen, als solche identifizieren und dann in der creator klasse weitergeben.)

## end 

