# Security Fix Instructions

## Problem
The following sensitive files were accidentally committed to the repository:
- `.env` (contains secrets)
- `backend/serviceAccountKey.json` (Firebase credentials)

## Solution

### Option 1: Using BFG Repo-Cleaner (Recommended)

1. **Download BFG Repo-Cleaner:**
   
```
bash
   # Download the jar file
   wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
   
   # Or using curl
   curl -L -o bfg.jar https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
   
```

2. **Run BFG to remove the sensitive files:**
   
```bash
   # Clone your repository (if not already cloned)
   git clone --mirror your-repo-url
   cd your-repo.git

   # Run BFG to delete files matching the pattern
   java -jar bfg.jar --delete-files ".env"
   java -jar bfg.jar --delete-files "serviceAccountKey.json"

   # Or delete everything except history
   java -jar bfg.jar --delete-folders ".git"
   java -jar bfg.jar --delete-files "*.json"  # If needed

   # Push changes back
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   git push --force
   
```

### Option 2: Using git-filter-repo (Modern approach)

1. **Install git-filter-repo:**
   
```
bash
   pip install git-filter-repo
   
```

2. **Remove sensitive files from history:**
   
```
bash
   # Clone your repository
   git clone --bare your-repo-url
   cd your-repo.git

   # Remove the files from history
   git filter-repo --path .env --invert-paths
   git filter-repo --path backend/serviceAccountKey.json --invert-paths

   # Push changes
   git push --force --all
   
```

### Option 3: Manual Git History Rewrite (Step by Step)

1. **Remove from current commit:**
   
```
bash
   # Remove the files from the working directory
   rm .env
   rm backend/serviceAccountKey.json

   # Update .gitignore to prevent future commits
   echo ".env" >> .gitignore
   echo "backend/serviceAccountKey.json" >> .gitignore
   echo "*.json" | grep -v ".gitignore" >> .gitignore  # Optional: ignore all json files in backend

   # Commit the changes
   git add .gitignore
   git commit -m "Remove sensitive files and update gitignore"

   # Push
   git push origin main
   
```

2. **For historical commits (if already pushed):**
   
```
bash
   # Use git filter-branch (older method)
   git filter-branch --tree-filter 'rm -f .env' HEAD
   git filter-branch --tree-filter 'rm -f backend/serviceAccountKey.json' HEAD

   # Or use git rebase
   git rebase -i HEAD~10  # Adjust the number of commits
   # In the interactive editor, mark commits for editing and remove the files
   
```

## Important: After Removal

1. **Create fresh credentials:**
   
```
bash
   # Generate new .env file
   cp backend/.env.example backend/.env
   # Edit backend/.env with new secrets

   # Download new Firebase service account key from Firebase Console
   # Save as backend/serviceAccountKey.json (add to .gitignore)
   
```

2. **Verify .gitignore contains:**
   
```
   .env
   backend/serviceAccountKey.json
   node_modules/
   *.log
   
```

3. **Test that sensitive data is no longer in history:**
   
```
bash
   git log --all --full-history -- "**/.env"
   git log --all --full-history -- "**/serviceAccountKey.json"
   # These should return empty if successfully removed
   
```

## Create .env.example Template

Create `backend/.env.example` with placeholder values:

```
env
# Server Configuration
PORT=5000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your_jwt_secret_here_change_in_production

# Firebase Configuration (replace with your own)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your_private_key_here
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
```

## Summary

After completing these steps:
1. Sensitive files will be removed from Git history
2. .env.example will serve as a template for developers
3. .gitignore will prevent future accidental commits
4. Fresh credentials should be generated for production
