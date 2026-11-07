//==============================================================
// ImeKrLangCorrector — Korean IME mistype corrector (Hangul ⇄ alphanumeric)
//
// GitHub: https://github.com/SevenKeyboard/ime-kr-lang-corrector
// Author: SevenKeyboard Ltd. (2026)
// License: MIT License
//==============================================================

using System;
using System.Text;

namespace SevenKeyboard;

public static class ImeKrLangCorrector
{
    public static string HangulToAlphanumeric(string str, bool capslockState = false) =>
        HalfwidthHangulToHalfwidthAlphanumeric(str, capslockState);

    public static string HalfwidthHangulToHalfwidthAlphanumeric(string str, bool capslockState = false)
    {
        ArgumentNullException.ThrowIfNull(str);
        StringBuilder output = new();
        foreach (char character in str)
        {
            if (character is >= 'ㄱ' and <= 'ㅣ')
                output.Append(Jamo[character - 'ㄱ']);
            else if (character is >= '가' and <= '힣')
            {
                int value = character - '가';
                output.Append(Cho[value / 588]).Append(Jung[value % 588 / 28]).Append(Jong[value % 28]);
            }
            else
                output.Append(character);
        }
        return capslockState ? ToggleAsciiCase(output.ToString()) : output.ToString();
    }

    public static string AlphanumericToHangul(string str, bool capslockState = false) =>
        HalfwidthAlphanumericToHalfwidthHangul(str, capslockState);

