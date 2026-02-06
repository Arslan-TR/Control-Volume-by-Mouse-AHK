#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetBatchLines -1
SetWinDelay, -1
SetMouseDelay, -1
SetKeyDelay, -1, -1
SetTitleMatchMode, 3
DetectHiddenWindows, On
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen

; icon settings / Simge Ayarı 
Menu, Tray, Icon, Shell32.dll, 195

; ---------------------------------------------------------
; BAŞLANGIÇ AYARLARI VE DEĞİŞKENLER
; ---------------------------------------------------------

; HotCorners (Sıcak Köşeler) Listesi
CornerList :=
(LTrim Join
	{
		"TopLeft":		"TopLeft",
		"TopRight":		"TopRight",
		"BottomRight":	"BottomRight",
		"BottomLeft":	"BottomLeft"
	}
)

; Sanal Masaüstü Değişkenleri
DesktopCount = 2
CurrentDesktop = 1
mapDesktopsFromRegistry() ; Başlangıçta masaüstlerini tara

; Timer'lar
SetTimer, HotCorners, 2
; Renk seçici tooltip timer'ı sadece ihtiyaç duyulduğunda açılacak, burada kapalı.

Return ; Auto-Execute Bölümü Bitişi

; ---------------------------------------------------------
; KISAYOLLAR (HOTKEYS)
; ---------------------------------------------------------

; --- Hafta Sayısını Göster (F1) ---
F1::
    yilin_basladigi_gun := 3
    FormatTime, currentDate,, dd.MM.yyyy
    FormatTime, CurrentDayOfYear,, YDay
    buguntarih := (CurrentDayOfYear) + yilin_basladigi_gun
    weekNum := Ceil(buguntarih / 7)
    
    ToolTip, Bugun %currentDate% ve %weekNum%. haftadasiniz.
    SetTimer, ToolTipKapat, -2000
return

ToolTipKapat:
    ToolTip
return

; --- Medya Kontrolleri ---
~F3::Suspend ; Scripti geçici olarak durdurur
F8:: Send {Media_Play_Pause}
F10:: Send {Volume_Down 2} ; Hızlı ses kısma (Klavye ile)
F11:: Send {Volume_Up 2}   ; Hızlı ses açma (Klavye ile)
F12:: Send {Volume_Mute}

; --- Sanal Masaüstü Geçişleri ---
LWin & 1::switchDesktopByNumber(1)
LWin & 2::switchDesktopByNumber(2)
LWin & 3::switchDesktopByNumber(3)

CapsLock & 1::switchDesktopByNumber(1)
CapsLock & 2::switchDesktopByNumber(2)
CapsLock & 3::switchDesktopByNumber(3)

; Alternatif Kısayollar
^!1::switchDesktopByNumber(1)
^!2::switchDesktopByNumber(2)
^!3::switchDesktopByNumber(3)
!1::switchDesktopByNumber(1)
!2::switchDesktopByNumber(2)
!3::switchDesktopByNumber(3)

; --- Görev Çubuğu Üzerinde Fare Tekerleği ile Ses Kontrolü ---
; (volume by mouse.ahk ve volume.ahk birleşimi)
#If MouseIsOver("ahk_class Shell_TrayWnd")
    WheelUp::Send {Volume_Up}      ; Standart artış
    WheelDown::Send {Volume_Down}  ; Standart azalış
    
    ; Eğer daha hızlı (2 birim) değişmesini isterseniz yukarıdaki satırları silip şunları kullanın:
    ; WheelUp::Send {Volume_Up 2}
    ; WheelDown::Send {Volume_Down 2}
    
    ; Orta tuş ile Mute (İsteğe bağlı, aktif etmek için noktalı virgülü kaldırın)
    ; MButton::Send {Volume_Mute}
#If

; --- Renk Seçici (Color Picker) ---
; Bu fonksiyon volume.ahk içindeki getColor mantığına dayanır.
; Aktif etmek için kısayol tanımlanmamış, örnek olarak Win+C eklenmiştir:
#c::getColor()

; ---------------------------------------------------------
; FONKSİYONLAR
; ---------------------------------------------------------

; --- Helper: Fare Belirli Bir Pencere Üzerinde mi? ---
MouseIsOver(WinTitle) {
    MouseGetPos,,, Win
    return WinExist(WinTitle . " ahk_id " . Win)
}

; --- Sanal Masaüstü Fonksiyonları ---
mapDesktopsFromRegistry() {
    global CurrentDesktop, DesktopCount
    IdLength := 32
    SessionId := getSessionId()
    if (SessionId) {
        RegRead, CurrentDesktopId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
        if (CurrentDesktopId)
            IdLength := StrLen(CurrentDesktopId)
    }
    
    RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
    if (DesktopList) {
        DesktopListLength := StrLen(DesktopList)
        DesktopCount := DesktopListLength / IdLength
    }
    else {
        DesktopCount := 1
    }
    
    i := 0
    while (CurrentDesktopId and i < DesktopCount) {
        StartPos := (i * IdLength) + 1
        DesktopIter := SubStr(DesktopList, StartPos, IdLength)
        if (DesktopIter = CurrentDesktopId) {
            CurrentDesktop := i + 1
            break
        }
        i++
    }
}

getSessionId() {
    ProcessId := DllCall("GetCurrentProcessId", "UInt")
    if ErrorLevel
        return
    DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
    if ErrorLevel
        return
    return SessionId
}

