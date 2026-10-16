#!/bin/bash
set -euo pipefail
ROOT=/home/yuyyuy/Projects/yuyyuy-projects
cd "$ROOT"
test -f client/src/app/layout.tsx || { echo "client not created, run steps 1 to 3 first"; exit 1; }
test -d server/node_modules || { echo "server deps not installed, run step 2 first"; exit 1; }

mkdir -p server/src/config server/src/middlewares server/src/modules/health server/src/utils server/prisma server/scripts server/tests
mkdir -p client/src/components/ui client/src/components/shared client/src/features client/src/hooks client/src/lib client/src/providers client/src/stores client/src/styles client/src/types client/tests
for d in server/src/middlewares server/src/utils server/prisma client/src/components/ui client/src/components/shared client/src/features client/src/hooks client/src/providers client/src/stores client/src/types; do touch "$d/.gitkeep"; done

cat > .gitignore <<'EOF'
node_modules
.env
.next
dist
EOF

cat > server/.env.example <<'EOF'
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/db_projects
JWT_SECRET=change-me
PORT=3001
EOF

cat > server/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "Preserve",
    "moduleResolution": "bundler",
    "lib": ["ESNext"],
    "types": ["bun"],
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "esModuleInterop": true
  },
  "include": ["src", "tests", "prisma"]
}
EOF

cat > server/src/config/env.ts <<'EOF'
import { z } from "zod";

const schema = z.object({
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(1),
  PORT: z.coerce.number().default(3001),
});

export const env = schema.parse(process.env);
EOF

cat > server/src/modules/health/schema.ts <<'EOF'
import { z } from "zod";

export const healthResponse = z.object({
  status: z.literal("ok"),
});

export type HealthResponse = z.infer<typeof healthResponse>;
EOF

cat > server/src/modules/health/service.ts <<'EOF'
import { type HealthResponse, healthResponse } from "./schema";

export function getHealth(): HealthResponse {
  return healthResponse.parse({ status: "ok" });
}
EOF

cat > server/src/modules/health/routes.ts <<'EOF'
import { Hono } from "hono";
import { getHealth } from "./service";

export const healthRoutes = new Hono().get("/", (c) => c.json(getHealth()));
EOF

cat > server/src/app.ts <<'EOF'
import { Hono } from "hono";
import { healthRoutes } from "./modules/health/routes";

const app = new Hono();

app.route("/health", healthRoutes);

export default app;
EOF

cat > server/src/index.ts <<'EOF'
import app from "./app";
import { env } from "./config/env";

export default {
  port: env.PORT,
  fetch: app.fetch,
};
EOF

cat > server/scripts/smoke.sh <<'EOF'
#!/bin/sh
curl -f http://localhost:3001/health
EOF

cat > server/tests/health.test.ts <<'EOF'
import { expect, test } from "bun:test";
import app from "../src/app";

test("GET /health returns 200 and status ok", async () => {
  const res = await app.request("/health");
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ status: "ok" });
});
EOF

cat > server/tests/stack.test.ts <<'EOF'
import { expect, test } from "bun:test";
import { Client } from "pg";
import { z } from "zod";
import { env } from "../src/config/env";

test("zod 4 parses a valid and an invalid object", () => {
  const schema = z.object({ email: z.email(), age: z.number().int() });
  expect(schema.safeParse({ email: "a@b.co", age: 20 }).success).toBe(true);
  expect(schema.safeParse({ email: "nope", age: 1.5 }).success).toBe(false);
});

test("database answers SELECT 1", async () => {
  const client = new Client({ connectionString: env.DATABASE_URL });
  await client.connect();
  const res = await client.query("SELECT 1 AS ok");
  await client.end();
  expect(res.rows[0].ok).toBe(1);
});
EOF

cat > client/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "types": ["bun"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    ".next/dev/types/**/*.ts",
    "**/*.mts"
  ],
  "exclude": ["node_modules"]
}
EOF

cat > client/postcss.config.mjs <<'EOF'
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
EOF

cat > client/src/styles/globals.css <<'EOF'
@import "tailwindcss";
EOF

cat > client/src/lib/utils.ts <<'EOF'
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

cat > client/src/lib/api.ts <<'EOF'
import axios from "axios";

export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001",
});
EOF

cat > client/.env.example <<'EOF'
NEXT_PUBLIC_API_URL=http://localhost:3001
EOF

[ -f client/.env ] || cp client/.env.example client/.env

cat > client/bunfig.toml <<'EOF'
[test]
preload = ["./tests/setup.ts"]
EOF

cat > client/tests/setup.ts <<'EOF'
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
EOF

cat > client/tests/stack.test.tsx <<'EOF'
import { expect, test } from "bun:test";
import { render, screen } from "@testing-library/react";
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import { z } from "zod";

test("happy-dom is registered", () => {
  expect(typeof document).toBe("object");
});

test("zod 4, clsx, tailwind-merge", () => {
  expect(z.email().safeParse("a@b.co").success).toBe(true);
  expect(z.email().safeParse("nope").success).toBe(false);
  expect(clsx("a", false, "b")).toBe("a b");
  expect(twMerge("p-2 p-4")).toBe("p-4");
});

test("renders a component", () => {
  render(<p>Hello</p>);
  expect(screen.getByText("Hello")).toBeTruthy();
});
EOF

JWT="$(bun -e 'console.log(crypto.randomUUID())')"
printf 'DATABASE_URL=postgresql://postgres:postgres@localhost:5432/db_projects\nJWT_SECRET=%s\nPORT=3001\n' "$JWT" > server/.env

(
  cd client
  grep -q 'styles/globals.css' src/app/layout.tsx || sed -i '1a import "@/styles/globals.css";' src/app/layout.tsx
  grep -q '^!.env.example' .gitignore || printf '\n!.env.example\n' >> .gitignore
  sed -i 's|"\$schema": "[^"]*"|"$schema": "./node_modules/@biomejs/biome/configuration_schema.json"|' biome.json
  bunx biome migrate --write
)

grep -q '^DATABASE_URL=postgresql://postgres:postgres@localhost:5432/db_projects$' server/.env
grep -q '^DATABASE_URL=postgresql://postgres:postgres@localhost:5432/db_projects$' server/.env.example
grep -q '^JWT_SECRET=change-me$' server/.env.example
if grep -rq '\*\*\*' server/.env server/.env.example client/.env.example; then echo "masking found in env files"; exit 1; fi
grep -q '"types": \["bun"\]' server/tsconfig.json
grep -q '"types": \["bun"\]' client/tsconfig.json
grep -q 'styles/globals.css' client/src/app/layout.tsx
grep -q '^NEXT_PUBLIC_API_URL=http://localhost:3001$' client/.env
grep -q '^PORT=3001$' server/.env
grep -q '^PORT=3001$' server/.env.example
diff <(cut -d= -f1 server/.env) <(cut -d= -f1 server/.env.example) || { echo "server env keys differ"; exit 1; }
diff <(cut -d= -f1 client/.env) <(cut -d= -f1 client/.env.example) || { echo "client env keys differ"; exit 1; }
echo "files-ok"

cd server
DBURL="$(grep '^DATABASE_URL=' .env | cut -d= -f2-)"
DATABASE_URL="$DBURL" bun -e '(async () => { const { Client } = require("pg"); const c = new Client({ connectionString: process.env.DATABASE_URL }); await c.connect(); const r = await c.query("SELECT 1 AS ok"); await c.end(); console.log("tcp-auth-ok", r.rows[0].ok); })().catch((e) => { console.error(e.message); process.exit(1); });'

echo "write-files: ALL OK"
