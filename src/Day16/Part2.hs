module Day16.Part2 (solve) where
    import Text.Printf (printf)
    import Data.Char (digitToInt)
    import Text.Parsec (anyChar, digit, getPosition, sourceColumn)
    import Text.ParserCombinators.Parsec (GenParser, count, parse)
    import Helpers.Input (orFail)

    import Debug.Trace (trace)

    mapHex :: Char -> String
    mapHex '0' = "0000"
    mapHex '1' = "0001"
    mapHex '2' = "0010"
    mapHex '3' = "0011"
    mapHex '4' = "0100"
    mapHex '5' = "0101"
    mapHex '6' = "0110"
    mapHex '7' = "0111"
    mapHex '8' = "1000"
    mapHex '9' = "1001"
    mapHex 'A' = "1010"
    mapHex 'B' = "1011"
    mapHex 'C' = "1100"
    mapHex 'D' = "1101"
    mapHex 'E' = "1110"
    mapHex 'F' = "1111"
    mapHex x = [x]

    data Payload = Operator [Packet] | Value Int
    -- Packet Version Type Payload
    data Packet = Packet Int Int Payload

    convertBitstring :: String -> Int
    convertBitstring = foldl (\acc next -> acc * 2 + digitToInt next) 0

    parsePacket :: GenParser Char st Packet
    parsePacket = do
        version <- convertBitstring <$> count 3 digit
        type' <- convertBitstring <$> count 3 digit
        payload <- case type' of
            4 -> parseValue
            _ -> parseOperator
        return $ Packet version type' payload

    parseValue :: GenParser Char st Payload
    parseValue = do
        numbers <- reverse <$> parseVarInt
        return $ Value $ foldl (\acc (shift, value) -> 16^shift * value + acc) 0 (zip [0..] numbers)

    parseVarInt :: GenParser Char st [Int]
    parseVarInt = do
        notLast <- convertBitstring <$> count 1 digit
        value <- convertBitstring <$> count 4 digit
        case notLast of
          0 -> return [value]
          1 -> ( value :) <$> parseVarInt
          _ -> error "I don't trust this a bit"

    parseOperator :: GenParser Char st Payload
    parseOperator = do
        lengthTypeId <- convertBitstring <$> count 1 digit
        length <- case lengthTypeId of
            0 -> convertBitstring <$> count 15 digit
            1 -> convertBitstring <$> count 11 digit
            _ -> error "Invalid length type id"
        pos <- sourceColumn <$> getPosition
        payload <- case lengthTypeId of
            0 -> parseLengthPayload (pos + length)
            1 -> count length parsePacket
            _ -> error "Invalid length type id"
        return $ Operator payload

    parseLengthPayload :: Int -> GenParser Char st [Packet]
    parseLengthPayload end = do
        pos <- sourceColumn <$> getPosition
        if pos == end then return [] else (:) <$> parsePacket <*> parseLengthPayload end

    getValue :: Packet -> Int
    -- Value packets are simply unwrapped
    getValue (Packet _ 4 (Value x)) = x
    getValue (Packet _ 0 (Operator packets)) = sum (map getValue packets)
    getValue (Packet _ 1 (Operator packets)) = product (map getValue packets)
    getValue (Packet _ 2 (Operator packets)) = minimum (map getValue packets)
    getValue (Packet _ 3 (Operator packets)) = maximum (map getValue packets)
    getValue (Packet _ 5 (Operator [a, b])) = fromEnum $ getValue a > getValue b
    getValue (Packet _ 6 (Operator [a, b])) = fromEnum $ getValue a < getValue b
    getValue (Packet _ 7 (Operator [a, b])) = fromEnum $ getValue a == getValue b
    getValue _ = error "Invalid packet"

    solve = do
        packets <- (orFail . parse parsePacket "Input") . concatMap mapHex =<< getContents
        printf "Evaluating the packet yields %d" $ getValue packets

