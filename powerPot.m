% Creates a table to convert voltage desired to PWM */

offset = 9; % Reduces leading zeros
scale = 0.97; % reduces step size

for power=1:0xff

  volts=0xff*(((power*scale+offset)/0xff)^2);
   if (volts > 0xff) % clips output
volts=0xff;
   endif


 printf("0x%0x", round(volts));

  if (rem(power, 12) == 0 || power == 0xff)
      printf(",\n");
  else
      printf(", ");
  endif

end
