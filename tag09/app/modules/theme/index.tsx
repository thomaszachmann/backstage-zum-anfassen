import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { ThemeBlueprint } from '@backstage/plugin-app-react';
import PaletteIcon from '@material-ui/icons/Palette';
import {
  UnifiedThemeProvider,
  createUnifiedTheme,
  genPageTheme,
  palettes,
  shapes,
} from '@backstage/theme';

// Kranich-Farben: Nachtblau, Kranich-Blau und das Rot der Krone
const kranichTheme = createUnifiedTheme({
  palette: {
    ...palettes.light,
    primary: { main: '#1d4e89' },
    secondary: { main: '#c8102e' },
    navigation: {
      ...palettes.light.navigation,
      background: '#0b2545',
      indicator: '#c8102e',
      selectedColor: '#ffffff',
    },
  },
  defaultPageTheme: 'home',
  pageTheme: {
    home: genPageTheme({ colors: ['#0b2545', '#1d4e89'], shape: shapes.wave }),
  },
});

const kranichThemeExtension = ThemeBlueprint.make({
  name: 'kranich',
  params: {
    theme: {
      id: 'kranich',
      title: 'Kranich',
      variant: 'light',
      icon: <PaletteIcon />,
      Provider: ({ children }) => (
        <UnifiedThemeProvider theme={kranichTheme} children={children} />
      ),
    },
  },
});

export const themeModule = createFrontendModule({
  pluginId: 'app',
  extensions: [kranichThemeExtension],
});
