module Inflate exposing
    ( inflate, inflateZLib, inflateGZip
    , crc32, adler32
    )

{-| Decompress data compressed with a deflate algorithm.

    import Bytes exposing (Bytes, Endianness(..))
    import Bytes.Decode as Decode
    import Bytes.Encode as Encode
    import Inflate

    {-| Some sample text
    -}
    text : String
    text =
        "Myn geast ferdizet"

    {-| The `text` compressed with raw deflate

    The bytes are combined into 32bit integers using
    hex notation so they are shorter in the docs

    -}
    textCompressedBytes =
        [ 0xF3ADCC53
        , 0x484F4D2C
        , 0x2E51484B
        , 0x2D4AC9AC
        , 0x4A2D0100
        ]
            |> List.map (Encode.unsignedInt32 BE)
            |> Encode.sequence
            |> Encode.encode

    decodeString : Bytes -> Maybe String
    decodeString buffer =
        let
            decoder =
                Decode.string (Encode.getStringWidth text)
        in
        Decode.decode decoder buffer

    decompressed =
        textCompressedBytes
            |> Inflate.inflate
            |> Maybe.andThen decodeString
            |> Maybe.withDefault ""


## Inflate

@docs inflate, inflateZLib, inflateGZip


## Checksums

@docs crc32, adler32

-}

import Adler32
import Bytes exposing (Bytes)
import Crc32
import GZip
import Internal
import ZLib


{-| Inflate a sequence of bytes that is compressed with raw deflate.
-}
inflate : Bytes -> Maybe Bytes
inflate buffer =
    case Internal.inflate buffer of
        Err _ ->
            Nothing

        Ok newBuffer ->
            Just newBuffer


{-| Inflate data compressed with [zlib](http://www.zlib.net/).

zlib adds some extra data at the front and the back. This decoder will take care of that and also check the checksum if specified.

-}
inflateZLib : Bytes -> Maybe Bytes
inflateZLib =
    ZLib.inflate >> Result.toMaybe


{-| Inflate data compressed with gzip.

gzip adds some extra data at the front and the back. This decoder will take care of that and also check the checksum if specified.

-}
inflateGZip : Bytes -> Maybe Bytes
inflateGZip =
    GZip.inflate


{-| The adler32 checksum.

Used in zlib. Faster than crc32, but also less reliable (larger chance of collisions).

-}
adler32 : Bytes -> Int
adler32 =
    Adler32.adler32


{-| The crc32 checksum.

Used in gzip. Slower than adler32, but also more reliable (smaller chance of collisions).

-}
crc32 : Bytes -> Int
crc32 =
    Crc32.crc32
