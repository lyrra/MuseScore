(map (lambda (score)
       (map (lambda (measure)
              (map (lambda (segment)
                     (ms-segment-elements segment))
                   (ms-measure-segments measure)))
            (ms-score-measures score)))
     (ms-scores))
