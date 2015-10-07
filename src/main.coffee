serveStatic = require 'serve-static'
browserify = require 'browserify-middleware'
autoprefixer = require 'autoprefixer'
postcss = require 'postcss'
coffee = require 'coffee-script'
less = require 'less-minimal'
path = require 'path'
fs = require 'fs'

errorClientLib = fs.readFileSync require.resolve 'panel-error'

beep = ->
  process.stdout.write '\x07'

module.exports = (dir) ->
  dir = path.resolve dir

  lesshat = fs.readFileSync require.resolve 'lesshat/build/lesshat.less'
  lessMiddleware = (req, res, next) ->
    if req.path.indexOf('.less') != -1
      urlPath = req.path.substr(1)
      filepath = path.resolve(dir, urlPath)

      fs.readFile filepath, 'utf-8', (err, file) ->
        if err
          next(err)
        else
          unless req.query.nolesshat?
            file = file + lesshat

          parser = new less.Parser
            paths: [path.dirname filepath]
            filename: path.basename filepath

          parser.parse file, (err, tree) ->
            if err
              return next(err)

            try
              css = tree && tree.toCSS && tree.toCSS()
            catch err
              return next(err)

            res.header 'Content-Type', 'text/css'
            if req.query.autoprefixer?
              postcss([ autoprefixer ]).process(css).then (result) ->
                result.warnings().forEach (warn) -> console.warn(warn.toString())
                res.send result.css
            else
              res.send css
    else
      next()

  coffeeMiddleware = (req, res, next) ->
    if req.path.indexOf('.coffee') != -1
      urlPath = req.path.substr(1)

      fs.readFile path.resolve(dir, urlPath), 'utf-8', (err, file) ->
        if err
          next(err)
        else
          res.header 'Content-Type', 'application/javascript'
          res.send(coffee.compile(file))
    else
      next()

  jsErrorMiddleware = (req, res, next) ->
    output = "window._panelErrors = window._panelErrors || [];window._panelErrors.push(#{JSON.stringify(req._panelError.message)});"
    output += errorClientLib

    res.header 'Content-Type', 'application/javascript'
    res.send(output)

  browserifyAndCoffeeMiddleware = browserify(dir,
    grep: /.(coffee|js)/i
    extensions: ['.coffee', '.js']
    transform: ['coffeeify', 'envify']
    insertGlobals: true
    detectGlobals: false
    debug: process.env.NODE_ENV isnt 'production'
  )
  staticMiddleware = serveStatic(dir)

  (req, res, next) ->
    fallback = (err) ->
      if err
        beep()
        console.error ""
        console.error err
        console.error ""
        req._panelError = err

        if extension in ['js', 'coffee']
          jsErrorMiddleware(req, res, next)
          return

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
