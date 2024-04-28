;~ MIT License

;~ Copyright (c) 2024 Michal Masek - masek@fortwana.sk

;~ Permission is hereby granted, free of charge, to any person obtaining a copy
;~ of this software and associated documentation files (the "Software"), to deal
;~ in the Software without restriction, including without limitation the rights
;~ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;~ copies of the Software, and to permit persons to whom the Software is
;~ furnished to do so, subject to the following conditions:

;~ The above copyright notice and this permission notice shall be included in all
;~ copies or substantial portions of the Software.

;~ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;~ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;~ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;~ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;~ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;~ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;~ SOFTWARE.



; Convert to exe after editing
; Place into C:\Program Files (x86)\CyberArk\PSM\Components\
; Add to applocker - generated exe and installed software
;    <Application Name="AutoIT-universal-web_PSM" Type="Exe" Path="C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.exe" Method="Hash" />
; Look for CHANGE_ME lines and edit accordingly
; Exe conversion command
; cd "C:\Program Files (x86)\AutoIt3\Aut2Exe"
; .\Aut2Exe.exe /in "C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.au3" /out "C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.exe" /x86
; AutoIt test mode - cd into test folder
; "c:\Program Files (x86)\AutoIt3\AutoIt3.exe" AutoIT-universal-web_PSM.au3 "c:\install\chrome-web-test\" /test

; Edit login process as needed
#include "PSMGenericClientWrapper.au3"
#include "Constants.au3"
#include "ScreenCapture.au3"
#include "WindowsConstants.au3"

; #FUNCTION# ====================================================================================================================
; Name...........: PSMGenericClient_GetSessionProperty
; Description ...: Fetches properties required for the session
; Parameters ....: None
; Return values .: None
; ===============================================================================================================================
Func FetchSessionProperties()
    ; Cyberark Username field
        if (PSMGenericClient_GetSessionProperty("Username", $TargetUsername) <> $PSM_ERROR_SUCCESS) Then
        Error(PSMGenericClient_PSMGetLastErrorString())
        EndIf

    ; Cyberark Password field
        if (PSMGenericClient_GetSessionProperty("Password", $TargetPassword) <> $PSM_ERROR_SUCCESS) Then
        Error(PSMGenericClient_PSMGetLastErrorString())
        EndIf

    ; Cyberark Address field
        if (PSMGenericClient_GetSessionProperty("Address", $TargetAddress) <> $PSM_ERROR_SUCCESS) Then
        Error(PSMGenericClient_PSMGetLastErrorString())
        EndIf

EndFunc

