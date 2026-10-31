import {
  coreServices,
  createBackendModule,
  UserInfoService,
} from '@backstage/backend-plugin-api';
import {
  AuthorizeResult,
  isResourcePermission,
  PolicyDecision,
} from '@backstage/plugin-permission-common';
import {
  PermissionPolicy,
  PolicyQuery,
  PolicyQueryUser,
} from '@backstage/plugin-permission-node';
import { policyExtensionPoint } from '@backstage/plugin-permission-node/alpha';
import {
  catalogConditions,
  createCatalogConditionalDecision,
} from '@backstage/plugin-catalog-backend/alpha';

// Diese Aktionen bleiben dem Team Plattform vorbehalten
const NUR_PLATTFORM = [
  'catalog.entity.delete',
  'catalog.location.delete',
  'scaffolder.task.create',
];
const PLATTFORM = 'group:default/plattform';

class KranichPolicy implements PermissionPolicy {
  constructor(private readonly userInfo: UserInfoService) {}

  async handle(
    request: PolicyQuery,
    user?: PolicyQueryUser,
  ): Promise<PolicyDecision> {
    const regelt =
      NUR_PLATTFORM.includes(request.permission.name) ||
      request.permission.name === 'catalog.entity.refresh';
    if (!regelt) {
      return { result: AuthorizeResult.ALLOW };
    }
    if (!user) {
      return { result: AuthorizeResult.DENY };
    }
    const { ownershipEntityRefs } = await this.userInfo.getUserInfo(
      user.credentials,
    );
    // Challenge: Refresh nur für Owner – der Katalog prüft die Bedingung selbst
    if (
      isResourcePermission(request.permission, 'catalog-entity') &&
      request.permission.name === 'catalog.entity.refresh'
    ) {
      return createCatalogConditionalDecision(
        request.permission,
        catalogConditions.isEntityOwner({ claims: ownershipEntityRefs }),
      );
    }
    return ownershipEntityRefs.includes(PLATTFORM)
      ? { result: AuthorizeResult.ALLOW }
      : { result: AuthorizeResult.DENY };
  }
}

export default createBackendModule({
  pluginId: 'permission',
  moduleId: 'kranich-policy',
  register(reg) {
    reg.registerInit({
      deps: {
        policy: policyExtensionPoint,
        userInfo: coreServices.userInfo,
      },
      async init({ policy, userInfo }) {
        policy.setPolicy(new KranichPolicy(userInfo));
      },
    });
  },
});
