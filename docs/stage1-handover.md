# My Joe – Stage 1 Handover  
## Git, GitHub & Vercel (Staging)

**Stage:** 1  
**Name:** Git, GitHub & Vercel (Staging)  
**Owner:** Jamie  
**Local project root:** `C:\myjoe\myjoe-app`  
**GitHub repo:** `https://github.com/Pozzers/myjoe-app`  
**Default branch:** `main`  

**Staging host:** Vercel  
**Staging URL:** https://myjoe-app.vercel.app/

---

## 1. Stage 1 goals

- Initialise a local Git repository in `C:\myjoe\myjoe-app`.
- Create/connect a GitHub repository for the project.
- Use `main` as the primary branch and push all baseline code.
- Connect the GitHub repo to Vercel and deploy a staging environment:
  - Automatic deploys on push to `main`.
  - Reachable staging URL on Vercel.
- Add a Stage 1 verification script:
  - `tools/Verify-Stage1.ps1` that generates `stage1-report.txt`.

---

## 2. What was done (tick as you confirm)

### 2.1 Git & local repo

- [x] Local Git repo exists in `C:\myjoe\myjoe-app`.
- [x] `.git` directory present.
- [x] Default branch is `main`.
- [x] Stage 0 files (`docs\`, `tools\`, `stage0-report.txt`) are tracked in Git.

### 2.2 GitHub

- [x] GitHub repository created: `Pozzers/myjoe-app`.
- [x] Remote `origin` configured to `https://github.com/Pozzers/myjoe-app.git`.
- [x] `main` branch pushed to GitHub.
- [x] Repo visible at: `https://github.com/Pozzers/myjoe-app`.

### 2.3 Vercel (staging)

- [x] Vercel account created and logged in.
- [x] Vercel linked to GitHub account.
- [x] Project imported from `Pozzers/myjoe-app`.
- [x] Framework auto-detected as Next.js.
- [x] Automatic deploys from `main` branch enabled.
- [x] First deployment completed successfully.
- [x] Staging URL reachable in a browser.

**Staging URL:**  
`Staging URL: https://myjoe-app.vercel.app/`

### 2.4 Verification

- [ ] `tools\Verify-Stage1.ps1` exists.
- [ ] `.\tools\Verify-Stage1.ps1` runs without error.
- [ ] `stage1-report.txt` is generated in the project root.
- [ ] Report shows:
  - `.git` present.
  - Current branch is `main`.
  - `origin` points to `https://github.com/Pozzers/myjoe-app.git`.
  - Stage 1 handover file exists.
  - Staging URL is present in this handover file.
  - Staging URL is reachable (or a clear warning if not).

---

## 3. Key decisions

- **Version control:** Git used for all source control; `main` is the primary branch.
- **Remote hosting:** GitHub repository at `https://github.com/Pozzers/myjoe-app` is the single source of truth for the codebase.
- **Remote name:** Standard `origin` remote is used for the GitHub repo.
- **Deploy target (staging):** Vercel is the default staging host for My Joe’s Next.js app.
- **Branch deployment policy:** `main` is the branch that triggers staging deploys on Vercel (unless explicitly changed later).

---

## 4. Known issues / TODOs

Use this section to record anything not fully done or any oddities.

Examples (edit/remove as needed):

- [ ] Any environment variables still missing (Supabase, Resend, OpenAI – future stages).
- [ ] Any warnings in `stage1-report.txt` that need to be fixed.

Notes:

- Before treating Stage 1 as fully done, all the items under **2.3 Vercel (staging)** and **2.4 Verification** should ideally be ticked.

---

## 5. How Stage 2 should treat Stage 1

- Assume:
  - Codebase lives in `Pozzers/myjoe-app` on GitHub.
  - `main` is always deployable (green) unless noted otherwise.
  - `https://myjoe-app.vercel.app/` is the canonical staging URL.
- Do **not**:
  - Rename `main` or change the `origin` URL without updating:
    - This file (`docs\stage1-handover.md`)
    - `tools\Verify-Stage1.ps1`
  - Change the Vercel project or staging URL without updating this handover and the Stage 1 verification script.
- Before major changes in Stage 2:
  - Run `.\tools\Verify-Stage1.ps1` and confirm a clean `stage1-report.txt`.
  - Fix any `[FAIL]` or important `[WARN]` in that report.

---

## 6. Quick verification steps before starting Stage 2

1. In PowerShell:

   ```powershell
   Set-Location "C:\myjoe\myjoe-app"
   .\tools\Verify-Stage1.ps1
