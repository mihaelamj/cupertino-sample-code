;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines templates for concepts that will be used within the rest of the modeler, such as mobile-agent, mobile-agent-execution-started, and mobile-agent-execution-interval
;;;


(deftemplate MODELER::mobile-agent
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot kind-code (type INTEGER))
    (slot kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type SYMBOL) (allowed-symbols unknown executing revisiting parked in-transit sentinel) (default unknown))
)

(deftemplate MODELER::mobile-agent-execution-started
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot stop-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot backtrace (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot thread (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

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
    (slot backtrace (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

