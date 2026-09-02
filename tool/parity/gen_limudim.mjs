import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
const out = process.argv[3];

const read = (p) => readFileSync(`${root}/src/limudim/${p}`, 'utf8');

const units = read('units.rs');
const hashavua = read('daf_hashavua_bavli.rs');
const amud = read('amud_yomi_bavli_dirshu.rs');
const mishna = read('mishna_yomis.rs');

function tractateList(name, source = units) {
  const block = source.match(new RegExp(`${name}[^=]*=\\s*\\[([\\s\\S]*?)\\];`))[1];
  return [...block.matchAll(/Tractate::([A-Za-z]+)/g)].map((m) => m[1]);
}

const bavli = tractateList('pub const BAVLI_TRACTATES');
const mishnaic = tractateList('pub const TRACTATES');

/** Reads a `match tractate { Tractate::X => <value>, ... }` arm table. */
function matchArms(source, fnName) {
  const body = source.slice(source.indexOf(fnName));
  const block = body.slice(body.indexOf('{'), body.indexOf('\n}'));
  const arms = new Map();
  for (const m of block.matchAll(/Tractate::([A-Za-z]+)\s*=>\s*([^,\n]+),/g)) {
    arms.set(m[1], m[2].trim());
  }
  const fallback = block.match(/_\s*=>\s*([^,\n]+),/);
  return { arms, fallback: fallback ? fallback[1].trim() : null };
}

// Daf Hashavua: first and last daf of each Bavli tractate.
const hashavuaStart = matchArms(hashavua, 'const fn start_daf');
const hashavuaEnd = matchArms(hashavua, 'const fn end_daf');
const hashavuaRange = bavli.map((t) => {
  const start = Number(hashavuaStart.arms.get(t) ?? hashavuaStart.fallback);
  const end = Number(hashavuaEnd.arms.get(t));
  if (!Number.isFinite(start) || !Number.isFinite(end)) throw new Error(`daf range ${t}`);
  return [start, end];
});

// Amud Yomi: first and last amud of each Bavli tractate.
function amudArms(fnName) {
  const body = amud.slice(amud.indexOf(fnName));
  const block = body.slice(body.indexOf('{'), body.indexOf('\n}'));
  const arms = new Map();
  for (const m of block.matchAll(
    /Tractate::([A-Za-z]+)\s*=>\s*Amud::new\(Tractate::[A-Za-z]+,\s*(\d+),\s*Side::([A-Za-z]+)\)/g,
  )) {
    arms.set(m[1], [Number(m[2]), m[3]]);
  }
  return arms;
}
const amudStartArms = amudArms('pub const fn start_daf');
const amudEndArms = amudArms('pub const fn end_daf');
const amudRange = bavli.map((t) => {
  const start = amudStartArms.get(t) ?? [2, 'Aleph'];
  const end = amudEndArms.get(t);
  if (!end) throw new Error(`amud range ${t}`);
  return [...start, ...end];
});

// Mishna Yomis: the mishnayos in each chapter of each tractate.
const chapterBody = mishna.slice(mishna.indexOf('const fn chapter_length'));
const chapterBlock = chapterBody.slice(chapterBody.indexOf('{'), chapterBody.indexOf('\n}'));
const chapterLengths = new Map();
for (const m of chapterBlock.matchAll(/Tractate::([A-Za-z]+)\s*=>\s*\[([\s\S]*?)\]\[chapter_index\]/g)) {
  chapterLengths.set(
    m[1],
    m[2]
      .split(',')
      .map((n) => n.trim())
      .filter((n) => n.length > 0)
      .map(Number),
  );
}
const chaptersArms = matchArms(mishna, 'const fn chapters');
const mishnaTable = mishnaic.map((t) => {
  const lengths = chapterLengths.get(t);
  const chapters = Number(chaptersArms.arms.get(t));
  if (!lengths) throw new Error(`chapter lengths ${t}`);
  if (lengths.length !== chapters) throw new Error(`${t}: ${lengths.length} chapters, declared ${chapters}`);
  return lengths;
});

const words = (name) => name.replace(/([a-z])([A-Z])/g, '$1 $2');

function rows(values, perRow) {
  const lines = [];
  for (let i = 0; i < values.length; i += perRow) {
    lines.push('    ' + values.slice(i, i + perRow).join(', ') + ',');
  }
  return lines.join('\n');
}

const source = `// GENERATED from kosher-rust by tool/parity/gen_limudim.mjs. Do not edit by hand.

/// The first and last daf of each masechta of the Bavli, in the order [Daf] numbers
/// them, for the schedules that run over whole dafim.
const List<List<int>> dafRangePerMasechta = [
${hashavuaRange.map(([s, e]) => `  [${s}, ${e}],`).join('\n')}
];

/// The first and last amud of each masechta of the Bavli, as page and side, for the
/// schedules that run over amudim. A side of 0 is amud aleph and 1 is amud beis.
const List<List<int>> amudRangePerMasechta = [
${amudRange.map(([sp, ss, ep, es]) => `  [${sp}, ${ss === 'Aleph' ? 0 : 1}, ${ep}, ${es === 'Aleph' ? 0 : 1}],`).join('\n')}
];

/// The masechtos of the Mishna, in the order Mishna Yomis learns them.
const List<String> mishnaMasechtosTransliterated = [
${rows(mishnaic.map((t) => `"${words(t)}"`), 4)}
];

/// The number of mishnayos in each chapter of each masechta, indexed as
/// [mishnaMasechtosTransliterated].
const List<List<int>> mishnayosPerChapter = [
${mishnaTable.map((lengths, i) => `  // ${words(mishnaic[i])}\n  [${lengths.join(', ')}],`).join('\n')}
];
`;

writeFileSync(out, source);
console.log(
  `bavli ${bavli.length}, mishnaic ${mishnaic.length}, ` +
    `mishnayos ${mishnaTable.reduce((a, c) => a + c.reduce((x, y) => x + y, 0), 0)}`,
);
