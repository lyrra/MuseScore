;;;; test utilities for testing musescore
(define-module (test test-musescore)
               #:use-module (ice-9 textual-ports) ; get-string-all
               #:use-module (sxml simple)
               #:use-module (rnrs bytevectors)
               #:use-module (system foreign)
               #:use-module (musescore-c)
               #:use-module (test ffi)
               #:export (tick2fraction
                         test-sxml-to-xml
                         test-read-score-sxlm
                         test-read-score-mscx-file
                         test-print-score-segments
                         test-print-score
                         walk-segments
                         walk-score))

(define (tick2fraction tick)
  ; FIX: 20190524, is 256 bytes enough?
  (let ((bv (bytevector->pointer (make-bytevector 256))))
    (ms-fraction-con bv tick 1)
    bv))

(define (test-sxml-to-xml sxml)
  (with-output-to-string
   (lambda () (sxml->xml sxml))))

(define (test-read-score-sxlm sxml)
  (let ((str (test-sxml-to-xml sxml)))
    (let ((score (ms-score-read-string str)))
      score)))

(define (test-read-score-mscx-file file)
  (let ((fp (open-input-file file)))
    (let ((score (ms-score-read-string
                  (get-string-all fp))))
      (close-port fp)
      score)))

(define (test-print-score-segments firstseg nextfun)
  (let ((lastseg #f)
        (oldmea 0))
    (do ((seg firstseg (nextfun seg)))
        ((not seg))
      (set! lastseg seg)
      (let ((mea (ms-segment-measure seg)))
        (if (not (= oldmea (pointer-address mea)))
          (begin
            (set! oldmea (pointer-address mea))
            (format #t "    mea:~s noOffset:~d no:~d~%" mea
                    (ms-measure-noOffset mea)
                    (ms-measure-no mea))
            (let ((elmvec (ms-measure-elements mea)))
              (do ((i 0 (+ i 1)))
                  ((>= i (vector-length elmvec)))
                (let ((elm (vector-ref elmvec i)))
                  (format #t "        elm: ~s ~s~%" elm (ms-element-name elm)))))))
        (format #t "      seg (tick ~a): ~s~%"
                (ms-element-tick seg)
                seg)
        (let ((elmvec (ms-segment-elements seg)))
          (do ((i 0 (+ i 1)))
              ((>= i (vector-length elmvec)))
            (let ((elm (vector-ref elmvec i)))
              (format #t "        elm: ~s ~s~%" elm (ms-element-name elm)))))))))

(define (test-print-score score)
  (format #t "--- Score: ---~%")
  (let ((firstseg (ms-score-tick2segment score 0))
        (firstMMseg (ms-score-tick2segmentMM score 0)))
    (format #t "  first-seg (tick 0): ~s~%" firstseg)
    (test-print-score-segments firstseg ms-segment-next1)
    (if (ms-measure-mmrest? (ms-segment-measure firstMMseg))
      (begin
        (format #t "  firstMM-seg (tick 0): ~s~%" firstMMseg)
        (test-print-score-segments firstMMseg ms-segment-next1MM)))))

(define (walk-segments firstseg nextfun meafun segfun elmfun)
  (let ((lastseg #f)
        (oldmea 0))
    (do ((seg firstseg (nextfun seg)))
        ((not seg))
      (set! lastseg seg)
      (if segfun (segfun seg))
      (let ((mea (ms-segment-measure seg)))
        (if (not (= oldmea (pointer-address mea)))
          (begin
            (if meafun (meafun mea))
            (set! oldmea (pointer-address mea))
            (if elmfun
              (let ((elmvec (ms-measure-elements mea)))
                (do ((i 0 (+ i 1)))
                    ((>= i (vector-length elmvec)))
                  (let ((elm (vector-ref elmvec i)))
                    (elmfun elm)))))))
        (if elmfun
          (let ((elmvec (ms-segment-elements seg)))
            (do ((i 0 (+ i 1)))
                ((>= i (vector-length elmvec)))
              (let ((elm (vector-ref elmvec i)))
                (elmfun elm)))))))))

(define (walk-score meafun segfun elmfun score)
  (let ((firstseg (ms-score-tick2segment score (tick2fraction 0)))
        (firstMMseg (ms-score-tick2segmentMM score (tick2fraction 0)))
        (lastseg #f)
        (oldmea 0))
    (walk-segments firstseg ms-segment-next1 meafun segfun elmfun)
    (if (ms-measure-mmrest? (ms-segment-measure firstMMseg))
      (walk-segments firstMMseg ms-segment-next1MM meafun segfun elmfun))))
