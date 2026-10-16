#!/bin/bash
set -uo pipefail
ROOT=/home/yuyyuy/Projects/yuyyuy-projects
cd "$ROOT" || exit 1
test -d .git || { echo "no .git in $ROOT"; exit 1; }
test -f client/package.json || { echo "client missing, run 00 first"; exit 1; }
test -f server/package.json || { echo "server missing, run 00 first"; exit 1; }

SKILLS=(
  "https://github.com/vercel-labs/skills|find-skills"
  "https://github.com/anthropics/skills|frontend-design"
  "https://github.com/vercel-labs/agent-skills|vercel-react-best-practices"
  "https://github.com/vercel-labs/agent-skills|vercel-composition-patterns"
  "https://github.com/shadcn-ui/ui|shadcn"
  "https://github.com/wshobson/agents|typescript-advanced-types"
  "https://github.com/anthropics/skills|webapp-testing"
  "https://github.com/wshobson/agents|tailwind-design-system"
  "https://github.com/vercel/turborepo|turborepo"
  "https://github.com/affaan-m/ecc|nextjs-turbopack"
  "https://github.com/wshobson/agents|nextjs-app-router-patterns"
  "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill|ui-ux-pro-max"
  "https://github.com/vercel-labs/agent-skills|vercel-react-view-transitions"
  "https://github.com/prisma/skills|prisma-client-api"
  "https://github.com/prisma/skills|prisma-cli"
  "https://github.com/prisma/skills|prisma-driver-adapter-implementation"
  "https://github.com/prisma/skills|prisma-postgres-setup"
  "https://github.com/honojs/skills|hono"
  "https://github.com/giuseppe-trisciuoglio/developer-kit|nextjs-authentication"
  "https://github.com/wshobson/agents|auth-implementation-patterns"
)

GLOBAL_DIR="$HOME/.hermes/skills"
before="$(ls -A "$GLOBAL_DIR" 2>/dev/null | sort | md5sum)"

installed() {
  [ -f ".hermes/skills/$1/SKILL.md" ] || [ -f ".agents/skills/$1/SKILL.md" ]
}

FAILED=()
for entry in "${SKILLS[@]}"; do
  repo="${entry%%|*}"
  skill="${entry##*|}"
  echo "== $skill"
  ok=0
  for attempt in 1 2 3; do
    bunx skills add "$repo" --skill "$skill" -a hermes-agent -y < /dev/null
    if installed "$skill"; then ok=1; break; fi
    echo "retry $skill (attempt $attempt failed)"
    sleep 3
  done
  [ "$ok" -eq 1 ] || FAILED+=("$skill")
done

after="$(ls -A "$GLOBAL_DIR" 2>/dev/null | sort | md5sum)"
if [ "$before" = "$after" ]; then
  echo "global-skills-unchanged"
else
  echo "global-skills-CHANGED: $GLOBAL_DIR differs from before, check manually"
fi

RC=0
if [ ${#FAILED[@]} -gt 0 ]; then
  printf 'INSTALL-FAILED %s\n' "${FAILED[@]}"
  RC=1
fi
bash /home/yuyyuy/Projects/yuyyuy-projects/scripts/check-skills.sh || RC=1
exit $RC
