#Requires AutoHotkey v1.1.35+
;==============================================================
; ImeKrLangCorrector — Korean IME mistype corrector (Hangul ⇄ alphanumeric)
;
; GitHub: https://github.com/SevenKeyboard/ime-kr-lang-corrector
; Author: SevenKeyboard Ltd. (2025)
; License: MIT License
;==============================================================

/*
Example Usage:
    msgbox % ImeKrLangCorrector.hangulToAlphanumeric("두히ㅑ노")
    msgbox % ImeKrLangCorrector.alphanumericToHangul("gksrnrdj")
    varC := "모든 인류 구성원의 천부의 존엄성과 동등하고 양도할 수 없는 권리를 인정하는 것이 세계의 자유 , 정의 및 평화의 기초이며 , 인권에 대한 무시와 경멸이 인류의 양심을 격분시키는 만행을 초래하였으며 , 인간이 언론과 신앙의 자유, 그리고 공포와 결핍으로부터의 자유를 누릴 수 있는 세계의 도래가 모든 사람들의 지고한 열망으로서 천명되어 왔으며 , 인간이 폭정과 억압에 대항하는 마지막 수단으로서 반란을 일으키도록 강요받지 않으려면 , 법에 의한 통치에 의하여 인권이 보호되어야 하는 것이 필수적이며 , 국가간에 우호관계의 발전을 증진하는 것이 필수적이며 , 국제연합의 모든 사람들은 그 헌장에서 기본적 인권, 인간의 존엄과 가치 , 그리고 남녀의 동등한 권리에 대한 신념을 재확인하였으며, 보다 폭넓은 자유속에서 사회적 진보와 보다 나은 생활수준을 증진하기로 다짐하였고, 회원국들은 국제연합과 협력하여 인권과 기본적 자유의 보편적 존중과 준수를 증진할 것을 스스로 서약하였으며 , 이러한 권리와 자유에 대한 공통의 이해가 이 서약의 완전한 이행을 위하여 가장 중요하므로 , 이에, 국제연합총회는, 모든 개인과 사회 각 기관이 이 선언을 항상 유념하면서 학습 및 교육을 통하여 이러한 권리와 자유에 대한 존중을 증진하기 위하여 노력하며 , 국내적 그리고 국제적인 점진적 조치를 통하여 회원국 국민들 자신과 그 관할 영토의 국민들 사이에서 이러한 권리와 자유가 보편적이고 효과적으로 인식되고 준수되도록 노력하도록 하기 위하여 , 모든 사람과 국가가 성취하여야 할 공통의 기준으로서 이 세계인권선언을 선포한다."
    varD := ImeKrLangCorrector.alphanumericToHangul(ImeKrLangCorrector.hangulToAlphanumeric(varC))
    msgbox % (varC==varD)
*/

