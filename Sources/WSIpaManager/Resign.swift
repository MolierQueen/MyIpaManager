//
//  Resign.swift
//  WSIpaManager
//
//  Created by Molier on 2023/2/24.
//

import Foundation
import ArgumentParser
import Security

class Resign: ParsableCommand {
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "针对ipa的重签工具")
    
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .long], help: "将要被重签的ipa路径")
    var inputIPAPath: String = ""
    
    @Option(name: [.short, .long], help: "重签用的证书")
    var certificate: String = ""
    
    @Option(name: [.short, .long], help: "重签用的描述文件")
    var mobileprovision: String = ""
    
    @Option(name: [.short, .long], help: "新的bundleID")
    var bundleId: String = ""
    
    func run() -> Void {
        CommonMethod().showCommonMessage(text: "重签完成")
        resignIPA(inputIPAPath: inputIPAPath, certificate: certificate, mobileprovision: mobileprovision)
    }
    

    // 重签名函数
    func resignIPA(inputIPAPath: String, certificate: String, mobileprovision: String) -> Void {

        let ipaName = inputIPAPath.components(separatedBy: "/").last!
        if ipaName.contains(".ipa") == false {
            CommonMethod().showErrorMessage(text: "不是ipa文件target = \(inputIPAPath)")
            return
        }
        let operationPath:String = String(inputIPAPath.dropLast(ipaName.count))
        
        // 解压 IPA 文件
        CommonMethod().runShell(shellPath:"/bin/bash", command:"unzip -o \(inputIPAPath) -d \(operationPath)", needWait: false) { code, des in
            if code == 0 {
                CommonMethod().showCommonMessage(text: "解压ipa成功，开始重签...")
                var appNmae = ""
                let payload = operationPath+"Payload"
                do {
                    let fileList = try FileManager.default.contentsOfDirectory(atPath: payload)
                    var appPath = ""
                    for item in fileList {
                        if item.hasSuffix(".app") {
                            appNmae = item.components(separatedBy: ".").first!
                            appPath = payload + "/\(item)"
                            break
                        }
                    }
                    
                    // 删除签名文件
                    let originalCodeSignaturePath = appPath + "/" + "_CodeSignature"
                    try FileManager.default.removeItem(atPath: originalCodeSignaturePath)
                    
                    
                    // 拷贝 mobileprovision 文件到指定位置
                    let embeddedPath = appPath + "/" + "embedded.mobileprovision"
                    try FileManager.default.copyItem(atPath: mobileprovision, toPath: embeddedPath)
    
                    // 获取 app 的 entitlements
                    let entitlementsPath = operationPath + "entitlements.plist"
                    CommonMethod().runShell(shellPath: "/bin/bash", command: "codesign -d --entitlements \(entitlementsPath) \(appPath)") { code, desc in
                        if code == 0 {
                            
                            CommonMethod().runShell(shellPath: "/bin/bash", command: "codesign -f -s \(certificate.utf8) --entitlements \(entitlementsPath) \(appPath)") { code, desc in
                                if code == 0 {
                                    CommonMethod().showSuccessMessage(text: "重签成功")
                                    
                                    let newAppPath = operationPath + appNmae + "_resigned.ipa"

                                    CommonMethod().runShell(shellPath: "/bin/bash", command: "cd \(operationPath); zip -qr \(newAppPath) Payload ", needWait: false) { code, desc in
                                        if code == 0 {
                                            CommonMethod().showSuccessMessage(text: "生成新包成功")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } catch let err {
                    CommonMethod().showErrorMessage(text: "解压成功但是文件操作错误\(err)")
                }
            } else {
                CommonMethod().showErrorMessage(text: "解压失败\(des)")
            }
        }

        
//        // Step 3: Change the bundle ID if needed
//        if let infoPlistPath = Bundle(path: tempAppPath)?.path(forResource: "Info", ofType: "plist") {
//            var infoPlist = NSMutableDictionary(contentsOfFile: infoPlistPath)!
//            if let currentBundleId = infoPlist.object(forKey: "CFBundleIdentifier") as? String {
//                if currentBundleId != bundleId {
//                    infoPlist.setValue(bundleId, forKey: "CFBundleIdentifier")
//                    infoPlist.write(toFile: infoPlistPath, atomically: true)
//                }
//            }
//        }
    

//        // 重新打包为 IPA 文件
//        let repackTask = Process()
//        repackTask.launchPath = "/usr/bin/zip"
//        repackTask.arguments = ["-qr", outputIPAPath, "Payload"]
//        repackTask.currentDirectoryPath = tempDir
//        repackTask.launch()
//        repackTask.waitUntilExit()
//
//        // 删除临时目录
//        do {
//            try fileManager.removeItem(atPath: tempDir)
//        } catch let error {
//            print("删除临时目录失败: \(error.localizedDescription)")
//            return false
//        }

        return
    }


}
