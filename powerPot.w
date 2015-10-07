
% powerPot
\input miniltx
\input graphicx

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction.

This converts the voltage from a potentiometer to a PWM output for heavier
loads.
The load then just need a switching device like a transistor.
Since the switch does not operate in a partialy on state, it disipates very
little power.

@* Operation
The potentiometer is connected across VCC, be it 3.3 or 5 Volts.
The wiper of the pot can then have any voltage from 0 to VCC.
The wiper is connected to the multiplexer. The MUX then selects this input and
connects it to the ADC.
The ADC is configured to use VCC as its reference voltage and to provide only
8 bits (0 -- 255).
For those reasons the ADC resolves 0 to VCC to an integer over the range of
0 to 255.
That integer is fed to the PWM timer.
The loop alternates between channels.



\vskip 4 pc
\includegraphics[width=35 pc]{powerPot.png}

Extensive use was made of the datasheet, Atmel ``Atmel ATtiny25, ATtiny45,
 ATtiny85 Datasheet'' Rev. 2586Q–AVR–08/2013 (Tue 06 Aug 2013 03:19:12 PM EDT)
and ``AVR130: Setup and Use the AVR Timers'' Rev. 2505A–AVR–02/02.
@c
@< Include @>@;
@< Volts Table @>@;


@ |"F_CPU"| is used to convey the Trinket clock rate.
@d F_CPU 8000000UL


@ @<Include...@>=
# include <avr/io.h> // need some port access
# include <avr/interrupt.h> // have need of an interrupt
# include <avr/sleep.h> // have need of sleep
# include <stdlib.h>
# include <stdint.h>





