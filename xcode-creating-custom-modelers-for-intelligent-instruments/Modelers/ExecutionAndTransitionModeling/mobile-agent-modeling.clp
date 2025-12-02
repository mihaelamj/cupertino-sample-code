;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for transforming incoming signpost data into mobile agent activity intervals.
;;;

;;; Since this instrument tracks an agent's execution and transition
;;; activity, there now exists an additional way to detect the presence
;;; of a new Mobile Agent. a Mobile Agent can now also be detected by
;;; matching against the "Mobile Agent Moved" signpost. To accomplish this,
;;; this rule utilizes the "or" CLIPS C.E. If either of the conditions contained
;;; in the "or" expression are satisfied, the "or" function succeeds.

;;; The "or" expression duplicates the rule to accomplish its goal.
;;; For example, the followng detect-new-mobile-agent rule will be split as if by
;;; creating two rules: detect-new-mobile-agent-1 and detect-new-mobile-agent-2.
;;; "detect-new-mobile-agent-1" rule will fire if the "Mobile Agent Exec" signpost
;;; is matched, in addition to the other LHS conditions. "detect-new-mobile-agent-2"
;;; will fire if the "Mobile Agent Moved" signpost is matched, in addition to the other
;;; LHS conditions. Note that this implies that a CLIPS "or" CE can be activated twice,
;;; unlike the use of "or" in other programming environments.

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

;;; The "Mobile Agent Moved" signpost serves two purposes.
;;; 1) Informing the modeler about the beginning of a transition interval.
;;; 2) Informing the modeler about the end of an execution interval.

;;; Because of these differences, multiple rules are needed to distinguish
;;; between the purpose of the signpost. The following rule establishes the
;;; beginning of a transition interval, but does not end any existing execution
;;; intervals. To accomplish this, the LHS first matches the "Mobile Agent Moved"
;;; signpost, then makes sure a mobile-agent fact exists with the same ?instance variable,
;;; and finally verifies that a mobile-agent-execution-started fact does NOT exist.

;;; If those conditions are satisfied, a mobile-agent-transition-started can be asserted.
;;; You may wonder when such conditions woud ever be satisifed. Doesn't a Mobile Agent
;;; always initially emit a "Mobile Agent Exec" signpost? Analyzing the MobileAgent implementation
;;; shows that a Mobile Agent will first deliver a "Mobile Agent Moved" signpost prior to beginning
;;; any execution. It is desirable to capture this knowledge as it may help debugging efforts when
;;; a Mobile Agent takes longer than expected to begin its execution.

;;; Further, consider the case when your Custom Instrument starts after a Mobile Agent emits the
;;; "Mobile Agent Exec" signpost. It is still desirable to track Mobile Agents that existed prior
;;; to the start of the  Instrument trace. This rule adds a layer of resilience by covering this case.
(defrule MODELER::detect-mobile-agent-transition-begin-without-prior-exec
    (os-signpost
        (time ?t&~0)
        (name "Mobile Agent Moved")
        (event-type "Event")
        (identifier ?instance)
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
    (assert (mobile-agent-transition-started (start ?t) (instance ?instance) (stop-kind-code ?stop-kind-code) (mode ?mode)
                                          (state ?state)))
    (log-narrative "Transition started without prior exec for %os-signpost-identifier% " ?instance)
)


(defrule MODELER::detect-mobile-agent-execution-begin-without-prior-transition
    (os-signpost
        (time ?t)
        (name "Mobile Agent Exec")
        (event-type "Event")
        (identifier ?instance)
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
            (stop-kind-code ?stop-kind-code)))
    (modify ?agent (mode ?mode) (state ?state))
    (log-narrative "Beginning execution inteval without prior transition for %os-signpost-identifier%" ?instance )
)

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
                            (stop-kind-code ?stop-kind-code) (state ?state))
    =>
    
    (bind ?duration (- ?end ?start))
    (assert (mobile-agent-transition-interval (start ?start) (duration ?duration) (instance ?instance)
                                            (mode ?mode) (kind ?kind) (stop-kind ?stop-kind) (state ?state)
                                            (agent-kind-code ?kind-code)))
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
                        (stop-kind ?stop-kind&~sentinel) (start ?start) )
    (not (mobile-agent-transition-started (start ?start) (instance ?instance) ))
    
    =>
    (bind ?duration (- ?end ?start))
    
    (assert (mobile-agent-execution-interval
        (start ?start) (duration ?duration)
        (kind ?kind) (state ?state) (stop-kind ?stop-kind)
        (agent-kind-code ?kind-code) (mode ?mode))
    )
    
    (retract ?exec-started)
    (modify ?agent (state in-transit))
    (log-narrative "Detected end of execution at %start-time% for agent %os-signpost-identifier%" ?end ?instance)
)

;;; When an agent parks, its journey is over.
;;; Since this modeler is aware of Mobile Agent transitions, the "Mobile Agent Parked"
;;; signpost can now be used to not only terminate a mobile-agent from working memory,
;;; but also to end a transition. Although other transitions are terminated by the
;;; "Mobile Agent Exec" signpost, a Mobile Agent will cease to emit any more signposts
;;; after "Mobile Agent Parked". 
(defrule MODELER::agent-parked
    (os-signpost (time ?end) (name "Mobile Agent Parked")
        (event-type "Event")
        (identifier ?instance)
        (message$ "Parked in mode " ?mode)
    )
    ?a <- (mobile-agent (instance ?instance) (kind ?kind&~sentinel) (kind-code ?kind-code))
    ?transition-begin <- (mobile-agent-transition-started (start ?start) (instance ?instance) (stop-kind ?stop-kind&~sentinel) (state ?state))
    
    =>
    (bind ?duration (- ?end ?start))
    (assert (mobile-agent-transition-interval (start ?start) (duration ?duration) (instance ?instance)
        (mode ?mode) (kind ?kind) (stop-kind ?stop-kind) (state ?state) (agent-kind-code ?kind-code)))
    
    (assert (mobile-agent-parking-started (start ?end) (instance ?instance) (agent-kind ?kind)
                                          (mode ?mode) (agent-kind-code ?kind-code)))
    (retract ?a) ;; close out the reference to the agent
    (retract ?transition-begin)
    (log-narrative "Parked agent %os-signpost-identifier%" ?instance)
)

(defrule MODELER::agent-parking-ended
    (os-signpost
        (time ?t&~0)
        (name "Mobile Agent Moved")
        (event-type "Event")
        (identifier ?instance)
    )
    
    ?parking-started <- (mobile-agent-parking-started (start ?start) (instance ?instance)
                                                      (agent-kind ?kind) (mode ?mode)
                                                      (agent-kind-code ?kind-code))
    
    =>
    (bind ?duration (- ?t ?start))
    (assert (mobile-agent-parking-interval (start ?start) (duration ?duration) (instance ?instance)
                                           (agent-kind ?kind) (mode ?mode) (agent-kind-code ?kind-code)))
    (retract ?parking-started)
    
)
