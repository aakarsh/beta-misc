(require 'cl)

;; My elisp sucks ;), like everything else
;; while this is a valient effort
;; there is just not enough time to do this
;; a translator from  beta to x86 might be possible.

(defun B/radix-decimal(number-list radix)
  (let ((sum  0)
        (i  0))
    (dolist (n (reverse number-list))
      (setq sum (+ sum (* (expt radix i) n)))
      (incf i))
    sum))

(defun B/x-ch(ch)
  (let ((c  (downcase ch)))
    (cond
     ((equal c  ?a) 10)
     ((equal c  ?b) 11)
     ((equal c  ?c) 12)
     ((equal c  ?d) 13)
     ((equal c  ?e) 14)
     ((equal c  ?f) 15)
     (1 (string-to-number (char-to-string c)))
     )))

(defun B/hex-parse(str)  "eg 0x20"
  (B/radix-decimal
   (mapcar 'B/x-ch (string-to-list (substring str 2)))
   16))

(defun B/dec-bin-list(n)
  (let ((l '()))
    (while (> n 0)
      (setq l (cons (mod n 2) l))
    (setq n (/ n 2)))
  l))

(defun B/fill-with(list value limit)
  (let ((head '()))
    (while (> (- limit (length list)) 0)
      (setq head (cons value head))
      (decf limit))
    (append head list)))

(defun B/op-code(ins)
  (B/fill-with
   (B/dec-bin-list
    (B/hex-parse (cdr (assoc ins B/op-codes)))) 0 6))

(defvar ld  "        LD(R0,-16,R1))")

(defun B/string-tokenize(str seps)
  (let ((acc '())
        (retval '())
        (str-list (string-to-list str))
        (seps-list (string-to-list seps)))
    (dolist (s str-list)
      (if (find s seps-list)
          (progn
            (setq retval (cons acc retval))
            (setq acc '()))
        (setq acc (append  acc  (list s)  ))
       ))
    (remove-if 
     (lambda(x)  (not x))
     (reverse (append (list acc) retval)))))

(defun B/instruction-tokenize (ins)
  (B/string-tokenize ins "(,) "))

(defun B/bin-invert (blist)
  (let (retval '())
    (dolist (b blist)
      (if (eq b 1)
          (setq retval (cons 0 retval))
        (setq retval (cons 1 retval))))
    (reverse retval)))

(defun B/bin-inc(blist)
  (B/dec-bin-list (+ 1 (B/radix-decimal blist 2))))

(defun B/bin-twos-complement(blist)               
  (B/bin-inc (B/bin-invert blist)))

(defun B/register-code (s)
  (B/fill-with (B/dec-bin-list (string-to-number (substring s 1)))
  0 5))

(defun B/instruction-code(s)
  (let* ((instruction-tokens (B/instruction-tokenize s))
         (instruction (upcase (concat  (car instruction-tokens)))))
    (cond 
     ((equal "LD" instruction)
          (append (B/op-code instruction)
                  (B/register-code (concat (nth 3 instruction-tokens)))
                  (concat (nth 2 instruction-tokens))
                  (B/register-code (concat (nth 1 instruction-tokens))))))))


(defun string/reverse (str)
  "Reverse the str where str is a string"
  (apply #'string (reverse (string-to-list str))))

(defvar B/op-codes
  '(("ADD"    . "0x20")
    ("CMPLEC" . "0x36")
    ("MULC"   . "0x32")
    ("SUB"    . "0x21")
    ("ADDC"   . "0x30")
    ("CMPLT"  . "0x25")
    ("OR"     . "0x29")
    ("SUBC"   . "0x31")
    ("AND"    . "0x28")
    ("CMPLTC" . "0x35")
    ("ORC"    . "0x39")
    ("ST"     . "0x19")
    ("ANDC"   . "0x38")
    ("DIV"    . "0x23")
    ("SHL"    . "0x2C")
    ("XOR"    . "0x2A")
    ("BEQ"    . "0x1C")
    ("DIVC"   . "0x33")
    ("SHLC"   . "0x3C")
    ("XORC"   . "0x3A")
    ("BNE"    . "0x1D")
    ("JMP"    . "0x1B")
    ("SHR"    . "0x2D")
    ("XNOR"   . "0x2B")
    ("CMPEQ"  . "0x24")
    ("LD"     . "0x18")
    ("SHRC"   . "0x3D")
    ("XNORC"  . "0x3B")
    ("CMPEQC" . "0x34")
    ("LDR"    . "0x1F")
    ("SRA"    . "0x2E")
    ("CMPLE"  . "0x26")
    ("MUL"    . "0x22")
    ("SRAC"   . "0x3E)")))


