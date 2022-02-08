(define contour-template "\
<contour>
~a
</contour>
")

(define pt-template "\
<pt x=\"~a\" y=\"~a\" on=\"1\"/>
")

(define glyphorder-template "\
<GlyphOrder>
~a
</GlyphOrder>
")

(define glyphid-template "\
<GlyphID id=\"~a\" name=\"char~a\"/>
")

(define hmtx-template "\
<hmtx>
~a
</hmtx>
")

(define mtx-template "\
<mtx width=\"~a\" lsb=\"~a\" name=\"char~a\"/>
")

(define cmap-template "\
<cmap>
<tableVersion version=\"0\"/>
<cmap_format_4 platformID=\"3\" platEncID=\"1\" language=\"0\">
~a
</cmap_format_4>\n</cmap>
")

(define map-template "\
<map code=\"0x~a\" name=\"char~a\"/>
")

(define glyf-template "\
<glyf>
~a
</glyf>
")

(define ttglyph-template "\
<TTGlyph name=\"char~a\">
~a
<instructions>
<assembly/>
</instructions>
</TTGlyph>
")

(define ttx-template "\
<?xml version=\"1.0\" ?>
<ttFont sfntVersion=\"\\x00\\x01\\x00\\x00\" ttLibVersion=\"4.2\">
~a
<head>
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
~a~a
<loca>
</loca>
~a
<name>
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
