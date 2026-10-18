/* Boombox v27 Chinese names. Local display/search adapter; no disk/database writes. */
(function (root) {
  'use strict';
  var dict = root.BoomboxZHDictionary;
  function copy(value) {
    var result = {};
    Object.keys(value || {}).forEach(function (key) { result[key] = value[key]; });
    return result;
  }
  function bilingual(zh, en) { return zh + ' · ' + en; }
  function prepare(packs) {
    if (!packs || !dict) return packs;
    var result = {};
    Object.keys(packs).forEach(function (packId) {
      var source = packs[packId], pack = copy(source);
      result[packId] = pack;
      // Keep user-created names intact. Built-in sounds in Flags/Recent still use their IDs.
      if (packId !== 'user' && dict.packs[packId] && source.title.indexOf(dict.packs[packId] + ' · ') !== 0) pack.title = bilingual(dict.packs[packId], source.title);
      pack.categories = {};
      Object.keys(source.categories || {}).forEach(function (id) {
        var category = copy(source.categories[id]);
        var entry = dict.categories[id];
        if (packId !== 'user' && entry) category.title = bilingual(entry.zh, entry.en);
        pack.categories[id] = category;
      });
      pack.sounds = {};
      Object.keys(source.sounds || {}).forEach(function (id) {
        var original = source.sounds[id], sound = copy(original), terms = [];
        var entry = dict.sounds[id];
        if (packId !== 'user') {
          if (entry && (original.title === entry.en || original.title === bilingual(entry.zh, entry.en))) {
            sound.title = bilingual(entry.zh, entry.en);
            terms.push(entry.zh, entry.en, entry.keywords);
          }
          (original.categories || []).forEach(function (categoryId) {
            var category = dict.categories[categoryId];
            if (category) terms.push(category.zh, category.en, category.keywords || '');
          });
          // Do not duplicate aliases on repeated reducer passes.
          var base = String(original.searchString || '');
          var marker = ',__boombox_zh_v1__,';
          var markerAt = base.indexOf(marker);
          if (markerAt !== -1) base = base.slice(0, markerAt);
          sound.searchString = base + marker + terms.join(',').toLowerCase();
        }
        pack.sounds[id] = sound;
      });
    });
    return result;
  }
  root.BoomboxZH = { version: '1.0.0', prepare: prepare };
}(window));
