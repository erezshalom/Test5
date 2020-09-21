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

; Encode rules into data by providing value ranges for matching in more general rules
; Note: For Hypokalemia the ranges could be collopased into single values (e.g. 4 GFR range values)
;
(deftemplate value-range-decision
	(slot diagnosis)
	(slot value-name)
	(slot low-value)
	(slot low-value-type)	; NONE, INCLUSIVE or EXCLUSIVE
	(slot high-value)
	(slot high-value-type)  ; NONE, INCLUSIVE or EXCLUSIVE
	(slot text)
	(slot source)
	(slot level)
	(slot rule)
	(slot node)
	(slot node-type)
	(slot new-node)
	(slot new-node-type)
)

(deftemplate flag ; used to control state
	(slot name)
	(slot value)
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

(deffunction value-in-range 
	(?value ?low-value-type ?low-value ?high-value-type ?high-value)
	(or (and (eq ?low-value-type CATEGORY) (eq ?value ?low-value))
		(and (or (eq ?low-value-type NONE)
				(and (eq ?low-value-type EXCLUSIVE) (> ?value ?low-value))
				(and (eq ?low-value-type INCLUSIVE) (>= ?value ?low-value))
			)
			(or (eq ?high-value-type NONE)
				(and (eq ?high-value-type EXCLUSIVE) (< ?value ?high-value))
				(and (eq ?high-value-type INCLUSIVE) (<= ?value ?high-value))
			)
		)
	)
)

(defrule make-decision
	(value-range-decision (diagnosis ?diagnosis) (value-name ?value-name) 
		(low-value ?low-value) (low-value-type ?low-value-type) 
		(high-value ?high-value) (high-value-type ?high-value-type)
		(text ?text) (source ?source) (level ?level) (rule ?rule)
		(node-type decision) (node ?node) (new-node-type ?new-node-type) (new-node ?new-node))
	?decision <- (decision (name ?diagnosis) (patient ?p) (node ?node))
	(test-value (name ?value-name) (patient ?p) (value ?value))
	(test (value-in-range ?value ?low-value-type ?low-value ?high-value-type ?high-value))
=>
	(if (eq ?new-node-type DECISION)
		then 
			(modify ?decision (node ?new-node))
		else
			(retract ?decision)
			(assert (treatment-scheme (patient ?p) (type ?new-node)))
	)
	(assert (reason (patient ?p) (level ?level) (rule ?rule) (text ?text)))
)

(deffacts value-range-decisions
	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR) 
		(low-value 60) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "GFR is over 60") (source "Doctor") (level 0) (rule GFR-over-60)
		(node-type decision) (node "0") (new-node-type DECISION) (new-node "1"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value STABLE) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is stable") (source "Doctor") (level 1) (rule GFR-over-60-stable)
		(node-type decision) (node "1") (new-node-type DECISION) (new-node "1.1"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-stable-Urine-over-0.5)
		(node-type decision) (node "1.1") (new-node-type treatment-scheme) (new-node 1))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-stable-Urine-0.4-to-0.5)
		(node-type decision) (node "1.1") (new-node-type treatment-scheme) (new-node 1))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-stable-Urine-0.2-to-0.3)
		(node-type decision) (node "1.1") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-stable-Urine-under-2.0)
		(node-type decision) (node "1.1") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value INCREASING) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is increasing") (source "Doctor") (level 1) (rule GFR-over-60-increasing)
		(node-type decision) (node "1") (new-node-type DECISION) (new-node "1.2"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-increasing-Urine-over-0.5)
		(node-type decision) (node "1.2") (new-node-type treatment-scheme) (new-node 1))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-increasing-Urine-0.4-to-0.5)
		(node-type decision) (node "1.2") (new-node-type treatment-scheme) (new-node 1))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-increasing-Urine-0.2-to-0.3)
		(node-type decision) (node "1.2") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-increasing-Urine-under-2.0)
		(node-type decision) (node "1.2") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value DECREASING) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is decreasing") (source "Doctor") (level 1) (rule GFR-over-60-decreasing)
		(node-type decision) (node "1") (new-node-type DECISION) (new-node "1.3"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-decreasing-Urine-over-0.5)
		(node-type decision) (node "1.3") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-decreasing-Urine-0.4-to-0.5)
		(node-type decision) (node "1.3") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-decreasing-Urine-0.2-to-0.3)
		(node-type decision) (node "1.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-decreasing-Urine-under-2.0)
		(node-type decision) (node "1.3") (new-node-type treatment-scheme) (new-node 3))



	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value UNKNOWN) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR trend is unknown") (source "Doctor") (level 1) (rule GFR-over-60-unknown)
		(node-type decision) (node "1") (new-node-type DECISION) (new-node "1.4"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-unknown-Urine-over-0.5)
		(node-type decision) (node "1.4") (new-node-type treatment-scheme) (new-node 1))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-unknown-Urine-0.4-to-0.5)
		(node-type decision) (node "1.4") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-unknown-Urine-0.2-to-0.3)
		(node-type decision) (node "1.4") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-over-60-unknown-Urine-under-2.0)
		(node-type decision) (node "1.4") (new-node-type treatment-scheme) (new-node 3))





	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR) 
		(low-value 30) (low-value-type INCLUSIVE) (high-value 60) (high-value-type INCLUSIVE)
		(text "GFR is between 30 and 60") (source "Doctor") (level 0) (rule GFR-30-to-60)
		(node-type decision) (node "0") (new-node-type DECISION) (new-node "2"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value STABLE) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is stable") (source "Doctor") (level 1) (rule GFR-30-to-60-stable)
		(node-type decision) (node "2") (new-node-type DECISION) (new-node "2.1"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-stable-Urine-over-0.5)
		(node-type decision) (node "2.1") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-stable-Urine-0.4-to-0.5)
		(node-type decision) (node "2.1") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-stable-Urine-0.2-to-0.3)
		(node-type decision) (node "2.1") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-stable-Urine-under-2.0)
		(node-type decision) (node "2.1") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value INCREASING) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is increasing") (source "Doctor") (level 1) (rule GFR-30-to-60-increasing)
		(node-type decision) (node "2") (new-node-type DECISION) (new-node "2.2"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-increasing-Urine-over-0.5)
		(node-type decision) (node "2.2") (new-node-type treatment-scheme) (new-node 1))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-increasing-Urine-0.4-to-0.5)
		(node-type decision) (node "2.2") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-increasing-Urine-0.2-to-0.3)
		(node-type decision) (node "2.2") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-increasing-Urine-under-2.0)
		(node-type decision) (node "2.2") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value DECREASING) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is decreasing") (source "Doctor") (level 1) (rule GFR-30-to-60-decreasing)
		(node-type decision) (node "2") (new-node-type DECISION) (new-node "2.3"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-decreasing-Urine-over-0.5)
		(node-type decision) (node "2.3") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-decreasing-Urine-0.4-to-0.5)
		(node-type decision) (node "2.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-decreasing-Urine-0.2-to-0.3)
		(node-type decision) (node "2.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-decreasing-Urine-under-2.0)
		(node-type decision) (node "2.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value UNKNOWN) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR trend is unknown") (source "Doctor") (level 1) (rule GFR-30-to-60-unknown)
		(node-type decision) (node "2") (new-node-type DECISION) (new-node "2.4"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-unknown-Urine-over-0.5)
		(node-type decision) (node "2.4") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-unknown-Urine-0.4-to-0.5)
		(node-type decision) (node "2.4") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-unknown-Urine-0.2-to-0.3)
		(node-type decision) (node "2.4") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-30-to-60-unknown-Urine-under-2.0)
		(node-type decision) (node "2.4") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR) 
		(low-value 0) (low-value-type INCLUSIVE) (high-value 30) (high-value-type EXCLUSIVE)
		(text "GFR is less than 30") (source "Doctor") (level 0) (rule GFR-1-to-29)
		(node-type decision) (node "0") (new-node-type DECISION) (new-node "3"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value STABLE) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is stable") (source "Doctor") (level 1) (rule GFR-1-to-29-stable)
		(node-type decision) (node "3") (new-node-type DECISION) (new-node "3.1"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-stable-Urine-over-0.5)
		(node-type decision) (node "3.1") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-stable-Urine-0.4-to-0.5)
		(node-type decision) (node "3.1") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-stable-Urine-0.2-to-0.3)
		(node-type decision) (node "3.1") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-stable-Urine-under-2.0)
		(node-type decision) (node "3.1") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value INCREASING) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is increasing") (source "Doctor") (level 1) (rule GFR-1-to-29-increasing)
		(node-type decision) (node "3") (new-node-type DECISION) (new-node "3.2"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-increasing-Urine-over-0.5)
		(node-type decision) (node "3.2") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-increasing-Urine-0.4-to-0.5)
		(node-type decision) (node "3.2") (new-node-type treatment-scheme) (new-node 2))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-increasing-Urine-0.2-to-0.3)
		(node-type decision) (node "3.2") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-increasing-Urine-under-2.0)
		(node-type decision) (node "3.2") (new-node-type treatment-scheme) (new-node 3))


	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value DECREASING) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR is decreasing") (source "Doctor") (level 1) (rule GFR-1-to-29-decreasing)
		(node-type decision) (node "3") (new-node-type DECISION) (new-node "3.3"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-decreasing-Urine-over-0.5)
		(node-type decision) (node "3.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-decreasing-Urine-0.4-to-0.5)
		(node-type decision) (node "3.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-decreasing-Urine-0.2-to-0.3)
		(node-type decision) (node "3.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-decreasing-Urine-under-2.0)
		(node-type decision) (node "3.3") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name GFR-trend) 
		(low-value UNKNOWN) (low-value-type CATEGORY) (high-value NONE) (high-value-type NONE)
		(text "GFR trend is unknown") (source "Doctor") (level 1) (rule GFR-1-to-29-unknown)
		(node-type decision) (node "3") (new-node-type DECISION) (new-node "3.4"))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.5) (low-value-type EXCLUSIVE) (high-value NONE) (high-value-type NONE)
		(text "Urine production is over 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-unknown-Urine-over-0.5)
		(node-type decision) (node "3.4") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.4) (low-value-type INCLUSIVE) (high-value 0.5) (high-value-type INCLUSIVE)
		(text "Urine production is 0.4 or more and less than or equal to 0.5 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-unknown-Urine-0.4-to-0.5)
		(node-type decision) (node "3.4") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value 0.2) (low-value-type INCLUSIVE) (high-value 0.4) (high-value-type EXCLUSIVE)
		(text "Urine production is 0.2 or more and less than 0.4 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-unknown-Urine-0.2-to-0.3)
		(node-type decision) (node "3.4") (new-node-type treatment-scheme) (new-node 3))

	(value-range-decision (diagnosis HYPOKALEMIA) (value-name Urine-production) 
		(low-value NONE) (low-value-type NONE) (high-value 0.2) (high-value-type EXCLUSIVE)
		(text "Urine production is less than 0.2 cc/kg/hr") (source "Doctor") (level 2) (rule GFR-1-to-29-unknown-Urine-under-2.0)
		(node-type decision) (node "3.4") (new-node-type treatment-scheme) (new-node 3))
)

