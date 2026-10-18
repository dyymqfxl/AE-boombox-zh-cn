'use strict';
// Optional development check: node tests/validate.cjs [original-extension-directory]
// Reads the original bundle only when explicitly supplied. Does not write to it.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert/strict');
const crypto = require('crypto');
const root = path.resolve(__dirname, '..');
const context = {window:{}};
vm.createContext(context);
for (const name of ['boombox-zh-cn.dictionary.js','boombox-zh-cn.js']) {
  vm.runInContext(fs.readFileSync(path.join(root,name),'utf8'),context);
}
const dict = context.window.BoomboxZHDictionary;
const api = context.window.BoomboxZH;
const spec = JSON.parse(fs.readFileSync(path.join(root,'patch-spec.json'),'utf8'));
assert.equal(dict.version,'1.0.0');
assert.equal(api.version,dict.version);
assert.equal(spec.version,dict.version);
assert.equal(Object.keys(dict.sounds).length,3950);
assert.equal(Object.keys(dict.categories).length,44);
const sounds = {};
for (const [id,entry] of Object.entries(dict.sounds)) {
  assert(/^[a-f0-9]{40}$/.test(id),'Invalid sound ID: '+id);
  assert(/[\u3400-\u9fff]/.test(entry.zh),'Missing Chinese: '+entry.en);
  assert(entry.en && entry.keywords,'Missing text: '+id);
  sounds[id] = {id,title:entry.en,searchString:entry.en.toLowerCase(),file:id+'.wav',categories:[],cuePoints:['1'],tags:''};
}
const packs = {sample:{title:'Sample',categories:{},sounds}};
const original = JSON.stringify(packs);
const output = api.prepare(packs);
assert.equal(JSON.stringify(packs),original,'Source data mutated');
assert(JSON.stringify(api.prepare(output))===JSON.stringify(output),'Repeated display conversion changed data');
for (const [id,entry] of Object.entries(dict.sounds)) {
  const sound=output.sample.sounds[id];
  assert.equal(sound.title,entry.zh+' · '+entry.en);
  assert(sound.searchString.includes(entry.zh.toLowerCase()));
  assert(sound.searchString.startsWith(entry.en.toLowerCase()));
  for(const key of ['id','file','categories','cuePoints','tags']) assert.deepEqual(sound[key],sounds[id][key]);
}
const queries = {'贝斯，刮弦':'Bass - Scrape 04','发动机':'Camaro Engine Turn On 02','雨声':'Rain Ambience','橡皮筋':'Rubber Band Pluck 01','bass':'Bass - Phrase 06'};
for(const [query,title] of Object.entries(queries)) {
  const matches=Object.values(output.sample.sounds).filter(s=>query.toLowerCase().split(/[,，]/).map(p=>p.trim()).filter(Boolean).every(p=>s.searchString.includes(p)));
  assert(matches.some(s=>s.title.endsWith(' · '+title)),'Search failed: '+query);
}
const custom={user:{title:'User',categories:{},sounds:{mine:{id:'mine',title:'我的自定义名称',searchString:'custom',categories:[],tags:''}}}};
assert.equal(JSON.stringify(api.prepare(custom)),JSON.stringify(custom));
if(process.argv[2]) {
  const file=path.join(path.resolve(process.argv[2]),'cep.js');
  const bytes=fs.readFileSync(file);
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),spec.sourceSha256,'Unsupported original bundle');
  let bundle=bytes.toString('utf8');
  for(const edit of spec.edits) {assert.equal(bundle.split(edit.from).length-1,edit.count);bundle=bundle.split(edit.from).join(edit.to);}
  new vm.Script(bundle);
  const start=bundle.indexOf('function Ta(s,o){'),end=bundle.indexOf('function Oa(',start);
  assert(start>=0 && end>start);
  vm.runInContext('var N=Object.assign;var y=function(a,b){return a.concat(b)};var g=function(a){return a[Symbol.iterator]()};'+bundle.slice(start,end)+';this.runTa=Ta;',context);
  const virtual=Object.assign({},packs,{flags:{title:'Flags',categories:{},sounds:{}},user:{title:'User',categories:{},sounds:{}},history:{title:'Recent',categories:{},sounds:{}}});
  for(const [query,title] of Object.entries(queries)) {
    const state={sounds:{},categories:{},tags:[],sortedSounds:[],sortedCategories:[],sortedTags:[],filteredSounds:[],activePacks:[],activeCategories:[],activeSound:null,query};
    assert(context.runTa(state,virtual).filteredSounds.some(s=>s.title.endsWith(' · '+title)),'Original search reducer: '+query);
  }
  console.log('PASS: original bundle checksum, hook counts, patched syntax and original search reducer.');
}
console.log('PASS: v1.0.0, 3950 bilingual names, 44 categories, Chinese/English search, source data preservation and repeat safety.');
