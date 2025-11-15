# Quick Deploy to GitHub Pages

## Fastest Method (3 Commands)

```bash
cd docs
git add .
git commit -m "Deploy SwiftMPI project page to GitHub Pages"
git push origin main
```

Then:
1. Go to your GitHub repository
2. **Settings** → **Pages** → Select **GitHub Actions** as source
3. Wait 1-2 minutes for deployment
4. Visit: `https://[username].github.io/[repository-name]`

## Or Use the Deployment Script

```bash
cd docs
./deploy.sh
```

## What Gets Deployed

- ✅ `index.html` - Main project page
- ✅ `_config.yml` - Jekyll configuration  
- ✅ `.github/workflows/deploy.yml` - GitHub Actions workflow
- ✅ `paper.pdf`, `presentation.pdf`, `reference.pdf` - Documentation PDFs
- ✅ All supporting files

## After First Deployment

The GitHub Actions workflow will automatically deploy on every push to `main` or `master` branch.
