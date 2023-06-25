
-- | Generate elliptic curve FFI between Haskell and C code

{-# LANGUAGE BangPatterns, RecordWildCards #-}
module Zikkurat.CodeGen.Curve.CurveFFI where

--------------------------------------------------------------------------------

import Data.List
import Data.Word
import Data.Bits

import Control.Monad
import System.FilePath

import Zikkurat.CodeGen.Misc

--------------------------------------------------------------------------------

data CRet 
  = CRetVoid          -- ^ returns void
  | CRetBool          -- ^ returns bool or carry (as uint8)
  deriving (Eq, Show)

data CArg
  = CArgInt           -- ^ C integer
  | CArgInScalarP     -- ^ input ptr to a scalar in Fp
  | CArgInScalarR     -- ^ input ptr to a scalar in Fr
  | CArgInAffine      -- ^ input ptr to an affine point (2 coordinates)
  | CArgInProj        -- ^ input ptr to a projective point (3 coordinates, doesn't matter if weighted)
  | CArgOutAffine     -- ^ output ptr to an affine point
  | CArgOutProj       -- ^ output ptr to a projective point
  deriving (Eq, Show)

data CTyp 
  = CTyp [CArg] CRet
  deriving (Eq,Show)

data CFun 
  = CFun String CTyp
  deriving (Eq,Show)

--------------------------------------------------------------------------------

data HsTyDesc = HsTyDesc 
  { hsTyName  :: HsName          -- ^ type name (eg. @BigInt256@)
  , hsTyCon   :: HsName          -- ^ constructor name (eg. @MkBigInt256@)
  , hsNLimbsP :: Int             -- ^ number of limbs in Fp
  , hsNLimbsR :: Int             -- ^ number of limbs in Fr
  }
  deriving Show

--------------------------------------------------------------------------------

{-
-- TODO: put these in their own modules
hsMiscTmp :: Code
hsMiscTmp =
  [ "fromWord64sLE :: [Word64] -> Integer"
  , "fromWord64sLE = go where"
  , "  go []     = 0"
  , "  go (x:xs) = fromIntegral x + shiftL (go xs) 64"
  , ""
  , "toWord64sLE :: Integer -> [Word64]"
  , "toWord64sLE = go where"
  , "  go 0 = []"
  , "  go k = fromInteger (k .&. (2^64-1)) : go (shiftR k 64)"
  , ""
  , "toWord64sLE' :: Int -> Integer -> [Word64]"
  , "toWord64sLE' len what = take len $ toWord64sLE what ++ repeat 0"
  ]
-}

--------------------------------------------------------------------------------

curveFfiCall :: HsTyDesc -> HsName -> CFun -> Code
curveFfiCall HsTyDesc{..} hsFunName cfunty@(CFun cname ctyp) = case ctyp of

  CTyp [CArgInProj] CRetBool -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> IO Word8"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: " ++ hsTyName ++ " -> Bool" 
    , hsFunName ++ " (" ++ hsTyCon ++ " fptr) = unsafePerformIO $ do"
    , "  cret <- withForeignPtr fptr $ \\ptr -> do"
    , "    c_" ++ cname ++ " ptr"
    , "  return (cret /= 0)"
    ]

  CTyp [CArgInProj,CArgInProj] CRetBool -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> IO Word8"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: " ++ hsTyName ++ " -> " ++ hsTyName ++ " -> Bool" 
    , hsFunName ++ " (" ++ hsTyCon ++ " fptr1) (" ++ hsTyCon ++ " fptr2) = unsafePerformIO $ do"
    , "  cret <- withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      c_" ++ cname ++ " ptr1 ptr2"
    , "  return (cret /= 0)"
    ]

  CTyp [CArgInProj, CArgOutProj] CRetVoid -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> IO ()"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: " ++ hsTyName ++ " -> " ++ hsTyName 
    , hsFunName ++ " (" ++ hsTyCon ++ " fptr1) = unsafePerformIO $ do"
    , "  fptr2 <- mallocForeignPtrArray " ++ show (3*hsNLimbsP)
    , "  withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      c_" ++ cname ++ " ptr1 ptr2"
    , "  return (" ++ hsTyCon ++ " fptr2)"
    ]

{-
-- needs affine type
  CTyp [CArgInAffine, CArgOutProj] CRetVoid -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> IO ()"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: " ++ hsTyNameAffine ++ " -> " ++ hsTyName 
    , hsFunName ++ " (" ++ hsTyCon ++ " fptr1) = unsafePerformIO $ do"
    , "  fptr2 <- mallocForeignPtrArray " ++ show (3*hsNLimbsP)
    , "  withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      c_" ++ cname ++ " ptr1 ptr2"
    , "  return (" ++ hsTyCon ++ " fptr2)"
    ]

  CTyp [CArgInProj, CArgOutAffine] CRetVoid -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> IO ()"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: " ++ hsTyName ++ " -> " ++ hsTyNameAffine
    , hsFunName ++ " (" ++ hsTyCon ++ " fptr1) = unsafePerformIO $ do"
    , "  fptr2 <- mallocForeignPtrArray " ++ show (2*hsNLimbsP)
    , "  withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      c_" ++ cname ++ " ptr1 ptr2"
    , "  return (" ++ hsTyCon ++ " fptr2)"
    ]
