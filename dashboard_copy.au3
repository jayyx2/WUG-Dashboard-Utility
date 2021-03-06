;Include AutoIT extensions
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <GUIComboBox.au3>
#include <GuiConstantsEx.au3>
#include <Constants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>

;Script start
LoginPrompt() ;Prompt for .txt with configuration information and/or prompt for servername, username, and password
GetWebUsers() ;Run SQL query to create web users array
GUIInitiate() ;Create and run the GUI
;Script End

Func GUIInitiate()
Global $Form1 = GUICreate("WhatsUp Gold Dashboard Utility", 575, 461, 192, 114)
;Create and populate source user combobox
Global $SourceUser = GUICtrlCreateCombo("", 170, 40, 257, 25, $CBS_DROPDOWNLIST + $CBS_AUTOHSCROLL + $WS_VSCROLL)
_GUICtrlComboBox_BeginUpdate($SourceUser)
For $i=0 To Ubound($WebUsersArray)-1
 If $WebUsersArray[$i][1] <> "guest" Then
  GUICtrlSetData($SourceUser, $WebUsersArray[$i][1])
 EndIf
Next
 GUICtrlSetData($SourceUser, "Default Dashboard")
 _GUICtrlComboBox_EndUpdate($SourceUser)
; _GUICtrlComboBox_SetCurSel($SourceUser, 0)
;Create dashboards section
Global $Dashboards = _GUICtrlListBox_Create($Form1, "", 16, 96, 257, 305, $LBS_EXTENDEDSEL + $LBS_DISABLENOSCROLL + $LBS_MULTIPLESEL + $WS_VSCROLL)
;Create destination users section
Global $DestinationUsers = _GUICtrlListBox_Create($Form1, "", 304, 96, 257, 305, $LBS_EXTENDEDSEL + $LBS_DISABLENOSCROLL + $LBS_MULTIPLESEL + $WS_VSCROLL)
;Create checkbox
Global $ReplaceExisting = GUICtrlCreateCheckbox("Replace Existing Dashboards?", 360, 408, 169, 17)
;Create labels
$SourceUserLabel = GUICtrlCreateLabel("Source User", 240, 20, 81, 17, $SS_CENTER)
$DashboardLabel = GUICtrlCreateLabel("Selected Users Dashboards", 84, 72, 161, 17)
$DestinationUsersLabel = GUICtrlCreateLabel("Destination User(s)", 384, 72, 93, 17)
;Create buttons
$BeginOperation = GUICtrlCreateButton("Copy dashboard(s) to user(s)", 352, 432, 177, 25)
$DeleteDashboardsButton = GUICtrlCreateButton("Delete selected dashboard(s)", 56, 432, 177, 25)
$RecreateDashboards = GUICtrlCreateButton("Recreate default dashboards", 56, 400, 177, 25)
GUISetState(@SW_SHOW, $Form1)
;Run the GUI until the dialog is closed
While 1
 $msg = GUIGetMsg()
 Switch $msg
  Case $GUI_EVENT_CLOSE
   ExitLoop
  Case $SourceUser
   Global $CurrentSourceUser = GUICtrlRead($SourceUser)
   GUICtrlSetOnEvent($SourceUser, DashboardUpdate())
   GUICtrlSetOnEvent($SourceUser, DestinationUserUpdate())
  Case $Dashboards
  Case $BeginOperation
   GUICtrlSetOnEvent($BeginOperation, HideGUI())
   GUICtrlSetOnEvent($BeginOperation, ReadTheValues())
  Case $DeleteDashboardsButton
   GUICtrlSetOnEvent($DeleteDashboardsButton, HideGUI())
   GUICtrlSetOnEvent($DeleteDashboardsButton, ReadDeleteValues())
  Case $RecreateDashboards
   GUICtrlSetOnEvent($RecreateDashboards, RecreateDefaultDash())
 EndSwitch
WEnd
EndFunc

Func HideGUI()
GUISetState(@SW_HIDE, $Form1)
EndFunc

Func ShowGUI()
Tooltip("")
GUISetState(@SW_SHOW, $Form1)
EndFunc

