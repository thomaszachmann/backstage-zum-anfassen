import { createBackendModule } from '@backstage/backend-plugin-api';
import { scaffolderActionsExtensionPoint } from '@backstage/plugin-scaffolder-node';
import { createTicketAction } from './actions/ticket';

export const scaffolderModule = createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'kranich',
  register({ registerInit }) {
    registerInit({
      deps: { scaffolderActions: scaffolderActionsExtensionPoint },
      async init({ scaffolderActions }) {
        scaffolderActions.addActions(createTicketAction());
      },
    });
  },
});
