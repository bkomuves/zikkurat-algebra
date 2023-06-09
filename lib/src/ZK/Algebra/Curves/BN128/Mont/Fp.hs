
-- NOTE 1: This module is intented to be imported qualified
-- NOTE 2: Generated code, do not edit!

{-# LANGUAGE BangPatterns, ForeignFunctionInterface #-}
module ZK.Algebra.Curves.BN128.Mont.Fp
  ( Fp(..)
  , prime
  , to , from
  , toStd , fromStd
  , zero , one , two
  , isZero , isOne , isEqual
  , neg , add , sub
  , sqr , mul
  , inv , div
  , pow , pow_
  )
  where

--------------------------------------------------------------------------------

import Prelude  hiding (div)
import GHC.Real hiding (div)

import Data.Bits
import Data.Word

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal
import Foreign.ForeignPtr

import System.Random
import System.IO.Unsafe

import ZK.Algebra.BigInt.BigInt256( BigInt256(..) )
import qualified ZK.Algebra.Curves.BN128.Std.Fp as Std

--------------------------------------------------------------------------------  

newtype Fp = MkFp (ForeignPtr Word64)

prime :: Integer
prime = 21888242871839275222246405745257275088696311157297823662689037894645226208583

to :: Integer -> Fp
to = fromStd . Std.to

from :: Fp -> Integer
from = Std.from . toStd

zero, one, two :: Fp
zero = to 0
one  = to 1
two  = to 2

instance Eq Fp where
  (==) = isEqual

instance Num Fp where
  fromInteger = to
  negate = neg
  (+) = add
  (-) = sub
  (*) = mul
  abs    = id
  signum = \_ -> one

instance Fractional Fp where
  fromRational r = fromInteger (numerator r) / fromInteger (denominator r)
  recip = inv
  (/)   = div

instance Show Fp where
  show = show . from

----------------------------------------

foreign import ccall unsafe "bn128_p_mont_from_std" c_bn128_p_mont_from_std :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE fromStd#-}
fromStd :: Std.Fp -> Fp
fromStd (Std.MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_p_mont_from_std ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_p_mont_to_std" c_bn128_p_mont_to_std :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE toStd#-}
toStd :: Fp -> Std.Fp
toStd (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_p_mont_to_std ptr1 ptr2
  return (Std.MkFp fptr2)

foreign import ccall unsafe "bn128_p_mont_pow_gen" c_bn128_p_mont_pow_gen :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE pow #-}
pow :: Fp -> BigInt256 -> Fp
pow (MkFp fptr1) (MkBigInt256 fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_p_mont_pow_gen ptr1 ptr2 ptr3
  return (MkFp fptr3)

----------------------------------------

fromWord64sLE :: [Word64] -> Integer
fromWord64sLE = go where
  go []     = 0
  go (x:xs) = fromIntegral x + shiftL (go xs) 64

toWord64sLE :: Integer -> [Word64]
toWord64sLE = go where
  go 0 = []
  go k = fromInteger (k .&. (2^64-1)) : go (shiftR k 64)

toWord64sLE' :: Int -> Integer -> [Word64]
toWord64sLE' len what = take len $ toWord64sLE what ++ repeat 0

foreign import ccall unsafe "bigint256_is_zero" c_bigint256_is_zero :: Ptr Word64 -> IO Word8

{-# NOINLINE isZero #-}
isZero :: Fp -> Bool
isZero (MkFp fptr) = unsafePerformIO $ do
  cret <- withForeignPtr fptr $ \ptr -> do
    c_bigint256_is_zero ptr
  return (cret /= 0)

foreign import ccall unsafe "bigint256_is_one" c_bigint256_is_one :: Ptr Word64 -> IO Word8

{-# NOINLINE isOne #-}
isOne :: Fp -> Bool
isOne (MkFp fptr) = unsafePerformIO $ do
  cret <- withForeignPtr fptr $ \ptr -> do
    c_bigint256_is_one ptr
  return (cret /= 0)

foreign import ccall unsafe "bigint256_is_equal" c_bigint256_is_equal :: Ptr Word64 -> Ptr Word64 -> IO Word8

{-# NOINLINE isEqual #-}
isEqual :: Fp -> Fp -> Bool
isEqual (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  cret <- withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr1 $ \ptr2 -> do
      c_bigint256_is_equal ptr1 ptr2
  return (cret /= 0)

foreign import ccall unsafe "bn128_p_mont_neg" c_bn128_p_mont_neg :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE neg #-}
neg :: Fp -> Fp
neg (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_p_mont_neg ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_p_mont_add" c_bn128_p_mont_add :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE add #-}
add :: Fp -> Fp -> Fp
add (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_p_mont_add ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_p_mont_sub" c_bn128_p_mont_sub :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE sub #-}
sub :: Fp -> Fp -> Fp
sub (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_p_mont_sub ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_p_mont_sqr" c_bn128_p_mont_sqr :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE sqr #-}
sqr :: Fp -> Fp
sqr (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_p_mont_sqr ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_p_mont_mul" c_bn128_p_mont_mul :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE mul #-}
mul :: Fp -> Fp -> Fp
mul (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_p_mont_mul ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_p_mont_inv" c_bn128_p_mont_inv :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE inv #-}
inv :: Fp -> Fp
inv (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_p_mont_inv ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_p_mont_div" c_bn128_p_mont_div :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE div #-}
div :: Fp -> Fp -> Fp
div (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_p_mont_div ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_p_mont_pow_uint64" c_bn128_p_mont_pow_uint64 :: Ptr Word64 -> Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE pow_ #-}
pow_ :: Fp -> Word64 -> Fp
pow_ (MkFp fptr1) x = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  cret <- withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_p_mont_pow_uint64 ptr1 x ptr2
  return (MkFp fptr2)
