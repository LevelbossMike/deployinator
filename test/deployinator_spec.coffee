expect     = require('expect.js')
redis      = require('then-redis')
RSVP       = require('rsvp')
git        = require('gitty')
sinon      = require('sinon')
Deploy     = require('../../../dist/deployinator.js')

getShortShaVersion = (sha) ->
  sha.slice(0, 6)

REDIS_CONNECTION_OPTIONS = { host: 'localhost', port: 6379 }
DOCUMENT_TO_SAVE         = 'Hello'
MANIFEST                 = 'test-deploy-manifest'
MANIFEST_SIZE            = 10
GIT_SHA                  = '04b724a6c656a21795067f9c344d22532cf593ae'
GIT_SHA_SHORTENED        = getShortShaVersion(GIT_SHA)
redisClient              = redis.createClient(REDIS_CONNECTION_OPTIONS)
deploy                   = null

options =
  storeConfig: REDIS_CONNECTION_OPTIONS
  manifest: MANIFEST
  manifestSize: MANIFEST_SIZE

deployWithSHA = (sha, done) ->
  sandbox = sinon.sandbox.create()
  sandbox
    .stub(git.Command.prototype, 'exec')
    .yields('error', sha, 'stderr')
  deploy = new Deploy(options)

  deployment = deploy.deploy(DOCUMENT_TO_SAVE)
  deployment.then ->
    done?()

  sandbox.restore()
  deployment

fillUpManifest = (deploymentCount, shaList = null) ->
  promises = []
  for n in[1..deploymentCount]
    newSHA = GIT_SHA.replace(GIT_SHA.charAt(0), n)
    shaList.push(getShortShaVersion(newSHA)) if shaList?
    promises.push(deployWithSHA(newSHA))
  promises

cleanUpRedis = (done) ->
  redisClient.del(MANIFEST)
    .then(-> redisClient.del(GIT_SHA_SHORTENED))
    .then(-> done?())

describe 'Deploy', ->

  describe '#deploy', ->

    beforeEach (done) ->
      deployWithSHA(GIT_SHA, done)

    afterEach (done) ->
      cleanUpRedis(done)

    it 'stores a passed value in Redis with the current git-sha as key', ->
      redisClient.get(GIT_SHA_SHORTENED)
        .then (value) ->
          expect(value).to.be(DOCUMENT_TO_SAVE)

    it 'updates a list of references of last deployments', ->
      redisClient.lrange(MANIFEST, 0, 10)
        .then (value) ->
          expect(value.length).to.be.greaterThan(0)

    it 'only keeps <manifestSize> revisions of deploys', ->
      moreThanManifestSize = MANIFEST_SIZE + 2

      RSVP.all(fillUpManifest(moreThanManifestSize)).then ->
        redisClient.lrange(MANIFEST, 0, moreThanManifestSize)
          .then (value) ->
            expect(value.length).to.be(MANIFEST_SIZE)

    it 'makes the deploy key available as a property after deploying', ->
      expect(deploy.key).to.be(GIT_SHA_SHORTENED)

  describe '#listDeploys ', ->
    shaList = []

    beforeEach ->
      shaList = []
      fillUpManifest(MANIFEST_SIZE, shaList)

    afterEach (done) ->
      cleanUpRedis(done)

    it 'lists all the deploys stored in the deploy manifest', ->
      deploy.listDeploys()
        .then (values) ->
          expect(values).to.contain("#{sha}") for sha in shaList

    it 'lists the last n-deploys when passing a number n', ->
      deploy.listDeploys(5)
        .then (values) ->
          expect(values.length).to.be(5)
          expect(values[0]).to.be("#{shaList[shaList.length - 1]}")
