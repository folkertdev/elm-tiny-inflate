module ZLib exposing (inflate)

-- original https://bitbucket.org/jibsen/tinf/src/default/src/tinfzlib.c

import Adler32
import Bitwise
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as Decode exposing (Decoder)
import Internal


type alias Slices =
    { cmf : Int
    , flg : Int
    , buffer : Bytes
    , a32 : Int
    }


slice : Bytes -> Maybe Slices
slice buffer =
    let
        decoder =
            Decode.map4 Slices
                Decode.unsignedInt8
                Decode.unsignedInt8
                (Decode.bytes (Bytes.width buffer - 2 - 4))
                decodeAdler32Checksum
    in
    Decode.decode decoder buffer


inflate : Bytes -> Maybe Bytes
inflate buffer =
    case slice buffer of
        Nothing ->
            Nothing

        Just sliced ->
            -- /* check checksum */
            if ((256 * sliced.cmf + sliced.flg) |> modBy 31) /= 0 then
                Nothing
                -- /* check method is deflate */

            else if Bitwise.and sliced.cmf 0x0F /= 8 then
                Nothing
                -- /* check window size is valid */

            else if Bitwise.shiftRightBy 4 sliced.cmf > 7 then
                Nothing
                -- /* check there is no preset dictionary */

            else if Bitwise.and sliced.flg 0x20 /= 0 then
                Nothing

            else
                case Internal.inflate sliced.buffer of
                    Err _ ->
                        Nothing

                    Ok resultBuffer ->
                        if sliced.a32 /= Adler32.adler32 resultBuffer then
                            Nothing

                        else
                            Just resultBuffer


decodeAdler32Checksum : Decoder Int
decodeAdler32Checksum =
    Decode.unsignedInt32 BE
