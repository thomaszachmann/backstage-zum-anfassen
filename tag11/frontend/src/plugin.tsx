import { createFrontendPlugin } from '@backstage/frontend-plugin-api';
import { EntityCardBlueprint } from '@backstage/plugin-catalog-react/alpha';

export const bereitschaftCard = EntityCardBlueprint.make({
  name: 'heute',
  params: {
    filter: { kind: 'component' },
    loader: () =>
      import('./components/BereitschaftCard').then(m => <m.BereitschaftCard />),
  },
});

export const bereitschaftPlugin = createFrontendPlugin({
  pluginId: 'bereitschaft',
  extensions: [bereitschaftCard],
});
