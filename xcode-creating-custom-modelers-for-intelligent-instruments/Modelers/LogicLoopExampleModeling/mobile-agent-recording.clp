;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for recording the facts asserted by the modeler into your data tables.
;;;


(defrule RECORDER::record-execution
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema mobile-agent-logic-loop))
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
    (set-column-narrative activity "\"%string%\" at stop %string%" ?mode ?stop-kind)
)