;=======================================
; Consts & Globals
;=======================================
Global $ConnectionClientPID = 0
Global $TargetUsername
Global $TargetPassword
Global $TargetAddress
Global Const $DISPATCHER_NAME = "Google Chrome" ; CHANGE_ME - change only if you are using different browser
Global Const $ConnectionComponent_NAME = "AutoIT-universal-web" ; CHANGE_ME - example = PVWA-web
Global Const $ERROR_MESSAGE_TITLE  = "PSM " & $DISPATCHER_NAME & " Dispatcher error message"
Global Const $LOG_MESSAGE_PREFIX = $DISPATCHER_NAME & " Dispatcher - "
Global Const $iScreenWidth = @DesktopWidth
Global Const $iScreenHeight = @DesktopHeight
; Timeout for application to turn on or for website to load
Global Const $AppTimeout = "30" ; CHANGE_ME
; Timeout for WinWait function
Global Const $WindowTimeout = "60" ; CHANGE_ME - not used in most use cases, but you may use it if needed, by default only $AppTimeout is used for turning on browser, loading website and login process
Global $WebPrefix = "https://" ; CHANGE_ME - everything before the address
Global $WebSuffix = "/PasswordVault/v10/" ; CHANGE_ME - everything after the address - this should point to login page
; Autologin
; If autologin is set to yes - the script will try to login automatically
; If autologin is set to no - the script end when login page is loaded successfully and user may interact with the page
; If you set autologin to no - some of the varables below are not important in your case, but they shoud have some value anyway to avoid unexpected errors
Global Const $AutoLogin = "yes" ; CHANGE_ME - yes or no
; Verification mode
; title = Use window titles to verify if login page was loaded and login was successful
; color = Use PixelSearch function to verify if login page was loaded and login was successful
; Option 1 is recommended if there is different title for login page and page after successful login
Global Const $VerificationMode = "color" ; CHANGE_ME
; Check window titles with AutoIt Window Info tool, 
Global Const $PAGE_LOADED_TITLE = "Password Vault" ; CHANGE_ME - title of the page where login form is
Global Const $LOGIN_SUCCESS_TITLE = "Accounts" ; CHANGE_ME - title of the page after successful login
; Check colors with AutoIt Window Info tool on your website
; PAGE_LOADED_COLOR can be found on login page - this is used for confirmation that page is loaded, so the login process can start
; LOGIN_SUCCESS_COLOR can be found on page after successful login and cannot be found on login page
Global Const $PAGE_LOADED_COLOR = "0x041939" ; CHANGE_ME
Global Const $LOGIN_SUCCESS_COLOR = "0xEAEEF7" ; CHANGE_ME
; Color mode error handling
; If $ColorErrorHandling is set to yes, the page is refreshed after tryied to login, to avoid exposing password in case of error
Global Const $ColorErrorHandling = "yes" ; CHANGE_ME - yes or no
; Based on the window title, change the WinWait function match mode
; Use option 3 if possible, as it is the most secure
; 1 = Title starts with the specified string
; 2 = Title contains the specified string
; 3 = Title must exactly match the specified string
Opt("WinTitleMatchMode", 2)
; Login process options
; How many times you have to press tab on login page to get to the username field
Global Const $Tabs_Before_Username = "0" ; CHANGE_ME
; How many times you have to press tab on login page to get to the password field after typing username
Global Const $Tabs_From_Username_To_Password = "1" ; CHANGE_ME
; How do you submit the login form
Global Const $Submit_Login = "{ENTER}" ; CHANGE_ME
; Google Chrome - Kiosk mode usage yes or no
Global Const $KioskMode = "yes" ; CHANGE_ME
; WARNING - --ignore-certificate-errors is not recommended for production use, delete this flag if not needed ; CHANGE_ME
if $KioskMode = "yes" Then
    Global $connect = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe --private --no-first-run --no-default-browser-check --ignore-certificate-errors --disable-translate --kiosk "
ElseIf $KioskMode = "no" Then
    Global $connect = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe --private --no-first-run --no-default-browser-check --ignore-certificate-errors --disable-translate "
EndIf

;=======================================
; Code
;=======================================
Exit Main()

;=======================================
; Main
;=======================================
Func Main()



;SplashTextOn($ConnectionComponent_NAME, $ConnectionComponent_NAME & " is starting, wait until autologin is completed...", $iScreenWidth, $iScreenHeight); Create a splash screen

; Init PSM Dispatcher utils wrapper
;ToolTip ("Initializing CyberArk session...")
if (PSMGenericClient_Init() <> $PSM_ERROR_SUCCESS) Then
Error(PSMGenericClient_PSMGetLastErrorString())
EndIf

LogWrite("INFO: Successfully initialized Dispatcher Utils Wrapper")
LogWrite("INFO: Variables set succesfully")
LogWrite("INFO: Verification mode is set to " & $VerificationMode & " mode")

; Get the dispatcher parameters
FetchSessionProperties()


; Phase 1 start - execute client application
LogWrite("INFO: starting client application - " & $DISPATCHER_NAME)
Global Const $CLIENT_EXECUTABLE = $connect & $WebPrefix & $TargetAddress & $WebSuffix
$ConnectionClientPID = Run($CLIENT_EXECUTABLE,  "", @SW_SHOWMAXIMIZED)
; StringReplace makes sure that password value is not logged in case you are using basic authentication sending password in URL
$logMessage = StringReplace($CLIENT_EXECUTABLE, $TargetPassword, "****") 
LogWrite("INFO: Executed " & $logMessage)

if ($ConnectionClientPID == 0) Then
Error(StringFormat("Failed to execute process [%s]", $connect, @error))
EndIf
; Phase 1 end

