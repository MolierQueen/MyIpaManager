//
//  Getheader.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/3/12.
//

import Foundation
import ArgumentParser

class Getheader: ParsableCommand {
    
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "获取ipa对应的所有的头文件")

    @Option(name: [.short, .long], help: "对应的Mach-o文件，注意是Mach-o文件 不是.ipa文件")
    var mach_oPath: String = ""
    
    @Option(name: [.short, .long], help: "目标路径，注意会生成大量的文件，建议选择空文件夹")
    var targetPath: String = ""
    
    public func run() {
        
        if mach_oPath.count == 0 {
            CommonMethod().showErrorMessage(text: "Mach_o文件路径不能为空")
            return
        }
        
        guard let number = FileManager.default.subpaths(atPath: targetPath) else {
            CommonMethod().showErrorMessage(text: "目标路径不合法,或缺少目标路径")
            return
        }
        
        Configenv().run()
        
        CommonMethod().showCommonMessage(text: "开始处理...")
        if number.count > 0 {
            CommonMethod().showWarningMessage(text: "目标路径不为空路径，是否继续，可能不便于检索\n是：Y 、终止：n")
            let mark = readLine();
            if mark == "n" {
                return
            }
        }
        
        let command = "-S -s -H \(mach_oPath) -o \(targetPath)"
        
        CommonMethod().runShell(shellPath: "/usr/local/bin/getheader", command: command) { code, desc in
            if code == 0 {
                CommonMethod().showSuccessMessage(text: "头文件导出成功")
            } else {
                CommonMethod().showErrorMessage(text: "导出失败 = \(desc.replacingOccurrences(of: "class-dump", with: "getheader"))")
                
            }
        }
        
        
    }
}
        
        
