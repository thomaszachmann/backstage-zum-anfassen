import { InfoCard, Progress, WarningPanel } from '@backstage/core-components';
import { fetchApiRef, useApi } from '@backstage/frontend-plugin-api';
import { parseEntityRef } from '@backstage/catalog-model';
import { EntityRefLink, useEntity } from '@backstage/plugin-catalog-react';
import { Text } from '@backstage/ui';
import useAsync from 'react-use/esm/useAsync';

type Bereitschaft = {
  team: string;
  datum: string;
  person: string;
  telefon?: string;
};

export const BereitschaftCard = () => {
  const { entity } = useEntity();
  const { fetch } = useApi(fetchApiRef);
  const owner = String(entity.spec?.owner ?? '');
  const team = parseEntityRef(owner, { defaultKind: 'group' }).name;

  const { value, loading, error } = useAsync(async () => {
    const res = await fetch(`plugin://bereitschaft/heute?team=${team}`);
    if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
    return (await res.json()) as Bereitschaft;
  }, [fetch, team]);

  return (
    <InfoCard title="Bereitschaft">
      {loading && <Progress />}
      {error && <WarningPanel title={`Kein Plan für ${team}`} />}
      {value && (
        <Text as="p">
          Heute ({value.datum}) für {team}:{' '}
          <EntityRefLink entityRef={value.person} />
        </Text>
      )}
      {value?.telefon && <Text as="p">Telefon: {value.telefon}</Text>}
    </InfoCard>
  );
};
