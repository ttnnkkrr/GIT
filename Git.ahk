
class git {

    gitURL := "https://api.github.com/user/repos"
    batchExecute := A_Temp "\gitExecute.sh"

    __new(user, pass, email){
        this.user := user, this.pass := pass, this.email := email

        ePath := ""
        ControlGetText,ePath, Edit1, A
        this.path := ePath
        
        if instr(this.installed(), "'git' is not recognized as an internal or external command"){
            MsgBox 0x42013, Git AHK, Git is not installed on your system. Would you like to download and install it?

            IfMsgBox Yes 
                this.install()
            Else IfMsgBox No
                Exit
            Else IfMsgBox Cancel
                ExitApp
        }
        
        ;; get the sh.exe
        EnvGet, WinPath, Path ;; check the windows path variable
        RegExMatch(WinPath, ";?([^;]*Git\\)cmd[^;]*;", SubPat) 
        this.BASH := SubPat1 "bin\sh.exe"

        ;; insure these defaults
        this.batchLines := "git config --global user.name '" this.user "'`r`n"
        this.batchLines .= "git config --global user.email '" this.email "'`r`n"
        this.batchLines .= "git config --global github.user '" this.user "'`r`n"
        this.batchLines .= "git config --global user.password '" this.pass "'"
        this.execute()
    }
    
    execute(){
        FileAppend, % sh := "cd """ this.path """`r`n" this.batchLines, % this.batchExecute
        res := this.cmd( """" this.BASH """ " this.batchExecute)
        FileDelete, % this.batchExecute
        this.batchLines := ""
        return res
    }
    
    cmd(cmd){
        ;;get a shell object
        shell := ComObjCreate("WScript.Shell")

        ; Execute a single command via cmd.exe
        exec := shell.Exec(ComSpec " /C " cmd)

        ; Read and return the command's output
        return exec.StdOut.ReadAll()
    }

    installed(){
        ;;git --version
        return this.cmd("git --version")
    }

    install(){
        ;; download git ;; 
        UrlDownloadToFile, https://github.com/git-for-windows/git/releases/download/v2.24.0.windows.2/Git-2.24.0.2-32-bit.exe, %A_Temp%\gitInstall.exe

        ;; run installer with defaults
        this.cmd(A_Temp  " \gitInstall.exe  /VERYSILENT")

        ;; return the version
        return this.installed()
    }

    cURL(cmd){
        if instr(this.cmd("curl --version"), "'curl' is not recognized as an internal or external command"){
            MsgBox 0x42010, Git AHK, cURL is not installed. Please resolve this and retry
            ExitApp
        }
        return this.cmd("curl " cmd)
    }

    init(name){
        ;; git remote add origin "https://github.com/ttnnkkrr/ACC Viewer.git"
        this.batchLines .= "`r`ngit init"
        this.batchLines .= "`r`ngit add ."
        this.batchLines .= "`r`ngit remote add origin ""https://github.com/" this.user "/" StrReplace(name, A_Space, "-") ".git"""
        this.execute()
    }

    commit(comment){
        ;; add all files and commit this
        this.batchLines .= "`r`ngit commit -m '" comment "'"
        this.execute()
    }

    push(branch = "master"){
        ;; this is for the initial push
        this.batchLines .= "`r`ngit push -u origin " branch
        this.batchLines .= "`r`ngit push"
        this.execute()
    }

    newRepo(comment = "initial project version", license = "GPL3"){    
        ;; this current directory
        ControlGetText,ePath, Edit1, A
        this.path := ePath
        
        ;; if there is a current folder then create a repo
        if (ePath) {
            ;; set the path components
            SplitPath, ePath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive

            ;; create the remote repo on github
            this.batchLines := "curl -u '" this.user ":" this.pass "' " this.gitURL " -d '{""name"":""" StrReplace(OutNameNoExt, A_Space, "-") """}'", this.execute()
            
            ;; init commit and push 
            this.init(OutNameNoExt), this.commit(comment), this.batchLines := "cd """ this.path """`r`ngit push --set-upstream origin master", this.execute(), this.push()
        }
    }
}