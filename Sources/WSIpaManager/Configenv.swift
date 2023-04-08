//
//  Configenv.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/3/10.
//

import ArgumentParser
import Foundation

class Configenv: ParsableCommand {
    
    var count = 0.0

    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "一键配置环境")
    
    public func run() {
        
        
        if CommonMethod().checkEnvConfig() {
            CommonMethod().showSuccessMessage(text: "环境配检测完成，继续任务")
        } else {
            let gitUrl = "https://github.com/MolierQueen/TmpDepency.git"
            CommonMethod().showCommonMessage(text: "开始按需配置环境...")
            
            if !CommonMethod().isSudo() {
                CommonMethod().showErrorMessage(text: "要使用sudo权限执行")
                return
            }

            fileCopyIfNeed(filePath: FileManager.default.currentDirectoryPath + "/" + "WSIpaManager", targetPath: wsipamanagerPath)

            CommonMethod().runShell(shellPath: "/bin/bash", command: "git clone \(gitUrl)") { code, desc in
                if code == 0 {
                    copyDepencyFileForTool()
                    copyDepencyFileForHookProj()
                    do {
                        try FileManager.default.removeItem(atPath: "\(FileManager.default.currentDirectoryPath)/TmpDepency")
                    } catch let err {
                        CommonMethod().showErrorMessage(text: "删除临时文件失败:\(err)")
                    }
                    CommonMethod().showSuccessMessage(text: "环境配置完成")

                } else {
                    CommonMethod().showErrorMessage(text: "拉取配置文件错误\(desc)")
                    Configenv.exit()
                }
            }
        }
    }
    

    
    func copyDepencyFileForTool() -> Void {
        let downloadSource = FileManager.default.currentDirectoryPath+"/TmpDepency/downloadmanager"
        let injectSource = FileManager.default.currentDirectoryPath+"/TmpDepency/injecttool"
        let getheaderSource = FileManager.default.currentDirectoryPath+"/TmpDepency/getheader"

        fileCopyIfNeed(filePath: downloadSource, targetPath: downloadmanagerPath)
        fileCopyIfNeed(filePath: injectSource, targetPath: injecttoolPath)
        fileCopyIfNeed(filePath: getheaderSource, targetPath: getheaderPath)
    }
    
    func copyDepencyFileForHookProj() -> Void {
        let runtime_1 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.0.9.dylib"
        let runtime_2 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.dylib"
        let runtime_3 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.dylib"

        fileCopyIfNeed(filePath: runtime_1, targetPath: runtimeTarget1)
        fileCopyIfNeed(filePath: runtime_2, targetPath: runtimeTarget2)
        fileCopyIfNeed(filePath: runtime_3, targetPath: runtimeTarget3)
        
        let SDK_1 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.0.9.tbd"
        let SDK_2 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.tbd"
        let SDK_3 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.tbd"

       fileCopyIfNeed(filePath: SDK_1, targetPath: MACTarget1)
       fileCopyIfNeed(filePath: SDK_2, targetPath: MACTarget2)
       fileCopyIfNeed(filePath: SDK_3, targetPath: MACTarget3)
       
       fileCopyIfNeed(filePath: SDK_1, targetPath: iphoneTarget1)
       fileCopyIfNeed(filePath: SDK_2, targetPath: iphoneTarget2)
       fileCopyIfNeed(filePath: SDK_3, targetPath: iphoneTarget3)
       
       fileCopyIfNeed(filePath: SDK_1, targetPath: simulatorTarget1)
       fileCopyIfNeed(filePath: SDK_2, targetPath: simulatorTarget2)
       fileCopyIfNeed(filePath: SDK_3, targetPath: simulatorTarget3)
    }
    
    func fileCopyIfNeed(filePath:String, targetPath:String) -> Void {
//        count += 1.0
//        print("pr -- \(count)")
//        let precent:Double = count / 15.0*100
//        //            打印进度
//        print( "\u{1B}[1A\u{1B}[KDownloaded:我是\(precent)% ")
//        fflush(__stdoutp)
        do {
            if !FileManager.default.fileExists(atPath: targetPath) {
                try FileManager.default.copyItem(atPath:filePath, toPath: targetPath)
            } else {
                CommonMethod().showWarningMessage(text: "文件已存在 = \(targetPath)")
            }
        } catch let err {
            do {
                try FileManager.default.removeItem(atPath: "\(FileManager.default.currentDirectoryPath)/TmpDepency")
            } catch {}
            CommonMethod().showErrorMessage(text: "配置依赖失败 = \(targetPath) error = \(err)")
            Configenv.exit()
        }
    }
}