; Phase 2 start
If $VerificationMode = "title" Then
    LogWrite("INFO: Verification mode is set to title - using window titles to verify login success")
        ; Login process - START
        ; Window names
        $window1 = $PAGE_LOADED_TITLE
        $window2 = $LOGIN_SUCCESS_TITLE

        ; Logging
        LogWrite("INFO: Window1 is identified as " & $window1)
        LogWrite("INFO: Window2 is identified as " & $window2)
        LogWrite("INFO: Login process starting...")

        ; If AutoLogin is set to yes, proceed as normal
        If $AutoLogin = "yes" Then
            ;Wait for window no 1
            LogWrite("INFO: Waiting for window - " & $window1)
            WinWait($window1, "", $AppTimeout)
            $ActiveWindow = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Current window title is " & $ActiveWindow)
            ;If window is active, perform login process
            If WinExists($window1) Then
                    LogWrite("INFO: Window - " & $window1 & " found, web is loaded, performing autologin...")
                                $Window1RealTitle = WinGetTitle("[ACTIVE]")
                                ; Bring the window to the front
                                WinActivate($window1)
                                    LogWrite("INFO: Chrome real title is " & $Window1RealTitle)
                                    Sleep(3000)
                                    LogWrite("INFO: Trying login now")
                                ; Login process CHANGE_ME - mostly no change needed, only if login process is different than typing username, then password and pressing enter.
                                For $i = 1 To $Tabs_Before_Username
                                    Send("{TAB}")
                                    LogWrite("INFO: Sending tab to get to username field - pressed " & $Tabs_Before_Username & " times")
                                Next
                                    LogWrite("INFO: Sending username - " & $TargetUsername & " to username field")
                                    Send($TargetUsername,1)                        
                                    Sleep(500)
                                For $i = 1 To $Tabs_From_Username_To_Password
                                    Send("{TAB}")
                                    LogWrite("INFO: Sending tab to get to password field - pressed " & $Tabs_From_Username_To_Password & " times")
                                Next
                                Sleep(500)
                                    LogWrite("INFO: Sending password - defined in $TargetPassword variable to password field")
                                    Send($TargetPassword,1)
                                Sleep(500)
                                    LogWrite("INFO: Sending submit - " & $Submit_Login & " to submit login form")
                                    Send($Submit_Login)
                                    LogWrite("INFO: Login process finished, going to verify login success now")
            Else
                ; Log an error message if the window is not found
                $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
                $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
                $errorMsg &= $window1 & " Window Title did not show up in app timeout seconds value " 
                $errorMsg &= $AppTimeout & " session details: " 
                $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                $errorMsg &= "Phase 2 - title - step 1"
                LogWrite($errorMsg)
                ; Display an error message if the window is not found
                $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
                $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
                $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $window1 & " not found "
                $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                $errorMsg &= "Phase 2 - title - step 1"
                SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
                Sleep(30000)
                WinClose($ActiveWindow)
                Exit
            EndIf

            ;Wait for window no 2
            ;If window is active, login is considered successful
            LogWrite("INFO: Waiting for window - " & $window2)
            WinWait($window2, "", $AppTimeout)
            $ActiveWindow = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Current window title is " & $ActiveWindow)
            If WinExists($window2) Then
                    LogWrite("INFO: Window - " & $window2 & " found, web is loaded and also logged in...")
                    ; Bring the window to the front
                    LogWrite("INFO: " & $window2 & " was found, proceeding to login")
                            WinActivate($window2)
                            $Window2RealTitle = WinGetTitle("[ACTIVE]")
                            LogWrite("INFO: Chrome real title is " & $Window2RealTitle)
                            LogWrite("INFO: Login process finished, login success verified")
                            SplashOff(); Remove the splash screen
            Else
                ; Log an error message if the window is not found
                $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
                $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
                $errorMsg &= $window1 & " Window Title did not show up in app timeout seconds value " 
                $errorMsg &= $AppTimeout & " session details: " 
                $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                $errorMsg &= "Phase 2 - title - step 2"
                LogWrite($errorMsg)
                ; Display an error message if the window is not found
                $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
                $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
                $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $window2 & " not found "
                $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                $errorMsg &= "Phase 2 - title - step 2"
                SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
                Sleep(30000)
                WinClose($ActiveWindow)
                Exit
            EndIf
        ElseIf $AutoLogin = "no" Then
            ;Wait for window no 1
            LogWrite("INFO: Waiting for window - " & $window1)
            WinWait($window1, "", $AppTimeout)
            $ActiveWindow = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Current window title is " & $ActiveWindow)
            ;If window is active, perform login process
            If WinExists($window1) Then
                LogWrite("INFO: Window - " & $window1 & " found, web is loaded, skipping autologin based on $AutoLogin is set to no...")
                $Window1RealTitle = WinGetTitle("[ACTIVE]")
                ; Bring the window to the front
                WinActivate($window1)
                LogWrite("INFO: Chrome real title is " & $Window1RealTitle)
                LogWrite("INFO: Removing splashscreen, user may interact with webpage now ")
                SplashOff(); Remove the splash screen
            Else
                ; Log an error message if the window is not found
                $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
                $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
                $errorMsg &= $window1 & " Window Title did not show up in app timeout seconds value " 
                $errorMsg &= $AppTimeout & " session details: " 
                $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                $errorMsg &= "Phase 2 - title - step 1"
                LogWrite($errorMsg)
                ; Display an error message if the window is not found
                $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
                $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
                $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $window1 & " not found "
                $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                $errorMsg &= "Phase 2 - title - step 1"
                SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
                Sleep(30000)
                WinClose($ActiveWindow)
                Exit 
            EndIf
        EndIf