(defrule GFR-dialysis-dependent
	?decisions <- (decision (patient ?p) (name HYPOKALEMIA) (node "0"))
	(test-value (patient ?p) (name Dialysis) (value TRUE))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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
	(assert (action (patient ?p) (text "retest potassium levels")))
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

(deftemplate value-range-limits
	(slot name)
	(slot units)
	(slot abs-min)			; values under this are probably not correct
	(slot min)				; values under this should be checked
	(slot max)				; vlaues above this should be checked
	(slot abs-max)			; values above this are probably not correct
	(multislot categories)	; allowed categorical values
)

(deffacts Value-Range-Checks
	(value-range-limits (name GFR) (units "ml/min") (abs-min 0) (min 15) (max 120) (abs-max 130))
	(value-range-limits (name GFR-trend) (units NONE) (categories INCREASING STABLE DECREASING UNKNOWN))
	(value-range-limits (name Urine-production) (units "ml/kg/hr") (abs-min 0) (min 0) (max 4) (abs-max 7))
	(value-range-limits (name Potassium) (units "meq/l") (abs-min 0) (min 0.9) (max 8) (abs-max 10))
	(value-range-limits (name Magnesium) (units "meq/l") (abs-min 0.3) (min 1.5) (max 2.5) (abs-max 5))
	(value-range-limits (name Phosphorus) (units "mg/dl") (abs-min 0.6) (min 0.9) (max 8) (abs-max 12))
	(value-range-limits (name Calcium-ionized) (units "mg/dl") (abs-min 0) (min 5.4) (max 10.3) (abs-max 15))
)

(defrule value-range-check-numeric
	(value-range-limits (name ?name) (abs-min ?abs-min) (min ?min) (max ?max) (abs-max ?abs-max) (categories ))
	(test-value (patient ?p) (name ?name) (value ?value))
=>
	(if (< ?value ?abs-min) 
		then
		(assert (action (patient ?p) (text (str-cat "Check the " ?name " value of " ?value ". It is lower than the minimum acceptable test value of " ?abs-min))))
		else 
		(if (< ?value ?min) 
			then
			(assert (action (patient ?p) (text (str-cat "Check the " ?name " value of " ?value ". It is lower than the normal minimum test value of " ?min))))
		)
	)
	(if (> ?value ?abs-max) 
		then
		(assert (action (patient ?p) (text (str-cat "Check the " ?name " value of " ?value ". It is higher than the maximum acceptable test value of " ?abs-max))))
		else 
		(if (> ?value ?max) 
			then
			(assert (action (patient ?p) (text (str-cat "Check the " ?name " value of " ?value ". It is higher than the normal maximum test value of " ?max))))
		)
	)
)

(defrule value-range-check-categorical
	(value-range-limits (name ?name) (categories $?allowed-categories &: (> (length$ $?allowed-categories) 0)))
	(test-value (patient ?p) (name ?name) (value ?value &: (not (member$ ?value $?allowed-categories))))
=>
	(assert (action (patient ?p) (text (str-cat "Check the " ?name " value of " ?value ". It is not one of the allowed values: " (implode$ $?allowed-categories)))))
)

;
; Rules for treatement interactions and past effects
;
; If K levels low, not increasing, treated multiple times in last two days increase treatment by 20 mEq.

(defrule potasium-low-not-increasing-treated
	?treatment <- (treatment (patient ?p) (index ?index) (type RECOMMENDED) (med KCL) (quantity ?quantity))
	(not (flag (name KCL-Increased) (value done)))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.4)))
	(test-value (patient ?p) (name Recent-KCL) (value ?recent-kcl&:(> ?recent-kcl 40)))
    (not (test-value (patient ?p) (name Diarrhea) (value Y)))
