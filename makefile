build:
	dmd GTeXT.d parser.d loadcmap.d pdfObjectClass.d fontanalyzer.d
quick:
	dmd GTeXT.d parser.d loadcmap.d pdfObjectClass.d fontanalyzer.d
	./GTeXT
run:
	./GTeXT
open:
	open ./output.pdf
