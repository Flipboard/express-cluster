cluster = require "cluster"
os = require "os"
http = require "http"

#
# Master process: Fork processes and hook cleanup signals as required.
#

master = (config) ->
  workerCount = config.count ? parseInt(process.env.WORKER_COUNT) or os.cpus().length
  respawn =
    if typeof config.respawn is "undefined"
      true
    else
      Boolean config.respawn
  workers = []
  if config.verbose
    console.log "Master started on pid #{process.pid}, forking #{workerCount} processes"
  for i in [0 .. workerCount - 1]
    workers.push cluster.fork()

  cluster.on "exit", (worker, code, signal) ->
    if config.verbose
      console.log "#{worker.process.pid} died with code #{code}, restarting"
    if respawn
      cluster.fork()

  process.on "SIGQUIT", ->
    if config.verbose
      console.log "QUIT received, will exit once all workers have finished current requests"
    for worker in workers
      worker.send "quit"

#
# Single worker process: attach close and message handlers
#

worker = (fn) ->
  server = fn()

  if not server
    return

  if typeof server.on is "function"
    server.on "close", ->
      process.exit()

  if typeof server.close is "function"
    # Handle master messages
    process.on "message", (msg) ->
      if msg is "quit"
        # Stop accepting new connections
        server.close()

module.exports = (fn, config={}) ->
  if cluster.isMaster
    master config
  else
    worker fn
