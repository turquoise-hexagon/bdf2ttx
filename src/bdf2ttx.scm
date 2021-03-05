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

;; ---
;; templates
;; ---

(define glyf-template "\
<glyf>
~a</glyf>
")

(define contour-template "\
<contour>
~a</contour>
")

(define pt-template "\
<pt x=\"~a\" y=\"~a\" on=\"1\"/>
")

(define ttglyph-template "\
<TTGlyph name=\"char~a\">
~a<instructions>
<assembly/>
</instructions>
</TTGlyph>
")

(define glyphorder-template "\
<GlyphOrder>
~a</GlyphOrder>
")

(define glyphid-template "\
<GlyphID id=\"~a\" name=\"char~a\"/>
")

(define hmtx-template "\
<hmtx>
~a</hmtx>
")

(define mtx-template "\
<mtx width=\"~a\" lsb=\"~a\" name=\"char~a\"/>
")

(define cmap-template "\
<cmap>
<tableVersion version=\"0\"/>
<cmap_format_4 platformID=\"3\" platEncID=\"1\" language=\"0\">
~a</cmap_format_4>\n</cmap>
")

(define map-template "\
<map code=\"0x~a\" name=\"char~a\"/>
")

(define ttx-template "\
<?xml version=\"1.0\" ?>
<ttFont sfntVersion=\"\\x00\\x01\\x00\\x00\" ttLibVersion=\"4.2\">
~a<head>
<tableVersion value=\"1.0\"/>
<fontRevision value=\"1.0\"/>
<checkSumAdjustment value=\"0x41b81b0d\"/>
<magicNumber value=\"0x5f0f3cf5\"/>
<flags value=\"00000000 00000001\"/>
<unitsPerEm value=\"16\"/>
<created value=\"Thu Jan  1 04:46:28 1970\"/>
<modified value=\"Sat Dec  7 16:19:12 2019\"/>
<xMin value=\"0\"/>
<yMin value=\"0\"/>
<xMax value=\"0\"/>
<yMax value=\"0\"/>
<macStyle value=\"00000000 00000000\"/>
<lowestRecPPEM value=\"1\"/>
<fontDirectionHint value=\"0\"/>
<indexToLocFormat value=\"0\"/>
<glyphDataFormat value=\"0\"/>
</head>
<hhea>
<tableVersion value=\"0x00010000\"/>
<ascent value=\"~a\"/>
<descent value=\"~a\"/>
<lineGap value=\"0\"/>
<advanceWidthMax value=\"0\"/>
<minLeftSideBearing value=\"0\"/>
<minRightSideBearing value=\"0\"/>
<xMaxExtent value=\"7\"/>
<caretSlopeRise value=\"1\"/>
<caretSlopeRun value=\"0\"/>
<caretOffset value=\"0\"/>
<reserved0 value=\"0\"/>
<reserved1 value=\"0\"/>
<reserved2 value=\"0\"/>
<reserved3 value=\"0\"/>
<metricDataFormat value=\"0\"/>
<numberOfHMetrics value=\"0\"/>
</hhea>
<maxp>
<tableVersion value=\"0x10000\"/>
<numGlyphs value=\"~a\"/>
<maxPoints value=\"0\"/>
<maxContours value=\"0\"/>
<maxCompositePoints value=\"0\"/>
<maxCompositeContours value=\"0\"/>
<maxZones value=\"0\"/>
<maxTwilightPoints value=\"0\"/>
<maxStorage value=\"0\"/>
<maxFunctionDefs value=\"0\"/>
<maxInstructionDefs value=\"0\"/>
<maxStackElements value=\"0\"/>
<maxSizeOfInstructions value=\"0\"/>
<maxComponentElements value=\"0\"/>
<maxComponentDepth value=\"0\"/>
</maxp>
<OS_2>
<version value=\"1\"/>
<xAvgCharWidth value=\"555\"/>
<usWeightClass value=\"500\"/>
<usWidthClass value=\"5\"/>
<fsType value=\"00000000 00000000\"/>
<ySubscriptXSize value=\"409\"/>
<ySubscriptYSize value=\"409\"/>
<ySubscriptXOffset value=\"0\"/>
<ySubscriptYOffset value=\"409\"/>
<ySuperscriptXSize value=\"409\"/>
<ySuperscriptYSize value=\"409\"/>
<ySuperscriptXOffset value=\"0\"/>
<ySuperscriptYOffset value=\"409\"/>
<yStrikeoutSize value=\"0\"/>
<yStrikeoutPosition value=\"512\"/>
<sFamilyClass value=\"0\"/>
<panose>
<bFamilyType value=\"0\"/>
<bSerifStyle value=\"0\"/>
<bWeight value=\"0\"/>
<bProportion value=\"0\"/>
<bContrast value=\"0\"/>
<bStrokeVariation value=\"0\"/>
<bArmStyle value=\"0\"/>
<bLetterForm value=\"0\"/>
<bMidline value=\"0\"/>
<bXHeight value=\"0\"/>
</panose>
<ulUnicodeRange1 value=\"00000000 00000000 11111111 11111111\"/>
<ulUnicodeRange2 value=\"00000000 00000000 11111111 11111111\"/>
<ulUnicodeRange3 value=\"00000000 00000000 00000011 11111111\"/>
<ulUnicodeRange4 value=\"00000000 00000000 00000000 00000000\"/>
<achVendID value=\"UNKN\"/>
<fsSelection value=\"00000000 01000000\"/>
<usFirstCharIndex value=\"0\"/>
<usLastCharIndex value=\"255\"/>
<sTypoAscender value=\"0\"/>
<sTypoDescender value=\"0\"/>
<sTypoLineGap value=\"0\"/>
<usWinAscent value=\"12\"/>
<usWinDescent value=\"0\"/>
<ulCodePageRange1 value=\"00000000 00000000 00000000 00000011\"/>
<ulCodePageRange2 value=\"00000000 00000000 00000000 00000000\"/>
</OS_2>
~a~a<loca>
</loca>
~a<name>
<namerecord nameID=\"1\" platformID=\"3\" platEncID=\"1\" langID=\"0x409\">
~a
</namerecord>
<namerecord nameID=\"8\" platformID=\"3\" platEncID=\"1\" langID=\"0x409\">
~a
</namerecord>
</name>
<post>
<formatType value=\"3.0\"/>
<italicAngle value=\"0.0\"/>
<underlinePosition value=\"0\"/>
<underlineThickness value=\"0\"/>
<isFixedPitch value=\"~a\"/>
<minMemType42 value=\"0\"/>
<maxMemType42 value=\"0\"/>
<minMemType1 value=\"0\"/>
<maxMemType1 value=\"0\"/>
</post>
</ttFont>
")

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
                 (fold
                   ;; draw a pixel using 4 strokes
                   (lambda (offsets acc)
                     (match offsets
                       ((x-offset y-offset)
                        (cons (format pt-template (+ x x-offset) (+ y y-offset)) acc))))
                   '() '((0 0) (1 0) (1 1) (0 1))))))

(define (bitmap->xml bounds bitmap)
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
                '() bitmap height))))))

(define (character->xml char)
  (match char
    ((properties bitmap)
     (format ttglyph-template
             (hash-table-ref properties "ENCODING")
             (if (null? bitmap) ""
                 (let ((bounds (hash-table-ref properties "BBX")))
                   (bitmap->xml bounds bitmap)))))))

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
