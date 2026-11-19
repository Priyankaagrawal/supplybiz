import assert from 'node:assert/strict';
import { test } from 'node:test';
import { contentSignature, validContentKey } from '../src/lib/content';
void test('T-158 form keys bind the current session, action and record; reject changed scope/key/signature', () => {
 const key='11111111-1111-4111-8111-111111111111',signature=contentSignature('synthetic-session','faq:synthetic-id',key);
 assert.equal(validContentKey('synthetic-session','faq:synthetic-id',key,signature),true);
 for(const args of [['other-session','faq:synthetic-id',key,signature],['synthetic-session','config:mobile',key,signature],['synthetic-session','faq:synthetic-id','bad',signature],['synthetic-session','faq:synthetic-id',key,'bad']]) assert.equal(validContentKey(args[0],args[1],args[2],args[3]),false);
});
