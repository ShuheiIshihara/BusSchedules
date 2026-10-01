// 使い方: node fetch.mjs <prod|staging>
// 環境変数: {PROD,STG}_URL / {PROD,STG}_ANON_KEY  (任意) CASES_FILE, OUT_DIR
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { normalizeForSearch, caseId, expandCases } from "./lib.mjs";

const ENVS = {
  prod: { url: "PROD_URL", key: "PROD_ANON_KEY", rpc: "get_phase1_bus_schedule_3" },
  staging: { url: "STG_URL", key: "STG_ANON_KEY", rpc: "get_bus_schedule_2026" },
};
const CONCURRENCY = 4;
const RETRIES = 3;

const name = process.argv[2];
const env = ENVS[name];
if (!env) { console.error("usage: node fetch.mjs <prod|staging>"); process.exit(2); }
const baseUrl = process.env[env.url]?.replace(/\/$/, "");
const anonKey = process.env[env.key];
if (!baseUrl || !anonKey) { console.error(`${env.url} / ${env.key} を設定してください`); process.exit(2); }

const cases = expandCases(JSON.parse(await readFile(process.env.CASES_FILE ?? new URL("cases.json", import.meta.url), "utf8")));
const outDir = `${process.env.OUT_DIR ?? "out"}/${name}`;
await mkdir(outDir, { recursive: true });

async function call(c) {
  const body = JSON.stringify({
    departure_station: normalizeForSearch(c.departure),
    arrival_station: normalizeForSearch(c.arrival),
    target_date: c.date,
  });
  let last;
  for (let i = 0; i < RETRIES; i++) {
    try {
      const res = await fetch(`${baseUrl}/rest/v1/rpc/${env.rpc}`, {
        method: "POST",
        headers: { apikey: anonKey, Authorization: `Bearer ${anonKey}`, "Content-Type": "application/json" },
        body,
      });
      const text = await res.text();
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${text.slice(0, 200)}`);
      return { ok: true, data: JSON.parse(text) };
    } catch (e) {
      last = e;
      await new Promise((r) => setTimeout(r, 1000 * (i + 1)));
    }
  }
  return { ok: false, error: String(last) };
}

let failed = 0, next = 0;
async function worker() {
  while (next < cases.length) {
    const c = cases[next++];
    const r = await call(c);
    if (!r.ok) failed++;
    await writeFile(`${outDir}/${caseId(c)}.json`, JSON.stringify({ case: c, ...r }, null, 2));
  }
}
await Promise.all(Array.from({ length: CONCURRENCY }, worker));
console.log(`${name}: ${cases.length - failed}/${cases.length} 件取得 (失敗 ${failed})`);
