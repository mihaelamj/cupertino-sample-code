;;;
;;;See LICENSE folder for this sample’s licensing information.

;;;Abstract:
;;;This rules file defines preexisting stop-kind-code and kind-code knowledge for the modeler.
;;;

;;; The following two deftemplates act as a Map, where a code
;;; and a descriptive string are associated. The first deftemplate
;;; maps Mobile Agent kind codes to their description. The second
;;; deftemplate does the same, but for stops instead of Mobile Agents.

(deftemplate MODELER::agent-kind-code-to-name
    (slot kind-code (type INTEGER))
    (slot kind (type STRING))
)

(deftemplate MODELER::stop-kind-code-to-name
    (slot kind-code (type INTEGER))
    (slot kind (type STRING))
)

;;; deffacts can be used to introduce initial knowledge into the
;;; rules engine. Since these associated codes and descriptions
;;; are known ahead of time, they can be kept in a separate file
;;; and introduced to the modelers by making sure this file name
;;; is specified as part of the <rule-path> tags when creating a
;;; modeler in your instrpkg.

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

