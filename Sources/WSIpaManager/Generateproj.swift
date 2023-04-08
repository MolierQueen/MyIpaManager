//
//  Generateproj.swift
//  WSIpaManager
//
//  Created by Molier on 2023/3/8.
//

import Foundation
import ArgumentParser
class Generateproj: ParsableCommand {
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "生成二次开发工程")
    
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .long], help: "已经被砸壳的ipa路径，可以为空")
    var iPAPath: String = ""
    
    
    func run() -> Void {
        
        if CommonMethod().checkEnvConfig() == false {
            CommonMethod().showErrorMessage(text: "请先使用 configenv 配置环境")
            return
        }
        
        if iPAPath.count == 0 {
            CommonMethod().showErrorMessage(text: "ipa路径不能为空")
            return
        }
        
        CommonMethod().showCommonMessage(text: "会在当前目录下生成WSIpaHookTool工程，是否继续 Y/n")
        let mark = readLine();
        if mark == "n" {
            return
        }
        
        let gitUrl = "https://github.com/MolierQueen/WSIpaHookTool.git"
        CommonMethod().showCommonMessage(text: "开始生成工程...")
        CommonMethod().runShell(shellPath: "/bin/bash", command: "git clone \(gitUrl)") { code, desc in
            if code == 0 {
                let gitSourct = "\(FileManager.default.currentDirectoryPath)/WSIpaHookTool/.git"
                let gitignoreSourct = "\(FileManager.default.currentDirectoryPath)/WSIpaHookTool/.gitignore"
                do {
                    try FileManager.default.removeItem(atPath: gitSourct)
                    try FileManager.default.removeItem(atPath: gitignoreSourct)
                } catch {}
                
                let tar = "\(FileManager.default.currentDirectoryPath)/WSIpaHookTool/WSIpaHookTool/TargetApp/target.ipa"
                do {
                    CommonMethod().showCommonMessage(text: "开始拷贝ipa...")
                    try FileManager.default.copyItem(atPath:iPAPath, toPath: "\(tar)")
                } catch let err {
                    CommonMethod().showErrorMessage(text: "拷贝ipa失败 = \(err)")
                }
            }
        }
    
        
        CommonMethod().runShell(shellPath:  "/bin/bash", command: "open WSIpaHookTool/WSIpaHookTool.xcworkspace") { code2, desc2 in
            if code2 == 0 {
                CommonMethod().showSuccessMessage(text: "任务完成")
            }
        }
    }
}
