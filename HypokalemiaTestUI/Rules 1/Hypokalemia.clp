; 
; Hypokalemia treatment rules
;

(deftemplate diagnosis
	(slot patient)
	(slot name))

(deftemplate decision
	(slot patient)
	(slot name)
	(slot node))

(deftemplate test-value
	(slot patient)
	(slot name)
	(slot value))

(deftemplate reason
	(slot patient)
	(slot level)
	(slot rule)
	(slot text))

(deftemplate treatment-scheme
	(slot patient)
	(slot type))
	
(deftemplate available-routes 
	(slot patient)
	(slot type))	; ENTERAL or CENTRAL-IV or PERIPHERAL-IV
	
(deftemplate treatment 
	(slot patient)
	(slot index) 	; Used to group the treatments which must be given together
	(slot type) 	; RECOMMENDED or ALTERNATE
	(slot med) 		; Name of the med or treatment
	(slot quantity) ; Numeric value
	(slot units) 	; Units of the quantity
	(slot route))	; ENTERAL or CENTRAL-IV or PERIPHERAL-IV

(deftemplate action
	(slot patient)
	(slot text))

(deftemplate reqired-decision-test-value
	(slot decision-node)
	(slot required-test)
)

(deftemplate reqired-treatment-test-value
	(slot treatment-type)
	(slot required-test)
)

;
; Hypokalemia decision tree rules
;
; Each rule implements a single decision.
; Decisions are ordered by the node slot. The top of the tree is node "0". Top branches lead to nodes "1", "2"...
; Lower branches lead to nodes "1.1", "1.2"... Each level needs to add to the node name.
;
; Leaf rules stop the decision tree by retracting the decision fact and asserting a treatment-scheme fact.
;

(defrule Start
	(diagnosis (patient ?p) (name HYPOKALEMIA))
=>
	(assert (decision (patient ?p) (name HYPOKALEMIA) (node "0")))
)

(defrule GFR-over-60
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "0"))
	(test-value (patient ?p) (name GFR) (value ?value &: (> ?value 60)))
=>
	(modify ?decisions (node "1"))
	(assert (reason (patient ?p) (level 0) (rule GFR-over-60) (text "GFR is over 60")))
)

(defrule GFR-over-60-stable
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1"))
	(test-value (patient ?p) (name GFR-trend) (value STABLE))
=>
	(modify ?decisions (node "1.1"))
	(assert (reason (patient ?p) (level 1) (rule GFR-over-60-stable) (text "GFR is stable")))
)

(defrule GFR-over-60-stable-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 1)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-stable-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-stable-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 1)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-stable-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-stable-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-stable-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-over-60-stable-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-stable-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-over-60-increasing
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1"))
	(test-value (patient ?p) (name GFR-trend) (value INCREASING))
=>
	(modify ?decisions (node "1.2"))
	(assert (reason (patient ?p) (level 1) (rule GFR-over-60-increasing) (text "GFR is increasing")))
)

(defrule GFR-over-60-increasing-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 1)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-increasing-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-increasing-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 1)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-increasing-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-increasing-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-increasing-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-over-60-increasing-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-increasing-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-over-60-decreasing
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1"))
	(test-value (patient ?p) (name GFR-trend) (value DECREASING))
=>
	(modify ?decisions (node "1.3"))
	(assert (reason (patient ?p) (level 1) (rule GFR-over-60-decreasing) (text "GFR is decreasing")))
)

(defrule GFR-over-60-decreasing-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-decreasing-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-decreasing-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-decreasing-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-decreasing-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-decreasing-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-over-60-decreasing-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-decreasing-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-over-60-unknown
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1"))
	(test-value (patient ?p) (name GFR-trend) (value UNKOWN))
=>
	(modify ?decisions (node "1.4"))
	(assert (reason (patient ?p) (level 1) (rule GFR-over-60-unknown) (text "GFR is unknown")))
)

(defrule GFR-over-60-unknown-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 1)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-unknown-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-unknown-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-unknown-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-over-60-unknown-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-unknown-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-over-60-unknown-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "1.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-over-60-unknown-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)



(defrule GFR-30-to-60
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "0"))
	(test-value (patient ?p) (name GFR) (value ?value &: (and (>= ?value 30) (<= ?value 60))))
=>
	(modify ?decisions (node "2"))
	(assert (reason (patient ?p) (level 0) (rule GFR-30-to-60) (text "GFR is between 30 and 60")))
)

(defrule GFR-30-to-60-stable
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2"))
	(test-value (patient ?p) (name GFR-trend) (value STABLE))
=>
	(modify ?decisions (node "2.1"))
	(assert (reason (patient ?p) (level 1) (rule GFR-30-to-60-stable) (text "GFR is stable")))
)

