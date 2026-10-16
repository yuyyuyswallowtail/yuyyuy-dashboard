#!/bin/bash
cd /home/yuyyuy/Projects/yuyyuy-projects || exit 1

EXPECTED=(
  find-skills
  frontend-design
  vercel-react-best-practices
  vercel-composition-patterns
  shadcn
  typescript-advanced-types
  webapp-testing
  tailwind-design-system
  turborepo
  nextjs-turbopack
  nextjs-app-router-patterns
  ui-ux-pro-max
  vercel-react-view-transitions
  prisma-client-api
  prisma-cli
  prisma-driver-adapter-implementation
  prisma-postgres-setup
  hono
  nextjs-authentication
  auth-implementation-patterns
)

MISSING=()
for n in "${EXPECTED[@]}"; do
  if [ -f ".hermes/skills/$n/SKILL.md" ] || [ -f ".agents/skills/$n/SKILL.md" ]; then
    :
  else
    MISSING+=("$n")
  fi
done

echo "expected=${#EXPECTED[@]} missing=${#MISSING[@]}"

if [ ${#MISSING[@]} -gt 0 ]; then
  printf 'MISSING %s\n' "${MISSING[@]}"
  echo "--- .hermes/skills:"
  ls -A .hermes/skills 2>/dev/null
  echo "--- .agents/skills:"
  ls -A .agents/skills 2>/dev/null
  exit 1
fi

[ -d .hermes/skills ] && echo "external-dir: $PWD/.hermes/skills"
[ -d .agents/skills ] && echo "external-dir: $PWD/.agents/skills"
echo "check-skills: ALL OK"
