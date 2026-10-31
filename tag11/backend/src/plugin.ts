import {
  coreServices,
  createBackendPlugin,
} from '@backstage/backend-plugin-api';
import { createRouter, Teams } from './router';

/**
 * bereitschaftPlugin backend plugin
 *
 * @public
 */
export const bereitschaftPlugin = createBackendPlugin({
  pluginId: 'bereitschaft',
  register(env) {
    env.registerInit({
      deps: {
        config: coreServices.rootConfig,
        logger: coreServices.logger,
        httpRouter: coreServices.httpRouter,
      },
      async init({ config, logger, httpRouter }) {
        const teams = config.getOptional<Teams>('bereitschaft.teams') ?? {};
        logger.info(`Bereitschaft für ${Object.keys(teams).length} Teams`);
        httpRouter.use(createRouter({ teams }));
      },
    });
  },
});