    public static string HalfwidthAlphanumericToHalfwidthHangul(string str, bool capslockState = false)
    {
        ArgumentNullException.ThrowIfNull(str);
        string inputAlnum = capslockState ? ToggleAsciiCase(str) : str;
        StringBuilder outputHangul = new();
        string[] hangulJohab = ["", "", ""];
        bool notDiphthong, notDoubleConsonant;
        string jongseongToChoseong;
        // The original sentinel flushes composition; only its final output space is removed.
        foreach (char character in inputAlnum + " ")
        {
            string current = character.ToString();
            while (true)
            {
                if (hangulJohab[0] == "")
                {
                    if (hangulJohab[1] == "")
                    {
                        if (IsAsciiLetter(character))
                        {
                            switch (GetJaeumMoeumType(current))
                            {
                                case "자음":
                                    hangulJohab[0] = current;
                                    break;
                                case "모음":
                                    if (current == "h" || current == "H"
                                    || current == "n" || current == "N"
                                    || current == "m" || current == "M")
                                    {
                                        hangulJohab[1] = current;
                                    }
                                    else
                                    {
                                        outputHangul.Append(RomanToHangulJamo(current));
                                    }
                                    break;
                            }
                        }
                        else
                        {
                            outputHangul.Append(current);
                        }
                        goto NextCharacter;
                    }
                    notDiphthong = false;
                    if (hangulJohab[1] == "h" || hangulJohab[1] == "H")
                    {
                        if (current == "k" || current == "o" || current == "l")
                            hangulJohab[1] += current;
                        else if (current == "K" || current == "L")
                            hangulJohab[1] += current;
                        else
                            notDiphthong = true;
                    }
                    else if (hangulJohab[1] == "n" || hangulJohab[1] == "N")
                    {
                        if (current == "j" || current == "p" || current == "l")
                            hangulJohab[1] += current;
                        else if (current == "J" || current == "L")
                            hangulJohab[1] += current;
                        else
                            notDiphthong = true;
                    }
                    else if (hangulJohab[1] == "m" || hangulJohab[1] == "M")
                    {
                        if (current == "l")
                            hangulJohab[1] += current;
                        else if (current == "L")
                            hangulJohab[1] += current;
                        else
                            notDiphthong = true;
                    }
                    else
                    {
                        notDiphthong = true;
                    }
                    switch (notDiphthong)
                    {
                        case true:
                            outputHangul.Append(RomanToHangulJamo(hangulJohab[1]));
                            hangulJohab[1] = "";
                            continue;
                        default:
                            outputHangul.Append(RomanToHangulJamo(hangulJohab[1]));
                            hangulJohab[1] = "";
                            goto NextCharacter;
                    }
                }
                else if (hangulJohab[0] != "" && hangulJohab[1] == "")
                {
                    if (IsAsciiLetter(character))
                    {
                        if (hangulJohab[0].Length != 2)
                        {
                            switch (GetJaeumMoeumType(current))
                            {
                                case "자음":
                                    notDoubleConsonant = false;
                                    if (hangulJohab[0] == "r")
                                    {
                                        if (current == "t")
                                            hangulJohab[0] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else if (hangulJohab[0] == "s" || hangulJohab[0] == "S")
                                    {
                                        if (current == "w" || current == "g" || current == "G")
                                            hangulJohab[0] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else if (hangulJohab[0] == "f" || hangulJohab[0] == "F")
                                    {
                                        if (current == "r" || current == "a" || current == "A" || current == "q"
                                        || current == "t" || current == "x" || current == "X"
                                        || current == "v" || current == "V" || current == "g" || current == "G")
                                            hangulJohab[0] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else if (hangulJohab[0] == "q")
                                    {
                                        if (current == "t")
                                            hangulJohab[0] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else
                                    {
                                        notDoubleConsonant = true;
                                    }
                                    switch (notDoubleConsonant)
                                    {
                                        case true:
                                            outputHangul.Append(RomanToHangulJamo(hangulJohab[0]));
                                            hangulJohab[0] = "";
                                            continue;
                                        default:
                                            goto NextCharacter;
                                    }
                                case "모음":
                                    hangulJohab[1] = current;
                                    goto NextCharacter;
                            }
                        }
                        else
                        {
                            switch (GetJaeumMoeumType(current))
                            {
                                case "자음":
                                    outputHangul.Append(RomanToHangulJamo(hangulJohab[0]));
                                    hangulJohab[0] = "";
                                    continue;
                                case "모음":
                                    outputHangul.Append(RomanToHangulJamo(hangulJohab[0][0].ToString()));
                                    hangulJohab[0] = hangulJohab[0][1].ToString();
                                    continue;
                            }
                        }
                    }
                    else
                    {
                        outputHangul.Append(RomanToHangulJamo(hangulJohab[0]));
                        hangulJohab[0] = "";
                        outputHangul.Append(current);
                        goto NextCharacter;
                    }
                }
                else if (hangulJohab[0] != "" && hangulJohab[1] != "" && hangulJohab[2] == "")
                {
                    if (IsAsciiLetter(character))
                    {
                        switch (GetJaeumMoeumType(current))
                        {
                            case "자음":
                                if (current == "W" || current == "Q" || current == "E")
                                {
                                    outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                        , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                        , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                    hangulJohab[0] = "";
                                    hangulJohab[1] = "";
                                    continue;
                                }
                                else
                                {
                                    hangulJohab[2] = current;
                                    goto NextCharacter;
                                }
                            case "모음":
                                if (hangulJohab[1].Length != 2)
                                {
                                    notDiphthong = false;
                                    if (hangulJohab[1] == "h" || hangulJohab[1] == "H")
                                    {
                                        if (current == "k" || current == "o" || current == "l")
                                            hangulJohab[1] += current;
                                        else if (current == "K" || current == "L")
                                            hangulJohab[1] += current;
                                        else
                                            notDiphthong = true;
                                    }
                                    else if (hangulJohab[1] == "n" || hangulJohab[1] == "N")
                                    {
                                        if (current == "j" || current == "p" || current == "l")
                                            hangulJohab[1] += current;
                                        else if (current == "J" || current == "L")
                                            hangulJohab[1] += current;
                                        else
                                            notDiphthong = true;
                                    }
                                    else if (hangulJohab[1] == "m" || hangulJohab[1] == "M")
                                    {
                                        if (current == "l")
                                            hangulJohab[1] += current;
                                        else if (current == "L")
                                            hangulJohab[1] += current;
                                        else
                                            notDiphthong = true;
                                    }
                                    else
                                    {
                                        notDiphthong = true;
                                    }
                                    switch (notDiphthong)
                                    {
                                        case true:
                                            outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                                , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                                , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                            hangulJohab[0] = "";
                                            hangulJohab[1] = "";
                                            continue;
                                        default:
                                            goto NextCharacter;
                                    }
                                }
                                else
                                {
                                    outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                        , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                        , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                    hangulJohab[0] = "";
                                    hangulJohab[1] = "";
                                    continue;
                                }
                        }
                    }
                    else
                    {
                        outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                            , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                            , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                        hangulJohab[0] = "";
                        hangulJohab[1] = "";
                        outputHangul.Append(current);
                        goto NextCharacter;
                    }
                }
                else if (hangulJohab[0] != "" && hangulJohab[1] != "" && hangulJohab[2] != "")
                {
                    if (IsAsciiLetter(character))
                    {
                        switch (GetJaeumMoeumType(current))
                        {
                            case "자음":
                                if (hangulJohab[2].Length != 2)
                                {
                                    notDoubleConsonant = false;
                                    if (hangulJohab[2] == "r")
                                    {
                                        if (current == "t")
                                            hangulJohab[2] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else if (hangulJohab[2] == "s" || hangulJohab[2] == "S")
                                    {
                                        if (current == "w" || current == "g" || current == "G")
                                            hangulJohab[2] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else if (hangulJohab[2] == "f" || hangulJohab[2] == "F")
                                    {
                                        if (current == "r" || current == "a" || current == "A"
                                        || current == "q" || current == "t" || current == "x" || current == "X"
                                        || current == "v" || current == "V" || current == "g" || current == "G")
                                            hangulJohab[2] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else if (hangulJohab[2] == "q")
                                    {
                                        if (current == "t")
                                            hangulJohab[2] += current;
                                        else
                                            notDoubleConsonant = true;
                                    }
                                    else
                                    {
                                        notDoubleConsonant = true;
                                    }
                                    switch (notDoubleConsonant)
                                    {
                                        case true:
                                            outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                                , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                                , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                            hangulJohab[0] = "";
                                            hangulJohab[1] = "";
                                            hangulJohab[2] = "";
                                            continue;
                                        default:
                                            goto NextCharacter;
                                    }
                                }
                                else
                                {
                                    outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                        , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                        , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                    hangulJohab[0] = "";
                                    hangulJohab[1] = "";
                                    hangulJohab[2] = "";
                                    continue;
                                }
                            case "모음":
                                if (hangulJohab[2].Length != 2)
                                {
                                    jongseongToChoseong = "";
                                    jongseongToChoseong = hangulJohab[2];
                                    hangulJohab[2] = "";
                                    outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                        , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                        , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                    hangulJohab[0] = "";
                                    hangulJohab[1] = "";
                                    hangulJohab[0] = jongseongToChoseong;
                                    continue;
                                }
                                else
                                {
                                    jongseongToChoseong = "";
                                    jongseongToChoseong = hangulJohab[2][1].ToString();
                                    hangulJohab[2] = hangulJohab[2][0].ToString();
                                    outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                                        , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                                        , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                                    hangulJohab[0] = "";
                                    hangulJohab[1] = "";
                                    hangulJohab[2] = "";
                                    hangulJohab[0] = jongseongToChoseong;
                                    continue;
                                }
                        }
                    }
                    else
                    {
                        outputHangul.Append(RomanToHangulWanseonghyeong(GetChoseongValue(RomanToHangulJamo(hangulJohab[0]))
                            , GetJungseongValue(RomanToHangulJamo(hangulJohab[1]))
                            , GetJongseongValue(RomanToHangulJamo(hangulJohab[2]))));
                        hangulJohab[0] = "";
                        hangulJohab[1] = "";
                        hangulJohab[2] = "";
                        outputHangul.Append(current);
                        goto NextCharacter;
                    }
                }
            }
        NextCharacter:;
        }
        return outputHangul.ToString(0, outputHangul.Length - 1);
    }

    private static bool IsAsciiLetter(char value) => value is >= 'A' and <= 'Z' or >= 'a' and <= 'z';

    private static string ToggleAsciiCase(string value)
    {
        char[] result = value.ToCharArray();
        for (int i = 0; i < result.Length; i++)
            result[i] = result[i] is >= 'A' and <= 'Z' ? (char)(result[i] + 32)
                : result[i] is >= 'a' and <= 'z' ? (char)(result[i] - 32) : result[i];
        return new string(result);
    }

    private static string GetJaeumMoeumType(string character) =>
        "qwertasdfgzxcv".Contains(char.ToLowerInvariant(character[0])) ? "자음" : "모음";

    private static readonly string[] Jamo = ["r", "R", "rt", "s", "sw", "sg", "e", "E", "f", "fr", "fa", "fq", "ft", "fx", "fv", "fg", "a", "q", "Q", "qt", "t", "T", "d", "w", "W", "c", "z", "x", "v", "g", "k", "o", "i", "O", "j", "p", "u", "P", "h", "hk", "ho", "hl", "y", "n", "nj", "np", "nl", "b", "m", "ml", "l"];

    private static readonly string[] Cho = ["r", "R", "s", "e", "E", "f", "a", "q", "Q", "t", "T", "d", "w", "W", "c", "z", "x", "v", "g"];

    private static readonly string[] Jung = ["k", "o", "i", "O", "j", "p", "u", "P", "h", "hk", "ho", "hl", "y", "n", "nj", "np", "nl", "b", "m", "ml", "l"];

    private static readonly string[] Jong = ["", "r", "R", "rt", "s", "sw", "sg", "e", "f", "fr", "fa", "fq", "ft", "fx", "fv", "fg", "a", "q", "qt", "t", "T", "d", "w", "c", "z", "x", "v", "g"];

    private static string RomanToHangulJamo(string character) => character switch
    {
        "" => "",
        "r" => "ㄱ",
        "R" => "ㄲ",
        "rt" => "ㄳ",
        "s" or "S" => "ㄴ",
        "sw" or "Sw" => "ㄵ",
        "sg" or "Sg" or "sG" or "SG" => "ㄶ",
        "e" => "ㄷ",
        "E" => "ㄸ",
        "f" or "F" => "ㄹ",
        "fr" or "Fr" => "ㄺ",
        "fa" or "Fa" or "fA" or "FA" => "ㄻ",
        "fq" or "Fq" => "ㄼ",
        "ft" or "Ft" => "ㄽ",
        "fx" or "Fx" or "fX" or "FX" => "ㄾ",
        "fv" or "Fv" or "fV" or "FV" => "ㄿ",
        "fg" or "Fg" or "fG" or "FG" => "ㅀ",
        "a" or "A" => "ㅁ",
        "q" => "ㅂ",
        "Q" => "ㅃ",
        "qt" => "ㅄ",
        "t" => "ㅅ",
        "T" => "ㅆ",
        "d" or "D" => "ㅇ",
        "w" => "ㅈ",
        "W" => "ㅉ",
        "c" or "C" => "ㅊ",
        "z" or "Z" => "ㅋ",
        "x" or "X" => "ㅌ",
        "v" or "V" => "ㅍ",
        "g" or "G" => "ㅎ",
        "k" or "K" => "ㅏ",
        "o" => "ㅐ",
        "i" or "I" => "ㅑ",
        "O" => "ㅒ",
        "j" or "J" => "ㅓ",
        "p" => "ㅔ",
        "u" or "U" => "ㅕ",
        "P" => "ㅖ",
        "h" or "H" => "ㅗ",
        "hk" or "Hk" or "hK" or "HK" => "ㅘ",
        "ho" or "Ho" => "ㅙ",
        "hl" or "Hl" or "hL" or "HL" => "ㅚ",
        "y" or "Y" => "ㅛ",
        "n" or "N" => "ㅜ",
        "nj" or "Nj" or "nJ" or "NJ" => "ㅝ",
        "np" or "Np" => "ㅞ",
        "nl" or "Nl" or "nL" or "NL" => "ㅟ",
        "b" or "B" => "ㅠ",
        "m" or "M" => "ㅡ",
        "ml" or "Ml" or "mL" or "ML" => "ㅢ",
        "l" or "L" => "ㅣ",
        _ => ""
    };

    private static int GetChoseongValue(string choseong)
    {
        if (choseong == "")
            return 0;
        int n = choseong[0] - 12593;
        if (20 <= n)
            --n;
        if (16 <= n)
            --n;
        if (15 <= n)
            --n;
        if (14 <= n)
            --n;
        if (13 <= n)
            --n;
        if (12 <= n)
            --n;
        if (11 <= n)
            --n;
        if (10 <= n)
            --n;
        if (6 <= n)
            --n;
        if (5 <= n)
            --n;
        if (3 <= n)
            --n;
        return n;
    }

    private static int GetJongseongValue(string jongseong)
    {
        if (jongseong == "")
            return 0;
        int n = jongseong[0] - 12593 + 1;
        if (25 <= n)
            --n;
        if (19 <= n)
            --n;
        if (8 <= n)
            --n;
        return n;
    }

    private static int GetJungseongValue(string jungseong) => jungseong == "" ? 0 : jungseong[0] - 12593 - 30;

    private static string RomanToHangulWanseonghyeong(int choseong, int jungseong, int jongseong) =>
        ((char)((choseong * 21 + jungseong) * 28 + jongseong + 44032)).ToString();
}