(defrule GFR-30-to-60-stable-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-stable-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-stable-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-stable-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-stable-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-stable-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-30-to-60-stable-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-stable-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-30-to-60-increasing
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2"))
	(test-value (patient ?p) (name GFR-trend) (value INCREASING))
=>
	(modify ?decisions (node "2.2"))
	(assert (reason (patient ?p) (level 1) (rule GFR-30-to-60-increasing) (text "GFR is increasing")))
)

(defrule GFR-30-to-60-increasing-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 1)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-increasing-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-increasing-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-increasing-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-increasing-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-increasing-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-30-to-60-increasing-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-increasing-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-30-to-60-decreasing
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2"))
	(test-value (patient ?p) (name GFR-trend) (value DECREASING))
=>
	(modify ?decisions (node "2.3"))
	(assert (reason (patient ?p) (level 1) (rule GFR-30-to-60-decreasing) (text "GFR is decreasing")))
)

(defrule GFR-30-to-60-decreasing-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-decreasing-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-decreasing-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-decreasing-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-decreasing-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-decreasing-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-30-to-60-decreasing-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-decreasing-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-30-to-60-unknown
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2"))
	(test-value (patient ?p) (name GFR-trend) (value UNKOWN))
=>
	(modify ?decisions (node "2.4"))
	(assert (reason (patient ?p) (level 1) (rule GFR-30-to-60-unknown) (text "GFR is unknown")))
)

(defrule GFR-30-to-60-unknown-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-unknown-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-unknown-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-unknown-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-30-to-60-unknown-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-unknown-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-30-to-60-unknown-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "2.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-30-to-60-unknown-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)



(defrule GFR-1-to-29
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "0"))
	(test-value (patient ?p) (name GFR) (value ?value &: (and (>= ?value 0) (<= ?value 30))))
=>
	(modify ?decisions (node "3"))
	(assert (reason (patient ?p) (level 0) (rule GFR-1-to-29) (text "GFR is less than 30")))
)

(defrule GFR-1-to-29-stable
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3"))
	(test-value (patient ?p) (name GFR-trend) (value STABLE))
=>
	(modify ?decisions (node "3.1"))
	(assert (reason (patient ?p) (level 1) (rule GFR-1-to-29-stable) (text "GFR is stable")))
)

(defrule GFR-1-to-29-stable-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-stable-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-stable-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-stable-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-stable-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-stable-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-1-to-29-stable-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.1"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-stable-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-1-to-29-increasing
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3"))
	(test-value (patient ?p) (name GFR-trend) (value INCREASING))
=>
	(modify ?decisions (node "3.2"))
	(assert (reason (patient ?p) (level 1) (rule GFR-1-to-29-increasing) (text "GFR is increasing")))
)

(defrule GFR-1-to-29-increasing-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-increasing-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-increasing-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 2)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-increasing-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-increasing-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-increasing-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-1-to-29-increasing-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.2"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-increasing-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-1-to-29-decreasing
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3"))
	(test-value (patient ?p) (name GFR-trend) (value DECREASING))
=>
	(modify ?decisions (node "3.3"))
	(assert (reason (patient ?p) (level 1) (rule GFR-1-to-29-decreasing) (text "GFR is decreasing")))
)

(defrule GFR-1-to-29-decreasing-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-decreasing-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-decreasing-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-decreasing-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-decreasing-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-decreasing-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-1-to-29-decreasing-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.3"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-decreasing-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-1-to-29-unknown
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3"))
	(test-value (patient ?p) (name GFR-trend) (value UNKOWN))
=>
	(modify ?decisions (node "3.4"))
	(assert (reason (patient ?p) (level 1) (rule GFR-1-to-29-unknown) (text "GFR is unknown")))
)

(defrule GFR-1-to-29-unknown-Urine-over-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (> ?urine-production 0.5)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-unknown-Urine-over-0.5) (text "Urine production is over 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-unknown-Urine-0.4-to-0.5
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.4) (<= ?urine-production 0.5))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-unknown-Urine-0.4-to-0.5) (text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr")))
)

(defrule GFR-1-to-29-unknown-Urine-0.2-to-0.3
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (and (>= ?urine-production 0.2) (< ?urine-production 0.4))))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-unknown-Urine-0.2-to-0.3) (text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr")))
)

(defrule GFR-1-to-29-unknown-Urine-under-2.0
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "3.4"))
	(test-value (patient ?p) (name Urine-production) (value ?urine-production &: (< ?urine-production 0.2)))
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 2) (rule GFR-1-to-29-unknown-Urine-over-0.5) (text "Urine production is less than 0.2 cc/kg/hr")))
)

(defrule GFR-dialysis-dependent
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "0"))
	(test-value (patient ?p) (name GFR) (value ?value &: (< ?value 0))) ; Use a value less than zero to indicate dialysis dependent