=>
	(modify ?treatment (quantity (+ ?quantity 20)))
	(assert (action (patient ?p) (text "test Mg for possible cause of lack of response to treatment.")))
	(assert (reason (patient ?p) (level ?index) (rule potasium-low-not-increasing-treated) (text "Treatment increased by 20mEq due to lack of response.")))
	(assert (flag (name KCL-Increased) (value done)))
)

; If K levels low, not increasing, treated multiple times in last two days add action to test Mg.

(defrule potasium-low-not-increasing-diarrhea
	?treatment <- (treatment (patient ?p) (index ?index) (type RECOMMENDED) (med KCL) (quantity ?quantity))
	(not (flag (name KCL-Increased) (value done)))
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3.4)))
    (test-value (patient ?p) (name Diarrhea) (value Y))
=>
	(modify ?treatment (quantity (+ ?quantity 20)))
	(assert (reason (patient ?p) (level ?index) (rule potasium-low-not-increasing-treated) (text "Treatment increased by 20mEq due to diarrhea.")))
	(assert (flag (name KCL-Increased) (value done)))
)

; If no Mg report or low (< 1.8) and K 3.4 to 3.9 add action to consider testing.
(defrule Low-K-Unknown-Mg
	(test-value (patient ?p) (name Potassium) (value ?value &: (and (>= ?value 3.4) (< ?value 3.8))))
	(not (test-value (patient ?p) (name Magnesium)))
=>
	(assert (reason (patient ?p) (level 10) (rule Low-K-Unknown-Mg) (text "Potassium between 3.4 and 3.8, Magnesium unknown.")))
	(assert (action (patient ?p) (text "recommend testing Mg levels.")))	
)

