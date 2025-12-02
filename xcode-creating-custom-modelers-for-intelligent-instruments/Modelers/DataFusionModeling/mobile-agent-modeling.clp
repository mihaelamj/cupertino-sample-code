;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for transforming incoming signpost data into mobile agent activity intervals.
;;;

(defrule MODELER::detect-new-mobile-agent
    
    (or (os-signpost
        (time ?t&~0)
        (name "Mobile Agent Exec")
        (event-type "Event")
        (identifier ?instance)
        (message$ "Agent of type " ?kind-code $?)
    )
    (os-signpost
        (time ?t&~0)
        (name "Mobile Agent Moved")
        (event-type "Event")
        (identifier ?instance)
        (message$ "Agent of type " ?kind-code $?)
    )
    )
    
    
    (not (mobile-agent (instance ?instance)))
    =>
    (assert (mobile-agent (start ?t) (instance ?instance) (kind-code ?kind-code)))
    (log-narrative "mobile-agent asserted at %start-time% with kind-code %uint64% and identifier %os-signpost-identifier%" ?t ?kind-code ?instance)
    
)

;;; Since transition states are being fused with backtraces, the transition facts need to also record
;;; which thread they were executed on. The os-signpost schema exposes a thread slot to inform its
;;; users of this. The ?thread variable which is bound to the thread on which the signpost was emitted
;;; will be given to the mobile-agent-transition-started fact.
(defrule MODELER::detect-mobile-agent-transition-begin-without-prior-exec
    (os-signpost
        (time ?t&~0)
        (name "Mobile Agent Moved")
        (event-type "Event")
        (identifier ?instance)
        (thread ?thread)
        (message$ "Agent of type " ?kind-code " received by " ?stop-kind-code " for mode " ?mode " movement type " ?movement-type)
    )
    
    ?agent <- (mobile-agent (instance ?instance) (state unknown|in-transit) (kind-code ?kind-code))
    (not (mobile-agent-execution-started (instance ?instance)))
    (not (mobile-agent-transition-started (start ?t) (stop-kind-code ?stop-kind-code) (mode ?mode)))
    =>
    
    (bind ?state (switch ?movement-type
        (case 1 then "Moving to")
        (case 2 then "Revisiting")
        (case 3 then "Parking at")
        (default "Unknown movement to")
    ))
    
    (modify ?agent (state in-transit) (mode ?mode))
    (assert (mobile-agent-transition-started (start ?t) (instance ?instance) (stop-kind-code ?stop-kind-code)
            (mode ?mode) (thread ?thread) (state ?state)))
    (log-narrative "Transition started without prior exec for %os-signpost-identifier% " ?instance)
)


(defrule MODELER::detect-mobile-agent-execution-begin-without-prior-transition
    (os-signpost
        (time ?t)
        (name "Mobile Agent Exec")
        (event-type "Event")
        (identifier ?instance)
        (thread ?thread)
        (message$ "Agent of type " ?kind-code " executing mode " ?mode ".  Movement type is " ?movement-type ". At stop " ?stop-kind-code)
    )
    ?agent <- (mobile-agent (instance ?instance) (state unknown|in-transit) (kind-code ?kind-code) (kind ?kind&~sentinel))
    (not (mobile-agent-transition-started (instance ?instance)))
    
    =>
    (bind ?state (switch ?movement-type
        (case 1 then executing)
        (case 2 then revisiting)
        (case 3 then parked)
    (default executing)))
    (assert (mobile-agent-execution-started (start ?t) (instance ?instance)
            (stop-kind-code ?stop-kind-code) (thread ?thread)))
    (modify ?agent (mode ?mode) (state ?state))
    (log-narrative "Beginning execution inteval without prior transition for %os-signpost-identifier%" ?instance )
)

