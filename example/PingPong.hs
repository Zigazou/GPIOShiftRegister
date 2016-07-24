module Main where

import Control.Concurrent (threadDelay)
import Control.Monad (forever)

import System.RaspberryPi.GPIO
import System.RaspberryPi.GPIOShiftRegister

pingPong :: GPIOShiftRegister -> IO ()
pingPong shiftRegister = do
    mapM_ (\v -> write8Bits shiftRegister v >> threadDelay 30000)
          [128, 64, 32, 16, 8, 4, 2, 1, 2, 4, 8, 16, 32, 64]

main :: IO ()
main = withGPIO $ do
    let shiftRegister = GPIOShiftRegister { gsrDataIn = Pin13
                                          , gsrLatch = Pin11
                                          , gsrClock = Pin07
                                          }

    initShiftRegister shiftRegister
    forever $ pingPong shiftRegister