; If no Mg report or low (< 1.8) and K < 3.4 add action to test.
(defrule Low-K-Low-Mg
	(test-value (patient ?p) (name Potassium) (value ?value1 &: (< ?value1 3.4)))
    (test-value (patient ?p) (name Magnesium) (value ?value2 &: (< ?value2 1.8)))
=>
	(assert (reason (patient ?p) (level 10) (rule Low-K-Low-Mg) (text "Potassium less then 3.4 and Magnesium less than 1.8.")))
	(assert (action (patient ?p) (text "retest Mg levels.")))	
)

; If P low use K Phos instead of KCL
(defrule Low-K-Low-P-Single-Route
	(test-value (patient ?p) (name Phosphorus) (value ?value &: (< ?value 2.5)))
	(not (flag (name K-Phos-Tried) (value done)))
	?treatment <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (route ?route))
	(not (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (route ~ ?route)))
=>
	(assert (reason (patient ?p) (level 10) (rule Low-K-Low-P-Single-Route) (text "Combine treatment of hypokalemia and hypophosphatemia.")))
	(modify ?treatment (med K-Phos) (units "mEq K as provided by mmol K-Phos"))
	(assert (flag (name K-Phos-Tried) (value done)))
)

(defrule Low-K-Low-P-Dual-Route
	(test-value (patient ?p) (name Phosphorus) (value ?value &: (< ?value 2.5)))
	(not (flag (name K-Phos-Tried) (value done)))
	?treatment1 <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (route ENTERAL))
	?treatment2 <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med KCL) (route ~ENTERAL))
