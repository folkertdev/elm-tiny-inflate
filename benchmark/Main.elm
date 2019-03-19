module Main exposing (suite)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import BitReader
import Bytes
import Bytes.Decode as Decode
import Bytes.Encode as Encode
import Internal as Inflate
import TestData.Havamal as Havamal


main : BenchmarkProgram
main =
    program suite


suite : Benchmark
suite =
    let
        encode v =
            v |> List.map Encode.unsignedInt8 |> Encode.sequence |> Encode.encode

        decode b =
            Decode.decode (BitReader.exactlyBytes (Bytes.width b) Decode.unsignedInt8) b
    in
    describe "havamál"
        [ benchmark "no compression" <|
            \_ ->
                Inflate.inflate (encode Havamal.noCompression)
        , benchmark "fixed compression" <|
            \_ ->
                Inflate.inflate (encode Havamal.fixed)
        , benchmark "dynamic compression" <|
            \_ ->
                Inflate.inflate (encode Havamal.compressed)
        ]



{-
   havamál
   no compression
   runs / second
   9,216
   goodness of fit
   99.87%
   havamál
   fixed compression
   runs / second
   3,591
   goodness of fit
   99.98%
   havamál
   dynamic compression
   runs / second
   2,181
   goodness of fit
   99.97%

-}