ElseIf $VerificationMode = "color" Then
    If $AutoLogin = "yes" Then
        ; Login process - START
        ; Window names
        ; Google chrome auth window - used just to verify if google chrome is running
        $window1 = "Google Chrome" ;CHANGE_ME - only if you are using different browser
        ; Logging
        LogWrite("INFO: Window1 is identified as " & $window1)
        LogWrite("INFO: Login process starting...")
        ;Wait for window no 1
        LogWrite("INFO: Waiting for " & $window1)
        WinWait($window1, "", $AppTimeout)
        $ActiveWindow = WinGetTitle("[ACTIVE]")
        LogWrite("INFO: Current window title is " & $ActiveWindow)
        ;If window is active, perform login process
        If WinExists($window1) Then
            LogWrite("INFO: Waiting until page loads - using PixelSearch and $PAGE_LOADED_COLOR - " & $PAGE_LOADED_COLOR)
            WinActivate($window1)
            $Window1RealTitle = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Chrome real title is " & $Window1RealTitle)
            SplashOff(); Remove the splash screen
            Local $startTime = TimerInit()
            While True
                $colorFound = PixelSearch(0, 0, @DesktopWidth, @DesktopHeight, $PAGE_LOADED_COLOR)
                If Not @error Then
                    ; Exit loop after specified color appears
                    LogWrite("INFO: Page loaded successfully - PixelSearch found specified color - " & $PAGE_LOADED_COLOR)
                    SplashTextOn($ConnectionComponent_NAME, $ConnectionComponent_NAME & " Page loaded successfully, proceeding to login...", $iScreenWidth, $iScreenHeight); Create a splash screen
                    ExitLoop
                EndIf
                If TimerDiff($startTime) > $AppTimeout * 1000 Then ; Convert timeout to milliseconds
                    ; Log an error message if the window is not found
                    $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
                    $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
                    $errorMsg &= $PAGE_LOADED_COLOR & " Color did not show up in app timeout seconds value " 
                    $errorMsg &= $AppTimeout & " session details: " 
                    $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                    $errorMsg &= " Phase 2 - color - step 1 - color loop"
                    LogWrite($errorMsg)
                    ; Display an error message if the window is not found
                    $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
                    $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
                    $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $PAGE_LOADED_COLOR & " color not found "
                    $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                    $errorMsg &= " Phase 2 - color - step 1 - color loop"
                    SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
                    Sleep(30000)
                    $ActiveWindow = WinGetTitle("[ACTIVE]")
                    LogWrite("INFO: Current window title is " & $ActiveWindow)
                    WinClose($ActiveWindow)
                    LogWrite("INFO: Closing active window - " & $ActiveWindow)
                    ExitLoop
                    Exit
                EndIf
                Sleep(1000) ; Wait for 1 second before checking again
            WEnd
                LogWrite("INFO: Login window " & $window1 & " found,  " & $ConnectionComponent_NAME & " component is loaded, performing autologin...")
                    ; Bring the window to the front
                    $Window1RealTitle = WinGetTitle("[ACTIVE]")
                    ; Bring the window to the front
                    WinActivate($window1)
                        LogWrite("INFO: Chrome real title is " & $Window1RealTitle)
                        Sleep(3000)
                        LogWrite("INFO: Trying login now")
                    ; Login process CHANGE_ME - mostly no change needed, only if login process is different than typing username, then password and pressing enter.
                    For $i = 1 To $Tabs_Before_Username
                        Send("{TAB}")
                        LogWrite("INFO: Sending tab to get to username field - pressed " & $Tabs_Before_Username & " times")
                    Next
                        LogWrite("INFO: Sending username - " & $TargetUsername & " to username field")
                        Send($TargetUsername,1)                        
                        Sleep(500)
                    For $i = 1 To $Tabs_From_Username_To_Password
                        Send("{TAB}")
                        LogWrite("INFO: Sending tab to get to password field - pressed " & $Tabs_From_Username_To_Password & " times")
                    Next
                    Sleep(500)
                        LogWrite("INFO: Sending password - defined in $TargetPassword variable to password field")
                        Send($TargetPassword,1)
                    Sleep(500)
                        LogWrite("INFO: Sending submit - " & $Submit_Login & " to submit login form")
                        Send($Submit_Login)
                        LogWrite("INFO: Login process finished, going to verify login success now")
        Else
            ; Log an error message if the window is not found
            $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
            $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
            $errorMsg &= $window1 & " Window Title did not show up in app timeout seconds value " 
            $errorMsg &= $AppTimeout & " session details: " 
            $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
            $errorMsg &= "Phase 2 - color - step 1 - color " & $PAGE_LOADED_COLOR " not found"
            LogWrite($errorMsg)
            ; Display an error message if the window is not found
            $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
            $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
            $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $window1 & " not found "
            $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
            $errorMsg &= "Phase 2 - color - step 1 - color " & $PAGE_LOADED_COLOR " not found"
            SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
            Sleep(30000)
            $ActiveWindow = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Current window title is " & $ActiveWindow)
            WinClose($ActiveWindow)
            LogWrite("INFO: Closing active window - " & $ActiveWindow)
            Exit
        EndIf

        WinWait($window1, "", $AppTimeout)
        ;If window is active, perform login process
        If WinExists($window1) Then
                LogWrite("INFO: Login window" & $window1 & " found, checking if login was successful")
                ; Bring the window to the front
                        WinActivate($window1)
                        LogWrite("INFO: Window " & $window1 & " is active, proceeding to check")
                        LogWrite("INFO: Waiting until logged in main page loads - using PixelSearch and $LOGIN_SUCCESS_COLOR - " & $LOGIN_SUCCESS_COLOR)
                        If $ColorErrorHandling = "yes" Then
                            LogWrite("INFO: ColorErrorHandling is set to yes, im refreshing page before veryfiyng login success")
                            ; Refresh page after tryied to login, to avoid exposing password in case of error
                            ; If the login process is not defined correctly, there is potential that password will be exposed in username field
                            ; Refreshing page will avoid this, however it may interfere with login process sometimes
                            Sleep(3000) ; This is precaution to do not expose password in case of error CHANGE_ME if the timeout is not good for you
                            send ("{F5}") ; This is precaution to do not expose password in case of error
                        EndIf
                        SplashOff(); Remove the splash screen
                        Local $startTime = TimerInit()
                            While True
                                $colorFound = PixelSearch(0, 0, @DesktopWidth, @DesktopHeight, $LOGIN_SUCCESS_COLOR)
                                If Not @error Then
                                    ; Exit loop after specified color appears
                                    LogWrite("INFO: Page loaded successfully - PixelSearch found specified color - " & $LOGIN_SUCCESS_COLOR)
                                    SplashOff(); Remove the splash screen
                                    ExitLoop
                                EndIf
                                If TimerDiff($startTime) > $AppTimeout * 1000 Then ; Convert timeout to milliseconds
                                    ; Log an error message if the window is not found
                                    $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
                                    $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
                                    $errorMsg &= $LOGIN_SUCCESS_COLOR & " Color did not show up in app timeout seconds value " 
                                    $errorMsg &= $AppTimeout & " session details: " 
                                    $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                                    $errorMsg &= "Phase 2 - color - step 2 - color loop"
                                    LogWrite($errorMsg)
                                    ; Display an error message if the window is not found
                                    $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
                                    $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
                                    $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $LOGIN_SUCCESS_COLOR & " color not found "
                                    $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                                    $errorMsg &= "Phase 2 - color - step 2 - color loop"
                                    SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
                                    Sleep(30000)
                                    $ActiveWindow = WinGetTitle("[ACTIVE]")
                                    LogWrite("INFO: Current window title is " & $ActiveWindow)
                                    WinClose($ActiveWindow)
                                    LogWrite("INFO: Closing active window - " & $ActiveWindow)
                                    ExitLoop
                                    Exit
                                EndIf
                                Sleep(1000) ; Wait for 1 second before checking again
                            WEnd
        Else
            ; Log an error message if the window is not found
            $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
            $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
            $errorMsg &= $window1 & " Window Title did not show up in app timeout seconds value " 
            $errorMsg &= $AppTimeout & " session details: " 
            $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
            $errorMsg &= "Phase 2 - color - step 2 - color - cannot found " & $window1 & " after tryied to login"
            LogWrite($errorMsg)
            ; Display an error message if the window is not found
            $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
            $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
            $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $window1 & " not found "
            $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
            $errorMsg &= "Phase 2 - color - step 2 - color - cannot found " & $window1 & " after tryied to login"
            SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
            Sleep(30000)
            $ActiveWindow = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Current window title is " & $ActiveWindow)
            WinClose($ActiveWindow)
            LogWrite("INFO: Closing active window - " & $ActiveWindow)
            Exit
        EndIf
    ElseIf $AutoLogin = "no" Then
        ; Window names
        ; Google chrome auth window - used just to verify if google chrome is running
        $window1 = "Google Chrome" ;CHANGE_ME - only if you are using different browser
        ; Logging
        LogWrite("INFO: Window1 is identified as " & $window1)
        LogWrite("INFO: Login process starting...")
        ;Wait for window no 1
        LogWrite("INFO: Waiting for " & $window1)
        WinWait($window1, "", $AppTimeout)
        $ActiveWindow = WinGetTitle("[ACTIVE]")
        LogWrite("INFO: Current window title is " & $ActiveWindow)
        ;If window is active, perform login process
        If WinExists($window1) Then
            LogWrite("INFO: Waiting until page loads - using PixelSearch and $PAGE_LOADED_COLOR - " & $PAGE_LOADED_COLOR)
            WinActivate($window1)
            $Window1RealTitle = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Chrome real title is " & $Window1RealTitle)
            SplashOff(); Remove the splash screen
            Local $startTime = TimerInit()
            While True
                $colorFound = PixelSearch(0, 0, @DesktopWidth, @DesktopHeight, $PAGE_LOADED_COLOR)
                If Not @error Then
                    ; Exit loop after specified color appears
                    LogWrite("INFO: Page loaded successfully - PixelSearch found specified color - " & $PAGE_LOADED_COLOR)
                    SplashTextOn($ConnectionComponent_NAME, $ConnectionComponent_NAME & " Page loaded successfully, proceeding to login...", $iScreenWidth, $iScreenHeight); Create a splash screen
                    ExitLoop
                EndIf
                If TimerDiff($startTime) > $AppTimeout * 1000 Then ; Convert timeout to milliseconds
                    ; Log an error message if the window is not found
                    $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
                    $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
                    $errorMsg &= $PAGE_LOADED_COLOR & " Color did not show up in app timeout seconds value " 
                    $errorMsg &= $AppTimeout & " session details: " 
                    $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                    $errorMsg &= " Phase 2 - color - step 1 - color loop"
                    LogWrite($errorMsg)
                    ; Display an error message if the window is not found
                    $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
                    $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
                    $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $PAGE_LOADED_COLOR & " color not found "
                    $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
                    $errorMsg &= " Phase 2 - color - step 1 - color loop"
                    SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
                    Sleep(30000)
                    $ActiveWindow = WinGetTitle("[ACTIVE]")
                    LogWrite("INFO: Current window title is " & $ActiveWindow)
                    WinClose($ActiveWindow)
                    LogWrite("INFO: Closing active window - " & $ActiveWindow)
                    ExitLoop
                    Exit
                EndIf
                Sleep(1000) ; Wait for 1 second before checking again
            WEnd
                LogWrite("INFO: Login window " & $window1 & " found,  " & $ConnectionComponent_NAME & " component is loaded, skipping autologin based on $AutoLogin is set to no...")
                    ; Bring the window to the front
                    $Window1RealTitle = WinGetTitle("[ACTIVE]")
                    ; Bring the window to the front
                    WinActivate($window1)
                    LogWrite("INFO: Chrome real title is " & $Window1RealTitle)
                    LogWrite("INFO: Removing splashscreen, user may interact with webpage now ")
                    SplashOff(); Remove the splash screen
        Else
            ; Log an error message if the window is not found
            $currentTime = @HOUR & ":" & @MIN & ":" & @SEC & " " & @MDAY & "/" & @MON & "/" & @YEAR
            $errorMsg = "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " 
            $errorMsg &= $window1 & " Window Title did not show up in app timeout seconds value " 
            $errorMsg &= $AppTimeout & " session details: " 
            $errorMsg &= $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
            $errorMsg &= "Phase 2 - color - step 1 - color " & $PAGE_LOADED_COLOR " not found"
            LogWrite($errorMsg)
            ; Display an error message if the window is not found
            $errorMsg = "Sorry, CyberArk could not start requested application. Contact CyberArk administrator/support. "
            $errorMsg &= "Please screenshot this error and attach as information for faster resolution. Thanks! "
            $errorMsg &= "ERROR: " & $DISPATCHER_NAME & " failed at automatic logon phase 2 " & $window1 & " not found "
            $errorMsg &= "session details: " & $ConnectionComponent_NAME & "/" & $TargetUsername & "/" & $TargetAddress & "/" & $currentTime
            $errorMsg &= "Phase 2 - color - step 1 - color " & $PAGE_LOADED_COLOR " not found"
            SplashTextOn("Error", $errorMsg, $iScreenWidth, $iScreenHeight)
            Sleep(30000)
            $ActiveWindow = WinGetTitle("[ACTIVE]")
            LogWrite("INFO: Current window title is " & $ActiveWindow)
            WinClose($ActiveWindow)
            LogWrite("INFO: Closing active window - " & $ActiveWindow)
            Exit
        EndIf
    EndIf
