# ime-kr-lang-corrector

Korean IME mistype corrector (Hangul ⇄ alphanumeric), ported to C# for .NET 10 on Windows.

```csharp
using SevenKeyboard;

ImeKrLangCorrector.HangulToAlphanumeric("두히ㅑ노"); // "english"
ImeKrLangCorrector.AlphanumericToHangul("gksrnrdj"); // "한국어"
```

Reference `src/SevenKeyboard.ImeKrLangCorrector/SevenKeyboard.ImeKrLangCorrector.csproj`.
Both methods accept an optional `bool capslockState` (default `false`), which
reverses ASCII letter case. The original halfwidth aliases are also available.
Input is not mutated, trimmed, or normalized; unknown characters pass through.
Null arguments throw `ArgumentNullException`. Version 1.0.0 preserves the original
composition order and case behavior. Supports x64, x86, and NativeAOT.

```powershell
dotnet run --project tests/ImeKrLangCorrector.Smoke -c Release -p:UseAppHost=false
```

Smoke checks include independent examples and an original-AHK oracle digest over
all Hangul syllables, compatibility jamo, letter pairs, and seeded random sequences.
MIT License. Copyright (c) 2025 SevenKeyboard Ltd.
