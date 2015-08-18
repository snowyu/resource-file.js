## resource-file [![npm](https://img.shields.io/npm/v/resource-file.svg)](https://npmjs.org/package/resource-file)

[![Build Status](https://img.shields.io/travis/snowyu/resource-file.js/master.svg)](http://travis-ci.org/snowyu/resource-file.js)
[![Code Climate](https://codeclimate.com/github/snowyu/resource-file.js/badges/gpa.svg)](https://codeclimate.com/github/snowyu/resource-file.js)
[![Test Coverage](https://codeclimate.com/github/snowyu/resource-file.js/badges/coverage.svg)](https://codeclimate.com/github/snowyu/resource-file.js/coverage)
[![downloads](https://img.shields.io/npm/dm/resource-file.svg)](https://npmjs.org/package/resource-file)
[![license](https://img.shields.io/npm/l/resource-file.svg)](https://npmjs.org/package/resource-file)

The Abstract Resource File Class inherited from
[AdvanceFile](https://github.com/snowyu/custom-file.js/blob/master/src/advance.coffee)

Each resource could have many custom attributes. These attributes could be a
[front-matter](http://jekyllrb.com/docs/frontmatter/) block in the same file,
or as a separate configuration file exists.

The priority is the front-matter > configuration file if they are both exist.

The Resource uses the [Front-matter](https://github.com/jonschlinkert/gray-matter)
to read the file attributes.

The separate configuration file name should be the same basename of the resource.

You can add the following configuration format(extname):

* YAML: .yml
* CSON: .cson
* TOML: .toml, .ini
* JSON: .json

You should register these formats by yourself.

It's only exists the separate configuration file if the resource if a folder.
The folder's configuration file name could be:

* `_config.(yml|cson|ini|json)`
* (index|readme).md

The folder's configuration file names need to be registered too.

## Usage

```coffee
loadCfgFile     = require 'load-config-file'
loadCfgFolder   = require 'load-config-folder'
yaml            = require 'gray-matter/lib/js-yaml'

loadCfgFile.register 'yml', yaml.safeLoad
loadCfgFolder.register 'yml', yaml.safeLoad
loadCfgFolder.addConfig '_config'

res = Resource './test/fixture'
res.loadSync(read:true)
res.should.have.property 'config', '_config'

res = resouce './test/'
```

## API

## TODOs

+ remove the folder's configuration file item from the contents of the folder.
+ replace the plain file object to the file object for customized contents of a folder.
* recursive the replaced contents "virtual folder".
  * howto load file contents recursively? or load on demand?
    because it may be exceed max memory if load all files at once.
    can use the getContent as load on demand.
    now the `getContent/getContentSync` supports the lazy load.

## License

MIT
