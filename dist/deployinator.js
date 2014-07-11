var Deploy, RSVP, RedisAdapter, git;

RedisAdapter = require('./adapters/redis_adapter');

git = require('gitty');

RSVP = require('rsvp');

module.exports = Deploy = (function() {
  function Deploy(options) {
    var _ref;
    this.adapter = (_ref = options.adapter) != null ? _ref : new RedisAdapter(options.storeConfig);
    this.manifest = options.manifest;
    this.manifestSize = options.manifestSize;
  }

  Deploy.prototype.upload = function(value) {
    var key;
    key = this._getKey();
    this.adapter.upload(key, value);
    this.adapter.updateManifest(this.manifest, key);
    return this.adapter.cleanUpManifest(this.manifest, this.manifestSize);
  };

  Deploy.prototype.listUploads = function(limit) {
    if (limit == null) {
      limit = this.manifestSize;
    }
    return this.adapter.listUploads(this.manifest, limit);
  };

  Deploy.prototype.setCurrent = function(key) {
    var adapter, manifest, manifestSize;
    adapter = this.adapter;
    manifest = this.manifest;
    manifestSize = this.manifestSize;
    return new RSVP.Promise(function(resolve, reject) {
      return adapter.listUploads(manifest, manifestSize).then(function(keys) {
        if (keys.indexOf(key) === -1) {
          return reject();
        } else {
          return adapter.upload("" + manifest + ":current", key).then(function() {
            return resolve();
          });
        }
      });
    });
  };

  Deploy.prototype._getKey = function() {
    var cmd, useSync;
    this.key = null;
    cmd = new git.Command('./', 'rev-parse', [], 'HEAD');
    cmd.exec(this._sliceGitSHA.bind(this), useSync = true);
    return this.key;
  };

  Deploy.prototype._sliceGitSHA = function(_error, sha, _stderr) {
    return this.key = sha.slice(0, 7);
  };

  return Deploy;

})();
