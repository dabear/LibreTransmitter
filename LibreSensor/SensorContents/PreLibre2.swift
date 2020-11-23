import Foundation

enum Libre2 {
    /// Decrypts 43 blocks of Libre 2 FRAM
    /// - Parameters:
    ///   - type: Suppurted sensor type (.libre2, .libreUS14day)
    ///   - id: ID/Serial of the sensor. Could be retrieved from NFC as uid.
    ///   - info: Sensor info. Retrieved by sending command '0xa1' via NFC.
    ///   - data: Encrypted FRAM data
    /// - Returns: Decrypted FRAM data
    static func decryptFRAM(type: SensorType, id: [UInt8], info: [UInt8], data: [UInt8]) throws -> [UInt8] {
        guard type == .libre2 || type == .libreUS14day else {
            struct DecryptFRAMError: Error {
                let errorDescription = "Unsupported sensor type"
            }
            throw DecryptFRAMError()
        }

        func getArg(block: Int) -> UInt16 {
            switch type {
            case .libreUS14day:
                if block < 3 || block >= 40 {
                    // For header and footer it is a fixed value.
                    return 0xcadc
                }
                return UInt16(info[5], info[4])
            case .libre2:
                return UInt16(info[5], info[4]) ^ 0x44
            default: fatalError("Unsupported sensor type")
            }
        }

        var result = [UInt8]()

        for i in 0 ..< 43 {
            let input = prepareVariables(id: id, x: UInt16(i), y: getArg(block: i))
            let blockKey = processCrypto(input: input)

            result.append(data[i * 8 + 0] ^ UInt8(truncatingIfNeeded: blockKey[0]))
            result.append(data[i * 8 + 1] ^ UInt8(truncatingIfNeeded: blockKey[0] >> 8))
            result.append(data[i * 8 + 2] ^ UInt8(truncatingIfNeeded: blockKey[1]))
            result.append(data[i * 8 + 3] ^ UInt8(truncatingIfNeeded: blockKey[1] >> 8))
            result.append(data[i * 8 + 4] ^ UInt8(truncatingIfNeeded: blockKey[2]))
            result.append(data[i * 8 + 5] ^ UInt8(truncatingIfNeeded: blockKey[2] >> 8))
            result.append(data[i * 8 + 6] ^ UInt8(truncatingIfNeeded: blockKey[3]))
            result.append(data[i * 8 + 7] ^ UInt8(truncatingIfNeeded: blockKey[3] >> 8))
        }
        return result
    }

    /// Decrypts Libre 2 BLE payload
    /// - Parameters:
    ///   - id: ID/Serial of the sensor. Could be retrieved from NFC as uid.
    ///   - data: Encrypted BLE data
    /// - Returns: Decrypted BLE data
    static func decryptBLE(id: [UInt8], data: [UInt8]) throws -> [UInt8] {
        let d = usefulFunction(id: id, x: 0x1b, y: 0x1b6a)
        let x = UInt16(d[1], d[0]) ^ UInt16(d[3], d[2]) | 0x63
        let y = UInt16(data[1], data[0]) ^ 0x63

        var key = [UInt8]()
        var initialKey = processCrypto(input: prepareVariables(id: id, x: x, y: y))

        for _ in 0 ..< 8 {
            key.append(UInt8(truncatingIfNeeded: initialKey[0]))
            key.append(UInt8(truncatingIfNeeded: initialKey[0] >> 8))
            key.append(UInt8(truncatingIfNeeded: initialKey[1]))
            key.append(UInt8(truncatingIfNeeded: initialKey[1] >> 8))
            key.append(UInt8(truncatingIfNeeded: initialKey[2]))
            key.append(UInt8(truncatingIfNeeded: initialKey[2] >> 8))
            key.append(UInt8(truncatingIfNeeded: initialKey[3]))
            key.append(UInt8(truncatingIfNeeded: initialKey[3] >> 8))
            initialKey = processCrypto(input: initialKey)
        }

        let result = data[2...].enumerated().map { i, value in
            value ^ key[i]
        }

        guard Crc.hasValidCrc16InLastTwoBytes(result) else {
            struct DecryptBLEError: Error, LocalizedError {
                let errorDescription = "BLE data decrytion failed"
            }
            throw DecryptBLEError()
        }

        return result
    }

