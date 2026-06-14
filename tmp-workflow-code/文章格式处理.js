
const allItems = $input.all();
const results = [];
const failed = [];

for (let i = 0; i < allItems.length; i++) {
  try {
    const buf = await this.helpers.getBinaryDataBuffer(i, 'data');
    let content = buf.toString('utf-8');
    const fileName = allItems[i].json.fileName || 'article';

    let title = fileName.replace(/\.md$/, '');
    const firstLines = content.split('\n');
    for (const line of firstLines) {
      const trimmed = line.trim();
      if (trimmed.length > 0) {
        title = trimmed.replace(/^#+\s*/, '').replace(/\*\*/g, '').slice(0, 64);
        break;
      }
    }

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

    const codeBlocks = [];
    content = content.replace(/```[\s\S]*?```/g, (match) => {
      codeBlocks.push(match);
      return `__CODE_BLOCK_${codeBlocks.length - 1}__`;
    });

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

      if (/^---+\s*$/.test(trimmed)) {
        flushParagraph();
        continue;
      }

      if (firstNonEmpty && trimmed.length > 0) {
        firstNonEmpty = false;
        continue;
      }

      if (/^#{1,6}\s+/.test(trimmed)) {
        flushParagraph();
        blocks.push({
          type: 'subtitle',
          text: trimmed.replace(/^#{1,6}\s+/, '').replace(/\*\*/g, '').trim()
        });
        continue;
      }

      if (/^[-*]\s+/.test(trimmed)) {
        flushParagraph();
        blocks.push({ type: 'list', text: trimmed.replace(/^[-*]\s+/, '') });
        continue;
      }

      if (trimmed === '') {
        flushParagraph();
        continue;
      }

      if (/^__CODE_BLOCK_\d+__$/.test(trimmed)) {
        flushParagraph();
        const idxNum = parseInt(trimmed.match(/\d+/)[0]);
        blocks.push({ type: 'code', text: codeBlocks[idxNum] });
        continue;
      }

      currentParagraph.push(trimmed);
    }
    flushParagraph();

    blocks = blocks.map((block) => {
      if (block.type !== 'paragraph') return block;

      const text = block.text;

      if (/^第[一二三四五六七八九十0-9]+[个类章节部分]/.test(text.trim())) {
        return block;
      }

      const match = text.match(/^([^\s。！？!?]{2,25}?[：:？?])\s*(.*)$/s);
      if (match && match[1].length <= 25 && match[1].length >= 4) {
        if (/^[一二三四五六七八九十0-9]+类[：:]$/.test(match[1])) {
          return block;
        }
        const subtitleText = match[1].trim();
        const rest = match[2].trim();
        if (rest.length > 0) {
          return [
            { type: 'subtitle', text: subtitleText },
            { type: 'paragraph', text: rest }
          ];
        } else {
          return [{ type: 'subtitle', text: subtitleText }];
        }
      }
      return block;
    }).flat();

    blocks = (() => {
      const result = [];
      for (let j = 0; j < blocks.length; j++) {
        const cur = blocks[j];
        const next = blocks[j + 1];
        if (
          cur.type === 'subtitle' &&
          next && next.type === 'paragraph' &&
          next.text.length <= 12 &&
          !/[。！!.，,]/.test(next.text)
        ) {
          result.push({ type: 'subtitle', text: cur.text + next.text });
          j++;
        } else {
          result.push(cur);
        }
      }
      return result;
    })();

    let finalBlocks = [];
    for (let j = 0; j < blocks.length; j++) {
      const cur = blocks[j];
      const prev = finalBlocks[finalBlocks.length - 1];

      if (cur.type !== 'paragraph') {
        finalBlocks.push(cur);
        continue;
      }

      const isVeryShort = cur.text.length < 15;
      if (prev && prev.type === 'paragraph' && cur.text.length < 80 && !cur.text.endsWith('：') && !cur.text.endsWith(':') && !cur.text.endsWith('？') && !cur.text.endsWith('?')) {
        prev.text = prev.text + ' ' + cur.text;
        continue;
      }
      if (prev && prev.type === 'paragraph' && isVeryShort) {
        prev.text = prev.text + cur.text;
        continue;
      }

      finalBlocks.push(cur);
    }

    const renderParagraph = (text) => {
      text = text.replace(/__CODE_BLOCK_(\d+)__/g, (m, idx) => codeBlocks[parseInt(idx)] || '');
      return text.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    };

    let html = '';
    for (const block of finalBlocks) {
      if (block.type === 'subtitle') {
        html += '<p style="font-weight:bold;font-size:16px;margin:30px 0 10px 0;line-height:1.6;color:#333;">' + escapeHtml(block.text) + '</p>\n';
      } else if (block.type === 'list') {
        const itemText = renderParagraph(block.text);
        html += '<p style="text-indent:0;margin:5px 0 5px 18px;line-height:1.8;font-size:16px;color:#333;">\u00b7 ' + itemText + '</p>\n';
      } else if (block.type === 'code') {
        html += '<pre style="background:#f5f5f5;padding:12px;border-radius:4px;overflow-x:auto;font-size:14px;line-height:1.5;margin:15px 0;">' + escapeHtml(block.text) + '</pre>\n';
      } else if (block.type === 'paragraph') {
        const paraText = renderParagraph(block.text);
        html += '<p style="text-indent:0;margin:15px 0;line-height:1.8;font-size:16px;color:#333;">' + paraText + '</p>\n';
      }
    }

    if (!html.trim()) {
      failed.push({ fileName, error: 'Empty content after formatting' });
      continue;
    }

    const assertions = {
      hasFontSize16: /font-size:16px/.test(html),
      hasMargin30: /margin:30px 0 10px 0/.test(html),
      hasBoldWeight: /font-weight:bold/.test(html),
      hasColor333: /color:#333/.test(html),
      hasSubtitles: (html.match(/font-weight:bold[^"]*">[^<]+/g) || []).length >= 1,
      noLayoutTipResidue: !/(排版提示|排版建议|排版贴士|配图插入位置参考|重点内容标注建议)/.test(html)
    };
    const failed_asserts = Object.entries(assertions).filter(([k, v]) => !v).map(([k]) => k);
    if (failed_asserts.length > 0) {
      failed.push({ fileName, error: 'Assertion failed: ' + failed_asserts.join(', ') });
      continue;
    }

    const htmlContent = '<div style="font-size:16px;color:#333;">\n' + html + '</div>';
    results.push({
      json: {
        content: htmlContent,
        title,
        fileName,
        itemType: 'article',
        formatted: true
      },
      binary: allItems[i].binary,
      pairedItem: { item: i }
    });
  } catch (err) {
    failed.push({ fileName: allItems[i].json.fileName || `item_${i}`, error: err.message, stack: err.stack });
  }
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

if (failed.length > 0) {
  console.log('[format-v3.1] Failed items:', JSON.stringify(failed));
  throw new Error('Some articles failed to format: ' + JSON.stringify(failed));
}

if (results.length === 0) {
  throw new Error('All articles failed to format: ' + JSON.stringify(failed));
}

return results;
