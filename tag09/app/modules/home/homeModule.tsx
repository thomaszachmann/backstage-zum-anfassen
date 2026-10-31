import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { HomePageWidgetBlueprint } from '@backstage/plugin-home-react/alpha';
import { MarkdownContent } from '@backstage/core-components';

const content = `
## Willkommen im Kranich Entwicklerportal

Alles über unsere Software an einem Ort: Services, APIs, Teams und Doku.

- **[Katalog](/catalog)** – wem gehört was, wer nutzt welche API?
- **[Neues Projekt](/create)** – Golden Paths als Software Templates
- **[Dokumentation](/docs)** – TechDocs direkt aus den Repos

Fragen? Team Plattform, plattform@kranich.example
`;

const gettingStartedWidget = HomePageWidgetBlueprint.make({
  name: 'getting-started',
  params: {
    name: 'GettingStarted',
    title: 'Erste Schritte',
    description: 'Einstieg ins Kranich Entwicklerportal',
    components: async () => ({
      Content: () => <MarkdownContent content={content} />,
    }),
  },
});

export const homeModule = createFrontendModule({
  pluginId: 'home',
  extensions: [gettingStartedWidget],
});
