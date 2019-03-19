module Internal exposing (HuffmanTable, Tree, buildBitsBase, buildTree, clcIndices, decodeDynamicTreeLength, decodeSymbol, decodeTrees, hardcodedDistanceTable, hardcodedLengthTable, inflate, inflateBlockData, inflateBlockDataHelp, inflateUncompressedBlock, sdtree, sltree, uncompress, uncompressHelp, update)

import Array exposing (Array)
import BitReader exposing (BitReader(..))
import Bitwise
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as Decode exposing (Step(..))
import Bytes.Encode as Encode


inflate : Bytes -> Result String Bytes
inflate buffer =
    case BitReader.decode buffer uncompress of
        Err e ->
            Err e

        Ok values ->
            Ok (Encode.encode <| Encode.sequence (List.map Encode.bytes values))


encodeUint8Array : Array Int -> Bytes
encodeUint8Array values =
    Array.toList (Array.map Encode.unsignedInt8 values)
        |> Encode.sequence
        |> Encode.encode


uncompress : BitReader (List Bytes)
uncompress =
    BitReader.loop [] uncompressHelp
        |> BitReader.map List.reverse


uncompressHelp : List Bytes -> BitReader (Step (List Bytes) (List Bytes))
uncompressHelp output =
    let
        readTwoBits =
            BitReader.map2 (\b1 b2 -> b1 + 2 * b2) BitReader.getBit BitReader.getBit

        uncompressBlock btype =
            case btype of
                0 ->
                    -- read 5 more bits (i.e. the first byte) without reading extra bytes into the `tag`
                    BitReader.exactly 5 BitReader.getBit
                        |> BitReader.andThen (\_ -> inflateUncompressedBlock)
                        |> BitReader.map (\v -> v :: output)

                1 ->
                    let
                        lengthSoFar =
                            List.sum (List.map Bytes.width output)
                    in
                    inflateBlockData sltree sdtree lengthSoFar Array.empty
                        |> BitReader.map encodeUint8Array
                        |> BitReader.map (\v -> v :: output)

                2 ->
                    let
                        lengthSoFar =
                            List.sum (List.map Bytes.width output)
                    in
                    decodeTrees
                        |> BitReader.andThen (\( ltree, dtree ) -> inflateBlockData ltree dtree lengthSoFar Array.empty)
                        |> BitReader.map encodeUint8Array
                        |> BitReader.map (\v -> v :: output)

                _ ->
                    BitReader.error "invalid block type"

        go isFinal blockType =
            if isFinal /= 0 then
                BitReader.map Done (uncompressBlock blockType)

            else
                BitReader.map (Debug.log "loop" Loop) (uncompressBlock blockType)
    in
    BitReader.map2 go BitReader.getBit readTwoBits
        |> BitReader.andThen identity


type alias HuffmanTable =
    { bits : Array Int, base : Array Int }


readHuffmanTable : Int -> HuffmanTable -> Maybe { bits : Int, base : Int }
readHuffmanTable index table =
    Maybe.map2 (\x y -> { bits = x, base = y })
        (Array.get index table.bits)
        (Array.get index table.base)


type alias Tree =
    { table : Array Int, trans : Array Int }


buildBitsBase : Int -> Int -> HuffmanTable
buildBitsBase delta first =
    let
        folder bit ( sum, accum ) =
            ( sum + Bitwise.shiftLeftBy bit 1, Array.push sum accum )

        initializer i =
            if i < delta then
                0

            else
                (i - delta) // delta

        bits =
            Array.initialize 30 initializer

        base =
            Array.foldl folder ( first, Array.empty ) bits
                |> Tuple.second
    in
    { bits = bits
    , base = base
    }


hardcodedLengthTable : HuffmanTable
hardcodedLengthTable =
    buildBitsBase 4 3
        -- fix a special case
        |> (\{ bits, base } -> { bits = Array.set 28 0 bits, base = Array.set 28 258 base })


hardcodedDistanceTable : HuffmanTable
hardcodedDistanceTable =
    buildBitsBase 2 1


sltree : Tree
sltree =
    { table = Array.fromList [ 0, 0, 0, 0, 0, 0, 0, 24, 152, 112, 0, 0, 0, 0, 0, 0 ]
    , trans =
        Array.fromList
            [ 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 280, 281, 282, 283, 284, 285, 286, 287, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255 ]
    }