=>
	(assert (reason (patient ?p) (level 10) (rule Low-K-Low-P-Single-Route) (text "Combine treatment of hypokalemia and hypophosphatemia.")))
	(modify ?treatment1 (med K-Phos) (units "mmols equal to meq K"))
	(modify ?treatment2 (med K-Phos) (units "mmols equal to meq K"))
	(assert (flag (name K-Phos-Tried) (value done)))
)

; if K low give 20 mEq or 40 mEq before switching to K Phos
(defrule Critical-Potassium-Low-Phos-Single-Route-IV
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3)))
	?treatment <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med K-Phos) (quantity ?quantity) (route ?route & ~ENTERAL))
	(not (treatment (patient ?p) (index 1) (type RECOMMENDED) (med K-Phos) (route ENTERAL)))
	(not (reason (patient ?p) (text "Treat critical hypokalemia before hypophosphatemia.")))
=>
	(assert (reason (patient ?p) (level 10) (rule Critical-Potassium-Low-Phos-Single-Route-IV) (text "Treat critical hypokalemia before hypophosphatemia.")))
	(if (> ?quantity 40) then
		(modify ?treatment (med KCL) (units mEq) (quantity (- ?quantity 40))) ; Change 40 mEq back to KCL
		(assert (treatment (patient ?p) (index 1.1) (type RECOMMENDED) (med K-Phos) (quantity (- ?quantity 40)) (units "mEq K from K-Phos") (route ?route)))
	else
		(modify ?treatment (med KCL) (units mEq)) ; change all back to KCL
	)
)

; if K low give 20 mEq or 40 mEq before switching to K Phos
(defrule Critical-Potassium-Low-Phos-Single-Route-Enteral
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3)))
	?treatment <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med K-Phos) (quantity ?quantity) (route ENTERAL))
	(not (treatment (patient ?p) (index 1) (type RECOMMENDED) (med K-Phos) (route ~ENTERAL)))
	(not (reason (patient ?p) (text "Treat critical hypokalemia before hypophosphatemia.")))
