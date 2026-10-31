import {
  mockCredentials,
  mockServices,
  startTestBackend,
} from '@backstage/backend-test-utils';
import request from 'supertest';
import { bereitschaftPlugin } from './plugin';

describe('bereitschaftPlugin', () => {
  it('liest die Teams aus der Config und verlangt Auth', async () => {
    const { server } = await startTestBackend({
      features: [
        bereitschaftPlugin,
        mockServices.rootConfig.factory({
          data: { bereitschaft: { teams: { 'team-web': ['chris.dietz'] } } },
        }),
      ],
    });
    const url = '/api/bereitschaft/heute?team=team-web';

    const res = await request(server).get(url).expect(200);
    expect(res.body.person).toBe('user:default/chris.dietz');

    await request(server)
      .get(url)
      .set('Authorization', mockCredentials.none.header())
      .expect(401);
  });
});
