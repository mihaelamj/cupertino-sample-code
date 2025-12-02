;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines templates for parking concepts, such as parking-started and a parking-interval
;;;

(deftemplate MODELER::mobile-agent-parking-started
    (slot start (type INTEGER))
    (slot instance (type INTEGER))
    (slot agent-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot agent-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

(deftemplate MODELER::mobile-agent-parking-interval
    (slot start (type INTEGER))
    (slot duration (type INTEGER))
    (slot instance (type INTEGER))
    (slot agent-kind (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot agent-kind-code (type INTEGER SYMBOL) (allowed-symbols sentinel) (default sentinel))
    (slot mode (type STRING SYMBOL) (allowed-symbols sentinel) (default sentinel))
)
