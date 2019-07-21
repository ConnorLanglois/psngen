#include <GuiConstants.au3>
#include <IE.au3>
#include <String.au3>
#include <WinHttp.au3>

Global $iWidth = 600
Global $iHeight = 200
Global $hWndMain
Global $idButtonGenerateAccount
Global $idInputID
Global $idInputPassword

Global $sSessionCookie

_Main()

Func _Main()
	_Init()
	_Run()
EndFunc

Func _Init()
	HotKeySet('{END}', '_Exit')

	_InitGUI()
EndFunc

Func _InitGUI()
	$hWndMain = GuiCreate('PSNGen', $iWidth, $iHeight, Default, @DesktopHeight / 7)

	Local $idLabelID = GUICtrlCreateLabel('Sign-In ID: ', $iWidth / 2 - 225, 54)
		GUICtrlSetResizing($idLabelID, $GUI_DOCKALL)

	Local $idLabelPassword = GUICtrlCreateLabel('Password: ', $iWidth / 2 - 225, 84)
		GUICtrlSetResizing($idLabelPassword, $GUI_DOCKALL)

	$idInputID = GUICtrlCreateInput('', $iWidth / 2 - 150, 50, 300, Default, $ES_READONLY)
		GUICtrlSetResizing($idInputID, $GUI_DOCKALL)

	$idInputPassword = GUICtrlCreateInput('', $iWidth / 2 - 150, 80, 300, Default, $ES_READONLY)
		GUICtrlSetResizing($idInputPassword, $GUI_DOCKALL)

	$idButtonGenerateAccount = GuiCtrlCreateButton('Generate Account', $iWidth / 2 - 150, $iHeight - 60, 300, 50)
		GUICtrlSetResizing($GUI_DOCKBOTTOM, $GUI_DOCKAUTO)
EndFunc

Func _Run()
	GUISetState(@SW_SHOW, $hWndMain)

	While True
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				_Exit()

			Case $idButtonGenerateAccount
				GenerateAccount()
		EndSwitch
	WEnd
EndFunc

Func GenerateAccount()
	Local $hWinHttpOpen = _WinHttpOpen()
	Local $sEmail = Email_Init($hWinHttpOpen)

	Account_CreateAccount($hWinHttpOpen, $sEmail)
	Email_VerifyAccount($hWinHttpOpen)
	Account_AddPayment($hWinHttpOpen)

	_WinHttpCloseHandle($hWinHttpOpen)

	GUICtrlSetData($idInputID, $sEmail)
	GUICtrlSetData($idInputPassword, '')
EndFunc

Func Email_Init($hWinHttpOpen)
	Local $hWinHttpConn = _WinHttpConnect($hWinHttpOpen, 'http://10minutemail.com')
	Local $hWinHttpRequest = _WinHttpOpenRequest($hWinHttpConn)
	Local $hCallback = DllCallbackRegister('Email_GetSessionCookie', 'NONE', 'HANDLE;DWORD_PTR;DWORD;PTR;DWORD')
	Local $sResponse

	_WinHttpSetStatusCallback($hWinHttpRequest, $hCallback, $WINHTTP_CALLBACK_FLAG_REDIRECT)
	_WinHttpSendRequest($hWinHttpRequest)
	_WinHttpReceiveResponse($hWinHttpRequest)

	$sResponse = _WinHttpReadData($hWinHttpRequest, Default, 32768)

	_WinHttpCloseHandle($hWinHttpRequest)
	_WinHttpCloseHandle($hWinHttpConn)

	Return _StringBetween($sResponse, '<input type="text" value="', '" class="mail-address-address" id="mailAddress" readonly="readonly"/>')[0]
EndFunc

