import { createMockActionContext } from '@backstage/plugin-scaffolder-node-test-utils';
import { createMockDirectory } from '@backstage/backend-test-utils';
import { createTicketAction } from './ticket';

describe('kranich:ticket:create', () => {
  const workspace = createMockDirectory();

  it('schreibt TICKET.md und gibt die Ticketnummer aus', async () => {
    const ctx = createMockActionContext({
      input: { title: 'Onboarding x', team: 'group:default/team-web', delaySeconds: 0 },
      workspacePath: workspace.path,
    });
    await createTicketAction().handler(ctx);
    expect(ctx.output).toHaveBeenCalledWith('ticketId', expect.stringMatching(/^KRA-/));
    expect(workspace.content()).toEqual({
      'TICKET.md': expect.stringContaining('Team: group:default/team-web'),
    });
  });
});