Func GetWebUsers()
$sSql1 = "Select nWebUserID, sUserName from ["&$databasename&"].[dbo].[WebUser] order by sUserName"
Global $WebUsersArray = RunSQLQuery($sSql1)
EndFunc

Func GetDashboards($SourceUser)
If $SourceUser = "Default Dashboard" Then
 $sSql1 = "Select nWorkspaceID, nWorkspaceType, sWorkspaceName FROM ["&$databasename&"].[dbo].[Workspace] WHERE nWebUserID IS NULL ORDER BY nWorkspaceType, sWorkspaceName"
Else
 $iIndex = _ArrayBinarySearch($WebUsersArray, $SourceUser, "", "", 1)
 $nWebUserID = $WebUsersArray[$iIndex][0]
 $sSql1 = "Select nWorkspaceID, nWorkspaceType, sWorkspaceName FROM ["&$databasename&"].[dbo].[Workspace] WHERE nWebUserID = "&$nWebUserID&" ORDER BY nWorkspaceType, sWorkspaceName"
EndIf
Global $DashboardArray = RunSQLQuery($sSql1)
EndFunc

Func RunSQLQuery($sQuery)
ConsoleWrite($sQuery & @CRLF)
$constrim="DRIVER={SQL Server};SERVER="&$servername&";DATABASE="&$databasename&";uid="&$sUsername&";pwd="&$sPassword&";"
$adCN = ObjCreate("ADODB.Connection")
$adCN.Open ($constrim)
$result = $adCN.Execute($sQuery)
If Not $result.EOF Then
 Return $result.GetRows()
EndIf
$adCN.Close
EndFunc

Func RunSQLCommand($sSql)
ConsoleWrite($sSql & @CRLF)
$constrim="DRIVER={SQL Server};SERVER="&$servername&";DATABASE="&$databasename&";uid="&$sUsername&";pwd="&$sPassword&";"
$adCN = ObjCreate("ADODB.Connection")
$adCN.Open ($constrim)
$result = $adCN.Execute($sSql)
$adCN.Close
EndFunc

Func DashboardUpdate()
GetDashboards($CurrentSourceUser)
_GUICtrlListBox_ResetContent($Dashboards)
_GUICtrlListBox_BeginUpdate($Dashboards)
For $i=0 To Ubound($DashboardArray)-1
  $sType = ""
  If $DashboardArray[$i][1] = 1 Then $sType = "Device Status"
  If $DashboardArray[$i][1] = 4 Then $sType = "Home"
  If $DashboardArray[$i][1] = 16 Then $sType = "Top 10"
 _GUICtrlListBox_AddString($Dashboards,$DashboardArray[$i][2] & " - " & $sType)
Next
 _GUICtrlListBox_EndUpdate($Dashboards)
EndFunc

Func DestinationUserUpdate()
If $CurrentSourceUser <> "Default Dashboard" Then
 $iIndex = _ArrayBinarySearch($WebUsersArray, $CurrentSourceUser, "", "", 1)
 $nWebUserID = $WebUsersArray[$iIndex][1]
EndIf
_GUICtrlListBox_ResetContent($DestinationUsers)
_GUICtrlListBox_BeginUpdate($DestinationUsers)
For $i=0 To Ubound($WebUsersArray)-1
 _GUICtrlListBox_AddString($DestinationUsers,$WebUsersArray[$i][1])
 _GUICtrlListBox_SetItemData($DestinationUsers, $i, $WebUsersArray[$i][0])
Next
_GUICtrlListBox_AddString($DestinationUsers, "Default Dashboard")
_GUICtrlListBox_SetItemData($DestinationUsers, Ubound($WebUsersArray)-1+1, "NULL")
If $CurrentSourceUser <> "Default Dashboard" Then
 $FindCurrSource = _GUICtrlListBox_FindString($DestinationUsers, $nWebUserID)
 _GUICtrlListBox_DeleteString($DestinationUsers, $FindCurrSource)
