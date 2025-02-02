
-- | Prime field (standard representation) with
--
-- > p = 21888242871839275222246405745257275088696311157297823662689037894645226208583
--
-- * NOTE 1: This module is intented to be imported qualified
--
-- * NOTE 2: Generated code, do not edit!

{-# LANGUAGE BangPatterns, ForeignFunctionInterface #-}
module ZK.Algebra.Curves.BN128.Fp.Std
  ( Fp(..)
  , prime
    -- * Conversion
  , to
  , from
    -- * Field elements
  , small , zero , one , two , primGen
    -- * Predicates
  , isValid , isZero , isOne , isEqual
    -- * Field operations
  , neg , add , sub
  , sqr , mul
  , inv , div , divBy2 , batchInv
    -- * Exponentiation
  , pow , pow_
    -- * Random
  , rnd
    -- * Export to C
  , exportToCDef , exportListToCDef
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
import qualified ZK.Algebra.BigInt.BigInt256 as B

import           ZK.Algebra.Class.Flat  as L
import qualified ZK.Algebra.Class.Field as C
import qualified ZK.Algebra.Class.Misc  as M
import ZK.Algebra.Helpers

--------------------------------------------------------------------------------  

newtype Fp = MkFp (ForeignPtr Word64)

prime :: Integer
prime = 21888242871839275222246405745257275088696311157297823662689037894645226208583

to :: Integer -> Fp
to x = unsafeTo (mod x prime)

from :: Fp -> Integer
from = unsafeFrom

zero, one, two :: Fp
zero = small 0
one  = small 1
two  = small 2

primGen :: Fp
primGen = small 3

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

instance L.Flat Fp where
  sizeInBytes  _pxy = 32
  sizeInQWords _pxy = 4
  withFlat (MkFp fptr) = withForeignPtr fptr
  makeFlat = L.makeFlatGeneric MkFp 4

rnd :: IO Fp
rnd = do
  x <- randomRIO (0,prime-1)
  return (unsafeTo x)

instance M.Rnd Fp where
  rndIO = rnd

instance C.Ring Fp where
  ringNamePxy _ = "BN128/Fp (standard repr.)"
  ringSizePxy _ = prime
  isZero = ZK.Algebra.Curves.BN128.Fp.Std.isZero
  isOne  = ZK.Algebra.Curves.BN128.Fp.Std.isOne
  zero   = ZK.Algebra.Curves.BN128.Fp.Std.zero
  one    = ZK.Algebra.Curves.BN128.Fp.Std.one
  square = ZK.Algebra.Curves.BN128.Fp.Std.sqr
  power  = ZK.Algebra.Curves.BN128.Fp.Std.pow
  -- power x e = pow x (B.to (mod e (prime-1)))

instance C.Field Fp where
  charPxy      _ = prime
  dimPxy       _ = 1
  primGenPxy   _ = primGen
  batchInverse   = batchInv
  frobenius      = id
  halve          = divBy2



{-# NOINLINE exportToCDef #-}
exportToCDef :: String -> Fp -> String
exportToCDef name val = unsafePerformIO $ do
  ws <- peekFlat val
  return $ exportWordsToC name ws

{-# NOINLINE exportListToCDef #-}
exportListToCDef :: String -> [Fp] -> String
exportListToCDef name vals = unsafePerformIO $ do
  ws <- mapM peekFlat vals
  return $ exportWordsArrayToC 4 name (concat ws)

----------------------------------------

foreign import ccall unsafe "bn128_Fp_std_pow_gen" c_bn128_Fp_std_pow_gen :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> CInt -> IO ()

pow :: Fp -> Integer -> Fp
pow x e
  | e == 0      = if isZero x then zero else one
  | e >  0      =      powNonNeg x         e  
  | otherwise   = inv (powNonNeg x (negate e))

withInteger :: Integer -> ((Int, Ptr Word64) -> IO a) -> IO a
withInteger !input action = do
  let (n,ws) = toWord64sLE_ input
  allocaArray n $ \ptr -> do
    pokeArray ptr ws
    action (n,ptr)

{-# NOINLINE powNonNeg #-}
powNonNeg :: Fp -> Integer -> Fp
powNonNeg (MkFp fptr1) expo = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withInteger expo $ \(nwords,ptr2) -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_Fp_std_pow_gen ptr1 ptr2 ptr3 (fromIntegral nwords)
  return (MkFp fptr3)

{-# NOINLINE pow #-}
powBigInt256 :: Fp -> BigInt256 -> Fp
powBigInt256 (MkFp fptr1) (MkBigInt256 fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_Fp_std_pow_gen ptr1 ptr2 ptr3 4
  return (MkFp fptr3)

----------------------------------------

foreign import ccall unsafe "bn128_Fp_std_batch_inv" c_bn128_Fp_std_batch_inv :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE batchInv #-}
batchInv :: FlatArray Fp -> FlatArray Fp
batchInv (MkFlatArray n fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray (n*4)
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_Fp_std_batch_inv (fromIntegral n) ptr1 ptr2
  return (MkFlatArray n fptr2)

----------------------------------------


{-# NOINLINE unsafeMk #-}
unsafeMk :: Integer -> IO Fp
unsafeMk x = do
  fptr <- mallocForeignPtrArray 4
  withForeignPtr fptr $ \ptr -> do
    pokeArray ptr $ toWord64sLE 4 x
  return $ MkFp fptr

{-# NOINLINE unsafeGet #-}
unsafeGet :: Fp -> IO Integer
unsafeGet (MkFp fptr) = do
  ws <- withForeignPtr fptr $ \ptr -> peekArray 4 ptr 
  return (fromWord64sLE ws)

{-# NOINLINE unsafeTo #-}
unsafeTo :: Integer -> Fp
unsafeTo x = unsafePerformIO (unsafeMk x)

{-# NOINLINE unsafeFrom #-}
unsafeFrom :: Fp -> Integer
unsafeFrom f = unsafePerformIO (unsafeGet f)

foreign import ccall unsafe "bn128_Fp_std_is_valid" c_bn128_Fp_std_is_valid :: Ptr Word64 -> IO Word8

{-# NOINLINE isValid #-}
isValid :: Fp -> Bool
isValid (MkFp fptr) = unsafePerformIO $ do
  cret <- withForeignPtr fptr $ \ptr -> do
    c_bn128_Fp_std_is_valid ptr
  return (cret /= 0)

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
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bigint256_is_equal ptr1 ptr2
  return (cret /= 0)

foreign import ccall unsafe "bigint256_set_small" c_bigint256_set_small :: Ptr Word64 -> Word64 -> IO ()

{-# NOINLINE small #-}
small :: Word64 -> Fp
small x = unsafePerformIO $ do
  fptr1 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    c_bigint256_set_small ptr1 x
  return (MkFp fptr1)

foreign import ccall unsafe "bn128_Fp_std_neg" c_bn128_Fp_std_neg :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE neg #-}
neg :: Fp -> Fp
neg (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_Fp_std_neg ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_Fp_std_add" c_bn128_Fp_std_add :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE add #-}
add :: Fp -> Fp -> Fp
add (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_Fp_std_add ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_Fp_std_sub" c_bn128_Fp_std_sub :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE sub #-}
sub :: Fp -> Fp -> Fp
sub (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_Fp_std_sub ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_Fp_std_sqr" c_bn128_Fp_std_sqr :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE sqr #-}
sqr :: Fp -> Fp
sqr (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_Fp_std_sqr ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_Fp_std_mul" c_bn128_Fp_std_mul :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE mul #-}
mul :: Fp -> Fp -> Fp
mul (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_Fp_std_mul ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_Fp_std_inv" c_bn128_Fp_std_inv :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE inv #-}
inv :: Fp -> Fp
inv (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_Fp_std_inv ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_Fp_std_div" c_bn128_Fp_std_div :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE div #-}
div :: Fp -> Fp -> Fp
div (MkFp fptr1) (MkFp fptr2) = unsafePerformIO $ do
  fptr3 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      withForeignPtr fptr3 $ \ptr3 -> do
        c_bn128_Fp_std_div ptr1 ptr2 ptr3
  return (MkFp fptr3)

foreign import ccall unsafe "bn128_Fp_std_div_by_2" c_bn128_Fp_std_div_by_2 :: Ptr Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE divBy2 #-}
divBy2 :: Fp -> Fp
divBy2 (MkFp fptr1) = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_Fp_std_div_by_2 ptr1 ptr2
  return (MkFp fptr2)

foreign import ccall unsafe "bn128_Fp_std_pow_uint64" c_bn128_Fp_std_pow_uint64 :: Ptr Word64 -> Word64 -> Ptr Word64 -> IO ()

{-# NOINLINE pow_ #-}
pow_ :: Fp -> Word64 -> Fp
pow_ (MkFp fptr1) x = unsafePerformIO $ do
  fptr2 <- mallocForeignPtrArray 4
  cret <- withForeignPtr fptr1 $ \ptr1 -> do
    withForeignPtr fptr2 $ \ptr2 -> do
      c_bn128_Fp_std_pow_uint64 ptr1 x ptr2
  return (MkFp fptr2)
