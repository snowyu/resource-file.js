chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

setPrototypeOf  = require 'inherits-ex/lib/setPrototypeOf'
loadCfgFile     = require 'load-config-file'
loadCfgFolder   = require 'load-config-folder'
yaml            = require('gray-matter/lib/parsers').yaml
fmatterMarkdown = require 'front-matter-markdown'
extend          = require 'util-ex/lib/_extend'
fs              = require 'fs'
fs.cwd          = process.cwd
fs.path         = require 'path.js'
Resource        = require '../src'

setImmediate    = setImmediate || process.nextTick
Resource.setFileSystem fs
filterBehaviorTest = require 'custom-file/test/filter'
path = fs.path

buildTree = (aContents, result)->
  aContents.forEach (i)->
    if i.isDirectory() and i.contents
      result.push v = {}
      v[i.inspect()] = buildTree i.contents, []
    else
      result.push i.inspect()
  result

describe 'ResourceFile', ->
  loadCfgFile.register 'yml', yaml
  loadCfgFolder.register 'yml', yaml
  loadCfgFolder.register 'md', fmatterMarkdown
  loadCfgFolder.addConfig ['_config', 'INDEX', 'index', 'README']

  it 'should setFileSystem to load-config-file and load-config-folder', ->
    fakeFS = extend {}, fs
    Resource.setFileSystem fakeFS
    expect(loadCfgFile::fs).to.be.equal fakeFS
    expect(loadCfgFolder::fs).to.be.equal fakeFS
    Resource.setFileSystem fs
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
      res.contents.should.have.length 5
      expect(res.date).to.be.an.instanceOf Date
      expect(res.title).to.be.equal 'Fixture'
    it 'should load a resource folder with summary', ->
      res = Resource 'fixture/folder', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', 'README'
      res.contents.should.have.length 4
      expect(res.summary).to.be.equal '\nthis is README.'
      expect(res.date).to.be.an.instanceOf Date
      expect(res.title).to.be.equal 'Folder'
    it 'should load a resource file', ->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', 'file0'
      expect(res.date).to.be.an.instanceOf Date
      expect(res.title).to.be.equal 'File 0'
    it 'should not get title and date from a resource file if property exists', ->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      vDate = new Date()
      vTtile = 'Custom title'
      res.title = vTtile
      res.date = vDate
      res.loadSync(read:true)
      res.should.have.property 'config', 'file0'
      expect(res.date).to.be.deep.equals vDate
      expect(res.title).to.be.equal vTtile
    it 'should load a resource folder recursively', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.loadSync(read:true, recursive:true)
      should.exist res.contents
      res.should.have.property 'config', '_config'
      res.contents.should.have.length 5 # the unknown file is not loaded.
      res.contents[2].getContentSync()
      res.contents.should.have.length 4
      expect(res.date).to.be.an.instanceOf Date
      expect(res.title).to.be.equal 'Fixture'
      result = buildTree(res.contents, [])
      expected = [
        '<File? "fixture/file0.md">'
        '<Folder "fixture/folder">': [
          '<File? "fixture/folder/file10.md">'
          '<Folder "fixture/folder/folder1">': []
        ,
          '<Folder "fixture/folder/folder2">': [
            '<File? "fixture/folder/folder2/test.md">'
          ]
          '<File? "fixture/folder/vfolder1.md">'
        ]
        '<File "fixture/unknown">'
        '<File? "fixture/vfolder.md">'
      ]
      if path.isWindows
        expected = [
          '<File? "fixture\\file0.md">'
          '<Folder "fixture\\folder">': [
            '<File? "fixture\\folder\\file10.md">'
            '<Folder "fixture\\folder\\folder1">': []
          ,
            '<Folder "fixture\\folder\\folder2">': [
              '<File? "fixture\\folder\\folder2\\test.md">'
            ]
            '<File? "fixture\\folder\\vfolder1.md">'
          ]
          '<File "fixture\\unknown">'
          '<File? "fixture\\vfolder.md">'
        ]
      result.should.be.deep.equal expected
    it 'should load a resource virtual folder', ->
      res = Resource 'vfolder.md', cwd: __dirname, base: 'fixture', load:true,read:true
      should.exist res, 'res'
      res.isDirectory().should.be.true
      should.exist res.contents, 'res.contents'
      expect(res.date).to.be.deep.equal new Date('2011-01-11T11:11:00Z')
      expect(res.title).to.be.equal 'Virtual Folder'
      result = res.contents
      expect(result[0].title).to.be.equal 'File Zero'
      result = buildTree(result, [])
      result.should.be.deep.equal ['<File? "file0.md">']
    it 'should inherit the parent\'s config', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.loadSync(read:true)
      res.should.have.property 'config', '_config'
      res.contents.should.have.length 5
      res.contents[0].getContentSync()
      res.should.have.ownProperty 'superLst'
      res.should.have.ownProperty 'superObj'
      res.should.have.ownProperty 'superStr'
      res.should.have.ownProperty 'superNum'
      res.superLst.should.be.deep.equal ['as', 'it']
      res.superObj.should.be.deep.equal key1:'hi', key2:'world'
      res.superStr.should.be.equal 'hi'
      res.superNum.should.be.equal 123
      res = res.contents[0]
      res.should.have.ownProperty 'superLst'
      res.should.have.ownProperty 'superObj'
      res.should.have.ownProperty 'superStr'
      res.should.have.ownProperty 'superNum'
      res.superLst.should.be.deep.equal ['add1','add2','as', 'it']
      res.superObj.should.be.deep.equal key1:'HI', key2:'world', key3:'append'
      res.superStr.should.be.equal 'hi world'
      res.superNum.should.be.equal 126
    it 'should load a resource file with getContent', ->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      result = res.getContentSync()
      res.should.have.property 'config', 'file0'
      expect(res.skipSize).to.be.at.least 104


  describe '#load', ->
    it 'should load a resource folder', (done)->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', '_config'
        expect(res.date).to.be.an.instanceOf Date
        expect(res.title).to.be.equal 'Fixture'
        done()
    it 'should load a resource folder with summary', (done)->
      res = Resource 'fixture/folder', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', 'README'
        expect(res.contents).have.length 4
        expect(res.summary).to.be.equal '\nthis is README.'
        expect(res.date).to.be.an.instanceOf Date
        expect(res.title).to.be.equal 'Folder'
        done()
    it 'should load a resource file', (done)->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', 'file0'
        expect(res.date).to.be.an.instanceOf Date
        expect(res.title).to.be.equal 'File 0'
        done()
    it 'should not get title and date from a resource file if property exists', (done)->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      vDate = new Date()
      vTtile = 'Custom title'
      res.title = vTtile
      res.date = vDate
      res.load read:true, (err, result)->
        return done(err) if err
        res.should.have.property 'config', 'file0'
        expect(res.date).to.be.deep.equals vDate
        expect(res.title).to.be.equal vTtile
        done()
    it 'should load a resource file with a configuration file', (done)->
      res = Resource '.', cwd: __dirname, base:'fixture', load:true,read:true
      expect(res).be.exist
      should.exist res.contents, 'res.contents'
      for file in res.contents
        break if file.relative is 'unknown'
      expect(file).have.property 'relative', 'unknown'
      expect(file.parent).be.equal res
      file.load read:true, (err, result)->
        return done(err) if err
        file.should.have.property 'config', 'unknown'
        done()
    it 'should load a resource folder recursively', (done)->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      res.load read:true, recursive:true, (err, contents)->
        return done(err) if err
        should.exist contents
        res.should.have.property 'config', '_config'
        contents.should.have.length 5
        # the "unknown" file
        res.contents[2].getContent (err)->
          res.contents.should.have.length 4
          result = buildTree(res.contents, [])
          expected = [
            '<File? "fixture/file0.md">'
            '<Folder "fixture/folder">': [
              '<File? "fixture/folder/file10.md">'
              '<Folder "fixture/folder/folder1">': []
            ,
              '<Folder "fixture/folder/folder2">': [
                '<File? "fixture/folder/folder2/test.md">'
              ]
              '<File? "fixture/folder/vfolder1.md">'
            ]
            '<File "fixture/unknown">'
            '<File? "fixture/vfolder.md">'
          ]
          if path.isWindows
            expected = [
              '<File? "fixture\\file0.md">'
              '<Folder "fixture\\folder">': [
                '<File? "fixture\\folder\\file10.md">'
                '<Folder "fixture\\folder\\folder1">': []
              ,
                '<Folder "fixture\\folder\\folder2">': [
                  '<File? "fixture\\folder\\folder2\\test.md">'
                ]
                '<File? "fixture\\folder\\vfolder1.md">'
              ]
              '<File "fixture\\unknown">'
              '<File? "fixture\\vfolder.md">'
            ]
          result.should.be.deep.equal expected
          done()
    it 'should load a resource virtual folder', (done)->
      res = Resource 'vfolder.md', cwd: __dirname, base: 'fixture'
      should.exist res, 'res'
      res.load read:true, (err, result)->
        unless err
          res.isDirectory().should.be.true
          should.exist res.contents, 'res.contents'
          expect(res.date).to.be.deep.equal new Date('2011-01-11T11:11:00Z')
          expect(res.title).to.be.equal 'Virtual Folder'
          expect(result[0].title).to.be.equal 'File Zero'
          result = buildTree(result, [])
          result.should.be.deep.equal ['<File? "file0.md">']
        done(err)
    it 'should load a resource file with getContent', (done)->
      res = Resource 'fixture/file0.md', cwd: __dirname
      should.exist res
      res.getContent (err, result)->
        return done(err) if err
        res.should.have.property 'config', 'file0'
        expect(res.skipSize).to.be.at.least 104
        done()

  describe '#toObject', ->
    it 'should convert a resource to a plain object', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      result = res.toObject()
      result.should.be.deep.equal
        cwd: __dirname
        base: __dirname
        path: path.join __dirname, 'fixture'
      f = {}
      setPrototypeOf f, res
      res.loadSync(read:true)
      result = res.toObject()
      result.should.have.ownProperty 'stat'
      result.should.have.ownProperty 'contents'
      result = f.toObject()
      result.should.not.have.ownProperty 'stat'
      result.should.not.have.ownProperty 'contents'
    it 'should convert a resource to a plain object and exclude', ->
      res = Resource 'fixture', cwd: __dirname
      should.exist res
      result = res.toObject(null, 'base')
      result.should.be.deep.equal
        cwd: __dirname
        path: path.join __dirname, 'fixture'
      result = res.toObject(null, ['base', 'path'])
      result.should.be.deep.equal
        cwd: __dirname

  #TODO: only supports buffer!! the filter should be run after loading config.
  # describe '#filter', filterBehaviorTest Resource,
  #   {path:path.join(__dirname, 'fixture/folder'), base: __dirname},
  #   (file)->
  #     path.basename(file.path) is 'file10.md'
  #   ,['fixture/folder/file10.md']
