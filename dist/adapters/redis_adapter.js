var RedisAdapter, redis;

redis = require('then-redis');

module.exports = RedisAdapter = (function() {
  function RedisAdapter(options) {
    this.client = redis.createClient(options);
  }

  RedisAdapter.prototype.upload = function(key, value) {
    return this.client.set(key, value);
  };

  RedisAdapter.prototype.updateManifest = function(manifest, key) {
    return this.client.lpush(manifest, key);
  };

  RedisAdapter.prototype.cleanUpManifest = function(manifest, manifestSize) {
    return this.client.ltrim(manifest, 0, manifestSize - 1);
  };

  RedisAdapter.prototype.listUploads = function(manifest, limit) {
    return this.client.lrange(manifest, 0, limit - 1);
  };

  RedisAdapter.prototype.get = function(key) {
    return this.client.get(key);
  };

  return RedisAdapter;

})();
