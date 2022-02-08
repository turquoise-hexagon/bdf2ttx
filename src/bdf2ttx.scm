(import
  (chicken condition)
  (chicken format)
  (chicken io)
  (chicken irregex)
  (chicken port)
  (chicken process-context)
  (chicken string)
  (matchable)
  (srfi 1)
  (srfi 69)
  (only (srfi 152) string-pad))

(include-relative "templates.scm")

(define (errx status . message)
  (with-output-to-port (current-error-port)
    (lambda () (apply print message)))
  (exit status))

(define (basename path)
  (last (string-split path "/")))

(define (usage)
  (errx 1 "usage : " (basename (program-name)) " [file]"))

(define (import-input path)
  (condition-case (read-string #f (open-input-file path))
    ((exn) (errx 1 "error : failed to open '" path "'"))))

(define (parse-properties properties)
  (let ((acc (make-hash-table)))
    (for-each
      (lambda (property)
        ;; strip quotes from value
        (let ((matches (irregex-match "([^ ]+) \"?([^\"]+)\"?" property)))
          (receive (name value)
            (apply values
              (map (cut irregex-match-substring matches <>) '(1 2)))
            (hash-table-set! acc name value))))
      (string-split properties "\n"))
    acc))

(define (parse-char-header header)
  (let ((acc (make-hash-table)))
    (for-each
      (lambda (property)
        (match (string-split property " ")
          ((name   value) (hash-table-set! acc name (string->number value)))
          ((name . value) (hash-table-set! acc name (map string->number value)))))
      (string-split header "\n"))
    acc))

(define (parse-char-bitmap bitmap)
  (map
    (lambda (line)
      ;; convert hex to bin and add padding
      (flatten
        (map string->list
          (map (cut string-pad <> 8 #\0)
            (map (cut number->string <> 2)
              (map (cut string->number <> 16)
                (string-chop line 2)))))))
    (string-split bitmap "\n")))

(define (parse-char char)
  (match (irregex-split "BITMAP\n" char)
    ;; handle empty bitmaps
    ((header bitmap) (list (parse-char-header header) (parse-char-bitmap bitmap)))
    ((header)        (list (parse-char-header header) '()))))

(define (parse-chars chars)
  (map parse-char chars))

(define (extract-data data)
  (receive (_ properties _ . chars)
    (apply values
      (irregex-split "(START(CHAR|PROPERTIES|FONT).*|END(CHAR|PROPERTIES|FONT))\n" data))
    (list (parse-properties properties)
          (parse-chars chars))))

(define (coordinate->xml coordinate)
  (format contour-template
    (apply string-append
      ;; draw a pixel using 4 strokes
      (map
        (lambda (offset)
          (apply format pt-template
            (map + coordinate offset)))
        '((0 0) (1 0) (1 1) (0 1))))))

(define (bitmap->xml bbx bitmap)
  (receive (width height _ descent) (apply values bbx)
    (let ((x (reverse (iota height descent))) (y (iota width)))
      (apply string-append
        (join
          (map
            (lambda (x line)
              (map
                (lambda (y char)
                  (if (char=? char #\0)
                    ""
                    (coordinate->xml (list y x))))
                y line))
            x bitmap))))))

(define (get-lsb bbx bitmap)
  (receive (limit _ lsb _) (apply values bbx)
    ;; find least number of leading 0s
    (let ((tmp (map
                 (lambda (line)
                   (length (take-while (cut char=? <> #\0) line)))
                 bitmap)))
      ;; handle empty bitmaps
      (+ lsb (if (null? tmp)
               0
               (min limit (apply min tmp)))))))

(define (get-spacing properties)
  (let ((spacing (hash-table-ref properties "SPACING")))
    (if (or (string=? spacing "p")
            (string=? spacing "P"))
      "1"
      "0")))

(define (get-font-descent properties)
  (let ((descent (hash-table-ref properties "FONT_DESCENT")))
    (string-append "-" descent)))

(define (generate-glyphorder-xml chars-properties)
  (format glyphorder-template
    (apply string-append
      (map
        (lambda (properties)
          (let ((encoding (hash-table-ref properties "ENCODING")))
            (format glyphid-template encoding encoding)))
        chars-properties))))

(define (generate-hmtx-xml chars-properties chars-bitmaps)
  (format hmtx-template
    (apply string-append
      (map
        (lambda (properties bitmap)
          (let ((bbx      (hash-table-ref properties "BBX"))
                (dwidth   (hash-table-ref properties "DWIDTH"))
                (encoding (hash-table-ref properties "ENCODING")))
            (format mtx-template (first dwidth) (get-lsb bbx bitmap) encoding)))
        chars-properties chars-bitmaps))))

(define (generate-cmap-xml chars-properties)
  (format cmap-template
    (apply string-append
      (map
        (lambda (properties)
          (let ((encoding (hash-table-ref properties "ENCODING")))
            (format map-template (number->string encoding 16) encoding)))
        chars-properties))))

(define (generate-glyf-xml chars-properties chars-bitmaps)
  (format glyf-template
    (apply string-append
      (map
        (lambda (properties bitmap)
          (let ((bbx      (hash-table-ref properties "BBX"))
                (encoding (hash-table-ref properties "ENCODING")))
            (format ttglyph-template encoding (bitmap->xml bbx bitmap))))
        chars-properties chars-bitmaps))))

(define (main properties chars)
  (receive (chars-properties chars-bitmaps) (unzip2 chars)
    (format (current-output-port) ttx-template
      (generate-glyphorder-xml chars-properties)
      (hash-table-ref          properties "FONT_ASCENT")
      (get-font-descent        properties)
      (length                  chars)
      (generate-hmtx-xml       chars-properties chars-bitmaps)
      (generate-cmap-xml       chars-properties)
      (generate-glyf-xml       chars-properties chars-bitmaps)
      (hash-table-ref          properties "FAMILY_NAME")
      (hash-table-ref          properties "FOUNDRY")
      (get-spacing             properties))))

(match (command-line-arguments)
  ((path)
   (apply main (extract-data (import-input path))))
  (_ (usage)))