ElseIf $CurrentSourceUser = "Default Dashboard" Then 
 $FindCurrSource = _GUICtrlListBox_FindString($DestinationUsers, "Default Dashboard")
 _GUICtrlListBox_DeleteString($DestinationUsers, $FindCurrSource)
EndIf
$sGuest = _GUICtrlListBox_FindString($DestinationUsers, "guest")
_GUICtrlListBox_DeleteString($DestinationUsers, $sGuest)
_GUICtrlListBox_EndUpdate($DestinationUsers)
;EndIf
EndFunc

Func ReadDeleteValues()
Global $SourceUserID = ""
If $CurrentSourceUser <> "Default Dashboard" Then
 $iIndex = _ArrayBinarySearch($WebUsersArray, $CurrentSourceUser, "", "", 1)
 $SourceUserID = $WebUsersArray[$iIndex][0]
 $SourceUserName =  $WebUsersArray[$iIndex][1]
Else
 $SourceUserID = 0
 $SourceUserName = "Default Dashboard"
EndIf
Global $DashArray[0]
;Final Dashboards Selected
For $i=0 to UBound($DashArray)
 _ArrayDelete($DashArray, $i)
Next
$FinalDashboards = _GUICtrlListBox_GetSelItems($Dashboards)
For $i = 1 to UBound($FinalDashboards)-1
 $iIndex = $FinalDashboards[$i]
 _ArrayAdd($DashArray, $DashboardArray[$iIndex][0])
Next
;Error Check and Dashboard copy
If UBound($DashArray) = 0 Then
 MsgBox(0, "No Dashboard(s) selected!", "You need to select at least one dashboard.")
 ShowGUI()
Else
 $Confirm = MsgBox(4, "WhatsUp Dashboard Utility", "Are you sure you want to delete " & UBound($DashArray) & " dashboards from the login named " & $SourceUserName & "?")
 If $Confirm = 6 Then
  ;On Yes
  For $i = 0 To UBound($DashArray)-1
   Tooltip("Deleting dashboard " & $i & " of " & UBound($DashArray))
   DeleteDashboard($DashArray[$i])
  Next
  DashboardUpdate()
 ElseIf $Confirm = 7 Then
  ;On No
 EndIf
 ShowGUI()
EndIf
EndFunc

Func DeleteDashboard($nWorkspaceID)
 $existsArray = CheckForExistance($nWorkspaceID, $SourceUserID)
 $exists = $existsArray[0][0]
 If $exists = 1 And $SourceUserID <> 0 Then
   $sSql = "delete from workspace where (nWebUserID = "&$SourceUserID&" and sWorkspaceName = '"&$sWorkspaceName&"' and nWorkspaceType = " & $nWorkspaceType& ")"
   RunSQLCommand($sSql)
  Else
   $sSql = "delete from workspace where (nWebUserID IS NULL and sWorkspaceName = '"&$sWorkspaceName&"' and nWorkspaceType = " & $nWorkspaceType& ")"
   RunSQLCommand($sSql)
 EndIf
EndFunc

Func ReadTheValues()
Global $DestUserArray[0]
Global $DashArray[0]
$FinalSourceUser = _GUICtrlComboBox_GetCurSel($SourceUser)
;Final Destination Users
For $i=0 to UBound($DestUserArray)
 _ArrayDelete($DestUserArray, $i)
Next
$FinalDestinationUsersArray = _GUICtrlListBox_GetSelItems($DestinationUsers)
For $i = 1 to UBound($FinalDestinationUsersArray)-1
 $iIndex = $FinalDestinationUsersArray[$i]
 $UserID = _GUICtrlListBox_GetItemData($DestinationUsers, $iIndex)
 _ArrayAdd($DestUserArray, $UserID)
Next
;Final Dashboards Selected
For $i=0 to UBound($DashArray)
 _ArrayDelete($DashArray, $i)
Next
$FinalDashboards = _GUICtrlListBox_GetSelItems($Dashboards)
For $i = 1 to UBound($FinalDashboards)-1
 $iIndex = $FinalDashboards[$i]
 _ArrayAdd($DashArray, $DashboardArray[$iIndex][0])
