;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for recording the facts asserted by the modeler into your data tables.
;;;



(defrule RECORDER::record-execution
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema mobile-agent-activity))
    (mobile-agent-execution-interval (start ?start) (duration ?duration)
        (instance ?instance) (agent-kind-code ?agent-kind-code) (kind ?kind) (mode ?mode)
        (stop-kind ?stop-kind&~sentinel) (state ?state)
    )
    =>
    (create-new-row ?output)
    (set-column start ?start)
    (set-column duration ?duration)
    (set-column instance ?instance)
    (set-column agent-kind ?kind)
    (set-column state ?state)
    (set-column stop-kind ?stop-kind)
    (set-column agent-kind-code ?agent-kind-code)
    
    ;;; CLIPS provides runtime conditional execution through the use of an "if" expression.
    ;;; If the Mobile Agent state was "Failed", set the column's activity type to "High".
    ;;; In the MobileAgentsExecutionModelingPlotTemplate.instrpkg file, the activity-type column is used to derive the
    ;;; color for a drawn interval. The Custom Instruments infrastructure will interpret "Very High"
    ;;; as an event that had high significance, and will color it red. This also allows you to visually
    ;;; distinguish events from one another.
    (if (eq ?state "Failed") then
        (set-column activity-type "High")
    else
        (set-column activity-type "Green")
    )

    
    (set-column-narrative activity "\"%string%\" at stop %string%" ?mode ?stop-kind)
)

(defrule RECORDER::record-transition
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema mobile-agent-activity))
    ?transition <- (mobile-agent-transition-interval (start ?start) (duration ?duration)
        (instance ?instance) (kind ?kind) (agent-kind-code ?agent-kind-code) (stop-kind ?stop-kind)
        (mode ?mode) (state ?state))
    =>
    (create-new-row ?output)
    (set-column start ?start)
    (set-column duration ?duration)
    (set-column instance ?instance)
    (set-column agent-kind ?kind)
    (set-column state ?state)
    (set-column stop-kind ?stop-kind)
    (set-column agent-kind-code ?agent-kind-code)
    
    (if (eq ?state "Failed") then
        (set-column activity-type "High")
    else
        (set-column activity-type "Very Low")
    )
    
    (set-column-narrative activity "%string% \"%string%\" in mode \"%string%\"" ?state ?stop-kind ?mode)
    (retract ?transition)
    (log-narrative "Recording transition interval")
)


(defrule RECORDER::record-parking-interval
    
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema mobile-agent-activity))

    ?parking <- (mobile-agent-parking-interval (start ?start) (duration ?duration) (instance ?instance)
                                               (agent-kind ?kind) (mode ?mode) (agent-kind-code ?agent-kind-code))
    
    =>
    (create-new-row ?output)
    (set-column start ?start)
    (set-column duration ?duration)
    (set-column instance ?instance)
    (set-column agent-kind ?kind)
    (set-column agent-kind-code ?agent-kind-code)
    (set-column state parking)
    (set-column activity-type "Orange")
    (set-column-narrative activity "Parking with mode %string%"  ?mode)
    (retract ?parking)
)
