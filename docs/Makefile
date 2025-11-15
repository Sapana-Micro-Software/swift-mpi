# Makefile for building SwiftMPI documentation
# Copyright (C) 2025, Shyamal Suhana Chandra

LATEX = pdflatex
BIBTEX = bibtex
RM = rm -f

PAPER = paper
PRESENTATION = presentation

.PHONY: all paper presentation clean

all: paper presentation

paper: $(PAPER).pdf

presentation: $(PRESENTATION).pdf

$(PAPER).pdf: $(PAPER).tex
	$(LATEX) $(PAPER).tex
	-$(BIBTEX) $(PAPER)
	$(LATEX) $(PAPER).tex
	$(LATEX) $(PAPER).tex

$(PRESENTATION).pdf: $(PRESENTATION).tex
	$(LATEX) $(PRESENTATION).tex

clean:
	$(RM) *.aux *.log *.out *.toc *.nav *.snm *.bbl *.blg *.synctex.gz

cleanall: clean
	$(RM) *.pdf
