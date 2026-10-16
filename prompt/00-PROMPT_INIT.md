# Setup yuyyuy-projects

Root: /home/yuyyuy/Projects/yuyyuy-projects. Work only inside it. Do only what is written here, nothing extra. Run the steps in order without asking for confirmation. Keep reasoning to one or two sentences per step: do not restate this prompt.

Rules:
- Use bun for everything (bun add, bunx, bun run, bun test). Never use npm, npx, pnpm or yarn. If any command fails, stop and report the exact error. Never switch tools or work around it. The only exception is the CREATE DATABASE command in step 5, which may report that the database already exists.
- Use mkdir only for folders, never for files.
- Never write or edit package.json by hand (no write_file, no patch, no heredoc, no bun pm init). Only the commands in steps 1 to 3 produce it. If step 4 reports a MISMATCH, copy the matching line from this file and run it again. Never retype a name or version from memory.
- Never run bun add, bun install or bun pm outside /home/yuyyuy/Projects/yuyyuy-projects/server or /home/yuyyuy/Projects/yuyyuy-projects/client. Every bun add and bun pm pkg set command in steps 2 to 4 must be run as one single line that starts with its own cd into server or client, joined with &&, exactly as written in this file. Never run any of them from the root or rely on a cd from an earlier command.
- Only two commands may create a package.json: create-next-app (step 1, for the client) and the first bun add of step 2 (for the server). If server/package.json or client/package.json is missing at any later point, stop and report. Never create it yourself, by any method.
- The client is created by create-next-app (step 1). The server has no generator.
- Every source and config file, every .env file and every .gitkeep is produced by /home/yuyyuy/Projects/yuyyuy-projects/scripts/write-files.sh (step 6). Never create, edit or patch any of them yourself, and never use write_file or patch on them.
- Never type, copy or print any password. The scripts handle all credentials. Do not read or print .env files. Terminal output may mask secrets as `***`; that is display only, and `***` must never end up in any file.
- Never modify the postgres container, its roles, passwords, pg_hba.conf or any setting (no ALTER ROLE, no ALTER USER, no config edits, no restart). The only allowed database commands are the two in step 5. If the database cannot be reached, stop and report. Do not change credentials.
- The terminal tool rejects commands containing a standalone `&` (background jobs). That is why the server smoke test lives in scripts/run-smoke.sh. Never try to background anything yourself. The `&&` operator is allowed.
- Nothing extra: no additional dependencies (for example no @types/node on the server), no sample components, no placeholder source files, no extra .gitkeep.
- Never edit /home/yuyyuy/Projects/yuyyuy-projects/prompt/00-PROMPT_INIT.md, /home/yuyyuy/Projects/yuyyuy-projects/scripts/check-setup.mjs, /home/yuyyuy/Projects/yuyyuy-projects/scripts/write-files.sh or /home/yuyyuy/Projects/yuyyuy-projects/scripts/run-smoke.sh.
- REPORT.md is the only file you write yourself (steps 7b and 8b), in the shell. The list of generated files in it is produced by a shell command, never typed or edited by you. Never put passwords, tokens or .env contents in it.
- Git is used only in steps 8 and 8b, with exactly the commands written there. Never force push, never type or print a token or password, and never commit a .env file.
- Report honestly. A failed, skipped or missing test is reported as failed, skipped or missing. Never write "complete" or "green" unless every command in steps 7 and 8 exited 0.

## 0. Preflight

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
ls -A client server
ls /home/yuyyuy/Projects/package.json /home/yuyyuy/package.json package.json
test -f /home/yuyyuy/Projects/yuyyuy-projects/scripts/check-setup.mjs && echo check-setup-ok
test -f /home/yuyyuy/Projects/yuyyuy-projects/scripts/write-files.sh && echo write-files-ok
test -f /home/yuyyuy/Projects/yuyyuy-projects/scripts/run-smoke.sh && echo run-smoke-ok
docker ps --format '{{.Names}}' | grep -x postgres
bun --version
```

Required: client and server do not exist or are empty (bun edits the nearest package.json it finds upward, and create-next-app needs an empty folder), none of the three package.json paths exist, check-setup-ok, write-files-ok and run-smoke-ok are printed, and postgres is listed. If any of this is not true, stop and report.

## 1. Create the client

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
bunx create-next-app@16 client --ts --no-tailwind --biome --app --src-dir --import-alias "@/*" --use-bun --disable-git --empty --no-agents-md --yes
mkdir -p server
```

