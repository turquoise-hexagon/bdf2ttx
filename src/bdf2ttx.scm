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
        ;; get property name and its value
        (let ((match (irregex-match "^([^ ]+) (.+)$" (irregex-replace/all "\"" property ""))))
          (let ((key (irregex-match-substring match 1))
                (val (irregex-match-substring match 2)))
            (hash-table-set! properties key val))))
      (extract-properties str))
    properties))

(define (extract-characters str)
  ;; get char sections
  (let ((chars (irregex-split "(STARTCHAR.*|ENDFONT)\n" str)))
    ;; trim useless information
    (map (cut irregex-replace "ENDCHAR\n" <> "") (cdr chars))))

(define (parse-bitmap bitmap)
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
    ((header bitmap) (list (parse-character-header header) (parse-bitmap bitmap)))
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
  (if (null? bitmap) ""
      (match bounds
        ((_ _ _ descent)
         (let ((height (reverse (iota (length bitmap)))) (width (iota (length (car bitmap)))))
           (apply string-append
                  (fold
                    (lambda (line x acc)
                      (append acc (fold
                                    (lambda (char y acc)
                                      (if (char=? char #\0) acc
                                          ;; adjust coordinates for descent
                                          (cons (coordinates->xml y (+ x descent)) acc)))
                                    '() line width)))
                    '() bitmap height)))))))

(define (character->xml char)
  (match char
    ((properties bitmap)
     (format ttglyph-template
             (hash-table-ref properties "ENCODING") (bitmap->xml (hash-table-ref properties "BBX") bitmap)))))

(define (get-lsb bbx bitmap)
  (match bbx
    ((limit _ lsb _)
     (let get-lsb/h ((i 0) (acc lsb))
       (if (= i limit)
           acc
           (if (member #\1 (map (cut list-ref <> i) bitmap))
               acc
               (get-lsb/h (+ i 1) (+ acc 1))))))))

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
                     (let ((encoding (hash-table-ref (car char) "ENCODING")))
                       (cons (format glyphid-template encoding encoding) acc)))
                   '() chars))))

(define (generate-hmtx-xml chars)
  (format hmtx-template
          (apply string-append
                 (fold-right
                   (lambda (char acc)
                     (match char
                       ((properties bitmap)
                        (cons (format mtx-template
                                      (car (hash-table-ref properties "DWIDTH"))
                                  (get-lsb (hash-table-ref properties "BBX") bitmap)
                                           (hash-table-ref properties "ENCODING"))
                              acc))))
                   '() chars))))

(define (generate-cmap-xml chars)
  (format cmap-template
          (apply string-append
                 (fold-right
                   (lambda (char acc)
                     (let ((encoding (hash-table-ref (car char) "ENCODING")))
                       (cons (format map-template (number->string encoding 16) encoding) acc)))
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
