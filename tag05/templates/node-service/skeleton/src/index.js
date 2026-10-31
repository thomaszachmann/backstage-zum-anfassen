// ${{ values.name }} – erzeugt aus dem Template node-service
const http = require('node:http');

const port = process.env.PORT || 8080;
http
  .createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ service: '${{ values.name }}', status: 'ok' }));
  })
  .listen(port, () => console.log('${{ values.name }} lauscht auf Port', port));