sdtree : Tree
sdtree =
    { table = Array.fromList [ 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    , trans = Array.append (Array.fromList [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 ]) (Array.repeat (288 - 32) 0)
    }


clcIndices : Array Int
clcIndices =
    Array.fromList
        [ 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 ]


buildTree : Array Int -> Int -> Int -> Tree
buildTree lengths offset num =
    let
        table : Array Int
        table =
            Array.slice offset (num + offset) lengths
                |> Array.foldl (\i -> update i (\v -> v + 1)) (Array.repeat 16 0)
                |> Array.set 0 0

        offsets : Array Int
        offsets =
            Array.foldl (\v ( sum, accum ) -> ( v + sum, Array.push sum accum )) ( 0, Array.empty ) table
                |> Tuple.second

        helper : Int -> { translation : Array Int, offsets : Array Int } -> { translation : Array Int, offsets : Array Int }
        helper i state =
            case Array.get (offset + i) lengths of
                Nothing ->
                    state

                Just v ->
                    if v /= 0 then
                        case Array.get v state.offsets of
                            Nothing ->
                                state

                            Just w ->
                                { offsets = update v (\x -> x + 1) state.offsets
                                , translation = Array.set w i state.translation
                                }

                    else
                        state

        { translation } =
            List.foldl helper { translation = Array.repeat num 0, offsets = offsets } (List.range 0 (num - 1))
    in
    { table = table, trans = translation }


update : Int -> (a -> a) -> Array a -> Array a
update index f array =
    case Array.get index array of
        Nothing ->
            array

        Just v ->
            Array.set index (f v) array


decodeSymbol : Tree -> BitReader Int
decodeSymbol tree =
    BitReader <|
        \state ->
            case BitReader.fillWindow state of
                Err e ->
                    Err e

                Ok d ->
                    let
                        help2 cur tag len sum =
                            let
                                newLen =
                                    1 + len
                            in
                            case Array.get newLen tree.table of
                                Nothing ->
                                    ( Array.get (sum + cur) tree.trans
                                        |> Maybe.withDefault -10
                                    , { d
                                        | tag = tag
                                        , bitcount = d.bitcount - len
                                      }
                                    )

                                Just value ->
                                    let
                                        newCur =
                                            (2 * cur + Bitwise.and tag 1) - value
                                    in
                                    if newCur >= 0 then
                                        help2 newCur (Bitwise.shiftRightZfBy 1 tag) newLen (sum + value)

                                    else
                                        ( Array.get (sum + value + newCur) tree.trans
                                            |> Maybe.withDefault -10
                                        , { d
                                            | tag = Bitwise.shiftRightZfBy 1 tag
                                            , bitcount = d.bitcount - newLen
                                          }
                                        )
                    in
                    Ok (help2 0 d.tag 0 0)



-- DECODE HUFFMAN TREES


decodeTrees : BitReader ( Tree, Tree )
decodeTrees =
    let
        cont : Int -> Int -> Int -> BitReader ( Tree, Tree )
        cont hlit hdist hclen =
            let
                decodeTreeLengths : List Int -> BitReader (Array Int)
                decodeTreeLengths codeLengths =
                    let
                        clcs =
                            Array.toList (Array.slice 0 hclen clcIndices)

                        initialLengths =
                            List.map2 Tuple.pair clcs codeLengths
                                |> List.foldl (\( index, codeLength ) -> Array.set index codeLength) (Array.repeat (288 + 32) 0)

                        codeTree =
                            buildTree initialLengths 0 19
                    in
                    BitReader.loop ( 0, initialLengths ) (decodeDynamicTreeLength codeTree hlit hdist)

                buildTrees : Array Int -> ( Tree, Tree )
                buildTrees lengths =
                    ( buildTree lengths 0 hlit
                    , buildTree lengths hlit hdist
                    )
            in
            BitReader.exactly hclen (BitReader.readBits 3 0)
                |> BitReader.andThen decodeTreeLengths
                |> BitReader.map buildTrees
    in
    BitReader.map3 cont (BitReader.readBits 5 257) (BitReader.readBits 5 1) (BitReader.readBits 4 4)
        |> BitReader.andThen identity


decodeDynamicTreeLength : Tree -> Int -> Int -> ( Int, Array Int ) -> BitReader (Step ( Int, Array Int ) (Array Int))
decodeDynamicTreeLength codeTree hlit hdist ( i, lengths ) =
    let
        copySegment : Int -> Int -> Step ( Int, Array Int ) a
        copySegment value length =
            Loop
                ( i + length
                , List.foldl (\j -> Array.set j value) lengths (List.range i ((i + length) - 1))
                )
    in
    if i < hlit + hdist then
        decodeSymbol codeTree
            |> BitReader.andThen
                (\sym ->
                    case sym of
                        16 ->
                            -- copy previous code length 3-6 times (read 2 bits)
                            let
                                prev =
                                    Array.get (i - 1) lengths |> Maybe.withDefault 0
                            in
                            BitReader.readBits 2 3
                                |> BitReader.map (copySegment prev)

                        17 ->
                            --  repeat code length 0 for 3-10 times (read 3 bits)
                            BitReader.readBits 3 3
                                |> BitReader.map (copySegment 0)

                        18 ->
                            -- repeat code length 0 for 11-138 times (read 7 bits)
                            BitReader.readBits 7 11
                                |> BitReader.map (copySegment 0)

                        _ ->
                            -- values 0-15 represent the actual code lengths
                            BitReader.succeed (Loop ( i + 1, Array.set i sym lengths ))
                )

    else
        BitReader.succeed (Done lengths)



-- INFLATE BLOCK


inflateBlockData : Tree -> Tree -> Int -> Array Int -> BitReader (Array Int)
inflateBlockData lt dt outputLength output =
    BitReader.loop output (inflateBlockDataHelp lt dt outputLength)


inflateBlockDataHelp : Tree -> Tree -> Int -> Array Int -> BitReader (Step (Array Int) (Array Int))
inflateBlockDataHelp lt dt outputLength output =
    decodeSymbol lt
        |> BitReader.andThen
            (\symbol ->
                -- check for end of block
                if symbol == 256 then
                    BitReader.succeed (Done output)

                else if symbol < 256 then
                    BitReader.succeed (Loop (Array.push symbol output))

                else
                    let
                        copySectionToEnd : Int -> Int -> Array Int -> Array Int
                        copySectionToEnd i end accum =
                            Array.append accum (Array.slice (i - outputLength) (end - outputLength) accum)

                        decodeLength : BitReader Int
                        decodeLength =
                            case readHuffmanTable (symbol - 257) hardcodedLengthTable of
                                Nothing ->
                                    BitReader.error
                                        ("index out of bounds in hardcodedLengthTable: requested index "
                                            ++ String.fromInt (symbol - 257)
                                            ++ "but hardcodedLengthTable has length "
                                            ++ String.fromInt (Array.length hardcodedLengthTable.bits)
                                        )

                                Just entry ->
                                    BitReader.readBits entry.bits entry.base

                        decodeOffset : BitReader Int
                        decodeOffset =
                            decodeSymbol dt
                                |> BitReader.andThen
                                    (\distance ->
                                        case readHuffmanTable distance hardcodedDistanceTable of
                                            Nothing ->
                                                BitReader.error
                                                    ("index out of bounds in hardcodedDistanceTable: requested index "
                                                        ++ String.fromInt distance
                                                        ++ "but hardcodedLengthTable has length "
                                                        ++ String.fromInt (Array.length hardcodedDistanceTable.bits)
                                                    )

                                            Just entry ->
                                                BitReader.readBits entry.bits entry.base
                                                    {-
                                                       TODO is this correct?
                                                       We know that the blocks are independent https://www.w3.org/Graphics/PNG/RFC-1951
                                                       But the offset is probably still given for the whole (across blocks)
                                                    -}
                                                    |> BitReader.map (\v -> ((outputLength + Array.length output) - v) - outputLength)
                                    )
                    in
                    BitReader.map2 (\length offset -> Loop (copySectionToEnd offset (offset + length) output)) decodeLength decodeOffset
            )



-- UNCOMPRESSED BLOCK


inflateUncompressedBlock : BitReader Bytes
inflateUncompressedBlock =
    BitReader
        (\state ->
            case Decode.decode (uncompressedBlockDecoder (Bytes.width state.buffer)) state.buffer of
                Nothing ->
                    Err "inflateUncompressedBlock: ran out of bounds"

                Just ( block, newBuffer ) ->
                    Ok ( block, { state | buffer = newBuffer } )
        )


uncompressedBlockDecoder : Int -> Decode.Decoder ( Bytes, Bytes )
uncompressedBlockDecoder bufferWidth =
    let
        decodeLengths =
            Decode.map2 Tuple.pair (Decode.unsignedInt16 LE) (Decode.unsignedInt16 LE)
    in
    decodeLengths
        |> Decode.andThen
            (\( length, invlength ) ->
                -- invlength has to be the complement of length for this block to be valid
                -- like a small simple checksum
                if length /= Bitwise.and (Bitwise.complement invlength) 0xFFFF then
                    Decode.fail

                else
                    let
                        remainingSize =
                            bufferWidth - 4 - length
                    in
                    Decode.map2 Tuple.pair (Decode.bytes length) (Decode.bytes remainingSize)
            )
