var express = require('express');
var cluster = require('..');

cluster(function() {
  var app = express();
  app.get('/', function(req, res) {
    res.send('ok');
  });
  return app.listen(0xbeef);
}, {count: 5, verbose: true});
