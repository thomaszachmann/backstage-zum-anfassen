import { InputError, NotFoundError } from '@backstage/errors';
import express from 'express';
import Router from 'express-promise-router';

/** Team-Name → Liste der User-Namen (aus bereitschaft.teams) */
export type Teams = Record<string, string[]>;

/** Reihum: jeden Tag ist die nächste Person dran. */
export function wer(personen: string[], datum: Date): string {
  const tag = Math.floor(datum.getTime() / 86_400_000);
  return personen[tag % personen.length];
}

export function createRouter(options: { teams: Teams }): express.Router {
  const router = Router();

  router.get('/heute', async (req, res) => {
    const team = req.query.team;
    if (typeof team !== 'string' || team === '') {
      throw new InputError('Parameter team fehlt');
    }
    const personen = options.teams[team];
    if (!personen?.length) {
      throw new NotFoundError(`Keine Bereitschaft für ${team}`);
    }
    const datum = new Date();
    res.json({
      team,
      datum: datum.toISOString().slice(0, 10),
      person: `user:default/${wer(personen, datum)}`,
    });
  });

  return router;
}
