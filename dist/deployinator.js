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
    return new RSVP.Promise(this._uploadIfNotAlreadyInManifest(key, value).bind(this));
  };

  Deploy.prototype.listUploads = function(limit) {
    if (limit == null) {
      limit = this.manifestSize;
    }
    return this.adapter.listUploads(this.manifest, limit);
  };

  Deploy.prototype.setCurrent = function(key) {
    return new RSVP.Promise(this._setCurrentIfKeyInManifest(key).bind(this));
  };

  Deploy.prototype.getCurrent = function() {
    return this.adapter.get(this._currentKey());
  };

  Deploy.prototype._uploadIfNotAlreadyInManifest = function(key, value) {
    return function(resolve, reject) {
      return this.listUploads().then((function(keys) {
        var promises;
        if (keys.indexOf(key) === -1) {
          promises = {
            upload: this.adapter.upload(key, value),
            update: this.adapter.updateManifest(this.manifest, key),
            cleanup: this.adapter.cleanUpManifest(this.manifest, this.manifestSize)
          };
          return resolve(RSVP.hash(promises));
        } else {
          return reject();
        }
      }).bind(this));
    };
  };

  Deploy.prototype._setCurrentIfKeyInManifest = function(key) {
    return function(resolve, reject) {
      return this.adapter.listUploads(this.manifest, this.manifestSize).then((function(keys) {
        if (keys.indexOf(key) === -1) {
          return reject();
        } else {
          return this.adapter.upload(this._currentKey(), key).then(function() {
            return resolve();
          });
        }
      }).bind(this));
    };
  };

  Deploy.prototype._getKey = function() {
    var cmd, useSync;
    this.key = null;
    cmd = new git.Command('./', 'rev-parse', [], 'HEAD');
    cmd.exec(this._generateKey.bind(this), useSync = true);
    return this.key;
  };

  Deploy.prototype._generateKey = function(_error, sha, _stderr) {
    return this.key = "" + this.manifest + ":" + (sha.slice(0, 7));
  };

  Deploy.prototype._currentKey = function() {
    var _ref;
    return this.currentKey = (_ref = this.currentKey) != null ? _ref : "" + this.manifest + ":current";
  };

  return Deploy;

})();