class VersionManager_ImeKrLangCorrector
{
    static _ := VersionManager_ImeKrLangCorrector._init()
    _init()    {
        global
        IMEKRLANGCORRECTOR_VERSION := "1.0.0"
    }
}
class ImeKrLangCorrector
{
    hangulToAlphanumeric(byRef str, capslockState := false)    {
        return this.halfwidthHangulToHalfwidthAlphanumeric(str, capslockState)
    }
    halfwidthHangulToHalfwidthAlphanumeric(byRef str, capslockState := false)    { ;  "두히ㅑ노" => "english"
        outputAlnum := ""
        loop Parse, % str
        {
            switch
            {
                default:                                outputAlnum .= A_LoopField
                case (A_LoopField ~= "[ㄱ-ㅣ]"):        outputAlnum .= this._hangulJamoToRoman(ord(A_LoopField))
                case (A_LoopField ~= "[가-힣]"):        outputAlnum .= this._hangulWanseonghyeongToRoman(ord(A_LoopField))
            }
        }
        if (capslockState)    {
            result := ""
            loop Parse, % outputAlnum
                result .= A_LoopField ~= "[A-Z]" ? format("{:L}", A_LoopField) : A_LoopField ~= "[a-z]" ? format("{:U}", A_LoopField) : A_LoopField
            return result
        }
        return outputAlnum
    }
    alphanumericToHangul(byRef str, capslockState := false)    {
        return this.halfwidthAlphanumericToHalfwidthHangul(str, capslockState)
    }
    halfwidthAlphanumericToHalfwidthHangul(byRef str, capslockState := false)    { ;  "gksrnrdj" => "한국어"
        inputAlnum := str
        if (capslockState)    {
            temp := ""
            loop Parse, % inputAlnum
                temp .= A_LoopField ~= "[A-Z]" ? format("{:L}", A_LoopField) : A_LoopField ~= "[a-z]" ? format("{:U}", A_LoopField) : A_LoopField
            inputAlnum := temp
        }
        outputHangul := ""
        hangulJohab := ["", "", ""]
        loop Parse, % (inputAlnum .= A_Space) ;  마무리를 쉽게 구성하기 위해 (IME 조합 종료를 의미)
        {
            /*
            n == ( 초성 * 21 + 중성 ) * 28 + 종성 + 44032
            n == 12593 + 자모
            */
            loop    {
                if (hangulJohab[1] == "")    { ;  자음X
                    ;   [0. 자음X] =================================================
                    ;  첫 조합 시작
                    if (hangulJohab[2] == "")    {
                        if (A_LoopField ~= "[A-Za-z]")    {
                            switch (this._getJaeumMoeumType(A_LoopField))
                            {
                                case "자음":        hangulJohab[1] := A_LoopField
                                case "모음":
                                    if (A_LoopField == "h" || A_LoopField == "H"
                                    || A_LoopField == "n" || A_LoopField == "N"
                                    || A_LoopField == "m" || A_LoopField == "M")    { ;  ㅗ, ㅜ, ㅡ
                                        hangulJohab[2] := A_LoopField
                                    }  else  { ;  이중모음 조합 아님. 담지 않고 새로 시작
                                        outputHangul .= this._romanToHangulJamo(A_LoopField)
                                    }
                            }
                        }  else  {
                            outputHangul .= A_LoopField
                        }
                        continue 2
                    }
                    ;   [0. 특수. 자음X 모음O] ======================================
                    ;  ㅘ, ㅢ 같은 조합 확인
                    ;  ㅗ, ㅜ, ㅡ 이중모음 가능
                    notDiphthong := false ;  이중모음 아닐 때 담기는 변수
                    if (hangulJohab[2] == "h" || hangulJohab[2] == "H")    { ;  ㅗ
                        ;  ㅘ, ㅙ, ㅚ
                        if (A_LoopField == "k" || A_LoopField == "o" || A_LoopField == "l")
                            hangulJohab[2] .= A_LoopField
                        ;  Shift ㅘ, ㅚ
                        else if (A_LoopField == "K" || A_LoopField == "L")
                            hangulJohab[2] .= A_LoopField
                        else
                            notDiphthong := true
                    }  else if (hangulJohab[2] == "n" || hangulJohab[2] == "N")    { ;  ㅜ
                        ;  ㅝ, ㅞ, ㅟ
                        if (A_LoopField == "j" || A_LoopField == "p" || A_LoopField == "l")
                            hangulJohab[2] .= A_LoopField
                        ;  Shift ㅝ, ㅟ
                        else if (A_LoopField == "J" || A_LoopField == "L")
                            hangulJohab[2] .= A_LoopField
                        else
                            notDiphthong := true
                    }  else if (hangulJohab[2] == "m" || hangulJohab[2] == "M")    { ;  ㅡ
                        ;  ㅢ
                        if (A_LoopField == "l")
                            hangulJohab[2] .= A_LoopField
                        ;  Shift ㅢ
                        else if (A_LoopField == "L")
                            hangulJohab[2] .= A_LoopField
                        else
                            notDiphthong := true
                    }  else  {
                        notDiphthong := true
                    }
                    switch (notDiphthong)
                    {
                        case true: ;  ㅗㅒ 이중모음 아님
                            outputHangul .= this._romanToHangulJamo(hangulJohab[2]) ; (ㅗ)
                            hangulJohab[2] := ""
                            continue ;  다시 루프 (ㅒ)
                        default: ;  이중 모음
                            outputHangul .= this._romanToHangulJamo(hangulJohab[2])
                            hangulJohab[2] := ""
                            continue 2
                    }
                ;-----------------------------------------------------------------------
                ;   [1. 자음O] =====================================================
                }  else if (hangulJohab[1] !== "" && hangulJohab[2] == "")    {
                    if (A_LoopField ~= "[A-Za-z]")    {
                        ;  이전 자음이 단자음
                        if (strLen(hangulJohab[1]) !== 2)    {
                            ;  단자음O 자음O - 자음 연속
                            switch (this._getJaeumMoeumType(A_LoopField))
                            {
                                case "자음": ;  ㄳ, ㄵ 등 (글자조합은 안되지만 초성자음끼리만으로 조합될 수 있음)
                                    notDoubleConsonant := false ;  겹자음이 아닐 때 담기는 변수
                                    if (hangulJohab[1] == "r")    { ;  ㄳ
                                        if (A_LoopField == "t")
                                            hangulJohab[1] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else if (hangulJohab[1] == "s" || hangulJohab[1] == "S")    { ;  ㄵ / ㄶ
                                        if (A_LoopField == "w" || A_LoopField == "g" || A_LoopField == "G")
                                            hangulJohab[1] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else if (hangulJohab[1] == "f" || hangulJohab[1] == "F")    { ;  ㄺ / ㄻ / ㄼ / ㄽ / ㄾ/ ㄿ / ㅀ
                                        if (A_LoopField == "r" || A_LoopField == "a" || A_LoopField == "A" || A_LoopField == "q"
                                        || A_LoopField == "t" || A_LoopField == "x" || A_LoopField == "X"
                                        || A_LoopField == "v" || A_LoopField == "V" || A_LoopField == "g" || A_LoopField == "G")
                                            hangulJohab[1] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else if (hangulJohab[1] == "q")    { ;  ㅄ
                                        if (A_LoopField == "t")
                                            hangulJohab[1] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else  {
                                        notDoubleConsonant := true
                                    }
                                    switch (notDoubleConsonant)
                                    {
                                        case true: ;  ㄱ ㄲ ㅅ ㅆ 겹자음 아님
                                            outputHangul .= this._romanToHangulJamo(hangulJohab[1]) ;  (ㄱ)
                                            hangulJohab[1] := ""
                                            continue ;  다시 루프 (ㅁ)
                                        default: ;  ㄳ 겹자음 (앞서 [1]을 겹자음으로 바꾸고 끝 - 바로 아래 "이전 자음이 겹자음" 부분 참조)
                                            continue 2
                                    }
                                ;  단자음O 모음O
                                case "모음": ;  ㅅㅏ
                                    hangulJohab[2] := A_LoopField
                                    continue 2
                            }
                        ;  이전 자음이 겹자음
                        }  else  {
                            ;  겹자음 O 자음O
                            switch (this._getJaeumMoeumType(A_LoopField))
                            {
                                case "자음": ;  ㄳ ㄱ
                                    outputHangul .= this._romanToHangulJamo(hangulJohab[1]) ;  (ㄳ)
                                    hangulJohab[1] := ""
                                    continue ;  다시 루프 (ㄱ)
                                case "모음": ;  ㄳ ㅏ
                                    outputHangul .= this._romanToHangulJamo(subStr(hangulJohab[1], 1, 1)) ;  (ㄱ)
                                    hangulJohab[1] := subStr(hangulJohab[1], 2, 1) ;  (ㅅ)
                                    continue ;  다시 루프 (ㅅㅏ)  -  단자음O 모음O으로 
                            }
                        }
                    }  else  {
                        ;  조합 종료
                        outputHangul .= this._romanToHangulJamo(hangulJohab[1]) ;  뭐가 들어있던 간에...
                        hangulJohab[1] := ""
                        outputHangul .= A_LoopField
                        continue 2
                    }
                ;-----------------------------------------------------------------------
                ;   [2. 자음O 모음O] ================================================
                }  else if (hangulJohab[1] !== "" && hangulJohab[2] !== "" && hangulJohab[3] == "")    {
                    ;  ㅅ ㅗ
                    if (A_LoopField ~= "[A-Za-z]")    {
                        switch (this._getJaeumMoeumType(A_LoopField))
                        {
                            case "자음": ;  속 (일단 받침으로 감)
                                ;  일부 쌍받침은 받침으로 못감 ;  가ㄸ
                                if (A_LoopField=="W" || A_LoopField=="Q" || A_LoopField=="E")    {
                                    outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                        ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                        ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3]))) ;  (가)
                                    hangulJohab[1] := ""
                                    hangulJohab[2] := ""
                                    continue ;  다시 루프 (ㄸ)
                                }  else  {
                                    hangulJohab[3] := A_LoopField
                                    continue 2
                                }
                            case "모음": ;  ㅗ, ㅡ
                                if (strLen(hangulJohab[2]) !== 2)    { ;  이전 모음이 이중모음이 아님
                                    ;  ㅗ, ㅜ, ㅡ 이중모음 가능
                                    notDiphthong := false ;  이중모음 아닐 때 담기는 변수
                                    if (hangulJohab[2] == "h" || hangulJohab[2] == "H")    { ;  ㅗ
                                        ;  ㅘ, ㅙ, ㅚ
                                        if (A_LoopField == "k" || A_LoopField == "o" || A_LoopField == "l")
                                            hangulJohab[2] .= A_LoopField
                                        ;  Shift ㅘ, ㅚ
                                        else if (A_LoopField == "K" || A_LoopField == "L")
                                            hangulJohab[2] .= A_LoopField
                                        else
                                            notDiphthong := true
                                    }  else if (hangulJohab[2] == "n" || hangulJohab[2] == "N")    { ;  ㅜ
                                        ;  ㅝ, ㅞ, ㅟ
                                        if (A_LoopField == "j" || A_LoopField == "p" || A_LoopField == "l")
                                            hangulJohab[2] .= A_LoopField
                                        ;  Shift ㅝ, ㅟ
                                        else if (A_LoopField == "J" || A_LoopField == "L")
                                            hangulJohab[2] .= A_LoopField
                                        else
                                            notDiphthong := true
                                    }  else if (hangulJohab[2] == "m" || hangulJohab[2] == "M")    { ;  ㅡ
                                        ;  ㅢ
                                        if (A_LoopField == "l")
                                            hangulJohab[2] .= A_LoopField
                                        ;  Shift ㅢ
                                        else if (A_LoopField == "L")
                                            hangulJohab[2] .= A_LoopField
                                        else
                                            notDiphthong := true
                                    }  else  {
                                        notDiphthong := true
                                    }
                                    switch (notDiphthong)
                                    {
                                        case true: ;  ㅅㅗㅒ -> 소ㅒ 이중모음 아님
                                            outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                                ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                                ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3]))) ;  (소)
                                            hangulJohab[1] := ""
                                            hangulJohab[2] := ""
                                            continue ;  다시 루프 (ㅒ)
                                        default: ;  이중 모음 ;  쇄
                                            continue 2
                                    }
                                }  else  { ;  이전 모음이 이중모음 - 조합 종료 ;  쇄ㅕ
                                    outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                        ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                        ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3]))) ;  (쇄)
                                    hangulJohab[1] := ""
                                    hangulJohab[2] := ""
                                    continue ;  다시 루프 (ㅕ)
                                }
                        }
                    }  else  {
                        outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                            ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                            ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3])))
                        hangulJohab[1] := ""
                        hangulJohab[2] := ""
                        outputHangul .= A_LoopField
                        continue 2
                    }
                ;-----------------------------------------------------------------------
                ;   [3. 자음O 모음O 받침O] ==========================================
                ;  단 무조건 받침있는 글자로 가는 건 아님    각ㅏ -> 가가
                }  else if (hangulJohab[1] !== "" && hangulJohab[2] !== "" && hangulJohab[3] !== "")    {
                    if (A_LoopField ~= "[A-Za-z]")    {
                        switch (this._getJaeumMoeumType(A_LoopField))
                        {
                            case "자음":
                                ;  이전 자음이 단받침 ; 괄 +
                                if (strLen(hangulJohab[3]) !== 2)    {
                                    notDoubleConsonant := false ;  겹자음이 아닐 때 담기는 변수
                                    if (hangulJohab[3] == "r")    { ;  ㄳ
                                        if (A_LoopField == "t")
                                            hangulJohab[3] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else if (hangulJohab[3] == "s" || hangulJohab[3] == "S")    { ;  ㄵ / ㄶ
                                        if (A_LoopField == "w" || A_LoopField == "g" || A_LoopField == "G")
                                            hangulJohab[3] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else if (hangulJohab[3] == "f" || hangulJohab[3] == "F")    { ;  ㄺ / ㄻ / ㄼ / ㄽ / ㄾ/ ㄿ / ㅀ
                                        if (A_LoopField == "r" || A_LoopField == "a" || A_LoopField == "A"
                                        || A_LoopField == "q" || A_LoopField == "t" || A_LoopField == "x" || A_LoopField == "X"
                                        || A_LoopField == "v" || A_LoopField == "V" || A_LoopField == "g" || A_LoopField == "G")
                                            hangulJohab[3] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else if (hangulJohab[3] == "q")    { ;  ㅄ
                                        if (A_LoopField == "t")
                                            hangulJohab[3] .= A_LoopField
                                        else
                                            notDoubleConsonant := true
                                    }  else  {
                                        notDoubleConsonant := true
                                    }
                                    switch (notDoubleConsonant)
                                    {
                                        case true: ;  괄 + ㅋ           겹자음 아님 (조합 완료)
                                            outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                                ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                                ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3])))
                                            hangulJohab[1] := ""
                                            hangulJohab[2] := ""
                                            hangulJohab[3] := ""
                                            continue ;  다시 루프 (ㅁ)
                                        default: ;  괄 + ㅎ -> 괋       (괋 + ㅓ -> 괄허 가 될 수 있으므로 조합중)
                                            continue 2
                                    }
                                }  else  { ;  이전 자음이 겹받침 ;  괋 + ㅋ (조합 완료)
                                    outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                        ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                        ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3]))) ;  (괄)
                                    hangulJohab[1] := ""
                                    hangulJohab[2] := ""
                                    hangulJohab[3] := ""
                                    continue ;  다시 루프 (ㅋ)
                                }
                            case "모음":
                                ;  이전 받침이 단받침 ;  괄 + ㅓ (쌍받침 곾 + ㅓ 도 과꺼로 로 되므로 여기에 포함)
                                if (strLen(hangulJohab[3]) !== 2)    {
                                    jongseongToChoseong := ""
                                    jongseongToChoseong := hangulJohab[3]
                                    hangulJohab[3] := "" ;  과
                                    outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                        ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                        ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3])))
                                    hangulJohab[1] := ""
                                    hangulJohab[2] := ""
                                    hangulJohab[1] := jongseongToChoseong
                                    continue ;  다시 루프 (ㄹㅓ)
                                }  else  { ;  이전 받침이 겹받침 ;  괋 + ㅓ -> 괄허
                                    jongseongToChoseong := ""
                                    jongseongToChoseong := subStr(hangulJohab[3], 2, 1)
                                    hangulJohab[3] := subStr(hangulJohab[3], 1, 1) ;  괄
                                    outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                                        ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                                        ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3])))
                                    hangulJohab[1] := ""
                                    hangulJohab[2] := ""
                                    hangulJohab[3] := ""
                                    hangulJohab[1] := jongseongToChoseong
                                    continue ;  다시 루프 (ㅎㅓ)
                                }
                        }
                    }  else  {
                        outputHangul .= this._romanToHangulWanseonghyeong(this._getChoseongValue(this._romanToHangulJamo(hangulJohab[1]))
                            ,this._getJungseongValue(this._romanToHangulJamo(hangulJohab[2]))
                            ,this._getJongseongValue(this._romanToHangulJamo(hangulJohab[3])))
                        hangulJohab[1] := ""
                        hangulJohab[2] := ""
                        hangulJohab[3] := ""
                        outputHangul .= A_LoopField
                        continue 2
                    }
                }
            }
        }
        return subStr(outputHangul, 1, -1) ;  마지막에 논리 마무리를 쉽게 하기 위한 Space는 제거
    }
    _hangulJamoToRoman(n)   {
        /*
        12593   U+3131  (첫 자음 "ㄱ(0)" 유니코드)
        12622   U+314E  (마지막 자음 "ㅎ(29)" 유니코드)
        12623   U+314F  (첫 모음 "ㅏ(30)" 유니코드)
        12643   U+3163  (마지막 모음 "ㅣ(50)" 유니코드)
        자음 총 30개 / 모음 총 21개
        자모 총 51개
        */
        static jamo := ["r" ;  ㄱ
            ,"R"    ;  ㄲ
            ,"rt"   ;  ㄳ
            ,"s"    ;  ㄴ
            ,"sw"   ;  ㄵ
            ,"sg"   ;  ㄶ
            ,"e"    ;  ㄷ
            ,"E"    ;  ㄸ
            ,"f"    ;  ㄹ
            ,"fr"   ;  ㄺ
            ,"fa"   ;  ㄻ
            ,"fq"   ;  ㄼ
            ,"ft"   ;  ㄽ
            ,"fx"   ;  ㄾ
            ,"fv"   ;  ㄿ
            ,"fg"   ;  ㅀ
            ,"a"    ;  ㅁ
            ,"q"    ;  ㅂ
            ,"Q"    ;  ㅃ
            ,"qt"   ;  ㅄ
            ,"t"    ;  ㅅ
            ,"T"    ;  ㅆ
            ,"d"    ;  ㅇ
            ,"w"    ;  ㅈ
            ,"W"    ;  ㅉ
            ,"c"    ;  ㅊ
            ,"z"    ;  ㅋ
            ,"x"    ;  ㅌ
            ,"v"    ;  ㅍ
            ,"g"    ;  ㅎ
            ,"k"    ;  ㅏ
            ,"o"    ;  ㅐ
            ,"i"    ;  ㅑ
            ,"O"    ;  ㅒ
            ,"j"    ;  ㅓ
            ,"p"    ;  ㅔ
            ,"u"    ;  ㅕ
            ,"P"    ;  ㅖ
            ,"h"    ;  ㅗ
            ,"hk"   ;  ㅘ
            ,"ho"   ;  ㅙ
            ,"hl"   ;  ㅚ
            ,"y"    ;  ㅛ
            ,"n"    ;  ㅜ
            ,"nj"   ;  ㅝ
            ,"np"   ;  ㅞ
            ,"nl"   ;  ㅟ
            ,"b"    ;  ㅠ
            ,"m"    ;  ㅡ
            ,"ml"   ;  ㅢ
            ,"l"]   ;  ㅣ
        return jamo[n + 1- 12593]
    }
    _hangulWanseonghyeongToRoman(n)   {
        /*
        n == ( 초성 * 21 + 중성 ) * 28 + 종성 + 44032
        44032   U+AC00  (첫 글자 "가(0/0/0)" 유니코드)
        55203   U+D7A3  (마지막 글자 "힣(18/20/27)" 유니코드)
        완성형 총 11172개
        */
        static cho := ["r" ;  ㄱ
            ,"R"    ;  ㄲ
            ,"s"    ;  ㄴ
            ,"e"    ;  ㄷ
            ,"E"    ;  ㄸ
            ,"f"    ;  ㄹ
            ,"a"    ;  ㅁ
            ,"q"    ;  ㅂ
            ,"Q"    ;  ㅃ
            ,"t"    ;  ㅅ
            ,"T"    ;  ㅆ
            ,"d"    ;  ㅇ
            ,"w"    ;  ㅈ
            ,"W"    ;  ㅉ
            ,"c"    ;  ㅊ
            ,"z"    ;  ㅋ
            ,"x"    ;  ㅌ
            ,"v"    ;  ㅍ
            ,"g"]   ;  ㅎ
            ,jung := ["k" ;  ㅏ
            ,"o"    ;  ㅐ
            ,"i"    ;  ㅑ
            ,"O"    ;  ㅒ
            ,"j"    ;  ㅓ
            ,"p"    ;  ㅔ
            ,"u"    ;  ㅕ
            ,"P"    ;  ㅖ
            ,"h"    ;  ㅗ
            ,"hk"   ;  ㅘ
            ,"ho"   ;  ㅙ
            ,"hl"   ;  ㅚ
            ,"y"    ;  ㅛ
            ,"n"    ;  ㅜ
            ,"nj"   ;  ㅝ
            ,"np"   ;  ㅞ
            ,"nl"   ;  ㅟ
            ,"b"    ;  ㅠ
            ,"m"    ;  ㅡ
            ,"ml"   ;  ㅢ
            ,"l"]   ;  ㅣ
            ,jong := ["" ;  없음
            ,"r"    ;  ㄱ
            ,"R"    ;  ㄲ
            ,"rt"   ;  ㄳ
            ,"s"    ;  ㄴ
            ,"sw"   ;  ㄵ
            ,"sg"   ;  ㄶ
            ,"e"    ;  ㄷ
            ,"f"    ;  ㄹ
            ,"fr"   ;  ㄺ
            ,"fa"   ;  ㄻ
            ,"fq"   ;  ㄼ
            ,"ft"   ;  ㄽ
            ,"fx"   ;  ㄾ
            ,"fv"   ;  ㄿ
            ,"fg"   ;  ㅀ
            ,"a"    ;  ㅁ
            ,"q"    ;  ㅂ
            ,"qt"   ;  ㅄ
            ,"t"    ;  ㅅ
            ,"T"    ;  ㅆ
            ,"d"    ;  ㅇ
            ,"w"    ;  ㅈ
            ,"c"    ;  ㅊ
            ,"z"    ;  ㅋ
            ,"x"    ;  ㅌ
            ,"v"    ;  ㅍ
            ,"g"]   ;  ㅎ
        choseongJungseongJongseong := n - 44032
        ,choseong := choseongJungseongJongseong // 588
        ,jungseongJongseong := mod(choseongJungseongJongseong, 588)
        ,jungseong := jungseongJongseong // 28
        ,jongseong := mod(jungseongJongseong, 28)
        return cho[choseong + 1] jung[jungseong + 1] jong[jongseong + 1]
    }
    _getJaeumMoeumType(char)   {
        static jaeums := {q:"", w:"", e:"", r:"", t:"", a:"", s:"", d:"", f:"", g:"", z:"", x:"", c:"", v:""}, moeums := {y:"", u:"", i:"", o:"", p:"", h:"", j:"", k:"", l:"", b:"", n:"", m:""}
        return jaeums.hasKey(char) ? "자음" : moeums.hasKey(char) ? "모음" : ""
    }
    _romanToHangulJamo(char)   {
        if (char == "")
            return ""
        else if (char == "r") ;  종성 기준 1
            return "ㄱ"
        else if (char == "R") ;  2
            return "ㄲ"
        else if (char == "rt") ;  3
            return "ㄳ"
        else if (char == "s" || char == "S") ;  4
            return "ㄴ"
        else if (char == "sw" || char == "Sw") ;  5
            return "ㄵ"
        else if (char == "sg" || char == "Sg" || char == "sG" || char == "SG") ;  6
            return "ㄶ"
        else if (char == "e") ;  7
            return "ㄷ"
        else if (char == "E") ;  초성 3
            return "ㄸ"
        else if (char == "f" || char == "F") ;  8
            return "ㄹ"
        else if (char == "fr" || char == "Fr") ;  9
            return "ㄺ"
        else if (char == "fa" || char == "Fa" || char == "fA" || char == "FA") ;  10
            return "ㄻ"
        else if (char == "fq" || char == "Fq") ;  11
            return "ㄼ"
        else if (char == "ft" || char == "Ft") ;  12
            return "ㄽ"
        else if (char == "fx" || char == "Fx" || char == "fX" || char == "FX") ;  13
            return "ㄾ"
        else if (char == "fv" || char == "Fv" || char == "fV" || char == "FV") ;  14
            return "ㄿ"
        else if (char == "fg" || char == "Fg" || char == "fG" || char == "FG") ;  15
            return "ㅀ"
        else if (char == "a" || char == "A") ;  16
            return "ㅁ"
        else if (char == "q") ;  17
            return "ㅂ"
        else if (char == "Q") ;  초성 8
            return "ㅃ"
        else if (char == "qt") ;  18
            return "ㅄ"
        else if (char == "t") ;  19
            return "ㅅ"
        else if (char == "T") ;  20
            return "ㅆ"
        else if (char == "d" || char == "D") ;  21
            return "ㅇ"
        else if (char == "w") ;  22
            return "ㅈ"
        else if (char == "W") ;  초성 13
            return "ㅉ"
        else if (char == "c" || char == "C") ;  23
            return "ㅊ"
        else if (char == "z" || char == "Z") ;  24
            return "ㅋ"
        else if (char == "x" || char == "X") ;  25
            return "ㅌ"
        else if (char == "v" || char == "V") ;  26
            return "ㅍ"
        else if (char == "g" || char == "G") ;  27
            return "ㅎ"
        ;-----------------------------
        else if (char == "k" || char == "K") ;  중성 기준 0
            return "ㅏ"
        else if (char == "o") ;  1
            return "ㅐ"
        else if (char == "i" || char == "I") ;  2
            return "ㅑ"
        else if (char == "O") ;  3
            return "ㅒ"
        else if (char == "j" || char == "J") ;  4
            return "ㅓ"
        else if (char == "p") ;  5
            return "ㅔ"
        else if (char == "u" || char == "U") ;  6
            return "ㅕ"
        else if (char == "P") ;  7
            return "ㅖ"
        else if (char == "h" || char == "H") ;  8
            return "ㅗ"
        else if (char == "hk" || char == "Hk" || char == "hK" || char == "HK") ;  9
            return "ㅘ"
        else if (char == "ho" || char == "Ho") ;  10
            return "ㅙ"
        else if (char == "hl" || char == "Hl" || char == "hL" || char == "HL") ;  11
            return "ㅚ"
        else if (char == "y" || char == "Y") ;  12
            return "ㅛ"
        else if (char == "n" || char == "N") ;  13
            return "ㅜ"
        else if (char == "nj" || char == "Nj" || char == "nJ" || char == "NJ") ;  14
            return "ㅝ"
        else if (char == "np" || char == "Np") ;  15
            return "ㅞ"
        else if (char == "nl" || char == "Nl" || char == "nL" || char == "NL") ;  16
            return "ㅟ"
        else if (char == "b" || char == "B") ;  17
            return "ㅠ"
        else if (char == "m" || char == "M") ;  18
            return "ㅡ"
        else if (char == "ml" || char == "Ml" || char == "mL" || char == "ML") ;  19
            return "ㅢ"
        else if (char == "l" || char == "L") ;  20
            return "ㅣ"
        else
            return ""
    }
    /*
    	1	2	3	4	5	6	7	8	9	10	11	12	13	14	15	16	17	18	19	20	21	22	23	24	25	26	27	28	29	30
    		ㄱ	ㄲ	ㄳ	ㄴ	ㄵ	ㄶ	ㄷ	ㄸ	ㄹ	ㄺ	ㄻ	ㄼ	ㄽ	ㄾ	ㄿ	ㅀ	ㅁ	ㅂ	ㅃ	ㅄ	ㅅ	ㅆ	ㅇ	ㅈ	ㅉ	ㅊ	ㅋ	ㅌ	ㅍ	ㅎ
    초		1	2		3			4	5	6								7	8	9		10	11	12	13	14	15	16	17	18	19
    종	0	1	2	3	4	5	6	7		8	9	10	11	12	13	14	15	16	17		18	19	20	21	22		23	24	25	26	27
    */
    _getChoseongValue(choseong)   {
        if (choseong == "")
            return 0
        n := ord(choseong) - 12593 ;  초성에 겹받침 제외
        if (20 <= n) ;  ㅄ 제외
            --n
        if (16 <= n) ;  ㅀ 제외
            --n
        if (15 <= n) ;  ㄿ 제외
            --n
        if (14 <= n) ;  ㄾ 제외
            --n
        if (13 <= n) ;  ㄽ 제외
            --n
        if (12 <= n) ;  ㄼ 제외
            --n
        if (11 <= n) ;  ㄻ 제외
            --n
        if (10 <= n) ;  ㄺ 제외
            --n
        if (6 <= n) ;  ㄶ 제외
            --n
        if (5 <= n) ;  ㄵ 제외
            --n
        if (3 <= n) ;  ㄳ 제외
            --n
        return n
    }
    _getJungseongValue(jungseong)   {
        return jungseong == "" ? 0 : ord(jungseong) - 12593 - 30
    }
    _getJongseongValue(jongseong)   {
        if (jongseong == "")
            return 0
        n := ord(jongseong) - 12593 + 1 ;  종성에 일부 쌍자음 제외
        if (25 <= n) ;  ㅉ 제외
            --n
        if (19 <= n) ;  ㅃ 제외
            --n
        if (8 <= n) ;  ㄸ 제외
            --n
        return n
    }
    _romanToHangulWanseonghyeong(choseong, jungseong, jongseong)   {
        return chr((choseong * 21 + jungseong) * 28 + jongseong + 44032)
    }
}