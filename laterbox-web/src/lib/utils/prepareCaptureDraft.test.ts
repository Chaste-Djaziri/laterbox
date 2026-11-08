// laterbox-web/src/lib/utils/prepareCaptureDraft.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { prepareCaptureDraft } from './prepareCaptureDraft';

test('tasks require an action title and preserve optional details separately', () => {
  assert.equal(prepareCaptureDraft({kind:'task',title:'  ',content:'details'}),null);
  assert.deepEqual(prepareCaptureDraft({kind:'task',title:'Submit assignment',content:''}), {
    type:'task',title:'Submit assignment',value:'Submit assignment'
  });
  assert.deepEqual(prepareCaptureDraft({kind:'task',title:'Submit assignment',content:'Include diagrams',fileCount:1}), {
    type:'task',title:'Submit assignment',value:'Include diagrams'
  });
});

test('notes require writing, support optional titles and retain typed content', () => {
  assert.equal(prepareCaptureDraft({kind:'note',title:'Ideas',content:'  '}),null);
  assert.deepEqual(prepareCaptureDraft({kind:'note',title:'  ',content:'First line\nSecond line',suggestedTitle:'First line'}),{
    type:'note',title:'First line',value:'First line\nSecond line'
  });
  assert.deepEqual(prepareCaptureDraft({kind:'note',title:'My notes',content:'https://example.com'}), {
    type:'note',title:'My notes',value:'https://example.com'
  });
});

test('links and attachments keep their original capture types', () => {
  assert.equal(prepareCaptureDraft({kind:'link',content:''}),null);
  assert.deepEqual(prepareCaptureDraft({kind:'link',content:'https://example.com'}), {
    type:'link',value:'https://example.com',title:undefined
  });
  assert.deepEqual(prepareCaptureDraft({kind:'link',content:'',fileCount:2}), {
    type:'file',value:'',title:undefined
  });
  assert.deepEqual(prepareCaptureDraft({kind:'file',content:'Some files',fileCount:1}), {
    type:'file',value:'Some files',title:undefined
  });
});
