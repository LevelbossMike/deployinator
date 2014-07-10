var Deploy, RedisAdapter, git;

RedisAdapter = require('./adapters/redis_adapter');

git = require('gitty');

module.exports = Deploy = (function() {
  function Deploy(options) {
    var _ref;
    this.adapter = (_ref = options.adapter) != null ? _ref : new RedisAdapter(options.storeConfig);
    this.manifest = options.manifest;
    this.manifestSize = options.manifestSize;
  }

  Deploy.prototype.deploy = function(value) {
    var key;
    key = this._getKey();
    this.adapter.deployBootstrapCode(key, value);
    this.adapter.updateManifest(this.manifest, key);
    return this.adapter.cleanUpManifest(this.manifest, this.manifestSize);
  };

  Deploy.prototype.listDeploys = function(limit) {
    if (limit == null) {
      limit = this.manifestSize;
    }
    return this.adapter.listDeploys(this.manifest, limit);
  };

  Deploy.prototype._getKey = function() {
    var cmd;
    this.key = null;
    cmd = new git.Command('./', 'rev-parse', [], 'HEAD');
    cmd.exec(this._sliceGitSHA.bind(this));
    return this.key;
  };

  Deploy.prototype._sliceGitSHA = function(_error, sha, _stderr) {
    return this.key = sha.slice(0, 6);
  };

  return Deploy;

})();
