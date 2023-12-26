
-- | Arrays over 'ZK.Algebra.Curves.BN128.Fr.Mont.Fr'
--
-- * NOTE 1: This module is intented to be imported qualified
--
-- * NOTE 2: Generated code, do not edit!
--

{-# LANGUAGE BangPatterns, ForeignFunctionInterface, PatternSynonyms, TypeFamilies, FlexibleInstances #-}
module ZK.Algebra.Curves.BN128.Array
  ( -- * Boolean predicates on arrays
    isValid
  , isZero , isOne
  , isEqual
    -- * Array conversion
  , fromStd , toStd
    -- * Pointwise arithmetics
  , neg , add , sub
  , sqr , mul
  , inv , div
    -- * Misc
  , scale
  , dotProd
  , powers
    -- * Fused mul-add
  , mulAdd
  , mulSub
  )
  where

--------------------------------------------------------------------------------

import Prelude  hiding (div,quot,rem)
import GHC.Real hiding (div,quot,rem)

import Data.Bits
import Data.Word
import Data.List
import Data.Array

import Control.Monad

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal
import Foreign.ForeignPtr

import System.Random
import System.IO.Unsafe

import ZK.Algebra.Curves.BN128.Fr.Mont ( Fr(..) )
import qualified ZK.Algebra.Curves.BN128.Fr.Mont
import qualified ZK.Algebra.Curves.BN128.Fr.Std as Std

import ZK.Algebra.Class.Flat ( FlatArray(..) )

import           ZK.Algebra.Class.Flat  as L
import           ZK.Algebra.Class.FFT   as T
import qualified ZK.Algebra.Class.Field as F
import qualified ZK.Algebra.Class.Poly  as P

--------------------------------------------------------------------------------

foreign import ccall unsafe "bn128_arr_mont_from_std" c_bn128_arr_mont_from_std :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()
foreign import ccall unsafe "bn128_arr_mont_to_std" c_bn128_arr_mont_to_std   :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE fromStd #-}
fromStd :: FlatArray Std.Fr -> FlatArray Fr
fromStd (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray (n1*4)
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_arr_mont_from_std (fromIntegral n1) ptr1 ptr2
  return (MkFlatArray n1 fptr2)

{-# NOINLINE toStd #-}
toStd :: FlatArray Fr -> FlatArray Std.Fr
toStd (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray (n1*4)
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_arr_mont_to_std (fromIntegral n1) ptr1 ptr2
  return (MkFlatArray n1 fptr2)

foreign import ccall unsafe "bn128_arr_mont_is_valid" c_bn128_arr_mont_is_valid :: CInt -> Ptr Word64 -> IO Word8

{-# NOINLINE isValid #-}
isValid :: FlatArray Fr -> Bool
isValid (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  cret <- withForeignPtr fptr1 $ \ptr1 -> do
    c_bn128_arr_mont_is_valid (fromIntegral n1) ptr1
  return (cret /= 0)

foreign import ccall unsafe "bn128_arr_mont_is_zero" c_bn128_arr_mont_is_zero :: CInt -> Ptr Word64 -> IO Word8

{-# NOINLINE isZero #-}
isZero :: FlatArray Fr -> Bool
isZero (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  cret <- withForeignPtr fptr1 $ \ptr1 -> do
    c_bn128_arr_mont_is_zero (fromIntegral n1) ptr1
  return (cret /= 0)

foreign import ccall unsafe "bn128_arr_mont_is_one" c_bn128_arr_mont_is_one :: CInt -> Ptr Word64 -> IO Word8

{-# NOINLINE isOne #-}
isOne :: FlatArray Fr -> Bool
isOne (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  cret <- withForeignPtr fptr1 $ \ptr1 -> do
    c_bn128_arr_mont_is_one (fromIntegral n1) ptr1
  return (cret /= 0)

foreign import ccall unsafe "bn128_arr_mont_is_equal" c_bn128_arr_mont_is_equal :: CInt -> Ptr Word64 -> Ptr Word64 -> IO Word8

{-# NOINLINE isEqual #-}
isEqual :: FlatArray Fr -> FlatArray Fr -> Bool
isEqual (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2)
  | n1 /= n2   = error "isEqual: incompatible input array lengths"
  | otherwise  = unsafePerformIO $ do
      cret <- withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          c_bn128_arr_mont_is_equal (fromIntegral n1) ptr1 ptr2
      return (cret /= 0)

foreign import ccall unsafe "bn128_arr_mont_neg" c_bn128_arr_mont_neg :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE neg #-}
neg :: FlatArray Fr -> FlatArray Fr
neg (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray (n1*4)
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_arr_mont_neg (fromIntegral n1) ptr1 ptr2
  return (MkFlatArray n1 fptr2)

foreign import ccall unsafe "bn128_arr_mont_add" c_bn128_arr_mont_add :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE add #-}
add :: FlatArray Fr -> FlatArray Fr -> FlatArray Fr
add (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2)
  | n1 /= n2   = error "add: incompatible input array lengths"
  | otherwise  = unsafePerformIO $ do
      fptr3 <- mallocForeignPtrArray (n1*4)
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            c_bn128_arr_mont_add (fromIntegral n1) ptr1 ptr2 ptr3
      return (MkFlatArray n1 fptr3)

foreign import ccall unsafe "bn128_arr_mont_sub" c_bn128_arr_mont_sub :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE sub #-}
sub :: FlatArray Fr -> FlatArray Fr -> FlatArray Fr
sub (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2)
  | n1 /= n2   = error "sub: incompatible input array lengths"
  | otherwise  = unsafePerformIO $ do
      fptr3 <- mallocForeignPtrArray (n1*4)
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            c_bn128_arr_mont_sub (fromIntegral n1) ptr1 ptr2 ptr3
      return (MkFlatArray n1 fptr3)

foreign import ccall unsafe "bn128_arr_mont_sqr" c_bn128_arr_mont_sqr :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE sqr #-}
sqr :: FlatArray Fr -> FlatArray Fr
sqr (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray (n1*4)
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_arr_mont_sqr (fromIntegral n1) ptr1 ptr2
  return (MkFlatArray n1 fptr2)

foreign import ccall unsafe "bn128_arr_mont_mul" c_bn128_arr_mont_mul :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE mul #-}
mul :: FlatArray Fr -> FlatArray Fr -> FlatArray Fr
mul (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2)
  | n1 /= n2   = error "mul: incompatible input array lengths"
  | otherwise  = unsafePerformIO $ do
      fptr3 <- mallocForeignPtrArray (n1*4)
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            c_bn128_arr_mont_mul (fromIntegral n1) ptr1 ptr2 ptr3
      return (MkFlatArray n1 fptr3)

foreign import ccall unsafe "bn128_arr_mont_inv" c_bn128_arr_mont_inv :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE inv #-}
inv :: FlatArray Fr -> FlatArray Fr
inv (MkFlatArray n1 fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray (n1*4)
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_arr_mont_inv (fromIntegral n1) ptr1 ptr2
  return (MkFlatArray n1 fptr2)

foreign import ccall unsafe "bn128_arr_mont_div" c_bn128_arr_mont_div :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE div #-}
div :: FlatArray Fr -> FlatArray Fr -> FlatArray Fr
div (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2)
  | n1 /= n2   = error "div: incompatible input array lengths"
  | otherwise  = unsafePerformIO $ do
      fptr3 <- mallocForeignPtrArray (n1*4)
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            c_bn128_arr_mont_div (fromIntegral n1) ptr1 ptr2 ptr3
      return (MkFlatArray n1 fptr3)

foreign import ccall unsafe "bn128_arr_mont_dot_prod" c_bn128_arr_mont_dot_prod :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE dotProd #-}
dotProd :: FlatArray Fr -> FlatArray Fr -> Fr
dotProd (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2)
  | n1 /= n2   = error "dotProd: incompatible input array lengths"
  | otherwise  = unsafePerformIO $ do
      fptr3 <- mallocForeignPtrArray 4
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            c_bn128_arr_mont_dot_prod (fromIntegral n1) ptr1 ptr2 ptr3
      return (MkFr fptr3)

foreign import ccall unsafe "bn128_arr_mont_powers" c_bn128_arr_mont_powers :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE powers #-}
powers :: Int -> Fr -> Fr -> FlatArray Fr
powers n (MkFr fptr1) (MkFr fptr2) = 
  unsafePerformIO $ do
    fptr3 <- mallocForeignPtrArray (n*4)
    withForeignPtr fptr1 $ \ptr1 -> do
      withForeignPtr fptr2 $ \ptr2 -> do
         withForeignPtr fptr3 $ \ptr3 -> do
           c_bn128_arr_mont_powers (fromIntegral n) ptr1 ptr2 ptr3
      return (MkFlatArray n fptr3)

foreign import ccall unsafe "bn128_arr_mont_mul_add" c_bn128_arr_mont_mul_add :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE mulAdd #-}
mulAdd :: FlatArray Fr -> FlatArray Fr -> FlatArray Fr -> FlatArray Fr
mulAdd (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2) (MkFlatArray n3 fptr3)
  | n1 /= n2 || n1 /= n3  = error "mulAdd: incompatible input array lengths"
  | otherwise             = unsafePerformIO $ do
      fptr4 <- mallocForeignPtrArray (n1*4)
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            withForeignPtr fptr4 $ \ptr4 -> do
              c_bn128_arr_mont_mul_add (fromIntegral n1) ptr1 ptr2 ptr3 ptr4
      return (MkFlatArray n1 fptr4)

foreign import ccall unsafe "bn128_arr_mont_mul_sub" c_bn128_arr_mont_mul_sub :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE mulSub #-}
mulSub :: FlatArray Fr -> FlatArray Fr -> FlatArray Fr -> FlatArray Fr
mulSub (MkFlatArray n1 fptr1) (MkFlatArray n2 fptr2) (MkFlatArray n3 fptr3)
  | n1 /= n2 || n1 /= n3  = error "mulSub: incompatible input array lengths"
  | otherwise             = unsafePerformIO $ do
      fptr4 <- mallocForeignPtrArray (n1*4)
      withForeignPtr fptr1 $ \ptr1 -> do
        withForeignPtr fptr2 $ \ptr2 -> do
          withForeignPtr fptr3 $ \ptr3 -> do
            withForeignPtr fptr4 $ \ptr4 -> do
              c_bn128_arr_mont_mul_sub (fromIntegral n1) ptr1 ptr2 ptr3 ptr4
      return (MkFlatArray n1 fptr4)

foreign import ccall unsafe "bn128_arr_mont_scaled" c_bn128_arr_mont_scaled :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE scale #-}
scale :: Fr -> FlatArray Fr -> FlatArray Fr
scale (MkFr fptr1) (MkFlatArray n2 fptr2) =
  unsafePerformIO $ do
    fptr3 <- mallocForeignPtrArray (n2*4)
    withForeignPtr fptr1 $ \ptr1 -> do
      withForeignPtr fptr2 $ \ptr2 -> do
         withForeignPtr fptr3 $ \ptr3 -> do
           c_bn128_arr_mont_scaled (fromIntegral n2) ptr1 ptr2 ptr3
      return (MkFlatArray n2 fptr3)
