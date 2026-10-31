import { makeStyles } from '@material-ui/core';
import { KranichMark } from './LogoIcon';

const useStyles = makeStyles({
  svg: { width: 'auto', height: 30 },
});

// Bildmarke plus Schriftzug „Kranich" für die ausgeklappte Sidebar
export const LogoFull = () => {
  const classes = useStyles();
  return (
    <svg
      className={classes.svg}
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 170 40"
    >
      <KranichMark />
      <text
        x="48"
        y="29"
        fill="#ffffff"
        fontFamily="Helvetica, Arial, sans-serif"
        fontSize="26"
        fontWeight="bold"
      >
        Kranich
      </text>
    </svg>
  );
};
