const allItems = $input.all();
const results = [];
for (let i = 0; i < allItems.length; i++) {
  const buf = await this.helpers.getBinaryDataBuffer(i, 'data');
  let content = buf.toString('utf-8');
  const fileName = allItems[i].json.fileName || 'article';
  const isLayoutTipHeading = (line) => {
    const normalized = line
      .trim()
      .replace(/^[-*#>\s]+/, '')
      .replace(/^\d+[.)、]\s*/, '')
      .replace(/\*\*/g, '')
      .replace(/[<《【\[]/g, '')
      .replace(/[>》】\]]/g, '');
    return /^(公众号)?(排版提示建议|排版提示|排版建议|排版贴士)([:：].*)?$/.test(normalized);
  };
  const rawLines = content.split('\n');
  const tipLineIdx = rawLines.findIndex(isLayoutTipHeading);
  if (tipLineIdx > -1) {
    let beforeLines = rawLines.slice(0, tipLineIdx);
    while (beforeLines.length > 0) {
      const last = beforeLines[beforeLines.length - 1].trim();
      if (last === '---' || last === '') beforeLines.pop();
      else break;
    }
    content = beforeLines.join('\n');
  }
  // Inline format logic
  let lines = content.split('\n');
  let blocks = [];
  let currentParagraph = [];
  let firstNonEmpty = true;
  const flushParagraph = () => {
    if (currentParagraph.length > 0) {
      blocks.push({ type: 'paragraph', text: currentParagraph.join(' ').replace(/\s+/g, ' ').trim() });
      currentParagraph = [];
    }
  };
  for (let idx = 0; idx < lines.length; idx++) {
    const trimmed = lines[idx].trim();
    if (/^---+\s*$/.test(trimmed)) { flushParagraph(); continue; }
    if (firstNonEmpty && trimmed.length > 0) { firstNonEmpty = false; continue; }
    if (/^[-*]\s+/.test(trimmed)) { flushParagraph(); blocks.push({ type: 'list', text: trimmed.replace(/^[-*]\s+/, '') }); continue; }
    if (trimmed === '') { flushParagraph(); continue; }
    currentParagraph.push(trimmed);
  }
  flushParagraph();
  // Subtitle detection
  blocks = blocks.map((b) => {
    if (b.type !== 'paragraph') return b;
    const m = b.text.match(/^([^\s。！？!?]{2,25}?[：:？?])\s*(.*)$/s);
    if (m && m[1].length <= 25 && m[1].length >= 4 && !/^[一二三四五六七八九十0-9]+类[：:]$/.test(m[1])) {
      return [{ type: 'subtitle', text: m[1].trim() }, { type: 'paragraph', text: m[2].trim() }];
    }
    return b;
  }).flat();
  let html = '';
  for (const b of blocks) {
    if (b.type === 'subtitle') {
      html += '<p style="font-weight:bold;font-size:16px;margin:30px 0 10px 0;line-height:1.6;color:#222;">' + b.text + '</p>\n';
    } else {
      html += '<p style="text-indent:0;margin:15px 0;line-height:1.8;font-size:16px;">' + b.text + '</p>\n';
    }
  }
  // Validation
  const checks = {
    font_size_16: (html.match(/font-size:16px/g) || []).length >= 3,
    margin_30: html.includes('margin:30px 0 10px 0'),
    font_weight_bold: html.includes('font-weight:bold'),
    has_subtitles: (html.match(/font-weight:bold/g) || []).length >= 1,
    no_layout_tip_residue: !/(排版提示|排版建议|排版贴士|配图插入位置参考|重点内容标注建议)/.test(html),
  };
  const all_ok = Object.values(checks).every(v => v);
  results.push({
    json: {
      fileName,
      all_ok,
      checks,
      ts: new Date().toISOString(),
      subtitle_count: (html.match(/font-weight:bold/g) || []).length
    }
  });
}
// Build log content from results
for (const r of results) {
  r.binary = {
    log_content: {
      mimeType: 'text/plain',
      fileType: 'text',
      fileExtension: 'log',
      data: Buffer.from(new Date().toISOString() + ' ' + JSON.stringify(r.json) + '\n').toString('base64')
    }
  };
  r.json.log_content = new Date().toISOString() + ' ' + JSON.stringify(r.json);
}
return results;