-}

  CTyp [CArgInProj, CArgInProj, CArgOutProj] CRetVoid -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: " ++ hsTyName ++ " -> " ++ hsTyName ++ " -> " ++ hsTyName
    , hsFunName ++ " (" ++ hsTyCon ++ " fptr1) (" ++ hsTyCon ++ " fptr2) = unsafePerformIO $ do"
    , "  fptr3 <- mallocForeignPtrArray " ++ show (3*hsNLimbsP)
    , "  withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      withForeignPtr fptr3 $ \\ptr3 -> do"
    , "        c_" ++ cname ++ " ptr1 ptr2 ptr3"
    , "  return (" ++ hsTyCon ++ " fptr3)"
    ]

  CTyp [CArgInScalarR, CArgInProj, CArgOutProj] CRetVoid -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: Fr -> " ++ hsTyName ++ " -> " ++ hsTyName
    , hsFunName ++ " (MkFr fptr1) (" ++ hsTyCon ++ " fptr2) = unsafePerformIO $ do"
    , "  fptr3 <- mallocForeignPtrArray " ++ show (3*hsNLimbsP)
    , "  withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      withForeignPtr fptr3 $ \\ptr3 -> do"
    , "        c_" ++ cname ++ " ptr1 ptr2 ptr3 " -- ++ show hsNLimbsR
    , "  return (" ++ hsTyCon ++ " fptr3)"
    ]

  CTyp [CArgInScalarP, CArgInProj, CArgOutProj] CRetVoid -> 
    [ "foreign import ccall unsafe \"" ++ cname ++ "\" c_" ++ cname ++ " :: Ptr Word64 -> Ptr Word64 -> Ptr Word64 -> IO ()"
    , ""
    , "{-# NOINLINE " ++ hsFunName ++ " #-}"
    , hsFunName ++ " :: Fp -> " ++ hsTyName ++ " -> " ++ hsTyName
    , hsFunName ++ " (MkFp fptr1) (" ++ hsTyCon ++ " fptr2) = unsafePerformIO $ do"
    , "  fptr3 <- mallocForeignPtrArray " ++ show (3*hsNLimbsP)
    , "  withForeignPtr fptr1 $ \\ptr1 -> do"
    , "    withForeignPtr fptr2 $ \\ptr2 -> do"
    , "      withForeignPtr fptr3 $ \\ptr3 -> do"
    , "        c_" ++ cname ++ " ptr1 ptr2 ptr3 " -- ++ show hsNLimbsP
    , "  return (" ++ hsTyCon ++ " fptr3)"
    ]

  _ -> error $ "Zikkurat.CodeGen.Curve.CurveFFI.ffiCall: C function type not implemented:\n    " ++ show cfunty

--------------------------------------------------------------------------------

{-
curveFfiMarshal :: String -> String -> Int -> Code
curveFfiMarshal postfix typeName nlimbs =
  [ "{-# NOINLINE unsafeMk" ++ postfix ++ " #-}"
  , "unsafeMk" ++ postfix ++ " :: Integer -> IO " ++ typeName
  , "unsafeMk" ++ postfix ++ " x = do"
  , "  fptr <- mallocForeignPtrArray " ++ show nlimbs
  , "  withForeignPtr fptr $ \\ptr -> do"
  , "    pokeArray ptr $ toWord64sLE' " ++ show nlimbs ++ " x"
  , "  return $ Mk" ++ typeName ++ " fptr"
  , ""
  , "{-# NOINLINE unsafeGet" ++ postfix ++ " #-}"
  , "unsafeGet" ++ postfix ++ " :: " ++ typeName ++ " -> IO Integer"
  , "unsafeGet" ++ postfix ++ " (Mk" ++ typeName ++ " fptr) = do"
  , "  ws <- withForeignPtr fptr $ \\ptr -> peekArray " ++ show nlimbs ++ " ptr "
  , "  return (fromWord64sLE ws)"
  , ""
  , "{-# NOINLINE unsafeTo" ++ postfix ++ " #-}"
  , "unsafeTo" ++ postfix ++ " :: Integer -> " ++ typeName ++ ""
  , "unsafeTo" ++ postfix ++ " x = unsafePerformIO (unsafeMk" ++ postfix ++ " x)"
  , ""
  , "{-# NOINLINE unsafeFrom" ++ postfix ++ " #-}"
  , "unsafeFrom" ++ postfix ++ " :: " ++ typeName ++ " -> Integer"
  , "unsafeFrom" ++ postfix ++ " f = unsafePerformIO (unsafeGet" ++ postfix ++ " f)"
  ]
-}

--------------------------------------------------------------------------------
