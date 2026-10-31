// ${{ values.name }} – erzeugt aus dem Template kranich-service
const http = require('node:http');
const env = process.env.UMGEBUNG || 'dev';
const config = require(`../config/${env}.json`);

http
  .createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ service: config.service, umgebung: env }));
  })
  .listen(config.port, () => console.log(config.service, 'auf Port', config.port));
