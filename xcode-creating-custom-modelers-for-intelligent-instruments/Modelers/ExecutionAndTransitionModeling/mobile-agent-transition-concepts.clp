;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines templates for concepts that will be used within the rest of the modeler, such as mobile-agent-transition-started, and mobile-agent-transition-interval
;;;

;;; MobileAgent transitions can be modeled very similarly to the execution concepts.
;;; Just as with the execution concepts, the transition concepts are deftemplates that
;;; are used within the modeling logic to remember when a Mobile Agent has entered its
;;; transition from one stop to another.

;;; Because the Custom Instruments infrastructure allows for separating concepts, rules,
;;; initial knowledge, and recording into separate files, this flexibility is exercised here
;;; by isolating the transition concepts from the execution concepts. Within the instrpkg
;;; file, these transition concepts are introduced into the modeler's scope via the use
;;; of a <rule-path> tag when defining your <modeler>.
(deftemplate MODELER::mobile-agent-transition-started
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

(deftemplate MODELER::mobile-agent-transition-interval
    (slot start (type INTEGER))
    (slot duration (type INTEGER))
    (slot instance (type INTEGER))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot agent-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    
)
