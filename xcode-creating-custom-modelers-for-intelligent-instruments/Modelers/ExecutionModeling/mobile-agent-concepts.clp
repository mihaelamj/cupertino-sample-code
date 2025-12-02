;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines templates for concepts that will be used within the rest of the modeler, such as mobile-agent, mobile-agent-execution-started, and mobile-agent-execution-interval
;;;

;;; This deftemplate is a representation of a Mobile Agent that the modeler
;;; will act upon, augment, and transform as different rules execute
;;; throughout the life-cycle of a Mobile Agent.

(deftemplate MODELER::mobile-agent
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot kind-code (type INTEGER))
    (slot kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type SYMBOL)
                (allowed-symbols unknown executing revisiting parked in-transit sentinel)
                (default unknown))
)

;;; This deftemplate allows the modeler to keep track of the beginning of
;;; a Mobile Agent's execution in a stop.
(deftemplate MODELER::mobile-agent-execution-started
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot stop-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

;;; This deftemplate serves as a representation for a Mobile Agent's execution
;;; interval at a stop. Note that it differs from the previous fact.
;;; It adds a "duration" slot so that any future rules can also know about how
;;; long an agent executed for at a given stop.
(deftemplate MODELER::mobile-agent-execution-interval
    (slot start (type INTEGER))
    (slot duration (type INTEGER))
    (slot instance (type INTEGER))
    (slot stop-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot agent-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type SYMBOL) (allowed-symbols unknown executing revisiting parked) (default unknown))
    (slot kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

