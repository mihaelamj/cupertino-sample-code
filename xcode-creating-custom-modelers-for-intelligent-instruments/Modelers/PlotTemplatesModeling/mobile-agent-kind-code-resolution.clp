;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for resolving an agent or stop kind-code into a descriptive string.
;;;


(defrule MODELER::lookup-known-stop-kind-for-execution
    
    ?exec-started <- (mobile-agent-execution-started (stop-kind-code ?stop-kind-code)
                                                     (stop-kind sentinel))
        
    
    (stop-kind-code-to-name (kind-code ?stop-kind-code) (kind ?kind))
    =>
    (modify ?exec-started (stop-kind ?kind))
    (log-narrative "Resolved stop kind code %uint64% to %string%" ?stop-kind-code ?kind)
)

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


(defrule MODELER::lookup-known-stop-kind-for-transition
    (declare (salience 100))
    ?transition-started <- (mobile-agent-transition-started
        (instance ?instance) (stop-kind-code ?stop-kind-code)
        (stop-kind sentinel))
    
    (stop-kind-code-to-name (kind-code ?stop-kind-code) (kind ?kind))
    =>
    (modify ?transition-started (stop-kind ?kind))
    (log-narrative "Resolved transition stop kind code %uint64% to %string%" ?stop-kind-code ?kind)
)

(defrule MODELER::lookup-unknown-stop-kind-for-transition
    (declare (salience 100))
    ?transition-started <- (mobile-agent-transition-started
        (instance ?instance) (stop-kind-code ?stop-kind-code)
        (stop-kind sentinel))
    
    (not (stop-kind-code-to-name (kind-code ?stop-kind-code) (kind ?kind)))
    =>
    (modify ?transition-started (stop-kind "Undocumented Stop"))
    (log-narrative "UNRESOLVED transition stop kind code %uint64%" ?stop-kind-code)
)



(defrule MODELER::lookup-known-agent-kind
    (declare (salience 100))
    ?agent <- (mobile-agent (instance ?instance) (kind-code ?kind-code)
                            (kind sentinel))
    
    (agent-kind-code-to-name (kind-code ?kind-code) (kind ?kind))
    =>
    (modify ?agent (kind ?kind))
    (log-narrative "Resolved agent kind code %uint64% to %string%" ?kind-code ?kind)
    
)

(defrule MODELER::lookup-unknown-agent-kind
    (declare (salience 100))
    ?agent <- (mobile-agent (instance ?instance) (kind-code ?kind-code)
                            (kind sentinel))
    
    (not (agent-kind-code-to-name (kind-code ?kind-code) (kind ?kind)))
    =>
    (modify ?agent (kind "Undocumented Agent"))
    (log-narrative "UNRESOLVED agent kind code %uint64%" ?kind-code)
)
