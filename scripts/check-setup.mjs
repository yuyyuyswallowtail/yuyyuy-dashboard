import { existsSync } from "node:fs";

const root = "/home/yuyyuy/Projects/yuyyuy-projects";
const lines = (await Bun.file(root + "/prompt/00-PROMPT_INIT.md").text()).split("\n");
const exp = { server: { dep: {}, dev: {}, scripts: {}, name: "" }, client: { dep: {}, dev: {}, scripts: {}, name: "" } };

const splitSpec = (s) => {
  const i = s.lastIndexOf("@");
  return i > 0 ? [s.slice(0, i), s.slice(i + 1)] : [s, ""];
};

// Split a command line on && but only outside double quotes,
// so values like scripts.prepare="cd .. && husky ..." stay in one piece.
const splitAnd = (s) => {
  const parts = [];
  let buf = "";
  let inQuote = false;
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (ch === '"') inQuote = !inQuote;
    if (!inQuote && ch === "&" && s[i + 1] === "&") {
      parts.push(buf.trim());
      buf = "";
      i++;
      continue;
    }
    buf += ch;
  }
  parts.push(buf.trim());
  return parts.filter(Boolean);
};

const CD_RE = /^cd \/home\/yuyyuy\/Projects\/yuyyuy-projects\/(server|client)$/;
const CD_INLINE_RE = /^cd \/home\/yuyyuy\/Projects\/yuyyuy-projects\/(server|client) && /;

let cur = null;
for (const raw of lines) {
  let line = raw.trim();
  const cd = line.match(CD_RE);
  if (cd) {
    cur = cd[1];
    continue;
  }
  const inline = line.match(CD_INLINE_RE);
  if (inline) {
    cur = inline[1];
    line = line.replace(CD_INLINE_RE, "");
  }
  if (!cur) continue;
  for (const cmd of splitAnd(line)) {
    if (cmd.startsWith("bun add -d ")) {
      for (const t of cmd.slice("bun add -d ".length).split(/\s+/)) {
        const [n, r] = splitSpec(t);
        exp[cur].dev[n] = r;
      }
    } else if (cmd.startsWith("bun add ")) {
      for (const t of cmd.slice("bun add ".length).split(/\s+/)) {
        const [n, r] = splitSpec(t);
        exp[cur].dep[n] = r;
      }
    } else if (cmd.startsWith("bun pm pkg set ")) {
      const rest = cmd.slice("bun pm pkg set ".length);
      for (const m of rest.matchAll(/(\S+?)=("([^"]*)"|\S+)/g)) {
        const key = m[1];
        const val = m[3] !== undefined ? m[3] : m[2];
        if (key === "name") exp[cur].name = val;
        else if (key.startsWith("scripts.")) exp[cur].scripts[key.slice("scripts.".length)] = val;
      }
    }
  }
}

const bad = [];

for (const f of ["package.json", "bun.lock", "node_modules"]) {
  if (existsSync(`${root}/${f}`)) bad.push(`ROOT: ${root}/${f} must not exist, stop and report`);
}

for (const dir of ["server", "client"]) {
  const base = `${root}/${dir}`;
  const pkgFile = Bun.file(`${base}/package.json`);
  if (!(await pkgFile.exists())) {
    bad.push(`MISMATCH ${dir}: package.json not found`);
    continue;
  }
  const pkg = await pkgFile.json();
  const e = exp[dir];
  if (e.name && pkg.name !== e.name) bad.push(`MISMATCH ${dir}: name is "${pkg.name}", expected "${e.name}"`);
  for (const [k, v] of Object.entries(e.scripts)) {
    if (pkg.scripts?.[k] !== v) bad.push(`MISMATCH ${dir}: script ${k} is "${pkg.scripts?.[k]}", expected "${v}"`);
  }
  for (const [group, field] of [["dep", "dependencies"], ["dev", "devDependencies"]]) {
    for (const [n, r] of Object.entries(e[group])) {
      const have = pkg[field]?.[n];
      if (!have) {
        bad.push(`MISMATCH ${dir}: ${n} missing from ${field}`);
        continue;
      }
      if (r.startsWith("^") && have !== r) bad.push(`MISMATCH ${dir}: ${n} range is ${have}, expected ${r}`);
      const instFile = Bun.file(`${base}/node_modules/${n}/package.json`);
      if (!(await instFile.exists())) {
        bad.push(`MISMATCH ${dir}: ${n} not installed`);
        continue;
      }
      const ver = (await instFile.json()).version;
      const ok = r.startsWith("^") ? Bun.semver.satisfies(ver, r) : r === "" || ver === r || ver.startsWith(r + ".");
      if (!ok) bad.push(`MISMATCH ${dir}: ${n} installed ${ver}, expected ${r}`);
    }
  }
}

if (bad.length) {
  console.log(bad.join("\n"));
  process.exit(1);
}
console.log("ALL OK");
