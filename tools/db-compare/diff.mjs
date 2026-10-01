// 使い方: node diff.mjs  (out/prod と out/staging を比較し out/report.md, out/diff.json を出力)
import { readFile, readdir, writeFile } from "node:fs/promises";

const OUT = process.env.OUT_DIR ?? "out";
const FIELDS = ["arrivalTime", "platform", "serviceId", "busStops"];
const rowKey = (r) => `${r.departureTime}|${r.routeName}|${r.destination}`;

function index(rows) {
  const m = new Map(), seen = new Map();
  for (const r of rows ?? []) {
    const k = rowKey(r);
    const n = seen.get(k) ?? 0;
    seen.set(k, n + 1);
    m.set(`${k}#${n}`, r); // 同一キーの重複は出現順で区別
  }
  return m;
}

function compare(a, b) {
  const A = index(a), B = index(b);
  const added = [], removed = [], changed = [];
  for (const [k, r] of B) if (!A.has(k)) added.push(r);
  for (const [k, r] of A) {
    if (!B.has(k)) { removed.push(r); continue; }
    const diffs = FIELDS.filter((f) => JSON.stringify(r[f] ?? null) !== JSON.stringify(B.get(k)[f] ?? null));
    if (diffs.length) changed.push({ key: k, fields: diffs, before: r, after: B.get(k) });
  }
  return { added, removed, changed };
}

const load = async (env, f) => JSON.parse(await readFile(`${OUT}/${env}/${f}`, "utf8"));
const files = (await readdir(`${OUT}/prod`)).filter((f) => f.endsWith(".json"));
const results = [];

for (const f of files) {
  let p, s;
  try { p = await load("prod", f); s = await load("staging", f); }
  catch { results.push({ file: f, status: "missing" }); continue; }
  const c = p.case;
  if (!p.ok || !s.ok) { results.push({ file: f, case: c, status: "error", prod: p.error, staging: s.error }); continue; }
  const d = compare(p.data, s.data);
  const same = !d.added.length && !d.removed.length && !d.changed.length;
  results.push({ file: f, case: c, status: same ? "same" : "diff", before: p.data?.length ?? 0, after: s.data?.length ?? 0, ...d });
}

const count = (st) => results.filter((r) => r.status === st).length;
const md = [
  "# DB比較レポート (本番=Before / 検証=After)", "",
  `- 比較ケース: ${results.length}`,
  `- 一致: ${count("same")} / 差分あり: ${count("diff")} / 取得エラー: ${count("error")} / 欠落: ${count("missing")}`, "",
  "| 出発 | 到着 | 日付 | 結果 | 本番件数 | 検証件数 | 追加 | 削除 | 変更 |",
  "|---|---|---|---|---|---|---|---|---|",
  ...results.map((r) => r.case
    ? `| ${r.case.departure} | ${r.case.arrival} | ${r.case.date} | ${r.status} | ${r.before ?? "-"} | ${r.after ?? "-"} | ${r.added?.length ?? "-"} | ${r.removed?.length ?? "-"} | ${r.changed?.length ?? "-"} |`
    : `| ${r.file} | | | ${r.status} | | | | | |`),
];
for (const r of results.filter((r) => r.status === "error")) md.push("", `**エラー** ${r.file}: prod=${r.prod ?? "ok"} / staging=${r.staging ?? "ok"}`);
for (const r of results.filter((r) => r.status === "diff")) {
  md.push("", `## ${r.case.departure} → ${r.case.arrival} (${r.case.date})`);
  const fmt = (x) => `${x.departureTime} ${x.routeName} 行き:${x.destination}`;
  for (const x of r.removed.slice(0, 20)) md.push(`- 削除: ${fmt(x)}`);
  for (const x of r.added.slice(0, 20)) md.push(`- 追加: ${fmt(x)}`);
  for (const x of r.changed.slice(0, 20)) md.push(`- 変更(${x.fields.join(",")}): ${fmt(x.before)}`);
  const more = r.added.length + r.removed.length + r.changed.length - Math.min(20, r.added.length) - Math.min(20, r.removed.length) - Math.min(20, r.changed.length);
  if (more > 0) md.push(`- …ほか ${more} 件 (詳細は diff.json)`);
}
await writeFile(`${OUT}/report.md`, md.join("\n") + "\n");
await writeFile(`${OUT}/diff.json`, JSON.stringify(results, null, 2));
console.log(md.slice(0, 5).join("\n"));
