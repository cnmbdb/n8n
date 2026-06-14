const inputItems = $input.all();

function getItemsFromNode(nodeName) {
  try {
    return $(nodeName).all();
  } catch (error) {
    return [];
  }
}

let articles = getItemsFromNode('尾图').filter(item => item.json.itemType === 'article');
if (articles.length === 0) {
  articles = getItemsFromNode('文章格式处理').filter(item => item.json.itemType === 'article');
}
if (articles.length === 0) {
  articles = inputItems.filter(item => item.json.itemType === 'article' || item.json.content);
}

let covers = getItemsFromNode('提取封面ID').filter(item => item.json.itemType === 'cover');
if (covers.length === 0) {
  covers = inputItems.filter(item => item.json.itemType === 'cover' || item.json.thumb_media_id);
}

articles.sort((a, b) => String(a.json.fileName || '').localeCompare(String(b.json.fileName || '')));
covers.sort((a, b) => String(a.json.cover_baseName || a.json.fileName || '').localeCompare(String(b.json.cover_baseName || b.json.fileName || '')));

if (articles.length === 0) {
  throw new Error('No article items found. Check 文章格式处理/尾图 output before creating WeChat drafts.');
}
if (covers.length === 0) {
  throw new Error('No cover items found. Check 上传封面到微信/提取封面ID output before creating WeChat drafts.');
}

const coverMap = {};
for (const cover of covers) {
  if (cover.json.cover_baseName && cover.json.thumb_media_id) {
    coverMap[cover.json.cover_baseName] = cover.json.thumb_media_id;
  }
}

const failures = [];

const tokenResp = await this.helpers.httpRequest({
  method: 'GET',
  url: 'https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=wx0abf66f7e4ac36bb&secret=ac4192df2c47fcd3fbd04b9e2662878f',
});
const tokenData = typeof tokenResp === 'string' ? JSON.parse(tokenResp) : tokenResp;
if (!tokenData.access_token) {
  throw new Error('access_token failed: ' + JSON.stringify(tokenData));
}

const draftArticles = [];
const articleMeta = [];

for (let i = 0; i < articles.length; i++) {
  const content = articles[i].json.content || '';
  const fileName = articles[i].json.fileName || 'article';
  const title = articles[i].json.title || fileName.replace(/\.md$/, '');
  const baseName = fileName.replace(/\.md$/, '');
  const thumbMediaId = coverMap[baseName];

  if (!thumbMediaId) {
    const failure = { title, file_name: fileName, error: 'No cover for ' + baseName };
    failures.push(failure);
    continue;
  }

  const digest = content.replace(/<[^>]+>/g, '').slice(0, 120).trim();
  draftArticles.push({
    title,
    author: 'HF Daily',
    digest,
    show_cover_pic: 1,
    content,
    content_source_url: 'https://macosabc.com/token',
    thumb_media_id: thumbMediaId,
  });

  articleMeta.push({
      title,
      file_name: fileName,
      thumb_media_id: thumbMediaId,
  });
}

if (failures.length > 0) {
  throw new Error('Draft creation failed: ' + JSON.stringify(failures));
}
if (draftArticles.length === 0) {
  throw new Error('No drafts were created. article_count=' + articles.length + ', cover_count=' + covers.length);
}

const draftResp = await this.helpers.httpRequest({
  method: 'POST',
  url: 'https://api.weixin.qq.com/cgi-bin/draft/add?access_token=' + tokenData.access_token,
  body: { articles: draftArticles },
  json: true,
});
const draftData = typeof draftResp === 'string' ? JSON.parse(draftResp) : draftResp;

if (draftData.errcode && draftData.errcode !== 0) {
  throw new Error('Draft creation failed: ' + JSON.stringify({
    error: draftData,
    article_count: draftArticles.length,
    articles: articleMeta,
  }));
}

return [{
  json: {
    success: true,
    media_id: draftData.media_id,
    article_count: draftArticles.length,
    cover_count: covers.length,
    titles: articleMeta.map(item => item.title),
    files: articleMeta.map(item => item.file_name),
    thumb_media_ids: articleMeta.map(item => item.thumb_media_id),
  },
}];
