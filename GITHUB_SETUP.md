# GitHub Setup

This workspace already has a local Git repository. It does not have a GitHub remote yet.

## Recommended first push

Run these commands from `C:\Users\User\Documents\Playground` after you create an empty repository on GitHub:

```powershell
git branch -M main
git add starter-web-app GITHUB_SETUP.md
git commit -m "Add starter web app"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

## If GitHub asks you to sign in

- Sign in with your GitHub username in the browser flow
- Use a personal access token if Git prompts for a password in the terminal

## If you already added a remote by mistake

```powershell
git remote set-url origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
```
