{- |
Module      : GPIOShiftRegister
Description : Library for driving a Shift Register based on 74HC595
Copyright   : (c) Frédéric BISSON, 2015
License     : GPL-3
Maintainer  : zigazou@free.fr
Stability   : experimental
Portability : POSIX

-}
module System.RaspberryPi.GPIOShiftRegister
( GPIOShiftRegister (GPIOShiftRegister, gsrDataIn, gsrLatch, gsrClock)
, initShiftRegister
, writeNBits
, write8Bits
)
where

import System.RaspberryPi.GPIO (Pin, PinMode(Output), writePin, setPinFunction)
import Data.Bits ((.&.), Bits)

{- |
A Shift Register chipset may be handled with 5 lines, though 3 lines are
really required if the remaining 2 lines are directly connected to Vcc or Gnd.

Internally, the Shift Register chipset has 2 registers:

- **Shift Register**: an 8 bit register which receives the bits, one by one
- **Storage Register**: an 8 bit register which is physically mapped on the 8
  output lines

This library works with 3 lines:

- **Serial Data Input**: used to transmit one bit at a time
- **Storage Register Clock Input or latch**: transition from low to high will
  transfer the content of the Shift Register into the Storage Register
- **Shift Register Clock Input or clock**: transition from low to high will
  insert the bit on Serial Data Input into the Shift Register

-}
data GPIOShiftRegister = GPIOShiftRegister
    { gsrDataIn :: Pin -- SI (Serial Data Input)
    , gsrLatch :: Pin -- RCK (Storage Register Clock Input)
    , gsrClock :: Pin -- SCK (Shift Register Clock Input)
    }

impulse :: Pin -> IO ()
impulse p = writePin p True >> writePin p False

{- |
Init the Shift Register chipset.
-}
initShiftRegister :: GPIOShiftRegister -> IO ()
initShiftRegister shifter = do
    setPinFunction (gsrDataIn shifter) Output
    setPinFunction (gsrClock shifter) Output
    setPinFunction (gsrLatch shifter) Output

    writePin (gsrLatch shifter) False
    writePin (gsrClock shifter) False

write1Bit :: GPIOShiftRegister -> Bool -> IO ()
write1Bit gsr bit = writePin (gsrDataIn gsr) bit >> impulse (gsrClock gsr)

{- |
Write N bits to the Shift Register. This function allows the library to
support daisy chaining of Shift Register chipsets.
-}
writeNBits :: (Num a, Bits a) => GPIOShiftRegister -> Int -> a -> IO ()
writeNBits gsr nBits value = do
    mapM_ (write1Bit gsr) bits
    impulse $ gsrLatch gsr
    where bits = [ value .&. (2 ^ position) /= 0
                 | position <- [ nBits - 1, nBits - 2 .. 0 ]
                 ]

{- |
Helper function for outputting bytes using a Shift Register chipset.
-}
write8Bits :: GPIOShiftRegister -> Int -> IO ()
write8Bits = flip writeNBits 8
