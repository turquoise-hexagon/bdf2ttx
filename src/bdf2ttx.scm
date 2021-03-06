(import (chicken condition)
        (chicken io)
        (chicken irregex)
        (chicken pathname)
        (chicken port)
        (chicken process-context)
        (chicken string)
        (format)
        (matchable)
        (srfi 1)
        (srfi 69))

(include-relative "templates.scm")

;; ---
;; general functions
;; ---

(define (error-handler status . args)
  (with-output-to-port (current-error-port)
    (lambda () (apply print args)))
  (exit status))

(define (usage)
  (error-handler 1 "usage : " (pathname-file (program-name)) " <file>"))

(define (import-input path)
  (condition-case (read-string #f (open-input-file path))
    ((exn) (error-handler 1 "error : failed to open '" path "'"))))

;; ---
;; main functions
;; ---

(define (extract-properties str)
  ;; get properties section
  (let ((properties (irregex-split "(STARTPROPERTIES.*|ENDPROPERTIES)\n" str)))
    (string-split (cadr properties) "\n")))

(define (parse-properties str)
  (let ((properties (make-hash-table)))
    (for-each
      (lambda (property)
        ;; remove quotes
        (let ((property (irregex-replace/all "\"" property "")))
          ;; get property name and its value
          (let ((tmp (irregex-match "^([^ ]+) (.+)$" property))) 
            (match (map (cut irregex-match-substring tmp <>) '(1 2))
              ((key val) (hash-table-set! properties key val))))))
      (extract-properties str))
    properties))

(define (extract-characters str)
  ;; get char sections
  (let ((chars (irregex-split "(STARTCHAR.*|ENDFONT)\n" str)))
    ;; trim useless information
    (map (cut irregex-replace "ENDCHAR\n" <> "") (cdr chars))))

(define (parse-character-bitmap bitmap)
  (map
    (lambda (line)
      ;; convert from hexadecimal to binary & add padding
      (string->list (apply string-append (map (cut format "~8,,,'0@A" <>)
        (map (cut number->string <> 2) (map (cut string->number <> 16) line))))))
    (map (cut string-chop <> 2) (string-split bitmap "\n"))))

(define (parse-character-header header)
  (let ((properties (make-hash-table)))
    (for-each
      (lambda (line)
        (match (string-split line " ")
          ((key   val) (hash-table-set! properties key     (string->number val)))
          ((key . val) (hash-table-set! properties key (map string->number val)))))
      (string-split header "\n"))
    properties))

(define (parse-character str)
  (match (irregex-split "BITMAP\n" str)
    ((header bitmap) (list (parse-character-header header) (parse-character-bitmap bitmap)))
    ((header)        (list (parse-character-header header) '()))))

(define (parse-characters str)
  (map parse-character (extract-characters str)))

(define (coordinates->xml x y)
  (format contour-template
          (apply string-append
                 ;; draw a pixel using 4 strokes
                 (fold
                   (lambda (offsets acc)
                     (match offsets
                       ((x-offset y-offset)
                        (cons (format pt-template (+ x x-offset) (+ y y-offset)) acc))))
                   '() '((0 0) (1 0) (1 1) (0 1))))))

(define (bitmap->xml bounds bitmap)
  (match bounds
    ((width height _ descent)
     (let ((x-lst (reverse (iota height))) (y-lst (iota width)))
       (apply string-append
              (fold
                (lambda (line x acc)
                  (append acc
                          (fold
                            (lambda (char y acc)
                              (if (char=? char #\0) acc
                                  ;; adjust coordinates for descent
                                  (cons (coordinates->xml y (+ x descent)) acc)))
                            '() line y-lst)))
                '() bitmap x-lst))))))

(define (character->xml char)
  (match char
    ((properties bitmap)
     (let ((bounds   (hash-table-ref properties "BBX"))
           (encoding (hash-table-ref properties "ENCODING")))
       (format ttglyph-template encoding (bitmap->xml bounds bitmap))))))

(define (get-lsb bounds bitmap)
  (match bounds
    ((limit _ lsb _)
     ;; find least number of leading 0s
     (let ((lst (map
                  (lambda (lst)
                    (length (take-while (cut char=? <> #\0) lst)))
                  (map (cut take <> limit) bitmap))))
       ;; fallback to 0 (useful for empty bitmaps)
       (+ lsb (if (null? lst) 0 (apply min lst)))))))

(define (get-number-chars chars)
  (length chars))

(define (get-spacing-fixed properties)
  (let ((spacing (hash-table-ref properties "SPACING")))
    (if (member spacing '("p" "P"))
        "1"
        "0")))

(define (get-font-descent properties)
  (let ((descent (hash-table-ref properties "FONT_DESCENT")))
    (string-append "-" descent)))

(define (generate-glyphorder-xml chars)
  (format glyphorder-template
          (apply string-append
                 (fold-right
                   (lambda (char acc)
                     (let ((properties (car char)))
                       (let ((encoding (hash-table-ref properties "ENCODING")))
                         (cons (format glyphid-template encoding encoding) acc))))
                   '() chars))))

(define (generate-hmtx-xml chars)
  (format hmtx-template
          (apply string-append
                 (fold-right
                   (lambda (char acc)
                     (match char
                       ((properties bitmap)
                        (let ((bounds   (hash-table-ref properties "BBX"))
                              (dwidth   (hash-table-ref properties "DWIDTH"))
                              (encoding (hash-table-ref properties "ENCODING")))
                          (cons (format mtx-template (car dwidth) (get-lsb bounds bitmap) encoding) acc)))))
                   '() chars))))

(define (generate-cmap-xml chars)
  (format cmap-template
          (apply string-append
                 (fold-right
                   (lambda (char acc)
                     (let ((properties (car char)))
                       (let ((encoding (hash-table-ref properties "ENCODING")))
                         (cons (format map-template (number->string encoding 16) encoding) acc))))
                   '() chars))))

(define (generate-glyf-xml chars)
  (format glyf-template (apply string-append (map character->xml chars))))

;; ---
;; argument parsing
;; ---

(define (main properties chars)
  (format (current-output-port)
          ttx-template
          (generate-glyphorder-xml chars)
          (hash-table-ref          properties "FONT_ASCENT")
          (get-font-descent        properties)
          (get-number-chars        chars)
          (generate-hmtx-xml       chars)
          (generate-cmap-xml       chars)
          (generate-glyf-xml       chars)
          (hash-table-ref          properties "FAMILY_NAME")
          (hash-table-ref          properties "FOUNDRY")
          (get-spacing-fixed       properties)))

(match (command-line-arguments)
  ((path)
   (let ((input (import-input path)))
     (main (parse-properties input) (parse-characters input))))
  (_ (usage)))
