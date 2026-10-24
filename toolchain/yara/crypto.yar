/*
  EasyRE crypto-constant rules. Usage:
    yara -s /opt/easyre/tools/yara/crypto.yar <file>
  -s prints the offsets of each hit. Patterns are little-endian (x86/ARM LE),
  so they match both data tables and 32-bit immediates in code.
  A hit means "look here", not proof: confirm the primitive in the code.
*/

rule MD5_MD4_SHA1_InitState
{
    meta:
        description = "MD5 / MD4 / SHA-1 initial state 0x67452301 0xEFCDAB89 0x98BADCFE 0x10325476"
    strings:
        $a = { 01 23 45 67 }
        $b = { 89 AB CD EF }
        $c = { FE DC BA 98 }
        $d = { 76 54 32 10 }
    condition:
        3 of them
}

rule SHA1_Constants
{
    meta:
        description = "SHA-1: 5th init word 0xC3D2E1F0 and round constants 0x5A827999 0x6ED9EBA1 0x8F1BBCDC 0xCA62C1D6"
    strings:
        $h4 = { F0 E1 D2 C3 }
        $k1 = { 99 79 82 5A }
        $k2 = { A1 EB D9 6E }
        $k3 = { DC BC 1B 8F }
        $k4 = { D6 C1 62 CA }
    condition:
        3 of them
}

rule SHA256_Constants
{
    meta:
        description = "SHA-224/256: init 0x6A09E667 0xBB67AE85, round constants 0x428A2F98 0x71374491 0xB5C0FBCF 0xE9B5DBA5"
    strings:
        $h0 = { 67 E6 09 6A }
        $h1 = { 85 AE 67 BB }
        $k0 = { 98 2F 8A 42 }
        $k1 = { 91 44 37 71 }
        $k2 = { CF FB C0 B5 }
        $k3 = { A5 DB B5 E9 }
    condition:
        3 of them
}

rule TEA_XTEA_Delta
{
    meta:
        description = "TEA/XTEA/XXTEA delta 0x9E3779B9 (also golden-ratio hashing), -delta 0x61C88647, 32*delta 0xC6EF3720"
    strings:
        $delta = { B9 79 37 9E }
        $neg   = { 47 86 C8 61 }
        $sum32 = { 20 37 EF C6 }
    condition:
        any of them
}

rule AES_Tables
{
    meta:
        description = "AES forward S-box, inverse S-box, or T-table Te0"
    strings:
        $sbox = { 63 7C 77 7B F2 6B 6F C5 30 01 67 2B FE D7 AB 76 }
        $inv  = { 52 09 6A D5 30 36 A5 38 BF 40 A3 9E 81 F3 D7 FB }
        $te0  = { A5 63 63 C6 84 7C 7C F8 99 77 77 EE }
    condition:
        any of them
}

rule CRC32_Table_Or_Poly
{
    meta:
        description = "CRC-32 (reflected) polynomial 0xEDB88320 or the start of its 256-entry table"
    strings:
        $poly  = { 20 83 B8 ED }
        $table = { 00 00 00 00 96 30 07 77 2C 61 0E EE }
    condition:
        any of them
}

rule Blowfish_PArray
{
    meta:
        description = "Blowfish P-array (digits of pi) 0x243F6A88 0x85A308D3"
    strings:
        $p = { 88 6A 3F 24 D3 08 A3 85 }
    condition:
        $p
}

rule ChaCha_Salsa_Sigma
{
    meta:
        description = "ChaCha / Salsa20 constant 'expand 32-byte k' / 'expand 16-byte k'"
    strings:
        $k32 = "expand 32-byte k"
        $k16 = "expand 16-byte k"
    condition:
        any of them
}

rule Base64_Alphabet
{
    meta:
        description = "Base64 alphabet (standard or URL-safe); a custom alphabet means a custom base64"
    strings:
        $std = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" ascii wide
        $url = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_" ascii wide
    condition:
        any of them
}

rule FNV1_Hash
{
    meta:
        description = "FNV-1/FNV-1a 32-bit offset basis 0x811C9DC5 and prime 0x01000193"
    strings:
        $basis = { C5 9D 1C 81 }
        $prime = { 93 01 00 01 }
    condition:
        all of them
}