@/
int main(void)@/
{@/

@<Initialize ADC@>@/

@<Initialize Timer@>@/

uint8_t pot = 0;

@

@c
  sei();
@
Rather than burning loops, waiting for something to happen,
the ``sleep'' mode is used.
The specific type of sleep is `idle'.
In idle, execution stops but timers continue and ADC conversion begins.

@c
 for (;;)@/
  {@/

  @
  The selected pot toggles at the beginning of each loop.
  @c

  pot = (pot == 0)?1:0;

  @
  Next a potentiometer is selected by setting the MUX.
  @c
  if (pot == 0)
     ADMUX = (ADMUX & 0xF0U)|0x03U; // ADC3 at PB3
   else
     ADMUX = (ADMUX & 0xF0U)|0x02U; // ADC2 at PB4

  @
  Now we wait in ``idle'' for an ADC conversion (7.1.1).
  The counter timer, and so PWM, will continue during sleep.
  @c
    sleep_mode();
  @
  If execution arrives here, some interrupt has been detected.
  Usualy we would check for which interrupt but we will assume that it's
  the ADC.

  Next the pot position, as determined by the ADC, is converted to a PWM value
  and written to the respective timer.
  PWM is naturally current but the table returns the PWM that would result in
  a voltage response..
  @c

  if (pot == 0)
    OCR0A = volts[ADCH]; // PB0 PWM
   else
    OCR0B = volts[ADCH]; // PB1 PWM

  } // end for

return 0;
} // end main()


@* These are the configuration blocks.


@ @<Initialize ADC@>=
{@/
  ADMUX  |= (1<<ADLAR); // Left adjust for an 8 bit result
  ADCSRA |= (1<<ADPS2); // 500 kHz ADC clock
  ADCSRA |= (1<<ADIE);  // Interrupt on completion
  ADCSRA |= (1<<ADEN);  // Enable ADC (prescaler starts up)
  // DIDR0 17.13.5
  DIDR0  |= (1<<ADC2D); // Disable digital on ADC2
  DIDR0  |= (1<<ADC3D); // Disable digital on ADC3
}

@
Timer Counter 0 is configured for ``Phase Correct'' PWM which, according to the
datasheet, is preferred for motor control.
OC0A and OC0B are set to clear on a match which creates a
non-inverting PWM.
@c

@ @<Initialize Timer@>=
{@/

 // 15.9.1 TCCR0A – Timer/Counter Control Register A
 TCCR0A |= (1<<WGM00);  // Phase correct, mode 1 of PWM (table 15-9)
 TCCR0A |= (1<<COM0A1); // Set/Clear on Comparator A match (table 15-4)
 TCCR0A |= (1<<COM0A0); // Set  on Comparator A match (table 15-4)
 TCCR0A |= (1<<COM0B1); // Set/Clear on Comparator B match (table 15-7)
 TCCR0A |= (1<<COM0B0); // Set on Comparator B match (table 15-7)

 // 15.9.2 TCCR0B – Timer/Counter Control Register B
 TCCR0B |= (1<<CS01);   // Prescaler set to clk/8 (table 15-9)

 // 14.4.9 DDRD – The Port D Data Direction Register
  DDRB |= (1<<DDB0); // Data direction to output (sec 14.3.3)
  DDRB |= (1<<DDB1); // Data direction to output (sec 14.3.3)
}


@* Interrupt Handling.
@c
ISR(ADC_vect)@/
{@/

}


@
This m file code:
|
for power=1:255

  volts=255*((power/255)^2);

 printf("0x%0x", round(volts));

  if (rem(power, 12) == 0 || power == 255)
      printf(",\n");
  else
      printf(", ");
  endif

end

|
was run in Octave to produce the following PWM power to PWM voltage table.
@c

@ @<Volts Table...@>=
const uint8_t volts[256]={
0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1,
0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x2, 0x2, 0x2, 0x2, 0x2,
0x2, 0x3, 0x3, 0x3, 0x3, 0x4, 0x4, 0x4, 0x4, 0x5, 0x5, 0x5,
0x5, 0x6, 0x6, 0x6, 0x7, 0x7, 0x7, 0x8, 0x8, 0x8, 0x9, 0x9,
0x9, 0xa, 0xa, 0xb, 0xb, 0xb, 0xc, 0xc, 0xd, 0xd, 0xe, 0xe,
0xf, 0xf, 0x10, 0x10, 0x11, 0x11, 0x12, 0x12, 0x13, 0x13, 0x14, 0x14,
0x15, 0x15, 0x16, 0x17, 0x17, 0x18, 0x18, 0x19, 0x1a, 0x1a, 0x1b, 0x1c,
0x1c, 0x1d, 0x1e, 0x1e, 0x1f, 0x20, 0x20, 0x21, 0x22, 0x23, 0x23, 0x24,
0x25, 0x26, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e,
0x2f, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x38,
0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44,
0x45, 0x46, 0x47, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51,
0x52, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
0x61, 0x62, 0x63, 0x64, 0x66, 0x67, 0x68, 0x69, 0x6b, 0x6c, 0x6d, 0x6f,
0x70, 0x71, 0x73, 0x74, 0x75, 0x77, 0x78, 0x79, 0x7b, 0x7c, 0x7e, 0x7f,
0x80, 0x82, 0x83, 0x85, 0x86, 0x88, 0x89, 0x8b, 0x8c, 0x8e, 0x8f, 0x91,
0x92, 0x94, 0x95, 0x97, 0x98, 0x9a, 0x9b, 0x9d, 0x9e, 0xa0, 0xa2, 0xa3,
0xa5, 0xa6, 0xa8, 0xaa, 0xab, 0xad, 0xaf, 0xb0, 0xb2, 0xb4, 0xb5, 0xb7,
0xb9, 0xba, 0xbc, 0xbe, 0xc0, 0xc1, 0xc3, 0xc5, 0xc7, 0xc8, 0xca, 0xcc,
0xce, 0xcf, 0xd1, 0xd3, 0xd5, 0xd7, 0xd9, 0xda, 0xdc, 0xde, 0xe0, 0xe2,
0xe4, 0xe6, 0xe8, 0xe9, 0xeb, 0xed, 0xef, 0xf1, 0xf3, 0xf5, 0xf7, 0xf9,
0xfb, 0xfd, 0xff};
