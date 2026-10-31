const express = require('express');
const app = express();
const sendungen = { 'KR-1001': { status: 'zugestellt' } };
app.get('/sendungen/:id', (req, res) =>
  sendungen[req.params.id] ? res.json(sendungen[req.params.id]) : res.sendStatus(404));
app.listen(8080);
