# elm-tiny-inflate 

Decompress deflate compressed data. Deflate compression is used in the zip and gzip archive formats, but also as a building block in other file formats like png and woff. The package supports raw inflate, zlib, and gzip.

```elm
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
```

Here the deflated data is given as a list of bytes, in practice you would probably load the `Bytes` directly. 
The inflation is only a small step in the process: I've included the full decoding of the compressed string
to show what that looks like.

## Thanks 

* Jørgen Ibsen, author of [tinf](https://bitbucket.org/jibsen/tinf/src/default/) which this package is based on
* Devon Govett, author of [tiny-inflate](https://github.com/foliojs/tiny-inflate), a JS port of tinf (easier to read)
