a := new classAutoPath(A_WinDir, "w500")
while true {
	if a.ready || a.error
		break
	sleep 100
}

if a.error
	MsgBox("error")
if a.ready
	Run(a.path)