## 2. Install the server

Run each of the three commands below separately, exactly as written, each as one line.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/server && bun add @nodewave/prisma-ezfilter@^0.2.1 @prisma/adapter-pg@^7.10.0 @prisma/client@7 dotenv@^18.0.0 hono@^4.13.8 jsonwebtoken@^9.0.3 pg@^8.23.0 zod@^4.6.5
```

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/server && bun add -d @types/bun@^1.4.2 @types/jsonwebtoken@^9.0.10 @types/pg@^8.23.1 prisma@7 typescript@^7.0.2
```

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/server && bun pm pkg set name=yuyyuy-server type=module scripts.dev="bun --watch src/index.ts" scripts.start="bun src/index.ts" scripts.typecheck="tsc --noEmit" scripts.test="bun test" scripts.test:watch="bun test --watch" scripts.db:generate="prisma generate" scripts.db:migrate="prisma migrate dev" scripts.db:push="prisma db push" scripts.db:studio="prisma studio" scripts.smoke="bash scripts/smoke.sh" scripts.db:seed="bun run prisma/seed.ts" && bun pm pkg set private=true --json
```

## 3. Install the client (on top of the generated app)

Run each of the three commands below separately, exactly as written, each as one line.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/client && bun add @fontsource-variable/bricolage-grotesque@^5.3.0 @fontsource-variable/instrument-sans@^5.3.0 @hookform/resolvers@^5.9.1 @radix-ui/react-dialog@^1.1.23 @radix-ui/react-dropdown-menu@^2.1.24 @radix-ui/react-switch@^1.3.7 @radix-ui/react-tabs@^1.1.21 @tanstack/react-query@^5.103.1 axios@^1.20.0 class-variance-authority@^0.7.1 clsx@^2.1.1 lucide-react@^1.47.0 next@^16.3.5 react@^19.3.0 react-dom@^19.3.0 react-hook-form@^7.88.0 sonner@^2.0.8 tailwind-merge@^3.7.0 zod@^4.6.5 zustand@^5.0.15
```

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/client && bun add -d @biomejs/biome@^2.5.14 @commitlint/cli@^21.2.3 @commitlint/config-conventional@^21.2.3 @happy-dom/global-registrator@^20.14.5 @tailwindcss/postcss@^4.3.3 @testing-library/dom@^10.4.1 @testing-library/react@^16.3.3 @types/bun@^1.4.2 @types/node@^26.6.2 @types/react@^19.3.0 @types/react-dom@^19.3.0 husky@^9.1.7 postcss@^8.5.28 tailwindcss@^4.3.3 typescript@^7.0.2
```

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/client && bun pm pkg set name=yuyyuy-client version=0.1.0 scripts.dev="next dev" scripts.build="next build" scripts.start="next start" scripts.typecheck="tsc --noEmit" scripts.lint="biome lint ." scripts.format="biome format --write ." scripts.check="biome check ." scripts.test="bun test" scripts.prepare="cd .. && husky client/.husky || true"
```

## 3b. Root must stay clean

Run this exact command, unchanged. It must print `root-clean`. If it prints anything else, stop and report. Do not delete anything yourself.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
test ! -e package.json && test ! -e bun.lock && test ! -e node_modules && echo root-clean
```

## 4. Match dependencies and scripts

Do not compare by eye. Run this exact command, unchanged. It reads the bun add and bun pm pkg set lines of this file and checks, in both folders, the package name, every dependency range, every script, and the installed version of every package. It also fails if package.json, bun.lock or node_modules exist in the root. It must print ALL OK.

```bash
bun /home/yuyyuy/Projects/yuyyuy-projects/scripts/check-setup.mjs
```

If it prints MISMATCH lines, fix each one only by re-running the matching command from step 2 or 3, copied from this file including its leading cd, then run the check again. If a MISMATCH says package.json not found, or a ROOT line appears, stop and report instead. Never edit or create package.json by hand. Repeat until ALL OK. Do not substitute versions silently.

## 5. Database db_projects

```bash
docker exec postgres psql -U postgres -c 'CREATE DATABASE db_projects'
docker exec postgres psql -U postgres -tAc "SELECT datname FROM pg_database WHERE datname='db_projects'"
```

The second command must print db_projects. If the first says the database already exists, that is fine and you continue.

## 6. Folders, files and .env

Run this one command, unchanged. It creates the folders and .gitkeep files, writes every file of the project, creates server/.env, client/.env, patches the generated client files, and checks the result including a TCP login to the database.

```bash
bash /home/yuyyuy/Projects/yuyyuy-projects/scripts/write-files.sh
```

It must print `files-ok`, `tcp-auth-ok 1` and finish with `write-files: ALL OK`. If it fails or prints anything else, stop and report the exact error. Do not fix files by hand and do not touch the database.

## 7. Verify

Run both blocks. Every command must exit 0.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/server
bun test && bun run typecheck && bash /home/yuyyuy/Projects/yuyyuy-projects/scripts/run-smoke.sh
```

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects/client
bun test && bun run typecheck && bun run check && bun run build
```

If a command fails, run `bash /home/yuyyuy/Projects/yuyyuy-projects/scripts/write-files.sh` once more, then run the failing command once more. If it still fails, stop and report the exact error. Never change anything else.

## 7b. Write REPORT.md

Run `date +%F` first. Then run the block below as one block. Replace every placeholder after the colon inside the first heredoc with facts from the output you saw. Keep every other character exactly, including the leading `#`, `##` and `- `. The list of generated files is produced by the find command: never type it, edit it or replace it. No secrets, no .env contents.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
cat > REPORT.md <<'EOT'
# Project report