Next
;Error Check and Dashboard copy
If UBound($DashArray) = 0 Then
 MsgBox(0, "No Dashboard(s) selected!", "You need to select at least one dashboard.")
 ShowGUI()
ElseIf UBound($DestUserArray) = 0 Then
 MsgBox(0, "No destination user(s) selected!", "You need to select at least one destination user.")
 ShowGUI()
Else
 For $i = 0 To UBound($DashArray)-1
  Tooltip("Copying dashboard " & $i & " of " & UBound($DashArray) & " to selected users.")
  CopyDashboard($DashArray[$i])
 Next
 ShowGUI()
EndIf
EndFunc

Func CopyDashboard($nWorkspaceID)
For $i = 0 To UBound($DestUserArray)-1
 $existsArray = CheckForExistance($nWorkspaceID, $DestUserArray[$i])
 $exists = $existsArray[0][0]
 If $exists = 0 And $DestUserArray[$i] <> "Default Dashboard" Then
  $sSql = "Insert into Workspace (sWorkspaceName, nWorkspaceType, nWebUserID, nLayoutMode, sXml, bDefaultWorkspace)(Select sWorkspaceName, nWorkspaceType, " & $DestUserArray[$i] & ", nLayoutMode, sXml, bDefaultWorkspace From Workspace where nWorkspaceID = " & $nWorkspaceID & ")"
  RunSQLCommand($sSql)
 ElseIf $exists = 0 And $DestUserArray[$i] = "Default Dashboard" Then
  $sSql = "Insert into Workspace (sWorkspaceName, nWorkspaceType, nWebUserID, nLayoutMode, sXml, bDefaultWorkspace)(Select sWorkspaceName, nWorkspaceType, NULL, nLayoutMode, sXml, bDefaultWorkspace From Workspace where nWorkspaceID = " & $nWorkspaceID & ")"
  RunSQLCommand($sSql)
 Else
  If $exists = 1 and GUICtrlRead($ReplaceExisting) = 1 Then
   If $DestUserArray[$i] = "Default Dashboard" Then
    $sSql = "delete from workspace where (nWebUserID IS NULL and sWorkspaceName = '"&$sWorkspaceName&"' and nWorkspaceType = " & $nWorkspaceType& ")"
    RunSQLCommand($sSql)
   Else
    $sSql = "delete from workspace where (nWebUserID = "&$DestUserArray[$i]&" and sWorkspaceName = '"&$sWorkspaceName&"' and nWorkspaceType = " & $nWorkspaceType& ")"
    RunSQLCommand($sSql)
   EndIf
   
   If $DestUserArray[$i] <> "Default Dashboard" Then
    $sSql = "Insert into Workspace (sWorkspaceName, nWorkspaceType, nWebUserID, nLayoutMode, sXml, bDefaultWorkspace)(Select sWorkspaceName, nWorkspaceType, " & $DestUserArray[$i] & ", nLayoutMode, sXml, bDefaultWorkspace From Workspace where nWorkspaceID = " & $nWorkspaceID & ")"
    RunSQLCommand($sSql)   
   ElseIf $DestUserArray[$i] = "Default Dashboard" Then
    $sSql = "Insert into Workspace (sWorkspaceName, nWorkspaceType, nWebUserID, nLayoutMode, sXml, bDefaultWorkspace)(Select sWorkspaceName, nWorkspaceType, NULL, nLayoutMode, sXml, bDefaultWorkspace From Workspace where nWorkspaceID = " & $nWorkspaceID & ")"
    RunSQLCommand($sSql)   
   EndIf
  Else
   ;Do nothing
  EndIf
 EndIf
Next
EndFunc

Func CheckForExistance($nWorkspaceID, $nWebUserID)
$sSql = "select sWorkspaceName, nWorkspaceType from workspace where nWorkspaceID = " &$nWorkspaceID
$sWorkspacenameArray = RunSQLQuery($sSql)
Global $sWorkspaceName = $sWorkspacenameArray[0][0]
Global $nWorkspaceType = $sWorkspacenameArray[0][1]
If $nWebUserID = "Default Dashboard" Then
 $sSql = "select count(*) from workspace where (nWebUserID IS NULL and sWorkspaceName = '"&$sWorkspaceName&"' and nWorkspaceType = " & $nWorkspaceType& ")"
