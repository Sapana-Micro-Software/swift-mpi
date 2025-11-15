# SwiftMPI Documentation

**Copyright (C) 2025, Shyamal Suhana Chandra**

This directory contains documentation for the SwiftMPI framework.

## Contents

- **`paper.tex`**: LaTeX source for the SwiftMPI research paper
- **`presentation.tex`**: Beamer presentation source for talks and demos
- **`reference.tex`**: API reference with usage examples for all SwiftMPI functions
- **`Makefile`**: Build script for generating PDFs

## Building Documentation

### Prerequisites

You need a LaTeX distribution installed:

- **macOS**: Install [MacTeX](https://www.tug.org/mactex/)
- **Linux**: Install `texlive-full` or `texlive-latex-extra`
- **Windows**: Install [MiKTeX](https://miktex.org/) or [TeX Live](https://www.tug.org/texlive/)

### Building

#### Using Makefile (Recommended)

```bash
# Build all documentation (paper, presentation, and reference)
make all

# Build only the paper
make paper

# Build only the presentation
make presentation

# Build only the reference
make reference

# Clean generated files
make clean

# Clean everything including PDFs
make cleanall
```

#### Manual Build

**Paper:**
```bash
pdflatex paper.tex
bibtex paper
pdflatex paper.tex
pdflatex paper.tex
```

**Presentation:**
```bash
pdflatex presentation.tex
```

**Reference:**
```bash
pdflatex reference.tex
```

## Paper

The paper (`paper.tex`) describes:
- Architecture and design principles
- Implementation details
- Performance characteristics
- Use cases and examples
- Future work

## Presentation

The Beamer presentation (`presentation.tex`) includes:
- Overview and motivation
- Architecture overview
- Features and capabilities
- Usage examples
- Performance benchmarks
- Future roadmap

## Reference

The API reference (`reference.tex`) provides:
- Complete function reference for all SwiftMPI operations
- Usage examples for each function
- Point-to-point communication examples
- Collective operation examples
- Non-blocking communication examples
- Datatype and operation references
- Error handling examples
- Complete working examples

## Output Files

After building, you'll get:
- `paper.pdf`: The research paper
- `presentation.pdf`: The Beamer presentation
- `reference.pdf`: The API reference manual

## Notes

- The LaTeX files use standard packages available in most distributions
- For the presentation, ensure you have the `beamer` class installed
- The paper uses standard bibliography format (BibTeX)
- Both documents use syntax highlighting for Swift code via `listings` package
