(define (scores-staves-info)
  (map (lambda (score)
         (map (lambda (stave)
                (ms-staff-info stave))
              (ms-score-staves score)))
       (ms-scores)))