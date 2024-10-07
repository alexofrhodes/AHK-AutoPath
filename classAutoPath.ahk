; Found at https://www.autohotkey.com/boards/viewtopic.php?t=58404
; i adapted it to work with the current ahk version	~Alex
;  

#SingleInstance force

test()

test(){
	a := classAutoPath(msgbox)
	while true {
		if a.ready || a.error
			break
		sleep 500
	}

	if a.error
		MsgBox("error")
	if a.ready
		
		Run(a.path)
}

/**
 * 
 * @param {Func} onComplete 
 * @param {String} defaultPath 
 * @param {String} guiShowOpt 
 */
Class classAutoPath {
	path := ""
	ready := false
	error := false
	list := []
	listPrev := []
	endChar := "*"
	acceptedSuggestion := false

	__New(onComplete, defaultPath := "", guiShowOpt := "w600") {
		; Make sure provided path is valid
		if !DirExist(defaultPath)
			defaultPath := A_ScriptDir
		if SubStr(defaultPath, -1) != "\"			
			defaultPath .= "\"
		this.defaultPath := defaultPath
		this.onComplete := onComplete
		
		; GUI stuff
		this.gui := gui()
		this.editBox := this.gui.Add("Edit", "w600", this.defaultPath)
		this.editBox.OnEvent("Change", this.editChanged.bind(this))
		this.displayBox := this.gui.Add("Text", "+readonly -wrap r20 w600", "")
		this.btn := this.gui.Add("Button", "Default w0", "OK")
		this.btn.OnEvent("Click", this.enterKey.bind(this))

		this.gui.OnEvent("Close", this.onClose.bind(this))
		this.gui.OnEvent("Escape", this.onClose.bind(this))
		this.gui.Show(guiShowOpt)

		this.gui.GetClientPos(,,&Width)
		; this.editBox.Move(5,, Width - 10)
		; this.displayBox.Move(5,, Width - 10)
		
		ControlSend("{End}", "Edit1", "ahk_id " this.gui.hwnd) ; Go to end of line
		
		HotIfWinActive("ahk_id " this.gui.hwnd)
		HotKey("Tab", this.autoComplete.bind(this, 1))
		HotKey("+Tab", this.autoComplete.bind(this, -1))
		HotIfWinActive()

		; Initial display
		this.mode := "FD"
		this.findFile(this.editBox.Value)
		this.listPrev := this.list.Clone()	
	}
	
	; When we complete
	onSubmit(*) {
		this.path := this.editBox.Value
		this.ready := true
		this.cleanUp()
		this.gui.Destroy()
		this.onComplete.call(this.path)
	}
	
	; When we exit before a path/file is submitted by user
	onClose(*) {
		this.cleanUp()
		this.gui.Destroy()
		this.error := true
	}
	
	cleanUp(*) {		
		this.list := []
		this.listPrev := []
	}

	; When the content of editBox changes
	editChanged(*) {
		; Loop files mode to "D" = show folders only
		if InStr(this.editBox.Value, "<") {
			this.mode := "D"
			SendMessage(0xb1, StrLen(this.editBox.Value) - 1, -1, "Edit1", "ahk_id " this.gui.hwnd)
		}
		; Loop files mode to "F" = show files only
		else if InStr(this.editBox.Value, ">") {
			this.mode := "F"
			SendMessage(0xb1, StrLen(this.editBox.Value) - 1, -1, "Edit1", "ahk_id " this.gui.hwnd)
		}
		; Show both
		else
			this.mode := "FD"
		
		; Ending with " (double quote character)
		this.endChar := InStr(this.editBox.Value, '"') ? "" : "*"
		this.findFile(this.editBox.Value)
	}
	
	; User presses ENTER
	enterKey(*) {
		
		this.selectedText := EditGetSelectedText("Edit1", "ahk_id " this.gui.hwnd)
		; No selection => user is submitting folder/file path
		if this.selectedText == ""
			this.onSubmit()
		; User has accepted autocomplete suggestion
		else {
			this.editChanged()
			ControlSend("{End}", "Edit1", "ahk_id " this.gui.hwnd)
			this.acceptedSuggestion := true
		}
	}

	; Code for auto-completion
	autoComplete(direction,*) {
		static index := 1
		static prevPath := ""

		; Revert to defaultPath if editBox is empty
		if !Trim(this.editBox.Value, " `t`n`r") {
			this.editBox.Value := this.defaultPath
			this.findFile(this.editBox.Value)
			ControlSend("{End}", "Edit1", "ahk_id " this.gui.hwnd)
			return
		}
		
		; Check if user is still cycling through selections
		found := false
		for k, v in this.listPrev {
			if this.editBox.Value == v {
				index := k + 1 * direction
				if index > this.listPrev.Length
					index := 1
				else if index < 1
					index := this.listPrev.Length
				found := true
				break
			}	
		}
		
		; A folder change has occurred
		if this.acceptedSuggestion || !found {
			prevPath := this.editBox.Value
			this.listPrev := this.list.Clone()
			index := 1	
			this.acceptedSuggestion := false
		}
		
		; If folder appears to be empty
		if this.listPrev.Length > 0 {		
			this.editChanged()
			this.editBox.Value := this.listPrev[index]
			SendMessage(0xb1, StrLen(prevPath), -1, "Edit1", "ahk_id " this.gui.hwnd)
			this.selectedText := EditGetSelectedText("Edit1", "ahk_id " this.gui.hwnd)
			this.findFile(this.editBox.Value)
		}
	}

	; Loop through files and determine if they are files or folders
	findFile(p) {
		this.displayBox.Value := ""
		this.list := []

		Loop Files p this.endChar, this.mode {
			If A_Index > 20
				break
			path := A_LoopFileFullPath
			displayName := A_LoopFileName
			if InStr(FileExist(path), "D") {
				path .= "\"
				displayName := "[" . displayName . "]"
			}
			this.displayBox.Value .= (A_Index > 1 ? "`n" : "") . displayName 
			this.list.push(path)
		}
	}
}
