import {readFileSync, writeFileSync, mkdirSync, cpSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
export const output = path.join(root, 'game/build/lore');
const definition = [
  ['world', '世界观与人物设定初稿', '基础初稿'],
  ['story', '主线叙事初稿', '叙事提案'],
];
export function buildLore(source = execFileSync('git', ['rev-parse', 'HEAD'], {cwd: root, encoding: 'utf8'}).trim()) {
  const records = [], documents = [];
  for (const [id, name, status] of definition) {
    const file = `docs/${name}.md`;
    // Git/Pages normalize text to LF. Hash and publish the same canonical bytes.
    const raw = readFileSync(path.join(root, file), 'utf8').replace(/\r\n?/g, '\n');
    const lines = raw.replace(/\r/g, '').split('\n');
    const doc = {id, name, file, raw, version: raw.match(/版本：([^。\r\n]+)/)?.[1] ?? '未标版本', sha256: createHash('sha256').update(raw).digest('hex')};
    documents.push(doc);
    let parent = '', active = null;
    const flush = () => {
      if (!active || !active.body.trim()) return;
      active.body = active.body.trim();
      active.summary = active.body.split(/\n\s*\n/).find(p => !/^(?:腔室：|#|\|)/.test(p)) ?? active.body;
      records.push(active);
    };
    for (const [i, line] of lines.entries()) {
      const heading = line.match(/^(#{2,3}) (.+)$/);
      // A chapter stays intact, including its combat subsection.
      if (heading && !(id === 'story' && heading[1] === '###')) {
        flush();
        if (heading[1] === '##') parent = heading[2];
        const title = heading[2].replace(/^[一二三四五六七]、/, '');
        const chapter = /^第.+章/.test(title);
        let category = id === 'world' ? '世界规则' : '叙事说明';
        if (parent.includes('主要人物')) category = '人物';
        if (parent.includes('守护组织')) category = '组织';
        if (parent.includes('后续设计')) category = '待定事项';
        if (chapter) category = '章节';
        if (title.includes('战斗')) category = '战斗';
        active = {id: `${id}-${encodeURIComponent(title)}`, title, parent, category, status, doc: id, line: i + 1, body: ''};
      } else if (active) active.body += line + '\n';
    }
    flush();
  }
  const chapters = records.filter(r => r.category === '章节');
  chapters.forEach((chapter, i) => {
    chapter.number = i + 1;
    chapter.place = chapter.body.match(/^腔室：(.+?)。/m)?.[1];
    const combat = chapter.body.split('### 战斗安排')[1]?.trim();
    records.push({id: `place-${i + 1}`, title: chapter.place, category: '地点', status: '叙事提案', doc: 'story', line: chapter.line, body: chapter.body.split('\n\n').slice(0, 2).join('\n\n'), summary: chapter.summary, chapter: chapter.id});
    if (combat) records.push({id: `combat-${i + 1}`, title: `${String(i + 1).padStart(2, '0')} · ${chapter.place}`, category: '战斗', status: '叙事提案', doc: 'story', line: chapter.line, body: combat, summary: combat, chapter: chapter.id});
  });
  // Keep excerpts verbatim: these are an index of mentions, not new character biographies.
  for (const name of ['补巢者', '负壳守卫', '封梁卫', '泵庭执卫', '缠巢鳗']) {
    const mentions = chapters.filter(c => c.body.includes(name));
    records.push({id: `person-${encodeURIComponent(name)}`, title: name, category: '人物', status: '叙事提案', doc: 'story', line: mentions[0].line, body: mentions.map(c => `### ${c.title}\n\n${c.body.split('\n\n').filter(p => p.includes(name) && !p.startsWith('N')).join('\n\n')}`).join('\n\n'), summary: mentions[0].body.split('\n\n').find(p => p.includes(name) && !p.startsWith('N')), mentions: mentions.map(c => c.id)});
  }
  for (const record of records) {
    record.summary = record.summary.replace(/\*\*/g, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
  }
  const data = {source, documents, records};
  mkdirSync(output, {recursive: true});
  for (const file of ['index.html', 'style.css', 'app.js']) cpSync(path.join(root, 'game/pages/lore', file), path.join(output, file));
  writeFileSync(path.join(output, 'data.json'), JSON.stringify(data));
  writeFileSync(path.join(output, 'build.json'), JSON.stringify({source, documents: documents.map(({file, sha256, version}) => ({file, sha256, version})), records: records.length}, null, 2));
  for (const doc of documents) writeFileSync(path.join(output, `${doc.id}.md`), doc.raw);
  console.log(`Lore: ${records.length} entries, ${chapters.length} chapters → ${output}`);
  return data;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) buildLore();
