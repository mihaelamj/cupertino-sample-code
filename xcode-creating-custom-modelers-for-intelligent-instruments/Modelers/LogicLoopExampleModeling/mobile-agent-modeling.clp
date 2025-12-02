;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for transforming incoming signpost data into mobile agent activity intervals.
;;;


(defrule MODELER::detect-new-mobile-agent
    
    (os-signpost
        (time ?t&~0)
        (name "Mobile Agent Exec")
        (event-type "Event")
        (identifier ?instance)
        (message$ "Agent of type " ?kind-code $?)
    )
    
    (not (mobile-agent (instance ?instance)))
    =>
    (assert (mobile-agent (start ?t) (instance ?instance) (kind-code ?kind-code)))
    (log-narrative "mobile-agent asserted at %start-time% with kind-code %uint64% and identifier %os-signpost-identifier%" ?t ?kind-code ?instance)
)

(defrule MODELER::detect-mobile-agent-execution-begin
    (os-signpost
        (time ?t)
        (name "Mobile Agent Exec")
        (event-type "Event")
        (identifier ?instance)
        (message$ "Agent of type " ?kind-code " executing mode " ?mode ".  Movement type is " ?movement-type ". At stop " ?stop-kind-code)
    )
    ?agent <- (mobile-agent (instance ?instance) (state unknown|in-transit) (kind-code ?kind-code))
    
    =>
    (bind ?state (switch ?movement-type
        (case 1 then executing)
        (case 2 then revisiting)
        (case 3 then parked)
    (default executing)))
    (assert (mobile-agent-execution-started (start ?t) (instance ?instance)
    (stop-kind-code ?stop-kind-code)))
    (modify ?agent (mode ?mode) (state ?state))
    (log-narrative "Beginning execution inteval for %os-signpost-identifier%" ?instance )
)

(defrule MODELER::detect-mobile-agent-execution-end
    (os-signpost
        (time ?end)
        (name "Mobile Agent Moved")
        (event-type "Event")
        (identifier ?instance)
        (thread ?thread)
        (message$ "Agent of type " $?)
    )
    
    ?agent <- (mobile-agent (instance ?instance) (mode ?mode)
        (kind ?kind) (kind-code ?kind-code) (state ?state) )
    ?exec-started <- (mobile-agent-execution-started
        (instance ?instance)
        (stop-kind ?stop-kind&~sentinel) (start ?start) )
    
    =>
    (bind ?duration (- ?end ?start))
    
    (assert (mobile-agent-execution-interval
        (start ?start) (duration ?duration)
        (kind ?kind) (state ?state) (stop-kind ?stop-kind)
        (agent-kind-code ?kind-code) (instance ?instance) (mode ?mode))
    )
    
    (retract ?exec-started)
    (modify ?agent (state in-transit))
    (log-narrative "Detected end of execution at %start-time% for agent %os-signpost-identifier%" ?end ?instance)
)

(defrule MODELER::agent-parked
    (os-signpost (time ?end) (name "Mobile Agent Parked")
        (event-type "Event")
        (identifier ?instance)
    )
    ?a <- (mobile-agent (instance ?instance))
    =>
    (retract ?a) ;; close out the reference to the agent
    (log-narrative "Parked agent %os-signpost-identifier%" ?instance)
)