EndIf
; Phase 2 end

; Send PID to PSM as early as possible so recording/monitoring can begin
LogWrite("INFO: sending PID to PSM")
if (PSMGenericClient_SendPID($ConnectionClientPID) <> $PSM_ERROR_SUCCESS) Then
Error(PSMGenericClient_PSMGetLastErrorString())
EndIf
LogWrite("INFO: Connection component actions completed and PID was sent to PSM")

; Terminate PSM Dispatcher utils wrapper
LogWrite("INFO: Terminating Dispatcher Utils Wrapper")
LogWrite("INFO: COMPONENT ACTIONS - finished")
PSMGenericClient_Term()

Return $PSM_ERROR_SUCCESS
EndFunc

;==================================
; Functions
;==================================
; #FUNCTION# ====================================================================================================================
; Name...........: Error
; Description ...: An exception handler - displays an error message and terminates the dispatcher
; Parameters ....: $ErrorMessage - Error message to display
;   $Code - [Optional] Exit error code
; ===============================================================================================================================
Func Error($ErrorMessage, $Code = -1)

; If the dispatcher utils DLL was already initialized, write an error log message and terminate the wrapper
if (PSMGenericClient_IsInitialized()) Then
LogWrite($ErrorMessage, True)
PSMGenericClient_Term()
EndIf

Local $MessageFlags = BitOr(0, 16, 262144) ; 0=OK button, 16=Stop-sign icon, 262144=MsgBox has top-most attribute set

MsgBox($MessageFlags, $ERROR_MESSAGE_TITLE, $ErrorMessage)

; If the connection component was already invoked, terminate it
if ($ConnectionClientPID <> 0) Then
LogWrite("Terminating Dispatcher Utils Wrapper")
ProcessClose($ConnectionClientPID)
$ConnectionClientPID = 0
EndIf

Exit $Code
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: LogWrite
; Description ...: Write a PSMWinSCPDispatcher log message to standard PSM log file
; Parameters ....: $sMessage - [IN] The message to write
;         $LogLevel - [Optional] [IN] Defined if the message should be handled as an error message or as a trace messge
; Return values .: $PSM_ERROR_SUCCESS - Success, otherwise error - Use PSMGenericClient_PSMGetLastErrorString for details.
; ===============================================================================================================================
Func LogWrite($sMessage, $LogLevel = $LOG_LEVEL_TRACE)
Return PSMGenericClient_LogWrite($LOG_MESSAGE_PREFIX & $sMessage, $LogLevel)
EndFunc