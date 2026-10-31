import { mockErrorHandler } from '@backstage/backend-test-utils';
import express from 'express';
import request from 'supertest';
import { createRouter, wer } from './router';

const teams = { 'team-sendung': ['anna.berger', 'ben.kraus'] };

describe('createRouter', () => {
  const app = express().use(createRouter({ teams })).use(mockErrorHandler());

  it('liefert die Bereitschaft eines Teams', async () => {
    const res = await request(app).get('/heute?team=team-sendung');
    expect(res.status).toBe(200);
    expect(res.body.person).toMatch(
      /^user:default\/(anna\.berger|ben\.kraus)$/,
    );
  });

  it('antwortet 400 ohne team und 404 für unbekannte Teams', async () => {
    expect((await request(app).get('/heute')).status).toBe(400);
    expect((await request(app).get('/heute?team=team-xyz')).status).toBe(404);
  });
});

describe('wer', () => {
  it('wechselt jeden Tag', () => {
    const p = ['a', 'b'];
    const montag = wer(p, new Date('2026-10-12T08:00:00Z'));
    expect(wer(p, new Date('2026-10-13T08:00:00Z'))).not.toBe(montag);
  });
});
