chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

loadCfgFile     = require 'load-config-file'
loadCfgFolder   = require 'load-config-folder'
yaml            = require 'gray-matter/lib/js-yaml'
fs              = require 'fs'
fs.cwd          = process.cwd
Resource        = require '../src'

setImmediate    = setImmediate || process.nextTick
Resource.setFileSystem fs

describe 'ResourceFile', ->
  loadCfgFile.register 'yml', yaml.safeLoad
  loadCfgFolder.register 'yml', yaml.safeLoad
  loadCfgFolder.addConfig '_config'

  it 'should get a resouce', ->
    res = Resource 'fixture', cwd: __dirname
    should.exist res
    res.should.be.instanceOf Resource
  describe '#loadSync', ->
    it 'should load a resouce folder', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', '_config'
    it 'should load a resouce file', ->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', 'file0'
  describe '#load', ->
    it 'should load a resouce folder', (done)->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', '_config'
        done()
    it 'should load a resouce file', (done)->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', 'file0'
        done()
