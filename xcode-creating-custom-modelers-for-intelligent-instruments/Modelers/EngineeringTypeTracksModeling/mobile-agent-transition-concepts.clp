;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines templates for concepts that will be used within the rest of the modeler, such as mobile-agent-transition-started, and mobile-agent-transition-interval
;;;

(deftemplate MODELER::mobile-agent-transition-started
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

(deftemplate MODELER::mobile-agent-transition-interval
    (slot start (type INTEGER))
    (slot duration (type INTEGER))
    (slot instance (type INTEGER))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot state (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot stop-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot agent-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    
)
