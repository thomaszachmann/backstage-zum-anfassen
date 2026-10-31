import { screen } from '@testing-library/react';
import { renderInTestApp } from '@backstage/frontend-test-utils';
import { fetchApiRef } from '@backstage/frontend-plugin-api';
import {
  EntityProvider,
  entityRouteRef,
} from '@backstage/plugin-catalog-react';
import { BereitschaftCard } from './BereitschaftCard';

const entity = {
  apiVersion: 'backstage.io/v1alpha1',
  kind: 'Component',
  metadata: { name: 'sendungs-api' },
  spec: { owner: 'group:default/team-sendung' },
};

describe('BereitschaftCard', () => {
  it('fragt das Backend mit dem Owner als team', async () => {
    const antwort = { datum: '2026-10-13', person: 'user:default/anna.berger' };
    const fetch = jest.fn(async () => Response.json(antwort));

    await renderInTestApp(
      <EntityProvider entity={entity}>
        <BereitschaftCard />
      </EntityProvider>,
      {
        apis: [[fetchApiRef, { fetch }]],
        mountedRoutes: { '/catalog/:namespace/:kind/:name': entityRouteRef },
      },
    );

    expect(await screen.findByText('anna.berger')).toBeInTheDocument();
    expect(fetch).toHaveBeenCalledWith(
      'plugin://bereitschaft/heute?team=team-sendung',
    );
  });
});
