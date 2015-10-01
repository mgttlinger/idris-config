-- ---------------------------------------------------------------- [ JSON.idr ]
-- Description : Parse JSON files.
--               This code was borrowed and improved from lightyear examples.
--
-- Copyright   : (c) Jan de Muijnck-Hughes
-- License     : see LICENSE
-- --------------------------------------------------------------------- [ EOH ]
module Config.JSON

import public Data.AVL.Dict

import Effects
import Effect.File

import Lightyear
import Lightyear.Char
import Lightyear.Strings

import public Config.Error

import Config.Parse.Utils
import Config.Parse.Common

%access private

-- ------------------------------------------------------------------- [ Model ]

public
data JsonValue = JsonString String
               | JsonNumber Float
               | JsonBool Bool
               | JsonNull
               | JsonArray (List JsonValue)
               | JsonObject (Dict String JsonValue)

instance Show JsonValue where
  show (JsonString s)   = show s
  show (JsonNumber x)   = show x
  show (JsonBool True ) = "true"
  show (JsonBool False) = "false"
  show  JsonNull        = "null"
  show (JsonArray  xs)  = show xs
  show (JsonObject xs)  =
      "{" ++ unwords (intersperse "," (map fmtItem $ Dict.toList xs)) ++ "}"
    where
      fmtItem (k, v) = show k ++ " : " ++ show v

-- ------------------------------------------------------------------ [ Parser ]
jsonString : Parser String
jsonString = quoted '"' <?> "JSON String"

jsonNumber : Parser Float
jsonNumber = map scientificToFloat parseScientific <?> "JSON Number"

jsonBool : Parser Bool
jsonBool  =  (char 't' >! string "rue"  *> return True)
         <|> (char 'f' >! string "alse" *> return False)
         <?> "JSON Bool"

jsonNull : Parser ()
jsonNull = (char 'n' >! string "ull" >! return ()) <?> "JSON Null"

mutual
  jsonArray : Parser (List JsonValue)
  jsonArray = brackets (commaSep jsonValue) <?> "JSON Array"

  keyValuePair : Parser (String, JsonValue)
  keyValuePair = do
      key <- spaces *> jsonString <* spaces
      colon
      value <- jsonValue
      pure (key, value)
    <?> "JSON KV Pair"

  jsonObject : Parser (Dict String JsonValue)
  jsonObject = map fromList $ braces (commaSep (keyValuePair)) <?> "JSON Object"

  jsonValue' : Parser JsonValue
  jsonValue' =  (map JsonString jsonString)
            <|> (map JsonNumber jsonNumber)
            <|> (map JsonBool   jsonBool)
            <|> (pure JsonNull <* jsonNull)
            <|>| map JsonArray  jsonArray
            <|>| map JsonObject jsonObject

  jsonValue : Parser JsonValue
  jsonValue = spaces *> jsonValue' <* spaces <?> "JSON Value"

public
parseJSONFile : Parser JsonValue
parseJSONFile = (map JsonArray jsonArray)
            <|> (map JsonObject jsonObject)
            <?> "JSON Files"



public
toString : JsonValue -> String
toString doc = show doc

public
fromString : String -> Either ConfigError JsonValue
fromString str =
    case parse parseJSONFile str of
      Left err  => Left (PureParseErr err)
      Right doc => Right doc

-- -------------------------------------------------------------------- [ Read ]
public
readJSONConfig : String -> Eff (Either ConfigError JsonValue) [FILE_IO ()]
readJSONConfig = readConfigFile parseJSONFile

-- --------------------------------------------------------------------- [ EOF ]
