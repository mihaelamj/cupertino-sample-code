;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for resolving an agent or stop kind-code into a descriptive string.
;;;

;;; If a mobile-agent-execution-started fact has been asserted, this rule
;;; attempts to match its stop-kind-code with one of the known
;;; stop-kind-code to stop-kind association facts. If the LHS is satisfied,
;;; the RHS will modify the mobile-agent-execution-started fact to include
;;; the descriptive ?kind.

;;; Note that one of the LHS conditions is that the mobile-agent-execution-started
;;; rule have a sentinel for its stop-kind slot. Since this slot will be sentinel
;;; upon the rule's first assertion, this rule will only capture mobile-agent-execution-started
;;; facts that do not yet have their stop-kind slots modified. Once the stop-kind-code resolution
;;; executes, the sentinel precondition will no longer hold true, and thus prevents this rule
;;; from firing again.

(defrule MODELER::lookup-known-stop-kind-for-execution
    (declare (salience 100))
    ?exec-started <- (mobile-agent-execution-started
        (instance ?instance) (stop-kind-code ?stop-kind-code)
    (stop-kind sentinel))
    
    (stop-kind-code-to-name (kind-code ?stop-kind-code) (kind ?kind))
    =>
    (modify ?exec-started (stop-kind ?kind))
    (log-narrative "Resolved stop kind code %uint64% to %string%" ?stop-kind-code ?kind)
)

;;; In the case that the stop kind is unknown, this rule will fire since
;;; it will activate in the absence of a known stop-kind-code to stop-kind association.
(defrule MODELER::lookup-unknown-stop-kind-for-execution
    (declare (salience 100))
    ?exec-started <- (mobile-agent-execution-started
        (instance ?instance) (stop-kind-code ?stop-kind-code)
    (stop-kind sentinel))
    
    (not (stop-kind-code-to-name (kind-code ?stop-kind-code) (kind ?kind)))
    =>
    (modify ?exec-started (stop-kind "Undocumented Stop"))
    (log-narrative "UNRESOLVED stop kind code %uint64%" ?stop-kind-code)
)


(defrule MODELER::lookup-known-agent-kind
    ?agent <- (mobile-agent (instance ?instance) (kind-code ?kind-code)
                            (kind sentinel))
    
    (agent-kind-code-to-name (kind-code ?kind-code) (kind ?kind))
    
    =>
    
    (modify ?agent (kind ?kind))
    (log-narrative "Resolved agent kind code %uint64% to %string%" ?kind-code ?kind)
)

;;; In the case that the stop kind is unknown, this rule will fire since
;;; it will activate in the absence of a known stop-kind-code to stop-kind association.
(defrule MODELER::lookup-unknown-agent-kind
    (declare (salience 100))
    ?agent <- (mobile-agent (instance ?instance) (kind-code ?kind-code)
    (kind sentinel))
    
    (not (agent-kind-code-to-name (kind-code ?kind-code) (kind ?kind)))
    =>
    (modify ?agent (kind "Undocumented Agent"))
    (log-narrative "UNRESOLVED agent kind code %uint64%" ?kind-code)
)
