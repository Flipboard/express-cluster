cluster = require "cluster"
os = require "os"

#
# Master process: Fork processes and hook cleanup signals as required.
#

master = (config) ->
  # determine count first from config then from the environment var WORKER_COUNT
  # if either parse incorrectly, NaN is returned. We require the count to be
  # greater than zero, so we fall back to CPU count if anything is out of the
  # ordinary
  count = parseInt(config.count or process.env.WORKER_COUNT)
  workerCount = if count > 0 then count else os.cpus().length

  respawn =
    if typeof config.respawn is "undefined"
      true
    else
      Boolean config.respawn

  outputStream =
    if config.outputStream and typeof config.outputStream.write is "function"
      config.outputStream.write
    else
      console.log

  workers = []
  if config.verbose
    outputStream "Master started on pid #{process.pid}, forking #{workerCount} processes"
  for i in [0 ... workerCount]
    worker = cluster.fork()
    if typeof config.workerListener is "function"
      worker.on "message", config.workerListener
    workers.push worker

  cluster.on "exit", (worker, code, signal) ->
    if config.verbose
      outputStream "#{worker.process.pid} died with #{signal or "exit code #{code}"}" +
        if respawn then ", restarting" else ""
    idx = workers.indexOf worker
    if idx > -1
      workers.splice idx, 1
    if respawn
      worker = cluster.fork()
      if typeof config.workerListener is "function"
        worker.on "message", config.workerListener
      workers.push worker

  process.on "SIGQUIT", ->
    respawn = false
    if config.verbose
      outputStream "QUIT received, will exit once all workers have finished current requests"
    for worker in workers
      worker.send "quit"

#
# Single worker process: attach close and message handlers
#

worker = (fn, worker) ->
  server = fn(worker)

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

module.exports = (arg0, arg1) ->
  fn = ->
  config = {}
  if typeof arg0 is 'function'
    fn = arg0
    config = arg1 || config
  else if typeof arg1 is 'function'
    fn = arg1
    config = arg0 || config
  if cluster.isMaster
    master config
  else
    worker fn, cluster.worker
