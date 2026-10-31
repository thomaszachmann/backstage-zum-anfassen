import { resolveSafeChildPath } from '@backstage/backend-plugin-api';
import { createTemplateAction } from '@backstage/plugin-scaffolder-node';
import { promises as fs } from 'node:fs';
import { setTimeout as sleep } from 'node:timers/promises';

// kranich:ticket:create – simuliert ein Ticketsystem: schreibt TICKET.md
export function createTicketAction() {
  return createTemplateAction({
    id: 'kranich:ticket:create',
    description: 'Legt ein Onboarding-Ticket an (Lab: Datei TICKET.md)',
    supportsDryRun: true,
    schema: {
      input: {
        title: z => z.string({ description: 'Titel des Tickets' }),
        team: z => z.string({ description: 'Zuständiges Team (Entity-Ref)' }),
        token: z => z.string({ description: 'API-Token' }).optional(),
        delaySeconds: z =>
          z.number({ description: 'Simulierte Antwortzeit' }).default(0),
      },
      output: {
        ticketId: z => z.string({ description: 'Nummer des Tickets' }),
      },
    },
    async handler(ctx) {
      const { title, team, token, delaySeconds } = ctx.input;
      ctx.logger.info(`Ticketsystem: Token ${token ? 'gesetzt' : 'fehlt'}`);
      // nur Demo: der Scaffolder maskiert Secrets im Log
      if (token) ctx.logger.info(`Token zur Kontrolle: ${token}`);
      await sleep(delaySeconds * 1000, undefined, { signal: ctx.signal });

      const ticketId = ctx.isDryRun ? 'KRA-DRYRUN' : `KRA-${Date.now() % 100000}`;
      const file = resolveSafeChildPath(ctx.workspacePath, 'TICKET.md');
      await fs.writeFile(file, `# ${ticketId}: ${title}\n\nTeam: ${team}\n`);
      ctx.logger.info(`Ticket ${ticketId} für ${team} angelegt`);
      ctx.output('ticketId', ticketId);
    },
  });
}
