serveStatic = require 'serve-static'
browserify = require 'browserify-middleware'
coffee = require 'coffee-script'
less = require 'less'
coffeeify = require 'coffeeify'
path = require 'path'
fs = require 'fs'

module.exports = (dir) ->
  dir = path.resolve dir

  lesshat = fs.readFileSync require.resolve 'lesshat/build/lesshat.less'
  lessMiddleware = (req, res, next) ->
    if req.path.indexOf('.less') != -1
      urlPath = req.path.substr(1)
      filepath = path.resolve(dir, urlPath)

      fs.readFile filepath, 'utf-8', (err, file) ->
        if err
          next()
        else
          unless req.query.nolesshat?
            file = file + lesshat

          parser = new less.Parser
            paths: [path.dirname filepath]
            filename: path.basename filepath

          parser.parse file, (err, tree) ->
            if err
              console.log err
              return next()

            try
              css = tree && tree.toCSS && tree.toCSS()
            catch err
              console.log err
              return next()

            res.header 'Content-Type', 'text/css'
            res.send css
    else
      next()
  coffeeMiddleware = (req, res, next) ->
    if req.path.indexOf('.coffee') != -1
      urlPath = req.path.substr(1)

      fs.readFile path.resolve(dir, urlPath), 'utf-8', (err, file) ->
        if err
          next()
        else
          res.header 'Content-Type', 'application/javascript'
          res.send(coffee.compile(file))
    else
      next()

  browserifyAndCoffeeMiddleware = browserify(dir,
    grep: /.(coffee|js)/i
    extensions: ['.coffee', '.js']
    transform: ['coffeeify']
  )
  staticMiddleware = serveStatic(dir)

  (req, res, next) ->
    fallback = (err) ->
      if err
        console.log err
      staticMiddleware(req, res, next)

    dotSplitted = req.path.split('.')
    if dotSplitted.length > 1 and not req.query.raw?
      extension = dotSplitted[dotSplitted.length - 1]

      if extension is 'coffee'
        unless req.query.nobrowserify?
          return browserifyAndCoffeeMiddleware(req, res, fallback)
        unless req.query.nocoffee?
          return coffeeMiddleware(req, res, fallback)

      if extension is 'js' and not req.query.nobrowserify?
        return browserifyAndCoffeeMiddleware(req, res, fallback)

      if extension is 'less' and not req.query.noless?
        return lessMiddleware(req, res, fallback)

    fallback(null)
