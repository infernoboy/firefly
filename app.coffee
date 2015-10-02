express = require 'express'
session = require 'express-session'
logger = require 'express-logger'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
errorHandler = require 'errorhandler'
http = require 'http'
path = require 'path'
{db} = require './db'
app = express()
less = require 'less-middleware'
socket = require 'socket.io'
socketHandshake = require 'socket.io-handshake'
socketRedis = require 'socket.io-redis'
SessionRedisStore = require('connect-redis')(session)

sessionStore = new SessionRedisStore
	host: '127.0.0.1'
	db: 1

crossOrigin = (req, res, next) ->
	if req.headers.origin and req._parsedUrl.pathname is '/api/init'
		res.header 'Access-Control-Allow-Credentials', 'true'
		res.header 'Access-Control-Allow-Origin', req.headers.origin
		res.header 'Access-Control-Allow-Methods', 'GET'
	next()

noCache = (req, res, next) ->
	res.header 'Cache-Control', 'no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0'
	next()

env = app.get('env')

app.set 'port', 3000
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
# app.use express.favicon, __dirname + '/public/favicon.ico'

if env is 'development'
	app.use logger path: path.join(__dirname, 'dev.log')

if env is 'production'
	app.use logger path: path.join(__dirname, 'production.log')

app.use bodyParser.json()
app.use cookieParser 'FIREFLYGOOOOO@#$$@!!!WEEEEMORGAN'

if env is 'development'
	app.use noCache

app.use crossOrigin
app.use less __dirname + '/public', force: true

if env is 'development'
	app.use express.static path.join(__dirname, 'public')
	app.use errorHandler()

if env is 'production'
	app.use express.static path.join(__dirname, 'public'), maxAge: 3000000

httpServer = http.createServer app

httpServer.listen app.get('port'), '0.0.0.0', ->
	console.log "Express server listening on port " + app.get 'port'

io = socket.listen httpServer

io.adapter socketRedis host: 'localhost'

io.use socketHandshake
	key: 'firefly'
	store: sessionStore
	parser: cookieParser 'FIREFLYGOOOOO@#$$@!!!WEEEEMORGAN'

io.use (socket, next) ->
	data = socket.request

	return next(new Error('no cookies')) unless data.headers.cookie

	data.cookie = cookie.parse data.headers.cookie

	return next(new Error('session init error: cooking missing')) unless data.cookie.firefly

	data.sessionID = data.cookie.firefly.split('.')[0][2..]

	sessionStore.get data.sessionID, (err, session) ->
		return next(new Error(err)) if err or not session

		next()

exports.io = io
exports.socket = io
exports.app = app

require './models'
require './urls'
