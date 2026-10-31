import { createBackendModule } from '@backstage/backend-plugin-api';
import {
  authProvidersExtensionPoint,
  createOAuthProviderFactory,
} from '@backstage/plugin-auth-node';
import {
  oidcAuthenticator,
  oidcSignInResolvers,
} from '@backstage/plugin-auth-backend-module-oidc-provider';

// Ersetzt das Standardmodul: Forgejo meldet email_verified nur im ID-Token,
// nicht in /login/oauth/userinfo – ohne Transform bliebe profile.email leer.
export default createBackendModule({
  pluginId: 'auth',
  moduleId: 'forgejo-oidc',
  register(reg) {
    reg.registerInit({
      deps: { providers: authProvidersExtensionPoint },
      async init({ providers }) {
        providers.registerProvider({
          providerId: 'oidc',
          factory: createOAuthProviderFactory({
            authenticator: oidcAuthenticator,
            async profileTransform({ fullProfile }) {
              const claims = fullProfile.tokenset.claims();
              return {
                profile: {
                  email:
                    claims.email_verified === true ? claims.email : undefined,
                  displayName: fullProfile.userinfo.name,
                  picture: fullProfile.userinfo.picture,
                },
              };
            },
            signInResolverFactories: oidcSignInResolvers,
          }),
        });
      },
    });
  },
});
