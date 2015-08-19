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
fmatterMarkdown = require 'front-matter-markdown'
fs              = require 'fs'
fs.cwd          = process.cwd
Resource        = require '../src'

setImmediate    = setImmediate || process.nextTick
Resource.setFileSystem fs

describe 'ResourceFile', ->
  loadCfgFile.register 'yml', yaml.safeLoad
  loadCfgFolder.register 'yml', yaml.safeLoad
  loadCfgFolder.register 'md', fmatterMarkdown
  loadCfgFolder.addConfig ['_config', 'index', 'README']

  it 'should get a resource', ->
    res = Resource 'fixture', cwd: __dirname
    should.exist res
    res.should.be.instanceOf Resource
  describe '#loadSync', ->
    it 'should load a resource folder', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', '_config'
    it 'should load a resource file', ->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', 'file0'
    it 'should load a resource folder recursively', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.loadSync(read:true, recursive:true)
      should.exist res.contents
      res.should.have.property 'config', '_config'
      res.contents.should.have.length 5
      res.contents[2].getContentSync()
      res.contents.should.have.length 4
      result = []
      res.contents.forEach (i)->result.push i.inspect()
      result.should.be.deep.equal [
        '<File? "fixture/file0.md">'
        '<Folder "fixture/folder">'
        '<File "fixture/unknown">'
        '<File? "fixture/vfolder.md">'
      ]
  describe '#load', ->
    it 'should load a resource folder', (done)->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', '_config'
        done()
    it 'should load a resource file', (done)->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', 'file0'
        done()
    it 'should load a resource folder recursively', (done)->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.load read:true, recursive:true, (err, contents)->
        return done(err) if err
        should.exist contents
        res.should.have.property 'config', '_config'
        contents.should.have.length 5
        res.contents[2].getContentSync()
        res.contents.should.have.length 4
        result = []
        res.contents.forEach (i)->result.push i.inspect()
        result.should.be.deep.equal [
          '<File? "fixture/file0.md">'
          '<Folder "fixture/folder">'
          '<File "fixture/unknown">'
          '<File? "fixture/vfolder.md">'
        ]
        done()
