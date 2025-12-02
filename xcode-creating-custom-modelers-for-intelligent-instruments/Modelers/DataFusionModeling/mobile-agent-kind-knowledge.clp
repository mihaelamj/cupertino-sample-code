;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines preexisting stop-kind-code and kind-code knowledge for the modeler.
;;;

(deftemplate MODELER::agent-kind-code-to-name
    (slot kind-code (type INTEGER))
    (slot kind (type STRING))
)

(deftemplate MODELER::stop-kind-code-to-name
    (slot kind-code (type INTEGER))
    (slot kind (type STRING))
)

(deffacts MODELER::kind-code-mapping
    (agent-kind-code-to-name (kind-code 1) (kind "Sorting Agent"))
    (agent-kind-code-to-name (kind-code 2) (kind "Display Agent"))
    (agent-kind-code-to-name (kind-code 3) (kind "Editing Agent"))
)

(deffacts MODELER::stop-kind-code-mapping
    (stop-kind-code-to-name (kind-code 1) (kind "Sort Stop"))
    (stop-kind-code-to-name (kind-code 2) (kind "Display Stop"))
    (stop-kind-code-to-name (kind-code 3) (kind "Edit Stop"))
    (stop-kind-code-to-name (kind-code 4) (kind "Goat List Stop"))
)