;;; When ending a mobile-agent transition, this rule now transfers the thread information that was captured
;;; in the mobile-agent-transition-started fact to a new mobile-agent-transition-interval fact.
(defrule MODELER::detect-mobile-agent-transition-end
    (declare (salience 100))
    (os-signpost
        (time ?end)
        (name "Mobile Agent Exec")
        (event-type "Event")
        (identifier ?instance)
        (message$ "Agent of type " ?kind-code " executing mode " ?mode ".  Movement type is " ?movement-type ". At stop " ?stop-kind-code)
    )
    ?agent <- (mobile-agent (instance ?instance) (kind-code ?kind-code) (kind ?kind&~sentinel) )
    ?transition-begin <- (mobile-agent-transition-started
        (start ?start) (instance ?instance) (stop-kind ?stop-kind&~sentinel)
        (stop-kind-code ?stop-kind-code) (state ?state) (thread ?thread) (backtrace ?backtrace))
    =>
    
    (bind ?duration (- ?end ?start))
    (assert (mobile-agent-transition-interval
                (start ?start) (duration ?duration) (instance ?instance)
                (mode ?mode) (kind ?kind) (stop-kind ?stop-kind) (state ?state)
                (thread ?thread) (backtrace ?backtrace) (agent-kind-code ?kind-code)))
    (retract ?transition-begin)
    (log-narrative "Ending transition for %os-signpost-identifier% " ?instance)
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
        (stop-kind ?stop-kind&~sentinel) (start ?start) (backtrace ?backtrace) )
    (not (mobile-agent-transition-started (start ?start) (instance ?instance) ))
    
    =>
    (bind ?duration (- ?end ?start))
    
    (assert (mobile-agent-execution-interval
        (start ?start) (duration ?duration)
        (kind ?kind) (state ?state) (stop-kind ?stop-kind)
        (agent-kind-code ?kind-code) (mode ?mode) (backtrace ?backtrace))
    )
    
    (retract ?exec-started)
    (modify ?agent (state in-transit))
    (log-narrative "Detected end of execution at %start-time% for agent %os-signpost-identifier%" ?end ?instance)
)

;;; This rule checks for the existence of a transition-started fact and a time-profile fact.
;;; The time-profile fact must represent the same thread that the agent is transitioning on.
;;; This is accomplished by capturing the `thread` slot in the transition fact and re-using it
;;; when capturing the time-profile fact.

;;; If these two facts are both present in working memory and the necessary preconditions are satisfied,
;;; the rule is eligible to fire. Upon firing, the transition fact is modified to contain the backtrace
;;; that was captured in the time-profile fact.

;;; If the mobile-agent-transition-started fact is used in a different rule, it will now contain
;;; the appropriate backtrace. This is an example of fusing together data from two tables.

(defrule MODELER::fuse-mobile-agent-transition-with-time-profile
    ?transition <- (mobile-agent-transition-started (thread ?thread) (backtrace sentinel))
    
    (time-profile (thread ?thread) (stack ?stack))
    
    =>
    
    (modify ?transition (backtrace ?stack))
    (log-narrative "Got a backtrace for a transition")
)

(defrule MODELER::fuse-mobile-agent-execution-with-time-profile
    ?execution <- (mobile-agent-execution-started (thread ?thread) (backtrace sentinel))
    
    (time-profile (thread ?thread) (stack ?stack))
    
    =>
    
    (modify ?execution (backtrace ?stack))
    (log-narrative "Got a backtrace for an execution")
    
)


(defrule MODELER::agent-parked
    (os-signpost (time ?end) (name "Mobile Agent Parked")
        (event-type "Event")
        (identifier ?instance)
        (thread ?thread)
        (message$ "Parked in mode " ?mode)
        
    )
    ?a <- (mobile-agent (instance ?instance) (kind ?kind&~sentinel) (kind-code ?kind-code))
    ?transition-begin <- (mobile-agent-transition-started (start ?start) (instance ?instance) (stop-kind ?stop-kind&~sentinel) (state ?state) (backtrace ?backtrace))
    
    =>
    (bind ?duration (- ?end ?start))
    (assert (mobile-agent-transition-interval
                (start ?start) (duration ?duration) (instance ?instance)
                (mode ?mode) (kind ?kind) (stop-kind ?stop-kind)
                (state ?state) (thread ?thread) (backtrace ?backtrace)
                (agent-kind-code ?kind-code)))
    (retract ?a) 
    (retract ?transition-begin)
    (log-narrative "Parked agent %os-signpost-identifier%" ?instance)
)
