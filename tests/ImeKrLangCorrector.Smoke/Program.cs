using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using SevenKeyboard;

internal static class Program
{
    // SHA-256 of ASCII hexadecimal UTF-16 outputs from original AHK 1.1.37.02,
    // baseline 5059dc87c370f17db88171392d146701c20b9ffb; both CapsLock states.
    private const string OracleDigest = "07CD118561F3BF242CC004CD3E3C64BD858848595B1E1281C8EBCDFECE2FC713";

    private static int Main(string[] args)
    {
        try
        {
            if (args.Length == 2 && args[0] == "--write-input")
            {
                using StreamWriter input = new(args[1], false, Encoding.ASCII);
                foreach (string value in Cases())
                    input.WriteLine(Hex(value));
                return 0;
            }
            Equal("english", ImeKrLangCorrector.HangulToAlphanumeric("두히ㅑ노"));
            Equal("한국어", ImeKrLangCorrector.AlphanumericToHangul("gksrnrdj"));
            Equal("가가", ImeKrLangCorrector.AlphanumericToHangul("rkrk"));
            Equal("각사", ImeKrLangCorrector.AlphanumericToHangul("rkrtk"));
            Equal("ㄱ사", ImeKrLangCorrector.AlphanumericToHangul("rtk"));
            Equal("ㅗㅒ", ImeKrLangCorrector.AlphanumericToHangul("hO"));
            Equal("ㅙ", ImeKrLangCorrector.AlphanumericToHangul("Ho"));
            Equal("가ㄸ", ImeKrLangCorrector.AlphanumericToHangul("rkE"));
            Equal("RKazé", ImeKrLangCorrector.HangulToAlphanumeric("가AZé", true));
            Equal("가", ImeKrLangCorrector.AlphanumericToHangul("RK", true));
            foreach (string value in new[] { "", " ", "  ", "123!?\r\n\t", "가ﾡＡé한😀" })
            {
                if (!value.Contains('한'))
                    Equal(value, ImeKrLangCorrector.AlphanumericToHangul(value));
            }
            Func<string, bool, string>[] methods = [
                ImeKrLangCorrector.HangulToAlphanumeric,
                ImeKrLangCorrector.AlphanumericToHangul,
                ImeKrLangCorrector.HalfwidthHangulToHalfwidthAlphanumeric,
                ImeKrLangCorrector.HalfwidthAlphanumericToHalfwidthHangul];
            foreach (var method in methods)
            {
                try { method(null!, false); throw new Exception("Null accepted"); }
                catch (ArgumentNullException) { }
            }
            StringBuilder transcript = new();
            int count = 0;
            foreach (string value in Cases())
            {
                foreach (bool caps in new[] { false, true })
                {
                    string roman = ImeKrLangCorrector.HangulToAlphanumeric(value, caps);
                    string hangul = ImeKrLangCorrector.AlphanumericToHangul(value, caps);
                    Equal(roman, ImeKrLangCorrector.HalfwidthHangulToHalfwidthAlphanumeric(value, caps));
                    Equal(hangul, ImeKrLangCorrector.HalfwidthAlphanumericToHalfwidthHangul(value, caps));
                    transcript.Append(Hex(roman)).Append('|').Append(Hex(hangul)).Append('\n');
                }
                count++;
            }
            string digest = Convert.ToHexString(SHA256.HashData(Encoding.ASCII.GetBytes(transcript.ToString())));
            Equal(OracleDigest, digest);
            Console.WriteLine($"PASS: fixtures, null contracts, aliases, {count} AHK oracle cases x 4 conversions; {RuntimeInformation.ProcessArchitecture}.");
            return 0;
        }
        catch (Exception error) { Console.Error.WriteLine(error); return 1; }
    }

    // Fixed xorshift32 keeps the corpus identical across runtimes and architectures.
    private static IEnumerable<string> Cases()
    {
        yield return "";
        yield return " ";
        yield return "  ";
        yield return "gksrnrdj 두히ㅑ노 AZazé가ﾡＡ😀\r\n\t";
        for (int code = 0xAC00; code <= 0xD7A3; code++)
            yield return ((char)code).ToString();
        for (int code = 0x3131; code <= 0x3163; code++)
            yield return ((char)code).ToString();
        const string letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        foreach (char first in letters)
            foreach (char second in letters)
                yield return $"{first}{second}";
        uint state = 0x51A7C0DE;
        uint Next() { state ^= state << 13; state ^= state >> 17; state ^= state << 5; return state; }
        const string alphabet = letters + " 0123!?\t\r\nㄱㄳㅙ가힣éᄀﾡＡ";
        for (int sample = 0; sample < 5000; sample++)
        {
            int length = (int)(Next() % 80);
            StringBuilder value = new();
            for (int i = 0; i < length; i++)
                value.Append(alphabet[(int)(Next() % (uint)alphabet.Length)]);
            yield return value.ToString();
        }
    }

    private static string Hex(string value)
    {
        StringBuilder result = new();
        foreach (char character in value)
            result.Append(((int)character).ToString("X4"));
        return result.ToString();
    }

    private static void Equal(string expected, string actual)
    {
        if (!string.Equals(expected, actual, StringComparison.Ordinal))
            throw new InvalidOperationException($"Expected {Hex(expected)}, actual {Hex(actual)}");
    }
}
