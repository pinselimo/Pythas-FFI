{- |
Module          : Foreign.Pythas
Description     : Haskell backend for Python's Pythas
Copyright       : (c) Simon Plakolb, 2020
License         : LGPLv3
Maintainer      : s.plakolb@gmail.com
Stability       : beta

    This package contains the Haskell backend to the Python package 'Pythas'. It contains wrapper functions and can create FFI bindings from a Haskell source file. The Python and Haskell package are closely related. Some of the provided wrapper types may have unconventional design due to limitations of Python's 'ctypes' library.
    This package is mainly provided to give developers the possibility to exporiment with Pythas's types within a Haskell environment. The Python library contains the source files as well and will compile them itself in a local directory.
 -}
module Foreign.Pythas (
    createFileBindings
) where

import System.FilePath.Posix (dropExtension)
import Text.Parsec.String (parseFromFile)
import Text.Parsec.Error (ParseError)
import Control.Exception (Exception, throw)

import Foreign.Pythas.Parser (parseTypeDefs, parseExports, parseModname)
import Foreign.Pythas.FFICreate (createFFI)
import Foreign.Pythas.Utils (TypeDef(funcN))

newtype PythasException = ParseException ParseError
                         deriving (Show)
instance Exception PythasException

{- |
    Parses a Haskell source file at @fp@ and creates a new module for which it will return the @FilePath@.
    The new file will be located in the same diretory and contain @foreign export ccall@s for all those functions, where wrapping is possible.
    Lists are converted to @Foreign.Pythas.Arrayæs, Strings also get their own type. This is due to the handling of these types by Python's 'ctypes'. Tuples with up to four fields can also be wrapped as C structs using the @c-structs@ package.
    It is not necessary to use @Foreign.C.Types@. Conversion to these types will be done automatically. It is however necessary to provide type definitions for all functions that should be in the exports. Type synonyms and custom types are not (yet) supported.
 -}
createFileBindings :: FilePath -> IO FilePath
createFileBindings fp = let
    check = either (throw . ParseException) return
    fp'   = dropExtension fp ++ "_pythas_ffi.hs"
    in do

    modname  <- check =<< parseFromFile parseModname  fp
    typeDefs <- check =<< parseFromFile parseTypeDefs fp
    expts    <- parseFromFile parseExports fp

    let exports   = either (\_ -> map funcN typeDefs) id expts
        fc = createFFI fp modname exports typeDefs

    writeFile fp' fc
    return fp'