Func Email_VerifyAccount($hWinHttpOpen)
	Local $hWinHttpConn = _WinHttpConnect($hWinHttpOpen, 'http://10minutemail.com')
	Local $hWinHttpRequest = _WinHttpOpenRequest($hWinHttpConn, Default, '10MinuteMail/resources/messages/messagesAfter/0')
	Local $sResponse = '[]'
	Local $sURLVerify

	While $sResponse = '[]'
		Sleep(10000)

		_WinHttpSendRequest($hWinHttpRequest, 'Cookie: ' & $sSessionCookie)
		_WinHttpReceiveResponse($hWinHttpRequest)

		$sResponse = _WinHttpReadData($hWinHttpRequest)
	WEnd

	$sURLVerify = _StringBetween($sResponse, 'display: block;\"><a href=\"', '\" style=\"color: #ffffff; font-size:16px; font-family:Helvetica, sans-serif; font-size:18px; text-decoration: none; line-height:40px; width:100%; display:inline-block\">Verify Now </a>')[0]

	_WinHttpCloseHandle($hWinHttpRequest)
	_WinHttpCloseHandle($hWinHttpConn)

	$hWinHttpConn = _WinHttpConnect($hWinHttpOpen, 'https://account.sonyentertainmentnetwork.com')
	$sResponse = _WinHttpSimpleSSLRequest($hWinHttpConn, Default, _StringBetween($sURLVerify, 'https://account.sonyentertainmentnetwork.com', '')[0])
EndFunc

Func Email_GetSessionCookie($hInternet, $dwContext, $dwInternetStatus, $lpvStatusInformation, $dwStatusInformationLength)
	Local $aCookies = _StringBetween(_WinHttpQueryHeaders($hInternet, $WINHTTP_QUERY_SET_COOKIE), '', '; path=/10MinuteMail')

	If Not @error Then
		$sSessionCookie = $aCookies[0]
	EndIf
EndFunc

Func Account_CreateAccount($hWinHttpOpen, $sEmail)
	Local $oIE = _IECreateEmbedded()
	Local $idIE
	Local $oIFrame
	Local $hWinHttpConn = _WinHttpConnect($hWinHttpOpen, 'https://account.sonyentertainmentnetwork.com')
	Local $iMob = Random(1, 12, 1)
	Local $iDob = Random(1, 28, 1)
	Local $iYob = Random(1985, 1995, 1)
	Local $sDataEncoded
	Local $sResponse

	$iHeight = 800

	WinMove($hWndMain, '', Default, Default, $iWidth, $iHeight, 0)

	$idIE = GUICtrlCreateObj($oIE, 10, 110, $iWidth - 20, $iHeight - 130 - 110 - 10)

	_IENavigate($oIE, 'https://account.sonyentertainmentnetwork.com/liquid/reg/account/create-account!input.action')
	_IELoadWait($oIE)

	$oIFrame = $oIE.document.getElementsByName('undefined').Item(0)

	For $oObj In $oIE.document.getElementsByTagName('*')
		Local $oObjCurrent = $oIFrame

		For $i = 0 To 12
			If $oObj.isSameNode($oObjCurrent) Then
				ContinueLoop 2
			EndIf

			$oObjCurrent = $oObjCurrent.parentElement
		Next

		$oObj.setAttribute('style', 'display: none')
	Next

	While _IEGetObjById($oIE, 'g-recaptcha-response').value = ''
		Sleep(1000)
	WEnd

	$sData = 'account.loginName=' & $sEmail & '&account.mob=' & $iMob & '&account.dob=' & $iDob & '&account.yob=' & $iYob & '&account.country=US&account.address.province=HI&account.language=en&account.password=&confirmPassword=&captchaType=recaptcha&g-recaptcha-response=' & _IEGetObjById($oIE, 'g-recaptcha-response').value

	_WinHttpSimpleSSLRequest($hWinHttpConn, 'POST', 'liquid/reg/account/create-account.action', Default, $sData)
	_WinHttpCloseHandle($hWinHttpConn)

	GUICtrlDelete($idIE)

	$iHeight = 240

	WinMove($hWndMain, '', Default, Default, $iWidth, $iHeight, 0)
EndFunc

Func Account_AddPayment($hWinHttpOpen)

EndFunc

Func _Exit()
	Exit
EndFunc
