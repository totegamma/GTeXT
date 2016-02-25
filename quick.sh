#!/bin/sh
dmd GTeXT.d parser.d loadcmap.d pdfObjectClass.d fontanalyzer.d
./GTeXT
open ./output.pdf
