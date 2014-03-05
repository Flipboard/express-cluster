# express-cluster

Run an express server on multiple processes. This is meant to be dropped in
directly to your main entry point without having to setup a separate script
that manages workers.

This actually works with any EventListener that emits the `"close"` event and
has a `close`. If it's a server object (e.g. an express app, `net.Server` or
`http.Server`, ensure that you've invoked `listen` before returning it).

By default the module will spawn N processes where N is the number of cores you
have. You can (and should) configure this parameter for your environments.

## Synopsis

    var express = require('express');
    var cluster = require('express-cluster')

    cluster(function() {
        var app = express();
        app.get('/', function(req, res) {
            res.send('ok');
        });
        return app.listen(0xbeef);
    }, {count: 5})

## Configuration options

    {
        count: 5,       // number of workers to spawn: defaults to CPU core count
        respawn: true,  // respawn process on exit: defaults to true
        verbose: false  // log what happens to console: defaults to false

	// Attach the given function to each spawned worker. The function will
	// be bound to the worker that sent the message so you can setup a two
	// way message bus if you please. See examples/messaging.js for an
	// example.
	workerListener: function(){}
    }
