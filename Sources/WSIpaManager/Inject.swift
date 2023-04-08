//
//  Inject.swift
//  WSIpaManager
//
//  Created by Molier on 2023/2/22.
//
import ArgumentParser
import Foundation
import MachO
class Inject: ParsableCommand {
    required init() {
    }
    
    static var configuration = CommandConfiguration(abstract: "针对Maco-o的注入工具")
    
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .long], help: "将要注入的动态库路径")
    var sourcePath: String = ""
    
    @Option(name: [.short, .long], help: "将要被注入的ipa文件路径,注意是ipa文件，不是mach-o文件")
    var targetPath: String = ""
    
    @Flag(name: [.short, .long], help: "是否要强制注入")
    var force: Bool = false

     func run() {
         Configenv().run()
         if force {
             CommonMethod().showCommonMessage(text: "开始进行强制注入...")
             let command = "install -c load -p \(sourcePath) -t \(targetPath)"
             CommonMethod().runShell(shellPath: "/usr/local/bin/injecttool", command: command) { code, desc in
                 if code == 0 {
                     CommonMethod().showSuccessMessage(text: "已经使用WSIpaManager注入成功...")
                 }
             }
         } else {
             if FileManager.default.fileExists(atPath: sourcePath) == false ||
                    FileManager.default.fileExists(atPath: targetPath) == false {
                 CommonMethod().showErrorMessage(text: "路径错误source = \(sourcePath) target = \(targetPath)")
                 return
             }
             let ipaName = targetPath.components(separatedBy: "/").last!
             if ipaName.contains(".ipa") == false {
                 CommonMethod().showErrorMessage(text: "不是ipa文件target = \(targetPath)")
                 return
             }
             let operationPath:String = String(targetPath.dropLast(ipaName.count))
             prepareToInjectIPA(ipaPath: targetPath, ipaName: ipaName, injectPath: sourcePath, operationPath: operationPath) { success in
             }
         }
    }
    
    
    func prepareToInjectIPA(ipaPath: String, ipaName:String, injectPath: String, operationPath:String, finishHandle:(Bool)->()) {
        var result = false
        var frameworkNameWithExt = ""
        var injectPathName = ""
        if injectPath.hasSuffix(".framework") {
            
            //            取到动态库名字和扩展名 xxx.framework
            frameworkNameWithExt = injectPath.components(separatedBy: "/").last!
            //            即将被注入的动态库的扩展名分开（取出名字）
            let frameworkName = frameworkNameWithExt.components(separatedBy: ".").first!
            
            injectPathName = "\(DYLIB_EXECUTABLE_PATH)\(frameworkNameWithExt)/\(frameworkName)"
            
            
        } else if injectPath.hasSuffix(".dylib") {
            frameworkNameWithExt = injectPath.components(separatedBy: "/").last!
            injectPathName = "\(DYLIB_EXECUTABLE_PATH)\(frameworkNameWithExt)"
        } else {
            CommonMethod().showErrorMessage(text: "动态库不合法")
            finishHandle(false)
        }
        CommonMethod().showCommonMessage(text: "入参检查完毕，准备动态库注入，开始解压ipa...")
        var zipMark = false
    
        CommonMethod().runShell(shellPath:"/bin/bash", command:"unzip -o \(ipaPath) -d \(operationPath)",needWait: false) { code, des in
            //            解压后取出app文件和macho文件的路径
            if code == 0 {
                zipMark = true
            } else {
                CommonMethod().showErrorMessage(text: "解压失败\(des)")
                return
            }
        }
        
        if zipMark {
            CommonMethod().showCommonMessage(text: "解压ipa成功，开始注入...")
            var appNmae = ""
            let payload = operationPath+"Payload"
            do {
                let fileList = try FileManager.default.contentsOfDirectory(atPath: payload)
                var machoPath = ""
                var appPath = ""
                for item in fileList {
                    if item.hasSuffix(".app") {
                        appNmae = item.components(separatedBy: ".").first!
                        appPath = payload + "/\(item)"
                        machoPath = appPath+"/\(appNmae)"
                        break
                    }
                }
                
                if FileManager.default.fileExists(atPath: "\(appPath)/\(DYLIB_PATH)/") == false {
                    //                    创建一个文件夹
                    try FileManager.default.createDirectory(atPath: "\(appPath)/\(DYLIB_PATH)/", withIntermediateDirectories: true, attributes: nil)
                }
                try FileManager.default.copyItem(atPath: injectPath, toPath: "\(appPath)/\(DYLIB_PATH)/\(frameworkNameWithExt)")
                
                //                    把要注入的动态库放进去
                //                    try FileManager.default.moveItem(atPath: injectPath, toPath: "\(appPath)/\(DYLIB_PATH)/\(frameworkNameWithExt)")
                
                //                    开始注入
                injectMachO(machoPath: machoPath, backup: false, injectPath: injectPathName) { success in
                    if success {
                        CommonMethod().showCommonMessage(text: "注入成功，开始将产物打包成ipa...")
                        //                            注入完成后压缩打包成ipa
                        let newAppPath = operationPath + appNmae + "_injected.ipa"
                        CommonMethod().runShell(shellPath:"/bin/bash", command:"cd \(operationPath); zip -r \(newAppPath) Payload", needWait: false) { code, desc in
                            if code == 0 {
                                CommonMethod().showSuccessMessage(text: "任务完成，新ipa = \(newAppPath)")
                                result = true
                            } else {
                                CommonMethod().showErrorMessage(text: "打包ipa失败\(desc)")
                            }
                        }
                    }
                }
                try FileManager.default.removeItem(atPath: payload)
            } catch let err {
                CommonMethod().showErrorMessage(text: "解压成功但是文件操作错误\(err)")
            }
        }
        
        
        
        
        
        
        
        
        
        
        finishHandle(result)
    }
    
    
    func injectMachO(machoPath: String, backup: Bool, injectPath: String, finishHandle:(Bool)->()) {
        var result = false
        //        打开mach-o文件（将mach-o打开以data形式读取出来）
        FileManager.open(machoPath: machoPath, backup: backup) { data in
            if let binary = data {
                let fatHeader = binary.extract(fat_header.self)
                let type = fatHeader.magic
                //                判断macho是什么类型
                if type != MH_MAGIC_64
                    && type != MH_CIGAM_64 {
                    CommonMethod().showErrorMessage(text: "mach_o文件类型不符合")
                    finishHandle(false)
                    return
                }
                if injectPath.count > 0 {
                    
                    //                            先判断能否注入
                    canInject(binary: binary, dylibPath: injectPath) { canInject in
                        if canInject {
                            //                                可以注入，开始注入
                            doRealInject(binary: binary, dylibPath: injectPath) { newBinary in
                                result = CommonMethod().writeFile(newBinary: newBinary, machoPath: machoPath, isRemove: false)
                            }
                        }
                    }
                }
            }
        }
        finishHandle(result)
    }
    
    
    func canInject(binary: Data, dylibPath: String, handle: (Bool)->()) {
        
        //            先取出Mach64Header
        let header = binary.extract(mach_header_64.self)
        //            先取出Mach64Header
        var offset = MemoryLayout.size(ofValue: header)
        if header.ncmds >= 512 {
            CommonMethod().showErrorMessage(text: "动态库已满，无法注入 一共有 \(header.ncmds)个动态库")
            handle(false)
            return
        }
        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            let tmpCmd:UInt32 = loadCommand.cmd
            switch tmpCmd {
            case LC_REEXPORT_DYLIB, LC_LOAD_UPWARD_DYLIB, LC_LOAD_WEAK_DYLIB, UInt32(LC_LOAD_DYLIB):
                let command = binary.extract(dylib_command.self, offset: offset)
//                print("dongtaiku = \(command)")
                let curPath = String(data: binary, offset: offset, commandSize: Int(command.cmdsize), loadCommandString: command.dylib.name)
                let curName = curPath.components(separatedBy: "/").last
                if !force {
                    if curName == dylibPath || curPath == dylibPath {
                        CommonMethod().showErrorMessage(text: "该动态库已经存在\(curPath)")
                        handle(false)
                        return
                    }
                }
                break
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }
        handle(true)
    }
    
    func doRealInject(binary: Data, dylibPath: String, handle: (Data?)->()) {
        var newbinary = binary
        let length = MemoryLayout<dylib_command>.size + dylibPath.lengthOfBytes(using: String.Encoding.utf8)
        let padding = (8 - (length % 8))
        let cmdsize = length+padding
        
        var start = 0
        var end = cmdsize
        var subData: Data
        var newHeaderData: Data
        var machoRange: Range<Data.Index>
        let header = binary.extract(mach_header_64.self)
        start = Int(header.sizeofcmds)+Int(MemoryLayout<mach_header_64>.size)
        end += start
        subData = newbinary[start..<end]
        
        var newheader = mach_header_64(magic: header.magic, cputype: header.cputype, cpusubtype: header.cpusubtype, filetype: header.filetype, ncmds: header.ncmds+1, sizeofcmds: header.sizeofcmds+UInt32(cmdsize), flags: header.flags, reserved: header.reserved)
        newHeaderData = Data(bytes: &newheader, count: MemoryLayout<mach_header_64>.size)
        machoRange = Range(NSRange(location: 0, length: MemoryLayout<mach_header_64>.size))!
        
        let d = String(data: subData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        if d != "" && d != nil {
            CommonMethod().showErrorMessage(text: "不能插入\(dylibPath)了没有空间了")
            handle(nil)
            return
        }
        
        let dy = dylib(name: lc_str(offset: UInt32(MemoryLayout<dylib_command>.size)), timestamp: 2, current_version: 0, compatibility_version: 0)
        var command = dylib_command(cmd: UInt32(LC_LOAD_DYLIB), cmdsize: UInt32(cmdsize), dylib: dy)
        
        var zero: UInt = 0
        var commandData = Data()
        commandData.append(Data(bytes: &command, count: MemoryLayout<dylib_command>.size))
        commandData.append(dylibPath.data(using: String.Encoding.ascii) ?? Data())
        commandData.append(Data(bytes: &zero, count: padding))
        
        let subrange = Range(NSRange(location: start, length: commandData.count))!
        newbinary.replaceSubrange(subrange, with: commandData)
        
        newbinary.replaceSubrange(machoRange, with: newHeaderData)
        
        handle(newbinary)
    }

}
