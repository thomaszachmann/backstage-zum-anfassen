import { makeStyles } from '@material-ui/core';

const useStyles = makeStyles({
  svg: { width: 'auto', height: 28 },
});

// Bildmarke: blaues Quadrat, stilisierter Kranich, rote Krone
export const KranichMark = () => (
  <g>
    <rect width="40" height="40" rx="8" fill="#1d4e89" />
    <path
      d="M9 30 L20 21 L31 9 L24 22 L33 24 L20 25 Z"
      fill="#ffffff"
    />
    <circle cx="31" cy="9" r="3.5" fill="#c8102e" />
  </g>
);

export const LogoIcon = () => {
  const classes = useStyles();
  return (
    <svg
      className={classes.svg}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 40 40"
    >
      <KranichMark />
    </svg>
  );
};
