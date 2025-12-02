;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file exemplifies a CLIPS logic loop when attempting to implement a counter for active mobile agents.

;;;
;;; This fact stores an integer that will be incremented upon detecting
;;; a mobile-agent fact in working memory. When the trace is complete,
;;; this fact will contain the total number of mobile agents that were
;;; used in an application.
(deftemplate MODELER::mobile-agent-counter
    (slot count (type INTEGER))
)

(deffacts MODELER::initial-mobile-agent-counter
    (mobile-agent-counter (count 0))
)

;;; The sole purpose of this rule is to demonstrate a CLIPS logic loop programming error.
;;; CLIPS logic loops occur when a rule's actions cause the rule engine to immediately
;;; consider the rule ready for activation. Consider the rule below. The rule attempts to
;;; count the amount of mobile agents that are asserted by the modeler in mobile-agent-modeling.clp

;;; In an attempt to achieve this goal, the rule checks for the presence of a mobile-agent-counter
;;; fact and the presence of a mobile-agent. If these two are detected, the rule modifies the
;;; mobile-agent-counter fact to increment the count. The "modify" CLIPS expression is used to
;;; achieve this. "modify" takes a given fact as input as well as the desired modifications to the given fact.
;;; See the rule below for an example of this. "modify" retracts the given fact and asserts a new
;;; fact with a union of the fact's original slot values and the specified modifications.

;;; When the fact is introduced into working memory, the CLIPS logic engine can determine which
;;; rules are available to fire. The conditions for count-mobile-agent-instances require a
;;; mobile-agent-counter fact and a mobile-agent fact. However, since a new mobile-agent-counter
;;; was introduced in the previous execution of count-mobile-agent-instances (due to the "modify"),
;;; the rule is eligible to fire again. Once it fires, it repeats the process ad-infinitum and the
;;; CLIPS logic engine has effectively entered an infinite loop. This is known as a logic loop.
;;; The logic loop's effects may either manifest on the Instruments UI as an error stating
;;; "Rules engine appears to be stuck.", or more subtly as a re-execution of rules that should
;;; have only been executed once.

;;; You can open the Instruments Inspector and navigate to the "Modelers" tab to see the
;;; the working memory facts. Turning on the "Narrative" tracing within the Instruments Inspector
;;; prior to a trace can also show any log-narrative messages that a rule emits.

(defrule MODELER::count-mobile-agent-instances
    ?counter <- (mobile-agent-counter (count ?count))
    ?agent <- (mobile-agent (instance ?instance))
    =>
    (modify ?counter (count (+ 1 ?count)))
)
