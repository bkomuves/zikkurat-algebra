
-- | Generating code for dense univariate polynomials over a field

{-# LANGUAGE RecordWildCards #-}
module Zikkurat.CodeGen.Poly where

--------------------------------------------------------------------------------

import Data.List
import Data.Word
import Data.Bits

import Control.Monad
import System.FilePath

import Zikkurat.CodeGen.Misc
import Zikkurat.CodeGen.FFI

--------------------------------------------------------------------------------

data PolyParams = PolyParams 
  { prefix      :: String       -- ^ prefix for C names
  , prefix_r    :: String       -- ^ prefix for C names of the field
  , nlimbs      :: Int          -- ^ number of 64-bit limbs of the field
  , c_path      :: Path         -- ^ path of the C module (without extension)
  , c_path_r    :: Path         -- ^ path of the C module for the field (without extension)
  , hs_path     :: Path         -- ^ path of the Haskell module (without extension) 
  , hs_path_r   :: Path         -- ^ path of the Haskell module for the field (without extension)
  , typeName    :: String       -- ^ name of the polynomial type
  , typeName_r  :: String       -- ^ name of the field type 
  }
  deriving Show

--------------------------------------------------------------------------------

c_header :: PolyParams -> Code
c_header (PolyParams{..}) =
  [ "#include <stdint.h>"
  , ""
  , "extern int " ++ prefix ++ "degree( const uint64_t *src );"
  , ""
  , "extern void " ++ prefix ++ "get_coeff( int n1, const uint64_t *src1, int k, uint64_t *tgt );"
  , "extern void " ++ prefix ++ "eval_at  ( int n1, const uint64_t *src1, const uint64_t *loc, uint64_t *tgt);"
  , ""
  , "extern uint8_t " ++ prefix ++ "is_zero     ( int n1, const uint64_t *src1 );"
  , "extern uint8_t " ++ prefix ++ "is_constant ( int n1, const uint64_t *src  , uint64_t *tgt_constant);"
  , "extern uint8_t " ++ prefix ++ "is_equal    ( int n1, const uint64_t *src1, int n2, const uint64_t *src2 );"
  , ""
  , "extern void " ++ prefix ++ "neg( int n1, const uint64_t *src1, uint64_t *tgt );"
  , "extern void " ++ prefix ++ "add( int n1, const uint64_t *src1, int n2, const uint64_t *src2, uint64_t *tgt );"
  , "extern void " ++ prefix ++ "sub( int n1, const uint64_t *src1, int n2, const uint64_t *src2, uint64_t *tgt );"
  , "extern void " ++ prefix ++ "scale( const uint64_t *kst1, int n2, const uint64_t *src2, uint64_t *tgt );"
  , "extern void " ++ prefix ++ "mul_naive( int n1, const uint64_t *src1, int n2, const uint64_t *src2, uint64_t *tgt );"
  , ""
  , "extern void " ++ prefix ++ "lincomb( int K, const int *ns, const uint64_t **coeffs, const uint64_t **polys, uint64_t *tgt );"  
  ]

--------------------------------------------------------------------------------

cBegin :: PolyParams -> Code
cBegin (PolyParams{..}) =
  [ "// dense univariate polynomials with coefficients in a field"
  , ""
  , "#include <stdint.h>"
  , "#include <assert.h>"
  , ""
  , "#include \"" ++ pathBaseName c_path_r ++ ".h\""
  , ""
  , "#define NLIMBS " ++ show nlimbs
  , ""
  , "#define MIN(a,b) ( ((a)<=(b)) ? (a) : (b) )"
  , "#define MAX(a,b) ( ((a)>=(b)) ? (a) : (b) )"
  , ""
  , "#define SRC1(i) (src1 + i*NLIMBS)"
  , "#define SRC2(i) (src2 + i*NLIMBS)"
  , "#define TGT(i)  (tgt  + i*NLIMBS)"
  , ""
  ]

hsBegin :: PolyParams -> Code
hsBegin (PolyParams{..}) =
  [ "-- | Univariate polynomials over '" ++ hsModule hs_path_r ++ "." ++ typeName_r ++ "'"
  , "--"
  , "-- * NOTE 1: This module is intented to be imported qualified"
  , "--"
  , "-- * NOTE 2: Generated code, do not edit!"
  , "--"
  , ""
  , "{-# LANGUAGE BangPatterns, ForeignFunctionInterface, PatternSynonyms, TypeFamilies, FlexibleInstances #-}"
  , "module " ++ hsModule hs_path
  , "  ( " ++ typeName ++ "(..)"
  , "    -- * Coefficients"
  , "  , coeffs"
  , "  , coeffsArr"
  , "  , coeffsFlatArr"
  , "    -- * Predicates"
  , "  , isZero , isEqual" 
  , "    -- * Queries"
  , "  , degree"
  , "  , constTermOf"
  , "  , kthCoeff"
  , "  , evalAt"
  , "    -- * Constant polynomials"
  , "  , constPoly"
  , "  , mbConst"
  , "  , zero , one"
  , "    -- * Creating polynomials"
  , "  , mkPoly , mkPoly' , mkPolyArr , mkPolyFlatArr"
  , "  , linearPoly"
  , "    -- * Pretty-printing"
  , "  , showPoly, showPoly'"
  , "    -- * Ring operations"
  , "  , neg , add , sub"
  , "  , mul , mulNaive"
  , "    -- * Linear combinations"
  , "  , scale"
--  , "  , linComb"
  , "    -- * Random"
  , "  , rndPoly , rnd"
  , "  )"  
  , "  where"
  , ""
  , "--------------------------------------------------------------------------------"
  , ""
  , "import Prelude  hiding (div)"
  , "import GHC.Real hiding (div)"
  , ""
  , "import Data.Bits"
  , "import Data.Word"
  , "import Data.List"
  , "import Data.Array"
  , ""
  , "import Control.Monad"
  , ""
  , "import Foreign.C"
  , "import Foreign.Ptr"
  , "import Foreign.Marshal"
  , "import Foreign.ForeignPtr"
  , ""
  , "import System.Random"
  , "import System.IO.Unsafe"
  , ""
  , "import " ++ hsModule hs_path_r ++ " ( " ++ typeName_r ++ "(..) )"
  , "import qualified " ++ hsModule hs_path_r
  , ""
  , "import qualified ZK.Algebra.Class.Flat  as L"
  , "import qualified ZK.Algebra.Class.Field as F"
  , "import qualified ZK.Algebra.Class.Poly  as P"
  , ""
  , "import ZK.Algebra.Class.Poly"
  , "  ( polyIsOne"
  , "  , constTermOf"
  , "  , mbConst   "
  , "  , constPoly "
  , "  , idPoly    "
  , "  , linearPoly"
  , "  , showPoly  "
  , "  , showPoly' "
  , "  )"
  , ""
  , "--------------------------------------------------------------------------------"
  , ""
  , "newtype " ++ typeName ++ " = Mk" ++ typeName ++ " (L.FlatArray " ++ typeName_r ++ ")"
  , ""
  , "pattern XPoly n arr = Mk" ++ typeName ++ " (L.MkFlatArray n arr)"
  , ""
  , "mkPoly :: [" ++ typeName_r ++ "] -> " ++ typeName
  , "mkPoly = Mk" ++ typeName ++ " . L.packFlatArrayFromList"
  , ""
  , "mkPoly' :: Int -> [" ++ typeName_r ++ "] -> " ++ typeName
  , "mkPoly' len xs = Mk" ++ typeName ++ " $ L.packFlatArrayFromList' len xs"
  , ""
  , "mkPolyArr :: Array Int " ++ typeName_r ++ " -> "  ++ typeName
  , "mkPolyArr = Mk" ++ typeName ++ " . L.packFlatArray"
  , "" 
  , "mkPolyFlatArr :: L.FlatArray " ++ typeName_r ++ " -> "  ++ typeName
  , "mkPolyFlatArr = Mk" ++ typeName 
  , "" 
  , "coeffs :: " ++ typeName ++ " -> [" ++ typeName_r ++ "]"
  , "coeffs (Mk" ++ typeName ++ " arr) = L.unpackFlatArrayToList arr"
  , "" 
  , "coeffsArr :: " ++ typeName ++ " -> Array Int " ++ typeName_r 
  , "coeffsArr (Mk" ++ typeName ++ " arr) = L.unpackFlatArray arr"
  , "" 
  , "coeffsFlatArr :: Poly -> L.FlatArray " ++ typeName_r
  , "coeffsFlatArr (MkPoly flat) = flat"
  , "" 
  , "--------------------------------------------------------------------------------"
  , "" 
  , "instance Eq " ++ typeName ++ " where"
  , "  (==) = isEqual"
  , ""
  , "instance Show " ++ typeName ++ " where"
  , "  show = showPoly' False"
  , ""
  , "instance Num " ++ typeName ++ " where"
  , "  fromInteger = constPoly . fromInteger"
  , "  negate = neg"
  , "  (+) = add"
  , "  (-) = sub"
  , "  (*) = mul" 
  , "  abs    = id"
  , "  signum = \\_ -> constPoly 1"
  , ""
  , "mul = mulNaive       -- TEMPORARY !!!"
  , ""
  , "instance F.Rnd " ++ typeName ++ " where"
  , "  rndIO = rnd"
  , ""
  , "instance F.Ring " ++ typeName ++ " where"
  , "  ringNamePxy _ = \"" ++ typeName_r ++ "[x]\""
  , "  ringSizePxy _ = error \"this is a polynomial ring, it's not finite\""
  , "  isZero    = " ++ hsModule hs_path ++ ".isZero"
  , "  isOne     = " ++ hsModule hs_path ++ ".isOne"
  , "  zero      = " ++ hsModule hs_path ++ ".zero"
  , "  one       = " ++ hsModule hs_path ++ ".one"
  , "  power     = error \"exponentiation of polynomials is not implemented\""
  , ""
  , "instance L.WrappedArray " ++ typeName ++ " where"
  , "  type Element " ++ typeName ++ " = " ++ typeName_r
  , "  wrapArray = Mk" ++ typeName
  , "  unwrapArray (Mk" ++ typeName ++ " flatArr) = flatArr"
  , ""
  , "instance P.Univariate " ++ typeName ++ " where"
  , "  type Coeff " ++ typeName ++ " = " ++ typeName_r
  , "  degree        = " ++ hsModule hs_path ++ ".degree"
  , "  kthCoeff      = " ++ hsModule hs_path ++ ".kthCoeff"
  , "  evalAt        = " ++ hsModule hs_path ++ ".evalAt"
  , "  scale         = " ++ hsModule hs_path ++ ".scale"
  , "  mkPoly        = " ++ hsModule hs_path ++ ".mkPoly"
  , "  coeffs        = " ++ hsModule hs_path ++ ".coeffs"
  , "  coeffsArr     = " ++ hsModule hs_path ++ ".coeffsArr"
  , "  coeffsFlatArr = " ++ hsModule hs_path ++ ".coeffsFlatArr"
  , ""
  , "--------------------------------------------------------------------------------"
  , ""
  , "-- | The constant zero polynomial"
  , "zero :: " ++ typeName 
  , "zero = constPoly 0"
  , ""
  , "-- | The constant one polynomial"
  , "one :: " ++ typeName 
  , "one = constPoly 1"
  , ""
  , "-- | Checks whether the input is the constant one polynomial?"
  , "isOne :: " ++ typeName ++ " -> Bool"
  , "isOne p = (mbConst p == Just " ++ hsModule hs_path_r ++ ".one)"
  , ""
{-
-- NOTE: these were moved next to the type class
--
  , "-- | The constant term of a polynomial"
  , "constTermOf :: " ++ typeName ++ " -> " ++ typeName_r
  , "constTermOf p = kthCoeff 0 p"
  , ""
  , "-- | Is this a constant polynomial?"
  , "mbConst :: " ++ typeName ++ " -> Maybe " ++ typeName_r
  , "mbConst p = if degree p <= 0 then Just (constTermOf p) else Nothing"
  , ""
  , "-- | Create a constant polynomial"
  , "constPoly :: " ++ typeName_r ++ " -> " ++ typeName
  , "constPoly y = mkPoly [y]"
  , ""
  , "-- | @linearPoly a b == a*x + b@"
  , "linearPoly :: " ++ typeName_r ++ " -> " ++ typeName_r ++ " -> " ++ typeName
  , "linearPoly a b = mkPoly [b,a]"
  , ""
  , "showPoly :: " ++ typeName ++ " -> String"
  , "showPoly = showPoly' True"
  , ""
  , "showPoly' :: Bool -> " ++ typeName ++ " -> String"
  , "showPoly' newlines_flag poly ="
  , "  case newlines_flag of"
  , "    False -> intercalate \" +\"   terms"
  , "    True  -> intercalate \" +\\n\" terms"
  , "  where"
  , "    terms = zipWith f [0..] (coeffs poly)"
  , "    f k x = ' ' : show x ++ \" * x^\" ++ show k" 
  , ""
-}
  , "-- | @rndPoly d@ generates a random polynomial of degree @d@"
  , "rndPoly :: Int -> IO " ++ typeName
  , "rndPoly d = mkPoly <$> replicateM (d+1) F.rndIO"
  , ""
  , "-- | @rnd@ generates a random polynomial between degree 0 and 12"
  , "rnd :: IO " ++ typeName
  , "rnd = do"
  , "  d <- randomRIO (0,12)"
  , "  rndPoly d"
  , ""
  , "--------------------------------------------------------------------------------"
  ]

--------------------------------------------------------------------------------

hsPolyBasics :: PolyParams -> Code
hsPolyBasics (PolyParams{..}) =  
  [ ""
  , "foreign import ccall unsafe \"" ++ prefix ++ "degree\"    c_" ++ prefix ++ "degree    :: CInt -> Ptr Word64 -> IO CInt"
  , "foreign import ccall unsafe \"" ++ prefix ++ "get_coeff\" c_" ++ prefix ++ "get_coeff :: CInt -> Ptr Word64 -> CInt -> Ptr Word64 -> IO ()"
  , "foreign import ccall unsafe \"" ++ prefix ++ "is_zero\"   c_" ++ prefix ++ "is_zero   :: CInt -> Ptr Word64                       -> IO Word8"
  , "foreign import ccall unsafe \"" ++ prefix ++ "is_equal\"  c_" ++ prefix ++ "is_equal  :: CInt -> Ptr Word64 -> CInt -> Ptr Word64 -> IO Word8"
  , "foreign import ccall unsafe \"" ++ prefix ++ "eval_at\"   c_" ++ prefix ++ "eval_at   :: CInt -> Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()"
  , ""
  , "foreign import ccall unsafe \"" ++ prefix ++ "neg\"       c_" ++ prefix ++ "neg       :: CInt -> Ptr Word64 -> Ptr Word64 -> IO ()"
  , "foreign import ccall unsafe \"" ++ prefix ++ "add\"       c_" ++ prefix ++ "add       :: CInt -> Ptr Word64 -> CInt -> Ptr Word64 -> Ptr Word64 -> IO ()"
  , "foreign import ccall unsafe \"" ++ prefix ++ "sub\"       c_" ++ prefix ++ "sub       :: CInt -> Ptr Word64 -> CInt -> Ptr Word64 -> Ptr Word64 -> IO ()"
  , "foreign import ccall unsafe \"" ++ prefix ++ "scale\"     c_" ++ prefix ++ "scale     :: Ptr Word64 -> CInt -> Ptr Word64 -> Ptr Word64 -> IO ()"
  , "foreign import ccall unsafe \"" ++ prefix ++ "mul_naive\" c_" ++ prefix ++ "mul_naive :: CInt -> Ptr Word64 -> CInt -> Ptr Word64 -> Ptr Word64 -> IO ()"
  , ""
  , "{-# NOINLINE degree #-}"
  , "-- | The degree of a polynomial. By definition, the degree of the constant"
  , "-- zero polynomial is @-1@."
  , "degree :: " ++ typeName ++ " -> Int"
  , "degree (XPoly n1 fptr1) = unsafePerformIO $ do"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    fromIntegral <$> c_" ++ prefix ++ "degree (fromIntegral n1) ptr1"
  , ""
  , "{-# NOINLINE kthCoeff #-}"
  , "-- | The k-th coefficient of a polynomial."
  , "kthCoeff :: Int -> " ++ typeName ++ " -> " ++ typeName_r
  , "kthCoeff k (XPoly n1 fptr1) = unsafePerformIO $ do"
  , "  fptr3 <- mallocForeignPtrArray " ++ show (nlimbs)
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr3 $ \\ptr3 -> do"
  , "      c_" ++ prefix ++ "get_coeff (fromIntegral n1) ptr1 (fromIntegral k) ptr3"
  , "      return (Mk" ++ typeName_r ++ " fptr3)"
  , ""
  , "{-# NOINLINE evalAt #-}"
  , "-- | Evaluate a polynomial at the given location @x@."
  , "evalAt :: " ++ typeName_r ++ " -> " ++ typeName ++ " -> " ++ typeName_r
  , "evalAt (Mk" ++ typeName_r ++ " fptr2) (XPoly n1 fptr1) = unsafePerformIO $ do"
  , "  fptr3 <- mallocForeignPtrArray " ++ show (nlimbs)
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr2 $ \\ptr2 -> do"
  , "      withForeignPtr fptr3 $ \\ptr3 -> do"
  , "        c_" ++ prefix ++ "eval_at (fromIntegral n1) ptr1 ptr2 ptr3"
  , "        return (Mk" ++ typeName_r ++ " fptr3)"
  , ""
  , "{-# NOINLINE isZero #-}"
  , "-- | Checks whether the given polynomial is the constant zero polynomial"
  , "isZero :: " ++ typeName ++ " -> Bool"
  , "isZero (XPoly n1 fptr1) = unsafePerformIO $ do"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    c <- c_" ++ prefix ++ "is_zero (fromIntegral n1) ptr1"
  , "    return (c /= 0)"
  , ""
  , "{-# NOINLINE isEqual #-}"
  , "-- | Checks whether two polynomials are equal"
  , "isEqual :: " ++ typeName ++ " -> " ++ typeName ++ " -> Bool"
  , "isEqual (XPoly n1 fptr1) (XPoly n2 fptr2) = unsafePerformIO $ do"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr2 $ \\ptr2 -> do"
  , "      c <- c_" ++ prefix ++ "is_equal (fromIntegral n1) ptr1 (fromIntegral n2) ptr2"
  , "      return (c /= 0)"
  , ""
  , "{-# NOINLINE neg #-}"
  , "-- | Negate a polynomial"
  , "neg :: " ++ typeName ++ " -> " ++ typeName
  , "neg (XPoly n1 fptr1) = unsafePerformIO $ do"
  , "  let n3 = n1"
  , "  fptr3 <- mallocForeignPtrArray (n3*" ++ show nlimbs ++ ")"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr3 $ \\ptr3 -> do"
  , "      c_" ++ prefix ++ "neg (fromIntegral n1) ptr1 ptr3"
  , "  return (XPoly n3 fptr3)"
  , ""
  , "{-# NOINLINE add #-}"
  , "-- | Adds two polynomials"
  , "add :: " ++ typeName ++ " -> " ++ typeName ++ " -> " ++ typeName
  , "add (XPoly n1 fptr1) (XPoly n2 fptr2) = unsafePerformIO $ do"
  , "  let n3 = max n1 n2"
  , "  fptr3 <- mallocForeignPtrArray (n3*" ++ show nlimbs ++ ")"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr2 $ \\ptr2 -> do"
  , "      withForeignPtr fptr3 $ \\ptr3 -> do"
  , "        c_" ++ prefix ++ "add (fromIntegral n1) ptr1 (fromIntegral n2) ptr2 ptr3"
  , "  return (XPoly n3 fptr3)"
  , ""
  , "{-# NOINLINE sub #-}"
  , "-- | Subtracts two polynomials"
  , "sub :: " ++ typeName ++ " -> " ++ typeName ++ " -> " ++ typeName
  , "sub (XPoly n1 fptr1) (XPoly n2 fptr2) = unsafePerformIO $ do"
  , "  let n3 = max n1 n2"
  , "  fptr3 <- mallocForeignPtrArray (n3*" ++ show nlimbs ++ ")"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr2 $ \\ptr2 -> do"
  , "      withForeignPtr fptr3 $ \\ptr3 -> do"
  , "        c_" ++ prefix ++ "sub (fromIntegral n1) ptr1 (fromIntegral n2) ptr2 ptr3"
  , "  return (XPoly n3 fptr3)"
  , ""
  , "{-# NOINLINE scale #-}"
  , "-- | Multiplies a polynomial by a constant"
  , "scale :: " ++ typeName_r ++ " -> " ++ typeName ++ " -> " ++ typeName
  , "scale (Mk" ++ typeName_r ++ " fptr1) (XPoly n2 fptr2) = unsafePerformIO $ do"
  , "  let n3 = n2"
  , "  fptr3 <- mallocForeignPtrArray (n3*" ++ show nlimbs ++ ")"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr2 $ \\ptr2 -> do"
  , "      withForeignPtr fptr3 $ \\ptr3 -> do"
  , "        c_" ++ prefix ++ "scale ptr1 (fromIntegral n2) ptr2 ptr3"
  , "  return (XPoly n3 fptr3)"
  , ""
  , "{-# NOINLINE mulNaive #-}"
  , "-- | Multiplication of polynomials, naive algorithm"
  , "mulNaive :: " ++ typeName ++ " -> " ++ typeName ++ " -> " ++ typeName
  , "mulNaive (XPoly n1 fptr1) (XPoly n2 fptr2) = unsafePerformIO $ do"
  , "  let n3 = n1 + n2 - 1"
  , "  fptr3 <- mallocForeignPtrArray (n3*" ++ show nlimbs ++ ")"
  , "  withForeignPtr fptr1 $ \\ptr1 -> do"
  , "    withForeignPtr fptr2 $ \\ptr2 -> do"
  , "      withForeignPtr fptr3 $ \\ptr3 -> do"
  , "        c_" ++ prefix ++ "mul_naive (fromIntegral n1) ptr1 (fromIntegral n2) ptr2 ptr3"
  , "  return (XPoly n3 fptr3)"
  ]

--------------------------------------------------------------------------------

cPolyBasics :: PolyParams -> Code
cPolyBasics (PolyParams{..}) =
  [ "// returns the degree of the polynomial (can be smaller than the size)"
  , "// by definition, the constant zero polynomials has degree -1"
  , "int " ++ prefix ++ "degree( int n1, const uint64_t *src1 ) {"
  , "  int deg = -1;"
  , "  for(int i=0; i<n1; i++) {"
  , "    if (!" ++ prefix_r ++ "is_zero( SRC1(i) )) { deg = i; }"
  , "  }"
  , "  return deg;"
  , "}"
  , ""
  , "// get the k-th coefficient"
  , "void " ++ prefix ++ "get_coeff( int n1, const uint64_t *src1, int k, uint64_t *tgt ) {"
  , "  if ( (k<0) || (k>=n1) ) {"
  , "    " ++ prefix_r ++ "set_zero( tgt );"
  , "  }"
  , "  else {"
  , "    " ++ prefix_r ++ "copy( SRC1(k), tgt ); "
  , "  }"
  , "}"
  , ""
  , "// check for zero polynomials"
  , "uint8_t " ++ prefix ++ "is_zero( int n1, const uint64_t *src1 ) {"
  , "  uint8_t ok = 1;"
  , "  for(int i=0; i<n1; i++) {"
  , "    if (!" ++ prefix_r ++ "is_zero( SRC1(i) )) { ok = 0; break; }"
  , "  }"
  , "  return ok;"
  , "}"
  , ""
  , "// check polynomial equality"
  , "uint8_t " ++ prefix ++ "is_equal"
  , "  ( int  n1, const uint64_t *src1"
  , "  , int  n2, const uint64_t *src2"
  , "  ) {"
  , "  int M = MIN( n1 , n2 );"
  , "  int N = MAX( n1 , n2 );"
  , ""
  , "  uint8_t ok = 1;"
  , ""
  , "  for(int i=0; i<M; i++) {"
  , "    if (!" ++ prefix_r ++ "is_equal( SRC1(i) , SRC2(i) )) { ok = 0; break; }"
  , "  }"
  , "  if (!ok) return ok;"
  , ""
  , "  if (n1 >= n2) {"
  , "    for(int i=M; i<N; i++) {"
  , "      if (!" ++ prefix_r ++ "is_zero( SRC1(i) )) { ok = 0; break; }"
  , "    }"
  , "  }"
  , "  else {"
  , "    // n2 > n1"
  , "    for(int i=M; i<N; i++) {"
  , "      if (!" ++ prefix_r ++ "is_zero( SRC2(i) )) { ok = 0; break; }"
  , "    }"
  , "  }  "
  , "  return ok;"
  , "}"
  , ""
  , "// Negates a polynomial. "
  , "// Requires a target buffer of size `n1`."
  , "void " ++ prefix ++ "neg"
  , "  ( int  n1, const uint64_t *src1"
  , "  ,                uint64_t *tgt ) {"
  , ""
  , "  for(int i=0; i<n1; i++) {"
  , "    " ++ prefix_r ++ "neg( SRC1(i) , TGT(i) );"
  , "  }"
  , "}"
  , ""
  , "// Add two polynomials. "
  , "// Requires a target buffer of size `max(n1,n2)`"
  , "void " ++ prefix ++ "add"
  , "  ( int  n1, const uint64_t *src1"
  , "  , int  n2, const uint64_t *src2"
  , "  ,                uint64_t *tgt ) {"
  , ""
  , "  int M = MIN( n1 , n2 );"
  , "  int N = MAX( n1 , n2 );"
  , ""
  , "  for(int i=0; i<M; i++) {"
  , "    " ++ prefix_r ++ "add( SRC1(i) , SRC2(i) , TGT(i) );    "
  , "  }"
  , "  if (n1 >= n2) {"
  , "    for(int i=M; i<N; i++) {"
  , "      " ++ prefix_r ++ "copy( SRC1(i) , TGT(i) );    "
  , "    }"
  , "  }"
  , "  else {"
  , "    // n2 > n1"
  , "    for(int i=M; i<N; i++) {"
  , "      " ++ prefix_r ++ "copy( SRC2(i) , TGT(i) );    "
  , "    }"
  , "  }"
  , "}"
  , ""
  , "// Subtract two polynomials. "
  , "// Requires a target buffer of size `max(n1,n2)`"
  , "void " ++ prefix ++ "sub"
  , "  ( int  n1, const uint64_t *src1"
  , "  , int  n2, const uint64_t *src2"
  , "  ,                uint64_t *tgt ) {"
  , ""
  , "  int M = (n1 <= n2) ? n1 : n2;     // min"
  , "  int N = (n1 >= n2) ? n1 : n2;     // max"
  , ""
  , "  for(int i=0; i<M; i++) {"
  , "    " ++ prefix_r ++ "sub( SRC1(i) , SRC2(i) , TGT(i) );    "
  , "  }"
  , "  if (n1 >= n2) {"
  , "    for(int i=M; i<N; i++) {"
  , "      " ++ prefix_r ++ "copy( SRC1(i) , TGT(i) );    "
  , "    }"
  , "  }"
  , "  else {"
  , "    // n2 > n1"
  , "    for(int i=M; i<N; i++) {"
  , "      " ++ prefix_r ++ "neg( SRC2(i) , TGT(i) );    "
  , "    }"
  , "  }"
  , "}"
  , ""
  , "// Multiplies a polynomial by a constant. "
  , "// Requires a target buffer of size `n1`."
  , "void " ++ prefix ++ "scale"
  , "  (          const uint64_t *kst1"
  , "  , int n2 , const uint64_t *src2"
  , "  ,          uint64_t *tgt ) {"
  , "  if (" ++ prefix_r ++ "is_zero(kst1)) {"
  , "    // multiply by zero"
  , "    for(int i=0; i<n2; i++) { " ++ prefix_r ++ "set_zero( TGT(i) ); }"
  , "    return;"
  , "  }"
  , "  if (" ++ prefix_r ++ "is_one(kst1)) {"
  , "    // multiply by one"
  , "    for(int i=0; i<n2; i++) { " ++ prefix_r ++ "copy( SRC2(i) , TGT(i) ); }"
  , "    return;"
  , "  }"
  , "  // generic scaling"
  , "  for(int i=0; i<n2; i++) {"
  , "    " ++ prefix_r ++ "mul( kst1 , SRC2(i) , TGT(i) );"
  , "  }"
  , "}"
  , ""
  , "// Linear combination of K polynomials. "
  , "// Requires a target buffer of size max{ n_k | k=0..K-1 }"
  , "void " ++ prefix ++ "lincomb"
  , "  ( int  K                           // number of polynomials"
  , "  , const int *ns                    // sizes of the polynomials"
  , "  , const uint64_t **coeffs          // pointers to the combination coefficients"
  , "  , const uint64_t **polys           // pointers to the polynomials"
  , "  ,       uint64_t *tgt              // target buffer "
  , "  ) {"
  , ""
  , "  int N = 0;"
  , "  for(int k=0; k<K; k++) { "
  , "    if (ns[k] > N) { N = ns[k]; }"
  , "  }"
  , ""
  , "  for(int i=0; i<N; i++) {"
  , "    uint64_t acc[NLIMBS];"
  , "    " ++ prefix_r ++ "set_zero(acc);"
  , "    for(int k=0; k<K; k++) {"
  , "      int n = ns[k];"
  , "      if (i < n) {"
  , "        uint64_t tmp[NLIMBS];"
  , "        " ++ prefix_r ++ "mul( coeffs[k] , polys[k]+i*NLIMBS , tmp );"
  , "        " ++ prefix_r ++ "add_inplace( acc , tmp );"
  , "      }"
  , "    }"
  , "    " ++ prefix_r ++ "copy( acc, tgt+i*NLIMBS );"
  , "  }"
  , "}"
  , ""
  , "// Multiply two polynomials, naive algorithm. "
  , "// Requires a target buffer of size `(n1+n2-1)` (!)"
  , "void " ++ prefix ++ "mul_naive( int  n1, const uint64_t *src1"
  , "                   , int  n2, const uint64_t *src2"
  , "                   ,                uint64_t *tgt ) {"
  , ""
  , "  int N = n1+n2-1;"
  , "  for(int k=0; k<N; k++) {"
  , "    uint64_t acc[NLIMBS];"
  , "    " ++ prefix_r ++ "set_zero( acc );"
  , "    // 0 <= i <= min(k , n1-1)"
  , "    // 0 <= j <= min(k , n2-1)"
  , "    // k = i + j"
  , "    // 0 >= i = k - j >= k - min(k , n2-1)"
  , "    // 0 >= j = k - i >= k - min(k , n1-1)"
  , "    int A = MAX( 0 , k - MIN(k , n2-1) );"
  , "    int B = MIN( k , n1-1 );"
  , "    for( int i = A ; i <= B ; i++ ) {"
  , "      uint64_t tmp[NLIMBS];"
  , "      int j = k - i;"
  , "      " ++ prefix_r ++ "mul( SRC1(i) , SRC2(j) , tmp );"
  , "      " ++ prefix_r ++ "add_inplace( acc, tmp );      "
  , "    }"
  , "    " ++ prefix_r ++ "copy( acc, TGT(k) );"
  , "  }"
  , "}"
  , ""
  , "// evaluate a polynomial at a single point"
  , "void " ++ prefix ++ "eval_at( int  n1, const uint64_t *src1, const uint64_t *loc, uint64_t *tgt ) {"
  , "  uint64_t run[NLIMBS];               // x^i"
  , "  " ++ prefix_r ++ "set_zero(tgt);"
  , "  " ++ prefix_r ++ "set_one (run);"
  , "  for(int i=0; i<n1; i++) {"
  , "    uint64_t tmp[NLIMBS];"
  , "    if (i>0) { "
  , "      " ++ prefix_r ++ "mul( SRC1(i) , run , tmp );"
  , "      " ++ prefix_r ++ "add_inplace( tgt, tmp );      "
  , "    }"
  , "    else {"
  , "      // constant term"
  , "      " ++ prefix_r ++ "copy( SRC1(i) , tgt );      "
  , "    }"
  , "    if (i < n1-1) {"
  , "      " ++ prefix_r ++ "mul_inplace( run, loc );"
  , "    }"
  , "  }"
  , "}"
  ]

--------------------------------------------------------------------------------

c_code :: PolyParams -> Code
c_code params = concat $ map ("":)
  [ cBegin      params
  , cPolyBasics params
  ]

hs_code :: PolyParams -> Code
hs_code params@(PolyParams{..}) = concat $ map ("":)
  [ hsBegin      params
  , hsPolyBasics params
  ]

--------------------------------------------------------------------------------

poly_c_codegen :: FilePath -> PolyParams -> IO ()
poly_c_codegen tgtdir params@(PolyParams{..}) = do

  let fn_h = tgtdir </> (cFilePath "h" c_path)
  let fn_c = tgtdir </> (cFilePath "c" c_path)

  createTgtDirectory fn_h
  createTgtDirectory fn_c

  putStrLn $ "writing `" ++ fn_h ++ "`" 
  writeFile fn_h $ unlines $ c_header params

  putStrLn $ "writing `" ++ fn_c ++ "`" 
  writeFile fn_c $ unlines $ c_code params

poly_hs_codegen :: FilePath -> PolyParams -> IO ()
poly_hs_codegen tgtdir params@(PolyParams{..}) = do

  let fn_hs = tgtdir </> (hsFilePath hs_path)

  createTgtDirectory fn_hs

  putStrLn $ "writing `" ++ fn_hs ++ "`" 
  writeFile fn_hs $ unlines $ hs_code params

--------------------------------------------------------------------------------
