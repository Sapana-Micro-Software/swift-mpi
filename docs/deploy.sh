#!/bin/bash

# SwiftMPI GitHub Pages Deployment Script
# This script helps you deploy the SwiftMPI project page to GitHub Pages

set -e

echo "🚀 SwiftMPI GitHub Pages Deployment"
echo "===================================="
echo ""

# Check if we're in the docs directory
if [ ! -f "index.html" ] || [ ! -f "_config.yml" ]; then
    echo "❌ Error: Please run this script from the docs/ directory"
    exit 1
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Please initialize git first."
    exit 1
fi

# Check if PDFs exist
if [ ! -f "paper.pdf" ] || [ ! -f "presentation.pdf" ] || [ ! -f "reference.pdf" ]; then
    echo "⚠️  Warning: Some PDF files are missing. Make sure to build them first with 'make all'"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📦 Staging files..."
git add index.html _config.yml Gemfile .gitignore .github/ DEPLOYMENT.md deploy.sh

# Add PDFs if they exist
if [ -f "paper.pdf" ]; then
    git add paper.pdf
fi
if [ -f "presentation.pdf" ]; then
    git add presentation.pdf
fi
if [ -f "reference.pdf" ]; then
    git add reference.pdf
fi

echo ""
echo "📝 Files staged. Please review the changes:"
git status

echo ""
read -p "Commit and push to GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "💾 Committing changes..."
    git commit -m "Deploy SwiftMPI project page to GitHub Pages

- Add Jekyll-compatible HTML project page
- Include dynamic JavaScript menus
- Add SVG graphics and animations
- Include benchmarks comparison with MPICH
- Add GitHub Actions workflow for automatic deployment
- Include PDF links for paper, presentation, and reference"

    echo ""
    echo "📤 Pushing to GitHub..."
    git push origin main || git push origin master

    echo ""
    echo "✅ Deployment initiated!"
    echo ""
    echo "Next steps:"
    echo "1. Go to your repository on GitHub"
    echo "2. Navigate to Settings → Pages"
    echo "3. Under Source, select 'GitHub Actions'"
    echo "4. Wait for the workflow to complete (check Actions tab)"
    echo "5. Your site will be live at: https://[username].github.io/[repository-name]"
    echo ""
else
    echo ""
    echo "⏸️  Deployment cancelled. Files are staged but not committed."
    echo "Run 'git commit' and 'git push' manually when ready."
fi
