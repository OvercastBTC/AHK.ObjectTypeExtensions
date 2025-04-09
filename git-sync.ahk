#Requires AutoHotkey v2.0+
; #Include <Includes\Basic>
#Include <Extensions/Gui>
; Git Repository Synchronization Tool
; This script automates the synchronization of multiple git repositories

; Define your repositories
class GitRepo {
	
	#Requires AutoHotkey v2.0+

	remote := ""
	local := ""
	branch := "master"  ; Default branch name
	
	__New(remoteRepo, localRepo, branchRepo := "master") {
		this.remote := remoteRepo
		this.local := localRepo
		this.branch := branchRepo
	}
}
; ^+#r::GitRepoGui
GitRepoGui
Class GitRepoGui {
	; GUI class to manage the Git repository synchronization tool
	__New() {
		; 	this.myGui := Gui("AlwaysOnTop", "Git Repository Manager")
		; 	this.myGui.SetFont("s10")
			
		; 	; Add title
		; 	this.myGui.AddText("w500 h30", "Git Repository Synchronization Tool")
		; 	this.myGui.AddText("w500 h2 0x10")  ; Horizontal Line
			
		; 	; Add ListView to display repository status
		; 	this.LV := this.myGui.AddListView("w800 h300", ["Repository", "Local Path", "Status", "Last Synced"])

		; Array of repositories to manage
		repos := [
			GitRepo("https://github.com/OvercastBTC/AHK.Standard.Lib", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib"),
			GitRepo("https://github.com/OvercastBTC/AHK.User.Lib", "C:\Users\bacona\Documents\AutoHotkey\Lib"),
			GitRepo("https://github.com/OvercastBTC/Personal", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Personal"),
			GitRepo("https://github.com/OvercastBTC/AHK.ObjectTypeExtensions", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib\Extensions"),
			GitRepo("https://github.com/OvercastBTC/AHK.Projects.v2", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2"),
			GitRepo("https://github.com/OvercastBTC/AHK.ExplorerClassicContextMenu", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2\AHK.ExplorerClassicContextMenu")
		]

		; Create GUI
		myGui := Gui("+AlwaysOnTop +Resize", "Git Repository Manager")
		; myGui.SetFont("s10")
		; myGui.DarkMode(GuiColors.mColors['forestgreen'])
		; myGui.BackColor := GuiColors.mColors['darkslategray']
		myGui.BackColor := GuiColors.github.githubdark
		myGui.SetFont('s10 Q5 c' GuiColors.github.githubgray, "Segoe UI")
		; Add title
		myGui.AddText("w500 h30", "Git Repository Synchronization Tool")
		textLine := myGui.AddText("w800 h2 0x10")  ; Horizontal Line

		; Add ListView to display repository status
		LV := myGui.AddListView("w800 h300", ["Repository", "Local Path", "Status", "Last Synced"])
		LV.SetFont("s10 Q5 c" GuiColors.github.githubdark, "Segoe UI")
		LV.GetPos(&lvX, &lvY, &lvW, &lvH)
		textLine.Move(,,lvW)
		; Populate ListView with repos
		for repo in repos {
			repoName := gitSplitPath(repo.remote).filename
			LV.Add(, repoName, repo.local, "Not checked", "Never")
		}

		; Add buttons
		buttonGroup := myGui.AddGroupBox("w800 h100 +Redraw", "Actions")
		bChkAllRpo := myGui.AddButton("xm+10 yp+30 w180 h40 +Redraw", "Check All Repositories").OnEvent("Click", CheckAllRepos)
		bPshLtoR := myGui.AddButton("x+20 w180 h40 +Redraw", "Push Local to Remote").OnEvent("Click", PushToRemote)
		bPshPfromR := myGui.AddButton("x+20 w180 h40 +Redraw", "Pull from Remote").OnEvent("Click", PullFromRemote)
		bPshIntRpo := myGui.AddButton("x+20 w180 h40 +Redraw", "Initialize Repositories").OnEvent("Click", InitRepos)

		; Add log window
		myGui.AddText("xm w800 h20", "Operation Log:")
		logEdit := myGui.AddEdit("xm w800 h200 ReadOnly -Wrap")

		; Show the GUI
		myGui.Show()

		myGui.OnEvent('Size', myGuiResize)
		myGuiResize(*) {
			myGui.GetPos(&x, &y, &w, &h)
			LV.Move(,, w - 45)
			textLine.Move(,, w - 45)
			buttonGroup.Move(,, w - 45)
			logEdit.Move(,, w - 45)
		}

		; Function to check all repositories
		CheckAllRepos(*) {
			LogMsg("Checking all repositories...")
			
			for i, repo in repos {
				repoName := gitSplitPath(repo.remote).filename
				LogMsg("Checking " . repoName . "...")
				
				; Check if directory exists
				if !DirExist(repo.local) {
					status := "Local directory missing"
					LV.Modify(i, , , , status)
					continue
				}
				
				; Check if it's a git repository
				if !DirExist(repo.local . "\.git") {
					status := "Not a Git repository"
					LV.Modify(i, , , status)
					continue
				}
				
				; Check repository status in more detail
				gitStatus := CheckGitRepoStatus(repo)
				LV.Modify(i, , , , gitStatus, FormatTime(,"yyyy-MM-dd HH:mm:ss"))
			}
			
			LogMsg("Repository check complete.")
		}

		; Function to check detailed Git repository status
		CheckGitRepoStatus(repo) {
			; Check if it has the correct remote
			remoteOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote -v")
			if !InStr(remoteOutput, repo.remote) {
				return "Wrong remote URL"
			}
			
			; Check if branch exists
			branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch")
			if !InStr(branchOutput, repo.branch) {
				return "Branch not found"
			}
			
			; Check for uncommitted changes
			statusOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git status --porcelain")
			if statusOutput {
				return "Uncommitted changes"
			}
			
			return "Repository ready"
		}

		; Function to push local to remote
		PushToRemote(*) {
			row := LV.GetNext(0)
			if !row {
				MsgBox("Please select a repository first.")
				return
			}
			
			repo := repos[row]
			repoName := gitSplitPath(repo.remote).filename
			
			LogMsg("Pushing " . repoName . " to remote...")
			
			try {
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git add . && git commit -m " "Auto-sync commit" " && git push --force-with-lease origin " . repo.branch)
				LogMsg(output)
				LV.Modify(row, , , , "Pushed to remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
			}
			catch as e {
				LogMsg("Error: " . e.Message)
			}
		}

		; Function to pull from remote
		PullFromRemote(*) {
			row := LV.GetNext(0)
			if !row {
				MsgBox("Please select a repository first.")
				return
			}
			
			repo := repos[row]
			repoName := gitSplitPath(repo.remote).filename
			
			LogMsg("Pulling " . repoName . " from remote...")
			
			try {
				; Backup untracked files first
				backupDir := A_Temp . "\git_backup_" . FormatTime(,"yyyyMMdd_HHmmss")
				DirCreate(backupDir)
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git ls-files --others --exclude-standard > " . backupDir . "\untracked_files.txt")
				
				; Fetch and reset to remote
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git reset --hard origin/" . repo.branch)
				LogMsg(output)
				LV.Modify(row, , , , "Pulled from remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
				
				; Inform about backup
				LogMsg("Untracked files list saved to: " . backupDir . "\untracked_files.txt")
			}
			catch as e {
				LogMsg("Error: " . e.Message)
			}
		}

		; Function to initialize repositories
		InitRepos(*) {
			row := LV.GetNext(0)
			if !row {
				MsgBox("Please select a repository first.")
				return
			}
			
			repo := repos[row]
			repoName := gitSplitPath(repo.remote).filename
			
			LogMsg("Initializing " . repoName . "...")
			
			try {
				; Create directory if it doesn't exist
				if !DirExist(repo.local) {
					DirCreate(repo.local)
					LogMsg("Created directory: " . repo.local)
				}
				
				; Enhanced check for existing Git repository
				if DirExist(repo.local . "\.git") {
					LogMsg("Found existing Git repository. Checking configuration...")
					
					; Check if the remote URL matches
					remoteOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote -v")
					
					if InStr(remoteOutput, repo.remote) {
						LogMsg("Remote URL already correctly configured.")
					} else {
						; Check if origin exists
						if InStr(remoteOutput, "origin") {
							output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote set-url origin " . repo.remote)
							LogMsg("Updated existing remote URL to: " . repo.remote)
						} else {
							output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote add origin " . repo.remote)
							LogMsg("Added remote 'origin' with URL: " . repo.remote)
						}
					}
					
					; Check if branch exists
					branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch")
					
					if !InStr(branchOutput, repo.branch) {
						LogMsg("Creating branch '" . repo.branch . "' tracking remote...")
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
						LogMsg(output)
					} else {
						; Make sure the branch is correctly tracking
						trackingOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -vv")
						
						if !InStr(trackingOutput, "origin/" . repo.branch) {
							LogMsg("Setting correct tracking for branch '" . repo.branch . "'...")
							output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch --set-upstream-to=origin/" . repo.branch . " " . repo.branch)
							LogMsg(output)
						} else {
							LogMsg("Branch '" . repo.branch . "' already correctly tracking remote.")
						}
					}
				} else {
					; Initialize a completely new repository
					LogMsg("No Git repository found. Initializing new repository...")
					output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git init && git remote add origin " . repo.remote)
					LogMsg("Initialized new Git repository and added remote.")
					
					; Try to fetch and track the remote branch
					fetchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin")
					LogMsg("Fetched remote repository.")
					
					; Check if the remote branch exists
					branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -r")
					
					if InStr(branchOutput, "origin/" . repo.branch) {
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
						LogMsg("Created local branch tracking remote branch '" . repo.branch . "'.")
					} else {
						; Create an empty branch with the right name
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout --orphan " . repo.branch)
						LogMsg("Created new branch '" . repo.branch . "'. Remote branch does not exist yet.")
					}
				}
				
				; Update status
				LV.Modify(row, , , , "Repository configured", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
			}
			catch as e {
				LogMsg("Error: " . e.Message)
			}
		}

		; Helper function to execute command and get output
		RunCmdAndGetOutput(cmd) {
			tempFile := A_Temp . "\git_cmd_output.txt"
			RunWait("cmd.exe /c " . cmd . " > " . tempFile . " 2>&1", , "Hide")
			output := FileRead(tempFile)
			FileDelete(tempFile)
			return output
		}

		; Helper function to add messages to the log
		LogMsg(msg) {
			logEdit.Value := FormatTime(,"[yyyy-MM-dd HH:mm:ss] ") . msg . "`r`n" . logEdit.Value
		}

		; SplitPath function for v2 (since the built-in doesn't return an object)
		gitSplitPath(Path) {
			FileName := ""
			Dir := ""
			Ext := ""
			NameNoExt := ""
			Drive := ""
			
			; Split the path into components
			SplitPath(Path, &FileName, &Dir, &Ext, &NameNoExt, &Drive)
			
			; Return as an object
			return { path: Path, filename: FileName, dir: Dir, ext: Ext, nameNoExt: NameNoExt, drive: Drive }
		}
		; Function to add a repository to the ListView
		AddRepo(repo) {
			repoName := gitSplitPath(repo.remote).filename
			LV.Add(, repoName, repo.local, "Not checked", "Never")
		}
	}




}
; ; Array of repositories to manage
; repos := [
;     GitRepo("https://github.com/OvercastBTC/AHK.Standard.Lib", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib"),
;     GitRepo("https://github.com/OvercastBTC/AHK.User.Lib", "C:\Users\bacona\Documents\AutoHotkey\Lib"),
;     GitRepo("https://github.com/OvercastBTC/Personal", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Personal"),
;     GitRepo("https://github.com/OvercastBTC/AHK.ObjectTypeExtensions", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib\Extensions"),
;     GitRepo("https://github.com/OvercastBTC/AHK.Projects.v2", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2"),
;     GitRepo("https://github.com/OvercastBTC/AHK.ExplorerClassicContextMenu", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2\AHK.ExplorerClassicContextMenu")
; ]

; ; Create GUI
; myGui := Gui("AlwaysOnTop", "Git Repository Manager")
; myGui.SetFont("s10")

; ; Add title
; myGui.AddText("w500 h30", "Git Repository Synchronization Tool")
; myGui.AddText("w500 h2 0x10")  ; Horizontal Line

; ; Add ListView to display repository status
; LV := myGui.AddListView("w800 h300", ["Repository", "Local Path", "Status", "Last Synced"])

; ; Populate ListView with repos
; for repo in repos {
;     repoName := gitSplitPath(repo.remote).filename
;     LV.Add(, repoName, repo.local, "Not checked", "Never")
; }

; ; Add buttons
; buttonGroup := myGui.AddGroupBox("w800 h100", "Actions")
; myGui.AddButton("xp+20 yp+30 w180 h40", "Check All Repositories").OnEvent("Click", CheckAllRepos)
; myGui.AddButton("x+20 w180 h40", "Push Local to Remote").OnEvent("Click", PushToRemote)
; myGui.AddButton("x+20 w180 h40", "Pull from Remote").OnEvent("Click", PullFromRemote)
; myGui.AddButton("x+20 w180 h40", "Initialize Repositories").OnEvent("Click", InitRepos)

; ; Add log window
; myGui.AddText("xm w800 h20", "Operation Log:")
; logEdit := myGui.AddEdit("xm w800 h200 ReadOnly -Wrap")

; ; Show the GUI
; myGui.Show()

; ; Function to check all repositories
; CheckAllRepos(*)
; {
;     LogMsg("Checking all repositories...")
	
;     for i, repo in repos {
;         repoName := gitSplitPath(repo.remote).filename
;         LogMsg("Checking " . repoName . "...")
		
;         ; Check if directory exists
;         if !DirExist(repo.local) {
;             status := "Local directory missing"
;             LV.Modify(i, , , , status)
;             continue
;         }
		
;         ; Check if it's a git repository
;         if !DirExist(repo.local . "\.git") {
;             status := "Not a Git repository"
;             LV.Modify(i, , , status)
;             continue
;         }
		
;         ; Check repository status in more detail
;         gitStatus := CheckGitRepoStatus(repo)
;         LV.Modify(i, , , , gitStatus, FormatTime(,"yyyy-MM-dd HH:mm:ss"))
;     }
	
;     LogMsg("Repository check complete.")
; }

; ; Function to check detailed Git repository status
; CheckGitRepoStatus(repo)
; {
;     ; Check if it has the correct remote
;     remoteOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote -v")
;     if !InStr(remoteOutput, repo.remote) {
;         return "Wrong remote URL"
;     }
	
;     ; Check if branch exists
;     branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch")
;     if !InStr(branchOutput, repo.branch) {
;         return "Branch not found"
;     }
	
;     ; Check for uncommitted changes
;     statusOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git status --porcelain")
;     if statusOutput {
;         return "Uncommitted changes"
;     }
	
;     return "Repository ready"
; }

; ; Function to push local to remote
; PushToRemote(*)
; {
;     row := LV.GetNext(0)
;     if !row {
;         MsgBox("Please select a repository first.")
;         return
;     }
	
;     repo := repos[row]
;     repoName := gitSplitPath(repo.remote).filename
	
;     LogMsg("Pushing " . repoName . " to remote...")
	
;     try {
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git add . && git commit -m " "Auto-sync commit" " && git push --force-with-lease origin " . repo.branch)
;         LogMsg(output)
;         LV.Modify(row, , , , "Pushed to remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
;     }
;     catch as e {
;         LogMsg("Error: " . e.Message)
;     }
; }

; ; Function to pull from remote
; PullFromRemote(*)
; {
;     row := LV.GetNext(0)
;     if !row {
;         MsgBox("Please select a repository first.")
;         return
;     }
	
;     repo := repos[row]
;     repoName := gitSplitPath(repo.remote).filename
	
;     LogMsg("Pulling " . repoName . " from remote...")
	
;     try {
;         ; Backup untracked files first
;         backupDir := A_Temp . "\git_backup_" . FormatTime(,"yyyyMMdd_HHmmss")
;         DirCreate(backupDir)
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git ls-files --others --exclude-standard > " . backupDir . "\untracked_files.txt")
		
;         ; Fetch and reset to remote
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git reset --hard origin/" . repo.branch)
;         LogMsg(output)
;         LV.Modify(row, , , , "Pulled from remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
		
;         ; Inform about backup
;         LogMsg("Untracked files list saved to: " . backupDir . "\untracked_files.txt")
;     }
;     catch as e {
;         LogMsg("Error: " . e.Message)
;     }
; }

; ; Function to initialize repositories
; InitRepos(*)
; {
;     row := LV.GetNext(0)
;     if !row {
;         MsgBox("Please select a repository first.")
;         return
;     }
	
;     repo := repos[row]
;     repoName := gitSplitPath(repo.remote).filename
	
;     LogMsg("Initializing " . repoName . "...")
	
;     try {
;         ; Create directory if it doesn't exist
;         if !DirExist(repo.local) {
;             DirCreate(repo.local)
;             LogMsg("Created directory: " . repo.local)
;         }
		
;         ; Enhanced check for existing Git repository
;         if DirExist(repo.local . "\.git") {
;             LogMsg("Found existing Git repository. Checking configuration...")
			
;             ; Check if the remote URL matches
;             remoteOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote -v")
			
;             if InStr(remoteOutput, repo.remote) {
;                 LogMsg("Remote URL already correctly configured.")
;             } else {
;                 ; Check if origin exists
;                 if InStr(remoteOutput, "origin") {
;                     output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote set-url origin " . repo.remote)
;                     LogMsg("Updated existing remote URL to: " . repo.remote)
;                 } else {
;                     output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote add origin " . repo.remote)
;                     LogMsg("Added remote 'origin' with URL: " . repo.remote)
;                 }
;             }
			
;             ; Check if branch exists
;             branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch")
			
;             if !InStr(branchOutput, repo.branch) {
;                 LogMsg("Creating branch '" . repo.branch . "' tracking remote...")
;                 output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
;                 LogMsg(output)
;             } else {
;                 ; Make sure the branch is correctly tracking
;                 trackingOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -vv")
				
;                 if !InStr(trackingOutput, "origin/" . repo.branch) {
;                     LogMsg("Setting correct tracking for branch '" . repo.branch . "'...")
;                     output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch --set-upstream-to=origin/" . repo.branch . " " . repo.branch)
;                     LogMsg(output)
;                 } else {
;                     LogMsg("Branch '" . repo.branch . "' already correctly tracking remote.")
;                 }
;             }
;         } else {
;             ; Initialize a completely new repository
;             LogMsg("No Git repository found. Initializing new repository...")
;             output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git init && git remote add origin " . repo.remote)
;             LogMsg("Initialized new Git repository and added remote.")
			
;             ; Try to fetch and track the remote branch
;             fetchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin")
;             LogMsg("Fetched remote repository.")
			
;             ; Check if the remote branch exists
;             branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -r")
			
;             if InStr(branchOutput, "origin/" . repo.branch) {
;                 output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
;                 LogMsg("Created local branch tracking remote branch '" . repo.branch . "'.")
;             } else {
;                 ; Create an empty branch with the right name
;                 output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout --orphan " . repo.branch)
;                 LogMsg("Created new branch '" . repo.branch . "'. Remote branch does not exist yet.")
;             }
;         }
		
;         ; Update status
;         LV.Modify(row, , , , "Repository configured", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
;     }
;     catch as e {
;         LogMsg("Error: " . e.Message)
;     }
; }

; ; Helper function to execute command and get output
; RunCmdAndGetOutput(cmd)
; {
;     tempFile := A_Temp . "\git_cmd_output.txt"
;     RunWait("cmd.exe /c " . cmd . " > " . tempFile . " 2>&1", , "Hide")
;     output := FileRead(tempFile)
;     FileDelete(tempFile)
;     return output
; }

; ; Helper function to add messages to the log
; LogMsg(msg)
; {
;     logEdit.Value := FormatTime(,"[yyyy-MM-dd HH:mm:ss] ") . msg . "`r`n" . logEdit.Value
; }

; ; SplitPath function for v2 (since the built-in doesn't return an object)
; gitSplitPath(Path){
; 	FileName := ""
; 	Dir := ""
; 	Ext := ""
; 	NameNoExt := ""
; 	Drive := ""
	
; 	; Split the path into components
; 	SplitPath(Path, &FileName, &Dir, &Ext, &NameNoExt, &Drive)
	
; 	; Return as an object
; 	return { path: Path, filename: FileName, dir: Dir, ext: Ext, nameNoExt: NameNoExt, drive: Drive }
; }

; #Requires AutoHotkey v2.0
; ; Git Repository Synchronization Tool
; ; This script automates the synchronization of multiple git repositories

; ; Define your repositories
; class GitRepo {
;     remote := ""
;     local := ""
;     branch := "master"  ; Default branch name
	
;     __New(remoteRepo, localRepo, branchRepo := "master") {
;         this.remote := remoteRepo
;         this.local := localRepo
;         this.branch := branchRepo
;     }
; }

; ; Array of repositories to manage
; repos := [
;     GitRepo("https://github.com/OvercastBTC/AHK.Standard.Lib", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib"),
;     GitRepo("https://github.com/OvercastBTC/AHK.User.Lib", "C:\Users\bacona\Documents\AutoHotkey\Lib"),
;     GitRepo("https://github.com/OvercastBTC/Personal", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Personal"),
;     GitRepo("https://github.com/OvercastBTC/AHK.ObjectTypeExtensions", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib\Extensions"),
;     GitRepo("https://github.com/OvercastBTC/AHK.Projects.v2", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2"),
;     GitRepo("https://github.com/OvercastBTC/AHK.ExplorerClassicContextMenu", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2\AHK.ExplorerClassicContextMenu")
; ]

; ; Create GUI
; myGui := Gui("AlwaysOnTop", "Git Repository Manager")
; myGui.SetFont("s10")

; ; Add title
; myGui.AddText("w500 h30", "Git Repository Synchronization Tool")
; myGui.AddText("w500 h2 0x10")  ; Horizontal Line

; ; Add ListView to display repository status
; LV := myGui.AddListView("w800 h300", ["Repository", "Local Path", "Status", "Last Synced"])

; ; Populate ListView with repos
; for repo in repos {
;     repoName := gitSplitPath(repo.remote).filename
;     LV.Add(, repoName, repo.local, "Not checked", "Never")
; }

; ; Add buttons
; buttonGroup := myGui.AddGroupBox("w800 h100", "Actions")
; myGui.AddButton("xp+20 yp+30 w180 h40", "Check All Repositories").OnEvent("Click", CheckAllRepos)
; myGui.AddButton("x+20 w180 h40", "Push Local to Remote").OnEvent("Click", PushToRemote)
; myGui.AddButton("x+20 w180 h40", "Pull from Remote").OnEvent("Click", PullFromRemote)
; myGui.AddButton("x+20 w180 h40", "Initialize Repositories").OnEvent("Click", InitRepos)

; ; Add log window
; myGui.AddText("xm w800 h20", "Operation Log:")
; logEdit := myGui.AddEdit("xm w800 h200 ReadOnly -Wrap")

; ; Show the GUI
; myGui.Show()

; ; Function to check all repositories
; CheckAllRepos(*)
; {
;     LogMsg("Checking all repositories...")
	
;     for i, repo in repos {
;         repoName := gitSplitPath(repo.remote).filename
;         LogMsg("Checking " . repoName . "...")
		
;         ; Check if directory exists
;         if !DirExist(repo.local) {
;             status := "Local directory missing"
;             LV.Modify(i, , , , status)
;             continue
;         }
		
;         ; Check if it's a git repository
;         if !DirExist(repo.local . "\.git") {
;             status := "Not a Git repository"
;             LV.Modify(i, , , status)
;             continue
;         }
		
;         ; Run git status
;         RunWait("cmd.exe /c cd /d " . '"' . repo.local . '"' . " && git status", , "Hide")
;         status := "Repository exists"
;         LV.Modify(i, , , , status, FormatTime(,"yyyy-MM-dd HH:mm:ss"))
;     }
	
;     LogMsg("Repository check complete.")
; }

; ; Function to push local to remote
; PushToRemote(*)
; {
;     row := LV.GetNext(0)
;     if !row {
;         MsgBox("Please select a repository first.")
;         return
;     }
	
;     repo := repos[row]
;     repoName := gitSplitPath(repo.remote).filename
	
;     LogMsg("Pushing " . repoName . " to remote...")
	
;     try {
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git add . && git commit -m " "Auto-sync commit" " && git push --force-with-lease origin " . repo.branch)
;         LogMsg(output)
;         LV.Modify(row, , , , "Pushed to remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
;     }
;     catch as e {
;         LogMsg("Error: " . e.Message)
;     }
; }

; ; Function to pull from remote
; PullFromRemote(*)
; {
;     row := LV.GetNext(0)
;     if !row {
;         MsgBox("Please select a repository first.")
;         return
;     }
	
;     repo := repos[row]
;     repoName := gitSplitPath(repo.remote).filename
	
;     LogMsg("Pulling " . repoName . " from remote...")
	
;     try {
;         ; Backup untracked files first
;         backupDir := A_Temp . "\git_backup_" . FormatTime(,"yyyyMMdd_HHmmss")
;         DirCreate(backupDir)
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git ls-files --others --exclude-standard > " . backupDir . "\untracked_files.txt")
		
;         ; Fetch and reset to remote
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git reset --hard origin/" . repo.branch)
;         LogMsg(output)
;         LV.Modify(row, , , , "Pulled from remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
		
;         ; Inform about backup
;         LogMsg("Untracked files list saved to: " . backupDir . "\untracked_files.txt")
;     }
;     catch as e {
;         LogMsg("Error: " . e.Message)
;     }
; }

; ; Function to initialize repositories
; InitRepos(*)
; {
;     row := LV.GetNext(0)
;     if !row {
;         MsgBox("Please select a repository first.")
;         return
;     }
	
;     repo := repos[row]
;     repoName := gitSplitPath(repo.remote).filename
	
;     LogMsg("Initializing " . repoName . "...")
	
;     try {
;         ; Create directory if it doesn't exist
;         if !DirExist(repo.local) {
;             DirCreate(repo.local)
;         }
		
;         ; Check if Git repo already exists
;         if DirExist(repo.local . "\.git") {
;             output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote set-url origin " . repo.remote)
;             LogMsg("Repository already exists. Updated remote URL.")
;         } else {
;             output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git init && git remote add origin " . repo.remote)
;             LogMsg("Initialized new Git repository and added remote.")
;         }
		
;         ; Set up tracking branch
;         output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
;         LogMsg(output)
		
;         ; Update status
;         LV.Modify(row, , , , "Initialized", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
;     }
;     catch as e {
;         LogMsg("Error: " . e.Message)
;     }
; }

; ; Helper function to execute command and get output
; RunCmdAndGetOutput(cmd)
; {
;     tempFile := A_Temp . "\git_cmd_output.txt"
;     RunWait("cmd.exe /c " . cmd . " > " . tempFile . " 2>&1", , "Hide")
;     output := FileRead(tempFile)
;     FileDelete(tempFile)
;     return output
; }

; ; Helper function to add messages to the log
; LogMsg(msg)
; {
;     logEdit.Value := FormatTime(,"[yyyy-MM-dd HH:mm:ss] ") . msg . "`r`n" . logEdit.Value
; }

; ; SplitPath function for v2 (since the built-in doesn't return an object)
; gitSplitPath(Path){
; 	FileName := ""
; 	Dir := ""
; 	Ext := ""
; 	NameNoExt := ""
; 	Drive := ""
	
; 	; Split the path into components
; 	SplitPath(Path, &FileName, &Dir, &Ext, &NameNoExt, &Drive)
	
; 	; Return as an object
; 	return { path: Path, filename: FileName, dir: Dir, ext: Ext, nameNoExt: NameNoExt, drive: Drive }
; }
