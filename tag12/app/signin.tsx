import {
  ApiBlueprint,
  configApiRef,
  createApiRef,
  createFrontendModule,
  discoveryApiRef,
  oauthRequestApiRef,
} from '@backstage/frontend-plugin-api';
import {
  BackstageIdentityApi,
  OpenIdConnectApi,
  ProfileInfoApi,
  SessionApi,
} from '@backstage/core-plugin-api';
import { OAuth2 } from '@backstage/core-app-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import { SignInPage } from '@backstage/core-components';

// Eigene API-Referenz: core-plugin-api bringt keine für OIDC mit
export const forgejoAuthApiRef = createApiRef<
  OpenIdConnectApi & ProfileInfoApi & BackstageIdentityApi & SessionApi
>().with({ id: 'auth.forgejo' });

const forgejoAuthApi = ApiBlueprint.make({
  name: 'forgejo-auth',
  params: defineParams =>
    defineParams({
      api: forgejoAuthApiRef,
      deps: {
        discoveryApi: discoveryApiRef,
        oauthRequestApi: oauthRequestApiRef,
        configApi: configApiRef,
      },
      factory: ({ discoveryApi, oauthRequestApi, configApi }) =>
        OAuth2.create({
          configApi,
          discoveryApi,
          oauthRequestApi,
          environment: configApi.getOptionalString('auth.environment'),
          // muss 'oidc' heißen: Pfad /api/auth/oidc/… im Backend
          provider: { id: 'oidc', title: 'Forgejo', icon: () => null },
          defaultScopes: ['openid', 'profile', 'email'],
        }),
    }),
});

const signInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props =>
      (
        <SignInPage
          {...props}
          title="Kranich Entwicklerportal"
          providers={[
            'guest',
            {
              id: 'forgejo-auth-provider',
              title: 'Forgejo',
              message: 'Mit dem Forgejo-Konto anmelden',
              apiRef: forgejoAuthApiRef,
            },
          ]}
        />
      ),
  },
});

export const signInModule = createFrontendModule({
  pluginId: 'app',
  extensions: [forgejoAuthApi, signInPage],
});
