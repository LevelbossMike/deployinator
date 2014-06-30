var RedisAdapter, redis;

redis = require('then-redis');

module.exports = RedisAdapter = (function() {
  function RedisAdapter(options) {
    this.client = redis.createClient(options);
  }

  RedisAdapter.prototype.deployBootstrapCode = function(timestampKey, bootstrapFile) {
    return this.client.set(timestampKey, bootstrapFile);
  };

  RedisAdapter.prototype.updateManifest = function(manifest, timestampKey) {
    return this.client.lpush(manifest, timestampKey);
  };

  RedisAdapter.prototype.cleanUpManifest = function(manifest, manifestSize) {
    return this.client.ltrim(manifest, 0, manifestSize - 1);
  };

  RedisAdapter.prototype.listDeploys = function(manifest, limit) {
    return this.client.lrange(manifest, 0, limit - 1);
  };

  return RedisAdapter;

})();
