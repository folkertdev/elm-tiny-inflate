# elm-tiny-inflate 

Decompress deflate compressed data. Deflate compression is used in e.g. zip, png and woff.

The api consists of just one function: `inflate : Bytes -> Maybe Bytes`.

```elm
import Bytes exposing (Bytes)
import Bytes.Encode as Encode 
import Inflate

deyrfé : String
deyrfé =
    "Deyr fé, deyja frændr"

-- string compressed with zlib
compressed : Bytes.Bytes
compressed =
    [ 115, 73, 173, 44, 82, 72, 59, 188, 82, 71, 33, 37
    , 181, 50, 43, 81, 33, 173, 232, 240, 178, 188, 148
    , 34, 46, 0 
    ]
        |> List.map Encode.unsignedInt8
        |> Encode.sequence
        |> Encode.encode

decompressedLength : Int 
decompressedLength = 
    -- + 2 because string uses 2 non-ascii characters 
    -- (they take an extra byte)
    String.length deyrfé + 2

decode : Bytes -> Maybe String
decode =
    Decode.decode (Decode.string decompressedLength)

decompressed : String
decompressed =
    Inflate.inflate compressed 
        |> Maybe.andThen decode
        |> Maybe.withDefault ""
        --> "Deyr fé, deyja frændr"
```

Here the deflated data is given as a list of bytes, in practice you would probably load the `Bytes` directly. 
The inflation is only a small step in the process, I've included the full decoding of the compressed string
to show what that looks like.

## Thanks 

* Jørgen Ibsen, author of [tinf](https://bitbucket.org/jibsen/tinf/src/default/) which this package is based on
* Devon Govett, author of [tiny-inflate](https://github.com/foliojs/tiny-inflate), a JS port of tinf (easier to read)
