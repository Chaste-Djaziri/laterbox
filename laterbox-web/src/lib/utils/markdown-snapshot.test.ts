import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createElement} from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import ReactMarkdown from 'react-markdown';
import {buildTextFragmentUrl} from './url';
test('snapshot renderer preserves Markdown and blocks raw HTML and unsafe links',()=>{const html=renderToStaticMarkup(createElement(ReactMarkdown,{skipHtml:true},'# Title\n\n- item\n\n[bad](javascript:alert)\n\n<img src=x onerror=alert(1)>\n\n```js\nconst x = 1;\n```'));assert.ok(html.includes('<h1>Title</h1>'));assert.ok(html.includes('<li>item</li>'));assert.ok(html.includes('<code'));assert.ok(!html.includes('javascript:'));assert.ok(!html.includes('onerror'));});
test('reader references keep anchors and safely encode exact Unicode quotes',()=>{assert.equal(buildTextFragmentUrl('https://www.apple.com/','Endless entertainment.'),'https://www.apple.com/#:~:text=Endless%20entertainment.');assert.equal(buildTextFragmentUrl('https://example.com/#section','Café, a-b!'),'https://example.com/#section:~:text=Caf%C3%A9%2C%20a%2Db%21');});
