var Deploy, RedisAdapter;

RedisAdapter = require('./adapters/redis_adapter');

module.exports = Deploy = (function() {
  function Deploy(options) {
    var _ref;
    this.adapter = (_ref = options.adapter) != null ? _ref : new RedisAdapter(options.storeConfig);
    this.manifest = options.manifest;
    this.manifestSize = options.manifestSize;
  }

  Deploy.prototype.deploy = function(value) {
    var timestamp;
    timestamp = this._getTimestamp();
    this.adapter.deployBootstrapCode(timestamp, value);
    this.adapter.updateManifest(this.manifest, timestamp);
    return this.adapter.cleanUpManifest(this.manifest, this.manifestSize);
  };

  Deploy.prototype.listDeploys = function(limit) {
    if (limit == null) {
      limit = this.manifestSize;
    }
    return this.adapter.listDeploys(this.manifest, limit);
  };

  Deploy.prototype._getTimestamp = function() {
    return new Date().getTime();
  };

  return Deploy;

})();