switchDesktopByNumber(targetDesktop) {
    global CurrentDesktop, DesktopCount
    mapDesktopsFromRegistry()
    
    if (targetDesktop > DesktopCount || targetDesktop < 1)
        return
        
    while(CurrentDesktop < targetDesktop) {
        Send ^#{Right}
        CurrentDesktop++
    }
    while(CurrentDesktop > targetDesktop) {
        Send ^#{Left}
        CurrentDesktop--
    }
}

createVirtualDesktop() {
    global CurrentDesktop, DesktopCount
    Send, #^d
    DesktopCount++
    CurrentDesktop = %DesktopCount%
}

deleteVirtualDesktop() {
    global CurrentDesktop, DesktopCount
    Send, #^{F4}
    DesktopCount--
    CurrentDesktop--
}

; --- Renk Seçici ve Tooltip (BTT) Fonksiyonları ---
getColor() {
    ; Animasyon ve renk alma döngüleri
    loop, 30 {
        MouseGetPos, xPos, yPos
        Angle:=(A_Index-1)*3
        gosub, GetStyles
        Text := "COLOR PICKED. "
        btt(Text,xPos + 10,yPos + 5,2,OwnStyle2)
        Sleep, 10
    }
    loop, 30 {
        MouseGetPos, xPos, yPos
        Angle:=(A_Index-1)*3
        gosub, GetStyles
        Text := "COLOR PICKED.. "
        btt(Text,xPos + 10,yPos + 5,2,OwnStyle2)
        Sleep, 10
    }
    loop, 30 {
        MouseGetPos, xPos, yPos
        Angle:=(A_Index-1)*3
        gosub, GetStyles
        Text := "COLOR PICKED..."
        btt(Text,xPos + 10,yPos + 5,2,OwnStyle2)
        Sleep, 10
    }
    
    ; Asıl rengi al ve panoya kopyala
    MouseGetPos, xPos, yPos
    PixelGetColor, pickedCol, xPos, yPos, RGB
    Clipboard := pickedCol
    
    loop, 50 {
        MouseGetPos, xPos, yPos
        Angle:=(A_Index-1)*3
        gosub, GetStyles
        Text := Clipboard
        btt(Text,xPos + 10,yPos + 5,2,OwnStyle2)
        Sleep, 10
    }
    
    ; Fade out
    for k, v in [240,220,200,180,160,140,120,100,80,60,40,20,0] {
        btt(Text,xPos + 10,yPos + 5,2,OwnStyle2,{Transparent:v})
        Sleep, 10
    }
    return

    GetStyles:
    OwnStyle2 := {Border:3
        , Rounded:30
        , Margin:30
        , BorderColorLinearGradientStart:0xffb7407c
        , BorderColorLinearGradientEnd:0xff3881a7
        , BorderColorLinearGradientAngle:Angle+45
        , BorderColorLinearGradientMode:6
        , TextColor:0xffd9d9db
        , BackgroundColor:0xff26293a}
    return
}

; --- BTT (Beautiful ToolTip) Kütüphanesi (Script içine gömülü) ---
btt(Text:="", X:="", Y:="", WhichToolTip:=1, Style:="", Options:="") {
    ; Not: BTT fonksiyonu oldukça uzundur ve görsel özelleştirme sağlar.
    ; Orijinal kodun yapısı korundu, ancak burada basitleştirilmiş standart ToolTip de kullanılabilir.
    ; Orijinal dosyadaki "btt" harici bir library çağrısı gibi görünüyor, 
    ; ancak fonksiyon tanımı eksikti. Eğer elinizde btt() fonksiyonunun tam tanımı yoksa, 
    ; yukarıdaki getColor() hata verebilir. 
    ; Güvenlik için standart ToolTip kullanan basit bir fallback ekliyorum:
    
    ToolTip, %Text%, %X%, %Y%, %WhichToolTip%
    return
}

; --- HotCorners (Sıcak Köşeler) Mantığı ---
HotCorners:
    For Each, Item in CornerList
        CheckCorner(Each, Item)
Return

TopLeft:
    ; Buraya sol üst köşe aksiyonu
Return
TopRight:
    ; Buraya sağ üst köşe aksiyonu
Return
BottomLeft:
    ; Buraya sol alt köşe aksiyonu
Return
BottomRight:
    ; Buraya sağ alt köşe aksiyonu
Return

IsCorner(CornerID) {
    Static T := 4, IsMouse := {} 
    MouseGetPos, MouseX, MouseY
    IsMouse.TopLeft     := (MouseY < T) && (MouseX < T)
    IsMouse.TopRight    := (MouseY < T) && (MouseX > (A_ScreenWidth - T))
    IsMouse.BottomLeft  := (MouseY > (A_ScreenHeight - T)) && (MouseX < T)
    IsMouse.BottomRight := (MouseY > (A_ScreenHeight - T)) && (MouseX > (A_ScreenWidth - T))
    Return, IsMouse[CornerID]
}

CheckCorner(Name, LabelOrFunc) {
    If (IsCorner(Name)) {
        SysGet, MonitorCount, MonitorCount
        If (MonitorCount = 1 ) {
            If (IsLabel(LabelOrFunc))
                GoSub, % LabelOrFunc
            Loop {
                If (!IsCorner(Name))
                    Break
            }
        }
    }
    Return
}
