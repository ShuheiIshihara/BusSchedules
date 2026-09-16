// iOS版 StringNormalization.swift と入出力を一致させる日本語正規化ユーティリティ。
// バス停名の検索・表示・読みがな検索で、入力ゆれ（合成文字・全角半角・カナ）を吸収する。

// しんにょう対象の基底文字（2点しんにょう）。表示時は異体字セレクタ U+E0100 を付けて1点表示に統一する。
// iOS版 shinnnyouMapping と同じ4文字。
const SHINNYOU_BASE_CHARS = ['辻', '込', '迫', '追'] as const;
// 異体字セレクタ（VS17, U+E0100）。付加すると対応フォントで1点しんにょう表示になる。
const VARIATION_SELECTOR_17 = '\u{E0100}';
// 各基底文字の直後に VS17 が付いていない箇所だけを対象にする（二重付加防止）。
const SHINNYOU_RE = new RegExp(
  `(${SHINNYOU_BASE_CHARS.join('|')})(?!${VARIATION_SELECTOR_17})`,
  'gu',
);

// 半角カタカナ（U+FF61–U+FF9F）→ 全角カタカナ／記号の基本マッピング。
const HALFWIDTH_KATAKANA_BASE: Record<string, string> = {
  '｡': '。', '｢': '「', '｣': '」', '､': '、', '･': '・',
  'ｦ': 'ヲ', 'ｧ': 'ァ', 'ｨ': 'ィ', 'ｩ': 'ゥ', 'ｪ': 'ェ', 'ｫ': 'ォ',
  'ｬ': 'ャ', 'ｭ': 'ュ', 'ｮ': 'ョ', 'ｯ': 'ッ', 'ｰ': 'ー',
  'ｱ': 'ア', 'ｲ': 'イ', 'ｳ': 'ウ', 'ｴ': 'エ', 'ｵ': 'オ',
  'ｶ': 'カ', 'ｷ': 'キ', 'ｸ': 'ク', 'ｹ': 'ケ', 'ｺ': 'コ',
  'ｻ': 'サ', 'ｼ': 'シ', 'ｽ': 'ス', 'ｾ': 'セ', 'ｿ': 'ソ',
  'ﾀ': 'タ', 'ﾁ': 'チ', 'ﾂ': 'ツ', 'ﾃ': 'テ', 'ﾄ': 'ト',
  'ﾅ': 'ナ', 'ﾆ': 'ニ', 'ﾇ': 'ヌ', 'ﾈ': 'ネ', 'ﾉ': 'ノ',
  'ﾊ': 'ハ', 'ﾋ': 'ヒ', 'ﾌ': 'フ', 'ﾍ': 'ヘ', 'ﾎ': 'ホ',
  'ﾏ': 'マ', 'ﾐ': 'ミ', 'ﾑ': 'ム', 'ﾒ': 'メ', 'ﾓ': 'モ',
  'ﾔ': 'ヤ', 'ﾕ': 'ユ', 'ﾖ': 'ヨ',
  'ﾗ': 'ラ', 'ﾘ': 'リ', 'ﾙ': 'ル', 'ﾚ': 'レ', 'ﾛ': 'ロ',
  'ﾜ': 'ワ', 'ﾝ': 'ン',
  'ﾞ': '゛', 'ﾟ': '゜',
};

// 半角カナ基底 + 半角濁点（ﾞ）→ 全角濁音。
const HALFWIDTH_DAKUTEN: Record<string, string> = {
  'ｶ': 'ガ', 'ｷ': 'ギ', 'ｸ': 'グ', 'ｹ': 'ゲ', 'ｺ': 'ゴ',
  'ｻ': 'ザ', 'ｼ': 'ジ', 'ｽ': 'ズ', 'ｾ': 'ゼ', 'ｿ': 'ゾ',
  'ﾀ': 'ダ', 'ﾁ': 'ヂ', 'ﾂ': 'ヅ', 'ﾃ': 'デ', 'ﾄ': 'ド',
  'ﾊ': 'バ', 'ﾋ': 'ビ', 'ﾌ': 'ブ', 'ﾍ': 'ベ', 'ﾎ': 'ボ',
  'ｳ': 'ヴ',
};

