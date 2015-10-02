{app} = require './app'
routes = require './routes/web'

require './routes/socket'

app.get '/', routes.index
