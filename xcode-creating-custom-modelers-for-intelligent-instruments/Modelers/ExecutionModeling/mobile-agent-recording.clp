;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines the CLIPS rules for recording the facts asserted by the modeler into your data tables.
;;;

;;; This recording rule checks for the presence of an appendable
;;; table with the schema mobile-agent-execution. The schema name is
;;; derived from the instrpkg file.

;;; The rule also checks for the existence of a mobile-agent-execution-interval
;;; fact. This fact will only be asserted once an agent has finished executing at
;;; a stop, as per the rules in mobile-agent-modeling.clp.

;;; Similar to a database table, inserting new information is done by creating rows.
;;; To create a row, you use the create-new-row modeler function. Continuing the
;;; database analogy, a row's columns contain the individual data slot of interest.
;;; By using the set-column function immediately after create-new-row, the newly
;;; created row's columns are set. In this rule, the columns are set based on the slots
;;; contained in the mobile-agent-execution-interval fact.

(defrule RECORDER::record-execution
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema mobile-agent-execution))
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