// 半角カナ基底 + 半角半濁点（ﾟ）→ 全角半濁音。
const HALFWIDTH_HANDAKUTEN: Record<string, string> = {
  'ﾊ': 'パ', 'ﾋ': 'ピ', 'ﾌ': 'プ', 'ﾍ': 'ペ', 'ﾎ': 'ポ',
};

// 検索用に正規化する。iOS版 normalizeForSearch と同一挙動。
// NFC → しんにょう異体字付加 → 空白正規化 の順。
export function normalizeForSearch(input: string): string {
  if (!input) return input;
  let result = input.normalize('NFC');
  result = applyShinnyouVariant(result);
  result = normalizeWhitespace(result);
  return result;
}

// 表示用に正規化する。iOS版 normalizeForDisplay と同一挙動。
// （Swift 実装上、しんにょう処理は search 用と同じく VS17 付加。挙動は normalizeForSearch と一致する）
export function normalizeForDisplay(input: string): string {
  if (!input) return input;
  let result = input.normalize('NFC');
  result = applyShinnyouVariant(result);
  result = normalizeWhitespace(result);
  return result;
}

// 読みがな検索用にひらがなへ揃える。iOS版 normalizeKana と同一挙動。
// 半角カナ・半角英数 → 全角 → カタカナをひらがな化 → normalizeForSearch を通す。
export function normalizeKana(input: string): string {
  if (!input) return input;
  let result = halfwidthToFullwidth(input);
  result = katakanaToHiragana(result);
  return normalizeForSearch(result);
}

// しんにょう4文字に VS17 を付加（未付加の箇所のみ）。
function applyShinnyouVariant(input: string): string {
  return input.replace(SHINNYOU_RE, `$1${VARIATION_SELECTOR_17}`);
}

// 空白正規化：前後トリム → 全角スペースを半角へ → 連続空白を1つに圧縮。
// JS の trim()・\s は U+3000 を含むため iOS の whitespacesAndNewlines と整合する。
function normalizeWhitespace(input: string): string {
  const trimmed = input.trim();
  const halfSpaced = trimmed.replace(/　/g, ' ');
  return halfSpaced.replace(/\s+/g, ' ');
}

// 半角カナ・半角ASCII を全角へ変換する。濁点・半濁点は直後1文字を見て合成する。
function halfwidthToFullwidth(input: string): string {
  const chars = [...input];
  let result = '';
  for (let i = 0; i < chars.length; i++) {
    const ch = chars[i];
    const next = chars[i + 1];

    if (ch in HALFWIDTH_KATAKANA_BASE) {
      // 濁点合成（ｶ + ﾞ → ガ）
      if (next === 'ﾞ' && ch in HALFWIDTH_DAKUTEN) {
        result += HALFWIDTH_DAKUTEN[ch];
        i++;
        continue;
      }
      // 半濁点合成（ﾊ + ﾟ → パ）
      if (next === 'ﾟ' && ch in HALFWIDTH_HANDAKUTEN) {
        result += HALFWIDTH_HANDAKUTEN[ch];
        i++;
        continue;
      }
      result += HALFWIDTH_KATAKANA_BASE[ch];
      continue;
    }

    // 半角ASCII（記号・数字・英字, U+0021–U+007E）→ 全角（+0xFEE0）。スペースは空白正規化に委ねる。
    const code = ch.codePointAt(0)!;
    if (code >= 0x21 && code <= 0x7e) {
      result += String.fromCodePoint(code + 0xfee0);
      continue;
    }

    result += ch;
  }
  return result;
}

// カタカナ（U+30A1–U+30F6）をひらがな（U+3041–U+3096）へ。長音符（ー）等は範囲外のため保持される。
function katakanaToHiragana(input: string): string {
  let result = '';
  for (const ch of input) {
    const code = ch.codePointAt(0)!;
    if (code >= 0x30a1 && code <= 0x30f6) {
      result += String.fromCodePoint(code - 0x60);
    } else {
      result += ch;
    }
  }
  return result;
}
