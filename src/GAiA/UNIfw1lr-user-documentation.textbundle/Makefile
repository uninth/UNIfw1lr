#
# Makefile til UNIfw1lr dokumentation
#
rev = "$Revision: 1.2 $"

css	=	assets/CSS/GitHub-ReadMe.css
css	=	assets/CSS/i2-Book.css

all: bundle UNIfw1lr.pdf

bundle: UNIfw1lr.html
	/bin/rm -fr UNIfw1lr-documentation
	mkdir UNIfw1lr-documentation
	cp -r UNIfw1lr.html assets UNIfw1lr-documentation
	@tar cvfpz UNIfw1lr-doc.tgz UNIfw1lr-documentation
	/bin/rm -fr UNIfw1lr-documentation
	ls -l UNIfw1lr-doc.tgz

UNIfw1lr.html: UNIfw1lr.md Makefile
	@./mk.sh $(css) UNIfw1lr.md > UNIfw1lr.html

UNIfw1lr-body.pdf: UNIfw1lr.md UNIfw1lr.html
	wkhtmltopdf toc UNIfw1lr.html --footer-line --enable-internal-links --footer-spacing 2 --footer-right 'page [page] of [topage]'  UNIfw1lr-body.pdf

coverpage.pdf: UNIfw1lr-coverpage.pdf
	cp UNIfw1lr-coverpage.pdf coverpage.pdf

UNIfw1lr.pdf: coverpage.pdf UNIfw1lr-body.pdf
	pdfunite coverpage.pdf UNIfw1lr-body.pdf UNIfw1lr.pdf