    static func activateParameters(id: [UInt8]) -> Data {
        let d = usefulFunction(id: id, x: 0x1b, y: 0x1b6a)
        return Data([UInt8]([0x1b, d[0], d[1], d[2], d[3]]))
    }
}

private extension Libre2 {
    static let key: [UInt16] = [0xA0C5, 0x6860, 0x0000, 0x14C6]

    static func processCrypto(input: [UInt16]) -> [UInt16] {
        func op(_ value: UInt16) -> UInt16 {
            // We check for last 2 bits and do the xor with specific value if bit is 1
            var res = value >> 2 // Result does not include these last 2 bits
            if value & 1 != 0 { // If last bit is 1
                res = res ^ key[1]
            }

            if value & 2 != 0 { // If second last bit is 1
                res = res ^ key[0]
            }

            return res
        }

        let r0 = op(input[0]) ^ input[3]
        let r1 = op(r0) ^ input[2]
        let r2 = op(r1) ^ input[1]
        let r3 = op(r2) ^ input[0]
        let r4 = op(r3)
        let r5 = op(r4 ^ r0)
        let r6 = op(r5 ^ r1)
        let r7 = op(r6 ^ r2)

        let f1 = r0 ^ r4
        let f2 = r1 ^ r5
        let f3 = r2 ^ r6
        let f4 = r3 ^ r7

        return [f4, f3, f2, f1]
    }

    static func prepareVariables(id: [UInt8], x: UInt16, y: UInt16) -> [UInt16] {
        let s1 = UInt16(truncatingIfNeeded: UInt(UInt16(id[5], id[4])) + UInt(x) + UInt(y))
        let s2 = UInt16(truncatingIfNeeded: UInt(UInt16(id[3], id[2])) + UInt(key[2]))
        let s3 = UInt16(truncatingIfNeeded: UInt(UInt16(id[1], id[0])) + UInt(x) * 2)
        let s4 = 0x241a ^ key[3]

        return [s1, s2, s3, s4]
    }

    static func usefulFunction(id: [UInt8], x: UInt16, y: UInt16) -> [UInt8] {
        let blockKey = processCrypto(input: prepareVariables(id: id, x: x, y: y))
        let low = blockKey[0]
        let high = blockKey[1]



        let r1 = low ^ 0x4163
        let r2 = high ^ 0x4344
        return [
            UInt8(truncatingIfNeeded: r1),
            UInt8(truncatingIfNeeded: r1 >> 8),
            UInt8(truncatingIfNeeded: r2),
            UInt8(truncatingIfNeeded: r2 >> 8)
        ]
    }
}

extension UInt16 {
    init(_ byte0: UInt8, _ byte1: UInt8) {
        self = Data([byte1, byte0]).withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}

extension Libre2 {
    enum Example {
        static let sensorInfo: [UInt8] = [
            157,
            8,
            48,
            1,
            115,
            23
        ]

        static let sensorId: [UInt8] = [
            157,
            129,
            194,
            0,
            0,
            164,
            7,
            224
        ]

