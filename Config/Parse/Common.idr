-- -------------------------------------------------------------- [ Common.idr ]
-- Description : Common Parsing Functions
-- Copyright   : (c) Jan de Muijnck-Hughes
-- License     : see LICENSE
-- --------------------------------------------------------------------- [ EOH ]
module Config.Parse.Common

import Control.Monad.Identity

import Lightyear.Core
import Lightyear.Combinators
import Lightyear.Strings

import Config.Parse.Utils

%access public

keyvalue : String
         -> Parser String
         -> Parser (String, String)
keyvalue s value = do
    k <- word
    token s
    v <- value
    space
    pure (k,v)
  <?> "KVPair"
-- --------------------------------------------------------------------- [ EOF ]
