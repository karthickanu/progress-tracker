# Progress Tracker

Progress Tracker is a static GitHub Pages app. GitHub Pages serves the interface; Supabase provides invite-only sign-in, shared checklist data, and private storage for original spreadsheet files. The exported `.xlsx` includes every worksheet from each uploaded workbook, with checklist status and update details added to the worksheet being tracked.

GitHub Pages sites are public. The app’s spreadsheet data is kept in Supabase and requires an invited, signed-in team account. Keep local uploads and tracker state out of the GitHub repository.

## One-time setup

### 1. Create the Supabase project

Create a Supabase project, open its SQL Editor, and run [`supabase/setup.sql`](supabase/setup.sql). The SQL creates the tracker tables, private upload bucket, and policies that allow signed-in team members to share the workspace.

In Supabase Authentication settings:

1. Turn off public sign-ups so only invited people can enter the workspace.
2. Invite team members under Authentication → Users. They sign in with an email link; each invitee must use an email address that can receive mail.
3. Set the Site URL to your published GitHub Pages URL and add that same URL to the allowed redirect URLs. The exact URL is shown in the repository’s Pages settings after the first deployment.
4. Configure a team SMTP provider for reliable sign-in emails before sharing the app broadly.

Find the project URL and the public anon/publishable key in the Supabase project API settings. The website needs only those public client values. **Never put a Supabase `service_role` key in this app or in GitHub.** Row-level security protects the data; the key alone does not grant access.

### 2. Put the app files in a GitHub repository

Create a repository and put the contents of this folder at the repository root, including `.github/workflows/`. Keep the repository’s `data/` folder out of Git; it contains local tracker data and is excluded by `.gitignore`. The Pages workflow publishes only `index.html` and generated `config.js`, never the Python server or local data.

In the repository, open **Settings → Secrets and variables → Actions → Variables** and add:

- `SUPABASE_URL` — the project URL
- `SUPABASE_ANON_KEY` — the public anon/publishable key

Then open **Settings → Pages** and select **GitHub Actions** as the source. Push to the `main` or `master` branch; [`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml) builds and deploys the site.

The local `config.js` is an empty placeholder. GitHub Actions generates the deployed configuration from the repository variables, so no backend credentials need to be committed.

## Using the app

Team members sign in from their invitation email, upload `.xlsx`, `.xlsm`, or `.csv` files, and check tasks off together. Spreadsheet files are stored in the private Supabase bucket. Each task’s checked state, updater, and timestamp are saved in the shared database. The app refreshes shared progress every few seconds.

Import reads the first worksheet as the checklist. Export downloads one `.xlsx` containing every worksheet from all uploaded workbooks, and adds **Checklist status**, **Checked by**, and **Last updated** columns to each tracked worksheet. CSV files are included as worksheets in the exported workbook.

## Existing local data

The checklist currently in the local app is still only in `data/state.json`. This GitHub version does not upload it automatically. After the site and Supabase project are configured, sign in and import the spreadsheet into the shared workspace. This sends that file to your Supabase project’s private storage and its checklist rows to the project database.

## Local preview

The GitHub Pages site is static, but the cloud features require a configured Supabase project. To preview it locally, set `supabaseUrl` and `supabaseAnonKey` in `config.js`, then serve this folder over HTTP. Do not use a service-role key in `config.js`.