## 00 Setup
- Date: YYYY-MM-DD
- Step 3b root check: root-clean
- Step 4 mismatches found: none or the lines
- Step 5 database db_projects: created or already existed
- Step 6 write-files result: files-ok, tcp-auth-ok 1, write-files: ALL OK
- Server: bun test pass/fail with count, typecheck pass/fail, smoke pass/fail
- Client: bun test pass/fail with count, typecheck pass/fail, check pass/fail, build pass/fail
- Skipped, failed or missing: none or the list
- Commit and push: pending
- Generated files (paths relative to /home/yuyyuy/Projects/yuyyuy-projects, listed by the shell; node_modules, .next and .git are left out; .env files are listed by path only):
EOT
find . \( -name node_modules -o -name .git -o -name .next -o -name .hermes -o -name .agents -o -path ./prompt -o -path ./scripts \) -prune -o -type f ! -name REPORT.md ! -name skills-lock.json -print | LC_ALL=C sort | sed 's|^\./|  - |' >> REPORT.md
cat >> REPORT.md <<'EOT'

## 01 Agent skills
- Not run yet
EOT
grep -c '^## ' REPORT.md
grep -n 'YYYY-MM-DD\|none or\|pass/fail\|created or' REPORT.md || echo report-clean
```

The first grep must print 2 and the second must print report-clean. If not, run the block again. A failed or skipped item is written as failed or skipped. Never write "complete" unless every command in step 7 exited 0.

## 8. Commit and push

Git is used only here and in step 8b. First stage the files and run the checks. Run this block alone.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
test -d .git || git init
git add -A
git ls-files | grep -E '(^|/)\.env$' || echo env-clean
git ls-files package.json bun.lock | grep . || echo root-files-clean
```

Both env-clean and root-files-clean must be printed. If either check prints a path instead, stop and report without committing.

Only after that, run this second block. It is one chained line: if any part fails, nothing after it runs.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
git commit -m "chore: initial project setup with Hono server and Next.js client" && (git remote add origin git@github.com:yuyyuyswallowtail/yuyyuy-dashboard.git || git remote set-url origin git@github.com:yuyyuyswallowtail/yuyyuy-dashboard.git) && git branch -M main && git push -u origin main
```

If the commit fails, or the push is rejected or asks for credentials, stop and report the exact message.

## 8b. Record the commit in REPORT.md

Run this block only if the push in step 8 succeeded. Otherwise skip it and report that it was skipped and why.

```bash
cd /home/yuyyuy/Projects/yuyyuy-projects
HASH="$(git rev-parse --short HEAD)"
sed -i "s|^- Commit and push:.*|- Commit and push: $HASH pushed to origin/main|" REPORT.md
grep -n 'Commit and push' REPORT.md
git add REPORT.md
git commit -m "docs: record setup commit in report"
git push
```

The grep must show the hash. If the commit or push fails, stop and report the exact message. Do not force push.

## 9. Report

Report only: any mismatch found in step 4, the result of every command in step 7 (pass or fail, with test counts), the commit hash and push result from step 8, and anything you could not do. If anything failed, say so and do not claim completion.
