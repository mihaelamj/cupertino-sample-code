;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for transforming incoming signpost data into mobile agent activity intervals.
;;;


;;; This rule brings a new mobile agent deftemplate to life. In order to accomplish this,
;;; two items must be satisfied. The criteria for determining whether a rule fires
;;; is known as the Left Hand Side (LHS) of the rule.

;;; 1) An os-signpost event signaling the beginning of an execution period
;;;    must be detected with the specified name "Mobile Agent Exec". The time at which the
;;;    signpost was generated must not be 0. The identifier associated with this signpost
;;;    message will be captured in the ?instance variable. The content of the
;;;    signpost message must start with exactly "Agent of type " and must have a kind-code
;;;    immediately after that text.

;;; 2) There must not already exist a mobile-agent with the same
;;;    instance (unique identifier). Since this rule attempts
;;;    to spawn a Mobile Agent into existence - an earlier, identical
;;;    one must not exist.

;;; Once the LHS conditions have been satisfied, the Right Hand Side (RHS) denotes
;;; the actions that will occur. Notice that the LHS and RHS are separated by "=>".
;;; This is CLIPS syntax which informs the CLIPS engine what actions to take when
;;; a rule's LHS is satisfied. In this rule, a new mobile-agent fact is asserted.
;;; Its start, instance, and kind-code properties are set by those attributes which were
;;; discovered in the signpost.

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

;;; This rule detects the start of a Mobile Agent's execution period. To accomplish this,
;;; the "Mobile Agent Exec" signpost is needed, as well as an associated mobile agent.
;;; When capturing the signpost, the identifier field is captured as ?instance.
;;; When capturing the agent, the same ?instance variable is used. This means that
;;; only an agent whose identifier matches that of the signpost can be used to match
;;; this rule.

;;; The RHS is asserting a new mobile-agent-execution-started fact with properties that
;;; were discovered in the signpost. The RHS also modifies the existing mobile-agent
;;; fact to give it some extra information. Modifying a fact, done with the "modify"
;;; modeler function, is a shorthand for retracting the fact and asserting a new one
;;; with the union of its previous properties and any new ones that were set as part of
;;; the "modify" expression.
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
    ;;; Just like in other programming languages, CLIPS supports switch-case expressions.
    ;;; Here, the ?movement-type variable is the subject of the "switch", and each "case"
    ;;; determines which symbol the ?state variable will take on.
    
    ;;; This rule's LHS requires the agent's state to be either unknown or in-transit.
    ;;; The former will only occur when a new mobile-agent fact is created in the working memory
    ;;; since mobile-agent-concepts.clp defaults the state slot to unknown. The latter occurs
    ;;; when a mobile-agent has finished its execution at one stop and is now starting a new one.
    ;;; See MODELER::detect-mobile-agent-execution-end to understand how the agent's state
    ;;; is modified to in-transit once an execution completes.
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
    ;;; the "bind" modeler function can be used to assign a value to
    ;;; a variable that can't be bound directly from other facts.
    ;;; The duration of the execution interval isn't part of any signpost
    ;;; message, but you can derive it from subtracting the time the
    ;;; "Mobile Agent Moved" signpost was issued and the start time that
    ;;; was stored in the mobile-agent-execution-started fact.
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
;;; This rule matches on a "Mobile Agent Parked" signpost and an existing
;;; mobile agent that shares the signpost's ?instance. If the LHS is satisfied,
;;; the mobile agent has logically terminated. In CLIPS, termination of a concept
;;; that was represented by a fact is accomplished by using the "retract" modeler function.

;;; Retracting a fact will remove it from the modeler's working memory. Any rules that
;;; match on this instance of a mobile agent fact will no longer fire because the fact
;;; has been removed.
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
