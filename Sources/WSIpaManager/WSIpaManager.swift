import ArgumentParser

@main
class wsipamanager: ParsableCommand {

    required init() {
    }

    
    static var configuration = CommandConfiguration(
            abstract: "🎉这是一个ipa管理工具，可以下载、搜索、注入反注入，重签等操作，",
            subcommands: [Search.self,
                          Login.self,
                          Download.self,
                          Inject.self,
                          Uninject.self,
//                          Resign.self,
                          Generateproj.self,
                          Configenv.self,
                          Uninstall.self,
                          Getheader.self])
    
     public func run() {
         if CommandLine.arguments.count <= 1 {
             CommonMethod().showErrorMessage(text: "缺少命令")
             return
         }
    }
}


