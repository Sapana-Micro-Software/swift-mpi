# GitHub Pages Deployment Guide

This guide will help you deploy the SwiftMPI project page to GitHub Pages.

## Prerequisites

- A GitHub repository (e.g., `swift-mpi`)
- Git installed on your local machine
- PDF files generated (`paper.pdf`, `presentation.pdf`, `reference.pdf`)

## Deployment Steps

### Option 1: Automatic Deployment with GitHub Actions (Recommended)

1. **Ensure all files are committed:**
   ```bash
   cd docs
   git add .
   git commit -m "Add project page with Jekyll support"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Navigate to **Settings** → **Pages**
   - Under **Source**, select **GitHub Actions**
   - The workflow will automatically deploy on every push to `main` or `master`

3. **Verify deployment:**
   - After pushing, go to **Actions** tab in your repository
   - Wait for the workflow to complete (usually 1-2 minutes)
   - Your site will be available at: `https://[username].github.io/[repository-name]`

### Option 2: Manual Deployment (Alternative)

If you prefer to use the `gh-pages` branch method:

1. **Install Jekyll locally:**
   ```bash
   cd docs
   bundle install
   ```

2. **Build the site:**
   ```bash
   bundle exec jekyll build
   ```

3. **Deploy to gh-pages branch:**
   ```bash
   git checkout --orphan gh-pages
   git rm -rf .
   cp -r _site/* .
   git add .
   git commit -m "Deploy to GitHub Pages"
   git push origin gh-pages
   ```

4. **Enable GitHub Pages:**
   - Go to **Settings** → **Pages**
   - Select **Deploy from a branch**
   - Choose `gh-pages` branch and `/ (root)` folder

## Configuration

### Update Repository URL

If your repository is not at the root of your GitHub Pages site, update `_config.yml`:

```yaml
url: "https://yourusername.github.io"
baseurl: "/repository-name"  # Leave empty if repository is at root
```

### Update GitHub Link

Update the GitHub repository link in `index.html` (around line 650):

```html
<a href="https://github.com/yourusername/swift-mpi" class="code-link" target="_blank">
```

## File Structure

```
docs/
├── index.html              # Main project page
├── _config.yml             # Jekyll configuration
├── Gemfile                 # Jekyll dependencies
├── .gitignore              # Git ignore rules
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions workflow
├── paper.pdf               # Research paper
├── presentation.pdf        # Presentation slides
├── reference.pdf           # API reference
└── DEPLOYMENT.md           # This file
```

## Troubleshooting

### PDFs not showing
- Ensure PDF files are committed to the repository
- Check that PDFs are in the `docs/` directory
- Verify file names match exactly: `paper.pdf`, `presentation.pdf`, `reference.pdf`

### Site not updating
- Clear browser cache
- Check GitHub Actions logs for errors
- Verify `_config.yml` settings

### Build errors
- Ensure `Gemfile` is present and committed
- Check Ruby version compatibility
- Review GitHub Actions logs

## Quick Deploy Commands

```bash
# Navigate to docs directory
cd docs

# Add all files
git add .

# Commit changes
git commit -m "Deploy SwiftMPI project page to GitHub Pages"

# Push to trigger deployment
git push origin main
```

After pushing, GitHub Actions will automatically build and deploy your site!

## Support

For issues or questions:
- Check GitHub Actions logs
- Review Jekyll documentation: https://jekyllrb.com/docs/
- GitHub Pages documentation: https://docs.github.com/en/pages
