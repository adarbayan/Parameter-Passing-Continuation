(module interp (lib "eopl.ss" "eopl")
  
  ;; cps interpreter for the LETREC language, using the data structure representation of continuations

  (require "drscheme-init.scm")

  (require "lang.scm")
  (require "data-structures.scm")
  (require "environments.scm")

  (provide value-of-program value-of/k)

;;;;;;;;;;;;;;;; the interpreter ;;;;;;;;;;;;;;;;

  ;; value-of-program : Program -> FinalAnswer
  ;; Page: 143 and 154
  (define value-of-program 
    (lambda (pgm)
      (cases program pgm
        (a-program (exp1)
          (value-of/k exp1 (init-env) (end-cont))))))  

  ;; value-of/k : Exp * Env * Cont -> FinalAnswer
  ;; Page: 143--146, and 154
  (define value-of/k
    (lambda (exp env cont)
      (cases expression exp
        (const-exp (num) (apply-cont cont (num-val num)))
        (var-exp (var) (apply-cont cont (apply-env env var)))
        (proc-exp (var body)
          (apply-cont cont 
            (proc-val (procedure var body env))))
        (letrec-exp (p-name b-var p-body letrec-body)
          (value-of/k letrec-body
            (extend-env-rec p-name b-var p-body env)
            cont))
        (zero?-exp (exp1)
          (value-of/k exp1 env
            (zero1-cont cont)))
        (let-exp (var exp1 body)
          (value-of/k exp1 env
            (let-exp-cont var body env cont)))
        (if-exp (exp1 exp2 exp3)
          (value-of/k exp1 env
            (if-test-cont exp2 exp3 env cont)))
        (diff-exp (exp1 exp2)
          (value-of/k exp1 env
            (diff1-cont exp2 env cont)))        
        (call-exp (rator rand) 
          (value-of/k rator env
            (rator-cont rand env cont)))


        ;;;; TASK 5 ;;;;;;;;;
        ; Implement car expression case here
        (car-exp (exp1)
                 (value-of/k exp1 env (car-cont env cont)))
        
        ; Implement cdr expression case here
        (cdr-exp (exp1)
                 (value-of/k exp1 env (cdr-cont cont)))
        ; Implement null? expression case here
        (null?-exp (exp1)
                   (value-of/k exp1 env (null?-cont cont)))

        ; Implement emptylist expression case here
        (emptylist-exp ()
                       (apply-cont cont (empty-list)))
        ; Implement your list expression case here
        (list-exp (expList)
                  (if (null? expList)
                      (apply-cont cont (empty-list))
                      (value-of/k (car expList) env (list-cont '() (cdr expList) env cont))))
        ; Implement the map expression case here        
        (map-exp (proc list)
                 (value-of/k proc env (map-cont list env cont)))
                 
        ;;;;;;;;;;;;;;;;;;;;;;
   )))

  ;; apply-cont : Cont * ExpVal -> FinalAnswer
  ;; Page: 148
  (define apply-cont
    (lambda (cont val)
      (cases continuation cont
        (end-cont () 
          (begin
            (eopl:printf
              "End of computation.~%")
            val))
        (zero1-cont (saved-cont)
          (apply-cont saved-cont
            (bool-val
              (zero? (expval->num val)))))
        (let-exp-cont (var body saved-env saved-cont)
          (value-of/k body
            (extend-env var val saved-env) saved-cont))
        (if-test-cont (exp2 exp3 saved-env saved-cont)
          (if (expval->bool val)
             (value-of/k exp2 saved-env saved-cont)
             (value-of/k exp3 saved-env saved-cont)))
        (diff1-cont (exp2 saved-env saved-cont)
          (value-of/k exp2
            saved-env (diff2-cont val saved-cont)))
        (diff2-cont (val1 saved-cont)
          (let ((num1 (expval->num val1))
                (num2 (expval->num val)))
            (apply-cont saved-cont
              (num-val (- num1 num2)))))
        (rator-cont (rand saved-env saved-cont)
          (value-of/k rand saved-env
            (rand-cont val saved-cont)))
        (rand-cont (val1 saved-cont)
          (let ((proc (expval->proc val1)))
            (apply-procedure/k proc val saved-cont)))

        ;;;;;;;;;;;;;;;;;;;;;;; TASK 5 ;;;;;;;;;;;;;;;;;;;;;;;;
        ; implement "car-cont" continuation here
        (car-cont (saved-env saved-cont)
                  (apply-cont saved-cont (expval->car val)))

        ; implement "cdr-cont" continuation here
        (cdr-cont (saved-cont)
                  (apply-cont saved-cont (expval->cdr val)))
        ; implement "null?-cont" continuation here
        (null?-cont (saved-cont)
                    (apply-cont saved-cont (expval->null? val)))
        ; implement continuation for list-exp here.
        ; hint: you will need to call value-of/k recursively, by passing this continuation as cont to value-of/k.
        (list-cont (values exps saved-env saved-cont)
                   (if (null? exps)
                       (apply-cont saved-cont (make-pair-c val values (lambda (n) n)))
                       (value-of/k (car exps) saved-env (list-cont (append values (list val)) (cdr exps) saved-env saved-cont))))
        ; implement map-exp continuation(s) here. you will notice that one continuation will not be enough.
        (map-cont (list saved-env saved-cont)
                  (value-of/k list saved-env (proc-cont val saved-cont)))
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        (proc-cont (proc saved-cont)
                   (apply-map-c val proc saved-cont))

        (apply-procedure-cont (proc list saved-cont)
                              (apply-procedure/k proc list (apply-map-cont val saved-cont)))

        (apply-map-cont (n saved-cont)
                    (apply-cont saved-cont (pair-val val n))))))
        

  (define make-pair-c
    (lambda (val vals cont)
      (if (null? vals)
          (cont (pair-val val (empty-list)))
          (make-pair-c val (cdr vals) (lambda (n) (cont (pair-val (car vals) n)))))))

  (define apply-map-c
    (lambda (list proc cont)
      (if (expval->bool (expval->null? list))
          (apply-cont cont (empty-list))
          (apply-map-c (expval->cdr list) proc (apply-procedure-cont (expval->proc proc) (expval->car list) cont)))))
  ;; apply-procedure/k : Proc * ExpVal * Cont -> FinalAnswer
  ;; Page 152 and 155
  (define apply-procedure/k
    (lambda (proc1 arg cont)
      (cases proc proc1
        (procedure (var body saved-env)
          (value-of/k body
            (extend-env var arg saved-env)
            cont)))))
  
  )
  


  