=>
	(assert (reason (patient ?p) (level 10) (rule Critical-Potassium-Low-Phos-Single-Route-Enteral) (text "Treat critical hypokalemia before hypophosphatemia.")))
	(if (> ?quantity 40) then
		(modify ?treatment (med KCL) (units mEq) (quantity (- ?quantity 40))) ; Change 40 mEq back to KCL
		(assert (treatment (patient ?p) (index 1.1) (type RECOMMENDED) (med K-Phos) (quantity (- ?quantity 40)) (units "mEq K from K-Phos") (route ENTERAL)))
	else
		(modify ?treatment (med KCL) (units mEq)) ; change all back to KCL
	)
)

; if K low give 20 mEq or 40 mEq before switching to K Phos
(defrule Critical-Potassium-Low-Phos-Dual-Route
	(test-value (patient ?p) (name Potassium) (value ?value &: (< ?value 3)))
	?treatment1 <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med K-Phos) (quantity ?quantity1) (route ENTERAL))
    ?treatment2 <- (treatment (patient ?p) (index 1) (type RECOMMENDED) (med K-Phos) (quantity ?quantity2) (route ?route & ~ENTERAL))
=>
	(assert (reason (patient ?p) (level 10) (rule Critical-Potassium-Low-Phos-Dual-Route) (text "Treat critical hypokalemia before hypophosphatemia.")))
	(if (> ?quantity2 40) then
		(modify ?treatment2 (med KCL) (units mEq) (quantity 40)) ; Change 40 mEq back to KCL
		(assert (treatment (patient ?p) (index 1.1) (type RECOMMENDED) (med K-Phos) (quantity (- ?quantity2 40)) (units "mEq K from K-Phos") (route ?route)))
	else
		(modify ?treatment2 (med KCL) (units mEq)) ; change all back to KCL
		(if (= ?quantity2 20) then
			(if (> ?quantity1 20) then
				(modify ?treatment1 (med KCL) (units mEq) (quantity 20)) ; Change 20 mEq back to KCL
				(assert (treatment (patient ?p) (index 1.1) (type RECOMMENDED) (med K-Phos) (quantity (- ?quantity1 20)) (units "mEq K from K-Phos") (route ENTERAL)))
			else
				(modify ?treatment1 (med KCL) (units mEq)) ; change all back to KCL
			)
		)
	)
)

; if Ca critical (< 7 mg/dL) give Ca first, then phos
(defrule Critical-Calcium
	(test-value (patient ?p) (name Calcium) (value ?value &: (< ?value 7)))
	?treatment <- (treatment (patient ?p) (index 1.1) (type RECOMMENDED) (med K-Phos) (route ?route & CENTRAL-IV | PERIPHERAL-IV))
	(not (treatment (patient ?p) (index 1) (type RECOMMENDED) (med Ca-Glu))) ; Otherwise the modify of ?treatment causes a loop
=>
	(assert (treatment (patient ?p) (index 1) (type RECOMMENDED) (med Ca-Glu) (quantity TBD) (units mg/dl) (route ?route)))
	(assert (reason (patient ?p) (level 13) (rule Critical-Calcium) (text "Treat critical hypocalcemia before hypophosphatemia.")))
	(modify ?treatment (units meq)) ; to place K-PHOS treatement after Ca-Glu treatment
)

(defrule test
	(flag (name test))
=>
	(assert (diagnosis (patient p123456) (name HYPOKALEMIA)))
	(assert (test-value (patient p123456) (name GFR) (value 45)))
	(assert (test-value (patient p123456) (name GFR-trend) (value STABLE)))
	(assert (test-value (patient p123456) (name Urine-production) (value 0.45)))
	(assert (test-value (patient p123456) (name Potassium) (value 2.4)))
	(assert (test-value (patient p123456) (name Magnesium) (value 1.6)))
	(assert (test-value (patient p123456) (name Phosphorus) (value 2)))
	(assert (test-value (patient p123456) (name Calcium) (value 6)))
	(assert (test-value (patient p123456) (name Diarrhea) (value Y)))
	(assert (test-value (patient p123456) (name Recent-KCL) (value 40)))
	 
;	(assert (available-routes (patient p123456) (type ENTERAL)))
	(assert (available-routes (patient p123456) (type CENTRAL-IV)))
	(assert (available-routes (patient p123456) (type PERIPHERAL-IV)))
)

(deffacts test
;	(flag (name test))
)