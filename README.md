# Panel Static

Extending express.static to compile CoffeeScript with Browserify to Javascript and LESS to CSS

# Before you use

This is not expected to work in standard server environment as it doesn't use any caching method. This is specificaly designed to work in Panels in Sketch and Photoshop.

# Instalation

```
npm install panel-static
```

# Usage

```
path = require 'path'
express = require 'express'
panelStatic = require 'panel-static'

directory = path.join(__dirname, 'public')

app = express()
app.use(panelStatic(directory))
app.listen(PORT)
```

All files with extension `.js`, `.coffee` or `less` would be processed on the fly.

## Special flags

You can manually force request to just serve static file by adding `raw` param to url or you can disable only some features in your request. Use them as params in query string, for example `http://example.com/style.less?noless`, `http://example.com/jquery.js?nobrowserify`

### For `.js` files

- nobrowserify to get raw js file

### For `.coffee` files (you can use both together)

- nobrowserify to just compile Coffee Script and skip browserify
- nobrowserify & nocoffee to get raw coffee file

### For `.less` files

- noless to get raw less file
