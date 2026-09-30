// アプリ(StringNormalization.normalizeForSearch)と同じ検索文字列正規化
const SHINNYOU = ["辻", "込", "迫", "追"];

export function normalizeForSearch(input) {
  if (!input) return input;
  let s = input.normalize("NFC");
  for (const ch of SHINNYOU) {
    s = s.replace(new RegExp(`${ch}(?!\u{E0100})`, "gu"), `${ch}\u{E0100}`);
  }
  return s.trim().replace(/　/g, " ").replace(/\s+/g, " ");
}

export function caseId({ departure, arrival, date }) {
  return `${departure}_${arrival}_${date}`.replace(/[\\/:*?"<>|\s]/g, "-");
}

export function expandCases(cfg) {
  return cfg.pairs.flatMap((p) => cfg.dates.map((date) => ({ ...p, date })));
}
