import { describe, it, expect } from 'vitest';
import {
  normalizeForSearch,
  normalizeForDisplay,
  normalizeKana,
} from './stringNormalization';

const VS17 = '\u{E0100}';

describe('normalizeForSearch', () => {
  it('しんにょう文字に異体字セレクタを付加する', () => {
    expect(normalizeForSearch('辻町')).toBe(`辻${VS17}町`);
  });

  it('既に異体字セレクタが付いている場合は二重付加しない', () => {
    expect(normalizeForSearch(`辻${VS17}町`)).toBe(`辻${VS17}町`);
  });

  it('全角スペース・前後空白・連続空白を正規化する', () => {
    expect(normalizeForSearch('  名古屋　駅  ')).toBe('名古屋 駅');
  });

  it('対象外の文字はそのまま返す', () => {
    expect(normalizeForSearch('名古屋駅')).toBe('名古屋駅');
  });

  it('空文字はそのまま返す', () => {
    expect(normalizeForSearch('')).toBe('');
  });
});

describe('normalizeForDisplay', () => {
  it('検索用と同じくしんにょう異体字を付加する', () => {
    expect(normalizeForDisplay('辻町')).toBe(`辻${VS17}町`);
  });
});

describe('normalizeKana', () => {
  it('全角カタカナをひらがなに変換する', () => {
    expect(normalizeKana('ナルミ')).toBe('なるみ');
  });

  it('半角カタカナをひらがなに変換する', () => {
    expect(normalizeKana('ﾅﾙﾐ')).toBe('なるみ');
  });

  it('半角濁点・半濁点・長音を合成して変換する', () => {
    expect(normalizeKana('ｶﾞｰﾃﾞﾝ')).toBe('がーでん');
  });

  it('半角数字を全角に揃える', () => {
    expect(normalizeKana('あいかわ1ちょうめ')).toBe('あいかわ１ちょうめ');
  });

  it('既にひらがなの読みはそのまま返す', () => {
    expect(normalizeKana('あいかわ１ちょうめ')).toBe('あいかわ１ちょうめ');
  });

  it('空文字はそのまま返す', () => {
    expect(normalizeKana('')).toBe('');
  });
});