        static let buffer: [UInt8] = [
            6,
            154,
            221,
            121,
            142,
            154,
            244,
            186,
            162,
            85,
            79,
            49,
            234,
            224,
            71,
            58,
            189,
            121,
            123,
            39,
            28,
            162,
            134,
            248,
            95,
            4,
            28,
            203,
            27,
            82,
            76,
            119,
            82,
            98,
            189,
            183,
            147,
            151,
            32,
            13,
            73,
            158,
            214,
            167,
            143,
            2,
            182,
            22,
            69,
            188,
            73,
            219,
            7,
            159,
            179,
            169,
            237,
            79,
            32,
            189,
            37,
            211,
            32,
            166,
            191,
            150,
            171,
            60,
            143,
            143,
            1,
            105,
            89,
            197,
            98,
            250,
            1,
            201,
            21,
            56,
            64,
            191,
            58,
            17,
            198,
            108,
            72,
            106,
            144,
            253,
            19,
            111,
            235,
            187,
            245,
            208,
            239,
            60,
            145,
            1,
            107,
            94,
            238,
            199,
            157,
            93,
            243,
            5,
            4,
            154,
            25,
            129,
            131,
            75,
            16,
            240,
            210,
            118,
            172,
            14,
            80,
            49,
            33,
            11,
            81,
            11,
            238,
            220,
            78,
            85,
            82,
            245,
            4,
            63,
            129,
            254,
            214,
            233,
            225,
            147,
            58,
            153,
            20,
            247,
            10,
            38,
            149,
            35,
            14,
            59,
            168,
            224,
            162,
            141,
            9,
            72,
            201,
            90,
            56,
            131,
            150,
            89,
            126,
            2,
            96,
            38,
            140,
            78,
            151,
            196,
            57,
            55,
            37,
            20,
            249,
            199,
            168,
            59,
            41,
            217,
            240,
            67,
            199,
            93,
            164,
            121,
            206,
            100,
            214,
            126,
            40,
            231,
            68,
            4,
            76,
            202,
            131,
            154,
            98,
            80,
            227,
            237,
            144,
            53,
            125,
            133,
            14,
            174,
            196,
            90,
            78,
            238,
            163,
            199,
            249,
            74,
            75,
            56,
            127,
            61,
            98,
            180,
            153,
            51,
            85,
            68,
            234,
            204,
            117,
            158,
            245,
            185,
            40,
            186,
            227,
            50,
            105,
            231,
            155,
            160,
            66,
            178,
            124,
            162,
            70,
            119,
            102,
            161,
            234,
            105,
            252,
            200,
            195,
            202,
            246,
            18,
            71,
            189,
            150,
            123,
            105,
            106,
            105,
            223,
            116,
            160,
            142,
            101,
            28,
            151,
            42,
            204,
            49,
            44,
            111,
            245,
            161,
            66,
            178,
            26,
            99,
            110,
            136,
            140,
            135,
            167,
            171,
            160,
            221,
            115,
            9,
            230,
            105,
            66,
            20,
            195,
            172,
            206,
            215,
            226,
            107,
            250,
            224,
            241,
            6,
            219,
            139,
            251,
            189,
            106,
            161,
            124,
            98,
            78,
            186,
            236,
            200,
            55,
            21,
            68,
            171,
            57,
            8,
            27,
            221,
            118,
            206,
            94,
            226,
            155,
            82,
            143,
            44,
            186,
            173,
            86,
            248,
            222,
            158,
            97,
            241,
            156,
            253,
            254
        ]
    }

    enum Example2 {
        static let sensorInfo: [UInt8] = [0x9D, 0x08, 0x30, 0x01, 0x76, 0x25]

        static let sensorId: [UInt8] = [0xDF, 0x20, 0xBE, 0x00, 0x00, 0xA4, 0x07, 0xE0]

