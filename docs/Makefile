# Makefile for building SwiftMPI documentation
# Copyright (C) 2025, Shyamal Suhana Chandra

LATEX = pdflatex
BIBTEX = bibtex
RM = rm -f

PAPER = paper
PRESENTATION = presentation
REFERENCE = reference

.PHONY: all paper presentation reference clean

all: paper presentation reference

paper: $(PAPER).pdf

presentation: $(PRESENTATION).pdf

reference: $(REFERENCE).pdf

$(PAPER).pdf: $(PAPER).tex
	$(LATEX) $(PAPER).tex
	-$(BIBTEX) $(PAPER)
	$(LATEX) $(PAPER).tex
	$(LATEX) $(PAPER).tex

$(PRESENTATION).pdf: $(PRESENTATION).tex
	$(LATEX) $(PRESENTATION).tex

$(REFERENCE).pdf: $(REFERENCE).tex
	$(LATEX) $(REFERENCE).tex

clean:
	$(RM) *.aux *.log *.out *.toc *.nav *.snm *.bbl *.blg *.synctex.gz

cleanall: clean
	$(RM) *.pdf
