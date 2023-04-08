//
//  Uninstall.swift
//  WSIpaManager
//
//  Created by Molier on 2023/3/10.
//

import Foundation
import ArgumentParser

class Uninstall: ParsableCommand {

    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "一键删除环境")
    
    public func run() {
        if !CommonMethod().isSudo() {
            CommonMethod().showErrorMessage(text: "要使用sudo权限执行")
            return
        }
        uninstallEnv(filePath: downloadmanagerPath)
        uninstallEnv(filePath: injecttoolPath)
        uninstallEnv(filePath: getheaderPath)
        uninstallEnv(filePath: wsipamanagerPath)
        
        uninstallEnv(filePath: runtimeTarget1)
        uninstallEnv(filePath: runtimeTarget2)
        uninstallEnv(filePath: runtimeTarget3)
        
        uninstallEnv(filePath: MACTarget1)
        uninstallEnv(filePath: MACTarget2)
        uninstallEnv(filePath: MACTarget3)

        uninstallEnv(filePath: iphoneTarget1)
        uninstallEnv(filePath: iphoneTarget2)
        uninstallEnv(filePath: iphoneTarget3)

        uninstallEnv(filePath: simulatorTarget1)
        uninstallEnv(filePath: simulatorTarget2)
        uninstallEnv(filePath: simulatorTarget3)

        CommonMethod().showSuccessMessage(text: "环境卸载完成！")
    }
    
    func uninstallEnv(filePath:String) -> Void {
        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath:filePath)
            }
        } catch let err {
            CommonMethod().showWarningMessage(text: "文件卸载失败 = \(filePath) err = \(err)")
            Configenv.exit()
        }
    }
}