        static let buffer: [UInt8] = [
            0x52, 0x0B, 0xF3, 0x44, 0xDC, 0xA0, 0x43, 0x21,
            0xCC, 0x7D, 0xD7, 0x4E, 0x29, 0xE2, 0x82, 0xE3,
            0xE7, 0x04, 0xC9, 0xCF, 0x6C, 0x57, 0x2C, 0x7D,
            0xA8, 0x82, 0x10, 0xAA, 0xD7, 0x32, 0x19, 0xB3,
            0xC7, 0x9F, 0x39, 0x5F, 0xE3, 0x7A, 0x45, 0x08,
            0xB7, 0x09, 0xBC, 0x6E, 0xFA, 0xDA, 0x34, 0x07,
            0xB4, 0x65, 0x68, 0x60, 0x7E, 0xA5, 0x04, 0xE6,
            0x65, 0x65, 0x48, 0x13, 0xF8, 0x9C, 0xA7, 0xC8,
            0x70, 0xA7, 0x4D, 0x9D, 0x52, 0x35, 0x86, 0xF2,
            0x02, 0xCC, 0x9B, 0x9B, 0x74, 0x32, 0xFF, 0xC5,
            0xBF, 0xE9, 0x78, 0x1F, 0x46, 0xC2, 0xC7, 0x0B,
            0x0F, 0xB0, 0xC8, 0x54, 0x23, 0xE2, 0x0D, 0x44,
            0x97, 0x44, 0x36, 0x8F, 0xAC, 0x12, 0xAE, 0x4A,
            0x6C, 0xE1, 0x37, 0xE2, 0x46, 0x2B, 0x5C, 0x74,
            0x1B, 0x7A, 0xFE, 0x67, 0x4F, 0xCC, 0xDD, 0x95,
            0x17, 0x73, 0xB3, 0x25, 0xE9, 0xAB, 0xA6, 0x5E,
            0x70, 0xE4, 0x6C, 0xCE, 0x56, 0x8D, 0xB9, 0xE5,
            0xFE, 0xAA, 0x50, 0x36, 0x52, 0xD2, 0xC5, 0x22,
            0x24, 0x39, 0xD8, 0x63, 0x08, 0x62, 0x04, 0xAD,
            0xFA, 0x89, 0x00, 0x10, 0x72, 0xCF, 0xA9, 0xF3,
            0x47, 0x4B, 0xF5, 0x70, 0x96, 0xF2, 0x8A, 0xCA,
            0xFF, 0xEF, 0xA3, 0x9E, 0x1A, 0xEC, 0x9F, 0x4A,
            0x2F, 0xE8, 0xA9, 0xCA, 0xE6, 0xC8, 0x74, 0x46,
            0x98, 0xB2, 0xA2, 0x9E, 0x8D, 0xF0, 0xAF, 0x09,
            0xC1, 0x5B, 0x52, 0x59, 0x7E, 0x00, 0xD3, 0x3F,
            0x59, 0x41, 0x7B, 0x33, 0xEE, 0xDB, 0x40, 0x51,
            0xB2, 0x3D, 0x94, 0x82, 0xF3, 0xB2, 0xE4, 0xCA,
            0xAD, 0x3C, 0xD8, 0xC0, 0xD7, 0xD7, 0x4C, 0x51,
            0xCA, 0xA3, 0xAD, 0x26, 0x24, 0xAB, 0x10, 0xBA,
            0x61, 0x35, 0xE1, 0x7F, 0x3D, 0x3F, 0xEC, 0xB4,
            0xCF, 0xE3, 0xA2, 0x31, 0x6A, 0xE7, 0xD7, 0x36,
            0x18, 0x21, 0x5B, 0x43, 0x5A, 0x9C, 0x75, 0x7C,
            0x89, 0xE2, 0x49, 0x6C, 0xB1, 0x71, 0x6A, 0x47,
            0x6E, 0x8A, 0xE5, 0xB2, 0xC5, 0x37, 0xE9, 0xE5,
            0xDD, 0xB3, 0x12, 0x37, 0x95, 0x7A, 0xD0, 0x1F,
            0x73, 0xEB, 0xB8, 0x15, 0xF1, 0xE6, 0x5D, 0x51,
            0xFB, 0x16, 0x88, 0xA6, 0x9C, 0x17, 0xB0, 0x40,
            0x0E, 0xBB, 0xD7, 0xCA, 0x9D, 0xCD, 0x8B, 0x60,
            0x88, 0x88, 0x54, 0xFC, 0x65, 0x71, 0x43, 0xE7,
            0x51, 0xE2, 0x18, 0xEA, 0x63, 0x1D, 0x5B, 0xAA,
            0xD1, 0xD3, 0xD7, 0x08, 0xB7, 0xED, 0x87, 0xC4,
            0xB4, 0x24, 0x31, 0xE7, 0xA0, 0xE6, 0x59, 0x51,
            0x93, 0xFD, 0xA3, 0xE6, 0xBF, 0xE1, 0xF2, 0x09
        ]
    }

    enum BLEExample {
        static let sensorId: [UInt8] = [0x2f, 0xe7, 0xb1, 0x00, 0x00, 0xa4, 0x07, 0xe0]
        static let data: [UInt8] = [
            0xb1,
            0x94,
            0xfa,
            0xed,
            0x2c,
            0xde,
            0xa1,
            0x69,
            0x46,
            0x57,
            0xcf,
            0xd0,
            0xd8,
            0x5a,
            0xaa,
            0xf1,
            0xe2,
            0x89,
            0x1c,
            0xe9,
            0xac,
            0x82,
            0x16,
            0xfb,
            0x67,
            0xa1,
            0xd3,
            0xb6,
            0x3f,
            0x91,
            0xcd,
            0x18,
            0x4b,
            0x95,
            0x31,
            0x6c,
            0x04,
            0x5f,
            0xe1,
            0x96,
            0xc4,
            0xfd,
            0x14,
            0xfc,
            0x68,
            0xe0
        ]
    }
}
