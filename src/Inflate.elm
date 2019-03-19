module Inflate exposing (inflate)

{-| Decompress data compressed with a deflate algorithm

@docs inflate

-}

import Bytes exposing (Bytes)
import Internal


{-| Inflate a sequence of bytes

    import Bytes exposing (Bytes)
    import Bytes.Encode as Encode
    import Inflate

    deyrfé : String
    deyrfé =
        "Deyr fé, deyja frændr"

    -- string compressed with zlib
    compressed : Bytes.Bytes
    compressed =
        [ 115, 73, 173, 44, 82, 72, 59, 188, 82, 71, 33, 37, 181, 50, 43, 81, 33, 173, 232, 240, 178, 188, 148, 34, 46, 0 ]
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

-}
inflate : Bytes -> Maybe Bytes
inflate buffer =
    case Internal.inflate buffer of
        Err _ ->
            Nothing

        Ok newBuffer ->
            Just newBuffer