=>
	(retract ?decisions)
	(assert (treatment-scheme (patient ?p) (type 3)))
	(assert (reason (patient ?p) (level 0) (rule GFR-dialysis-dependent) (text "GFR is dialysis dependent")))
)

;
; Hypokalemia treatment scheme rules
;

(defrule Hypokalemia-Treatment-Scheme-1-a-enteral
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (>= ?value 3.8)))
	(available-routes (patient ?p) (type ENTERAL))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-a-enteral) 
		(text "K 3.8 or more and enteral route available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-a-central-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (> ?value 3.8)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-a-enteral) 
		(text "K 3.8 or more and enteral route not available but central iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-a-peripheral-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (> ?value 3.8)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-a-enteral) 
		(text "K 3.8 or more and enteral and central iv routes not available but peripheral iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-b-enteral
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(available-routes (patient ?p) (type ENTERAL))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (action (patient ?p) (text "retest potassium levels")))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-b-enteral) 
		(text "K 3.4 or more and less than 3.8 and enteral route available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-b-central-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route CENTRAL-IV)))
	(assert (action (patient ?p) (text "retest potassium levels")))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-b-enteral) 
		(text "K 3.4 or more and less than 3.8 and enteral route not available but central iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-b-peripheral-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route PERIPHERAL-IV)))
	(assert (action (patient ?p) (text "retest potassium levels")))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-b-enteral) 
		(text "K 3.4 or more and less than 3.8 and enteral and central iv routes not available but peripheral iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-c-enteral-only
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(available-routes (patient ?p) (type ENTERAL))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(not (available-routes (patient ?p) (type PERIPHERAL-IV)))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and only enteral route available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-c-enteral-and-central
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(available-routes (patient ?p) (type ENTERAL))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral and central iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-c-enteral-and-peripheral
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(available-routes (patient ?p) (type ENTERAL))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral and peripheral iv routes available but not central iv route")))
)

(defrule Hypokalemia-Treatment-Scheme-1-c-central-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral route not available but central iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-c-peripheral-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral and central iv routes not available but peripheral iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-d-enteral-central-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(available-routes (patient ?p) (type ENTERAL))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-d-enteral-central-iv) 
		(text "K less than 3.0 and enteral and central iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-d-enteral-peripheral-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(available-routes (patient ?p) (type ENTERAL))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-d-enteral-peripheral-iv) 
		(text "K less than 3.0 and enteral and peripheral iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-d-central-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-d-central-iv) 
		(text "K less than 3.0 and enteral rounte not available and central iv route available")))
)

(defrule Hypokalemia-Treatment-Scheme-1-d-peripheral-iv
	(treatment-scheme (patient ?p) (type 1))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-1-d-peripheral-iv) 
		(text "K less than 3.0 and only peripheral iv route available")))
)



(defrule Hypokalemia-Treatment-Scheme-2-a-none
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (>= ?value 3.8)))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med NONE) (quantity 0) (units NONE) (route NONE)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-a-none) 
		(text "K 3.8 or more")))
)

(defrule Hypokalemia-Treatment-Scheme-2-b-enteral
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(available-routes (patient ?p) (type ENTERAL))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-b-enteral) 
		(text "K 3.4 or more and less than 3.8 and enteral route available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-b-central-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-b-enteral) 
		(text "K 3.4 or more and less than 3.8 and enteral route not available but central iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-b-peripheral-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-b-enteral) 
		(text "K 3.4 or more and less than 3.8 and enteral and central iv routes not available but peripheral iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-c-enteral
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(available-routes (patient ?p) (type ENTERAL))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral route available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-c-central-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route CENTRAL-IV)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral route not available but central iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-c-peripheral-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route PERIPHERAL-IV)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (treatment (patient ?p) (index 2) (type ALTERNATE) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-c-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral and central iv routes not available but peripheral iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-d-enteral-central-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(available-routes (patient ?p) (type ENTERAL))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-d-enteral-central-iv) 
		(text "K less than 3.0 and enteral and central iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-d-enteral-peripheral-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(available-routes (patient ?p) (type ENTERAL))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-d-enteral-peripheral-iv) 
		(text "K less than 3.0 and enteral and peripheral iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-d-central-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-d-central-iv) 
		(text "K less than 3.0 and enteral rounte not available and central iv route available")))
)

(defrule Hypokalemia-Treatment-Scheme-2-d-peripheral-iv
	(treatment-scheme (patient ?p) (type 2))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 60) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-2-d-peripheral-iv) 
		(text "K less than 3.0 and only peripheral iv route available")))
)


(defrule Hypokalemia-Treatment-Scheme-3-a-none
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (>= ?value 3.4)))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med NONE) (quantity 0) (units NONE) (route NONE)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-a-none) 
		(text "K 3.4 or more")))
)