Else
 $sSql = "select count(*) from workspace where (nWebUserID = "&$nWebUserID&" and sWorkspaceName = '"&$sWorkspaceName&"' and nWorkspaceType = " & $nWorkspaceType& ")"
EndIf
Return RunSQLQuery($sSql)
EndFunc

Func LoginPrompt()
Global $servername, $sUsername, $sPassword, $databasename
$hGUI = GUICreate("", 0, 0, 0, 0, Default, $WS_EX_TOPMOST) ;This is created to keep the input and message boxes on top of other windows
Local $wugdash
;Config file
Global $ofile = FileOpenDialog("Browse to and select the configuration file.", @WorkingDir, "Text files (*.txt)")
If $ofile <> "" Then
 $servername = FileReadLine($ofile, 1) ;First line of file for servername\instance
 $sUsername = FileReadLine($ofile, 2) ;SQL login
 $sPassword = FileReadLine($ofile, 3) ;Password of above SQL login
 $databasename = FileReadLine($ofile, 4) ;Database name
Else
 Exit 0
EndIf
While $servername = "" ;Loop until the URL has been filled in
 $servername = InputBox("WhatsUp Gold SQL Server\Instance?", "Please enter the FQDN or IP address of the WhatsUp Gold server and instance", "", "", "", "", Default, Default, "", $hGUI)
 If @Error <> 0 Then
  $wugdash = MsgBox(1, "Error", "Please enter the WhatsUp Gold database host name and instance and hit 'OK'. Hit 'OK' to try again or hit 'Cancel' to Exit")
  If $wugdash <> 1 Then
   Exit
  EndIf
EndIf
WEnd
;Username input
While $sUsername = "" ;Loop until the username has been filled in
 $sUsername = InputBox("User name?", "Please enter a SQL username with rights to the WhatsUp database", "", "", "", "", Default, Default, "", $hGUI)
If @Error <> 0 Then
 $wugdash = MsgBox(1, "Error", "Please enter the username and hit 'OK'. Hit 'OK' to try again or hit 'Cancel' to Exit")
 If $wugdash <> 1 Then
  Exit
 EndIf
EndIf
WEnd
;Password Input
While $sPassword = "" ;Loop until a password has been filled in
 $sPassword = InputBox("Password?", "Enter the password for the username entered in the previous input box", "", "*", "", "", Default, Default, "", $hGUI)
If @Error <> 0 Then
 Local $wugdash = MsgBox(1, "Error", "Please enter the password and hit 'OK'. Hit 'OK' to try again or hit 'Cancel' to Exit")
 If $wugdash <> 1 Then
  Exit
 EndIf
EndIf
WEnd
;Database input
While $databasename = "" ;Loop until the username has been filled in
 $databasename = InputBox("Database name?", "Please enter the name of the WhatsUp database", "WhatsUp", "", "", "", Default, Default, "", $hGUI)
If @Error <> 0 Then
 $wugdash = MsgBox(1, "Error", "Please enter the name of the database and hit 'OK'. Hit 'OK' to try again or hit 'Cancel' to Exit")
 If $wugdash <> 1 Then
  Exit
 EndIf
EndIf
WEnd
EndFunc

Func RecreateDefaultDash()
$sSql = FileRead(@ScriptDir & "\default_dashboards.txt")
HideGUI()
 $Confirm = MsgBox(4, "WhatsUp Dashboard Utility", "Are you sure you want to recreate all default dashboards?")
 If $Confirm = 6 Then
  ;On Yes
  RunSQLCommand($sSql)
  MsgBox(0, "Default Dashboards", "Default dashboards have been recreated if necessary.")
  DashboardUpdate()
 ElseIf $Confirm = 7 Then
  ;On No
 EndIf
ShowGUI()
EndFunc