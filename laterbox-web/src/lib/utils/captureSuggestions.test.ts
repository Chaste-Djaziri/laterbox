import assert from 'node:assert/strict';
import test from 'node:test';
import { captureSummary, suggestCapture, suggestionLabel } from './captureSuggestions';
import { resolveReturnPreset } from './schedule';

const now = new Date(2026, 9, 23, 9, 15);

test('auto suggestions use task language without changing captured content', () => {
  const urgent = suggestCapture('TODO: submit the work report today', 'task', [], now);
  assert.equal(urgent.preset, 'laterToday');
  assert.equal(urgent.returnAt, resolveReturnPreset('laterToday', now));
  assert.deepEqual(urgent.tags, ['Work']);
  assert.deepEqual(suggestCapture('Urgent work deadline', 'task', [], now).tags, ['Work', 'Urgent']);
  assert.equal(urgent.title, 'TODO: submit the work report today');
  assert.equal(suggestCapture('Read the article next week', 'note', [], now).preset, 'oneWeek');
  assert.equal(suggestCapture('Watch the video someday', 'note', [], now).preset, 'someday');
  assert.equal(suggestCapture('Buy groceries tomorrow', 'note', [], now).preset, 'tomorrow');
});

test('URL hostname does not produce accidental scheduling hints', () => {
  const link = suggestCapture('https://urgent-today.example.com/docs?q=work', 'link', [], now);
  assert.equal(link.title, 'urgent-today.example.com');
  assert.equal(link.preset, 'weekend');
  assert.equal(link.tags.length, 0);
  const annotated = suggestCapture('Read later: https://example.com/long-link', 'note', [], now);
  assert.equal(annotated.title, 'Read later:');
  assert.deepEqual(annotated.tags, ['Reading']);
});

test('files and empty notes retain useful defaults, without fabricated tags', () => {
  assert.equal(suggestCapture('', 'file', ['assignment.pdf'], now).title, 'assignment.pdf');
  assert.equal(suggestCapture('', 'file', ['assignment.pdf'], now).preset, 'tomorrow');
  assert.equal(suggestCapture('', 'note', [], now).title, '');
  assert.equal(suggestCapture('Some thoughts', 'note', [], now).preset, 'tomorrow');
  assert.equal(captureSummary('', ['a.pdf', 'b.pdf']), '2 attached files');
  assert.equal(captureSummary('Notes\nMore notes', ['a.pdf']), 'Notes · 1 attached file');
  assert.equal(suggestionLabel(suggestCapture('someday', 'note', [], now)), 'Someday (no deadline)');
});

test('title suggestions are capped and preserve user-entered natural language', () => {
  const text = 'x'.repeat(145);
  assert.equal(suggestCapture(text, 'note', [], now).title.length, 100);
});