(defrule Hypokalemia-Treatment-Scheme-3-b-enteral
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(available-routes (patient ?p) (type ENTERAL))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-b-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral route available")))
)

(defrule Hypokalemia-Treatment-Scheme-3-b-central-iv
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-b-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral route not available but central iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-3-b-peripheral-iv
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.0) (< ?value 3.4))))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-b-enteral) 
		(text "K 3.0 or more and less than 3.4 and enteral and central iv routes not available but peripheral iv available")))
)

(defrule Hypokalemia-Treatment-Scheme-3-c-enteral-central-iv
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(available-routes (patient ?p) (type ENTERAL))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-c-enteral-central-iv) 
		(text "K less than 3.0 and enteral and central iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-3-c-enteral-peripheral-iv
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(available-routes (patient ?p) (type ENTERAL))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route ENTERAL)))
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 20) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-c-enteral-peripheral-iv) 
		(text "K less than 3.0 and enteral and peripheral iv routes available")))
)

(defrule Hypokalemia-Treatment-Scheme-3-c-central-iv
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(available-routes (patient ?p) (type CENTRAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route CENTRAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-c-central-iv) 
		(text "K less than 3.0 and enteral rounte not available and central iv route available")))
)

(defrule Hypokalemia-Treatment-Scheme-3-c-peripheral-iv
	(treatment-scheme (patient ?p) (type 3))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.0)))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(available-routes (patient ?p) (type PERIPHERAL-IV))
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (quantity 40) (units meq) (route PERIPHERAL-IV)))
	(assert (reason (patient ?p) (level 10) (rule Hypokalemia-Treatment-Scheme-3-c-peripheral-iv) 
		(text "K less than 3.0 and only peripheral iv route available")))
)

(defrule No-Routes
	(declare (salience -10)) ; Allow more specific rules to provide a treatment if they can.
	(treatment-scheme (patient ?p))
	(not (available-routes (patient ?p) (type ENTERAL)))
	(not (available-routes (patient ?p) (type CENTRAL-IV)))
	(not (available-routes (patient ?p) (type PERIPHERAL-IV)))
	(not (treatment (patient ?p))) ; There are treatments which don't require a route
=>
	(assert (action (patient ?p) (text "check for usable route")))
	(assert (reason (patient ?p) (level 10) (rule No-Routes) 
		(text "without an available route KCL can not be provided")))
)

;
; Handle missing values required to make decisions and choose treatment schemes.
;
(deffacts Required-Test-Values
	(reqired-decision-test-value (decision-node "0") (required-test "GFR"))
	(reqired-decision-test-value (decision-node "1") (required-test "GFR-trend"))
	(reqired-decision-test-value (decision-node "1.1") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "1.2") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "1.3") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "1.4") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "2") (required-test "GFR-trend"))
	(reqired-decision-test-value (decision-node "2.1") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "2.2") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "2.3") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "2.4") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "3") (required-test "GFR-trend"))
	(reqired-decision-test-value (decision-node "3.1") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "3.2") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "3.3") (required-test "Urine-production"))
	(reqired-decision-test-value (decision-node "3.4") (required-test "Urine-production"))
	(reqired-treatment-test-value (treatment-type 1) (required-test "Potassium"))
	(reqired-treatment-test-value (treatment-type 2) (required-test "Potassium"))
	(reqired-treatment-test-value (treatment-type 3) (required-test "Potassium"))
)

(defrule Missing-Decision-Value
	(declare (salience -10)) ; Allow more specific rules to provide a decision if they can.
	(diagnosis (patient ?p) (name HYPOKALEMIA))
	(decision (patient ?p) (node ?decision-node))
	(reqired-decision-test-value (decision-node ?decision-node) (required-test ?required-test))
	(not (treatment (patient ?p)))
	(not (action (patient ?p)))
=>
	(assert (action (patient ?p) (text (str-cat "please provide a value for " ?required-test))))
	(assert (reason (patient ?p) (level 10) (rule No-Routes) 
		(text (str-cat "the next decision requires a value for " ?required-test))))
)

(defrule Missing-Treatment-Value
	(declare (salience -10)) ; Allow more specific rules to determine the treatment if they can.
	(diagnosis (patient ?p) (name HYPOKALEMIA))
	(treatment-scheme (patient ?p) (type ?treatment-type))
	(reqired-treatment-test-value (treatment-type ?treatment-type) (required-test ?required-test))
	(not (treatment (patient ?p)))
	(not (action (patient ?p)))
=>
	(assert (action (patient ?p) (text (str-cat "please provide a value for " ?required-test))))
	(assert (reason (patient ?p) (level 10) (rule No-Routes) 
		(text (str-cat "the choice of treatment requires a value for " ?required-test))))
)

