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

  it 'should get a resouce', ->
    res = Resource 'fixture', cwd: __dirname
    should.exist res
    res.should.be.instanceOf Resource
  describe '#loadSync', ->
    it 'should load a resouce folder', ->
      loadCfgFile.register 'yml', yaml.safeLoad
      loadCfgFolder.register 'yml', yaml.safeLoad
      loadCfgFolder.addConfig '_config'
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', '_config'
    it 'should load a resouce file', ->
      loadCfgFile.register 'yml', yaml.safeLoad
      loadCfgFolder.register 'yml', yaml.safeLoad
      loadCfgFolder.addConfig '_config'
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', 'file0'
