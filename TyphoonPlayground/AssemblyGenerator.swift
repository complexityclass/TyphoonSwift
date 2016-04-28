//
//  AssemblyGenerator.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 19/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

struct Replacement {
    var range: Range<Int>! = 0..<0
    var string: String! = ""
}

class FileGenerator
{
    let indentStep = "    "
    
    var file :FileDefinition!
    
    convenience init(file: FileDefinition) {
        self.init()
        self.file = file
    }
    
    func generate(to outputPath :String)
    {
        var outputBuffer = ""
     
        outputBuffer += "import Foundation"

        for assembly in file.assemblies {
            outputBuffer += generateAssembly(assembly)
        }
    
        outputBuffer += "\n\n// Extensions\n"
        for assembly in file.assemblies {
            outputBuffer += "\n"
            outputBuffer += generateAssemblyExtension(assembly)
        }
        
        outputBuffer += generateActivation(file.assemblies)
    
        do {
            try outputBuffer.writeToFile(outputPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Failed writing to path")
        }
        
    }
    
    func generateActivation(assemblies: [AssemblyDefinition]) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "\n\n// Umbrella activation\n"
        outputBuffer += "extension Typhoon {\n"
        outputBuffer += indentStep + "class func activateAssemblies() {\n"
        for assembly in assemblies {
            outputBuffer += indentStep + indentStep + "\(assembly.name).assembly \n"
        }
        outputBuffer += indentStep + "}\n"
        outputBuffer += "}"
        
        return outputBuffer
    }
    
    func generateAssembly(assembly: AssemblyDefinition) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "\n\nclass \(assemblyImplClassName(assembly)) : ActivatedAssembly { \n"
        
        for method in assembly.methods {
            outputBuffer += generateMethod(method, indent: indentStep)
        }
        
        outputBuffer += generateSingletones(fromMethods: assembly.methods)

        
        outputBuffer += "}"

        return outputBuffer
    }
    
    func generateSingletones(fromMethods methods:[MethodDefinition]) -> String
    {
        var output = ""
        
        var methodNames : [String] = []
        
        for method in methods {
            if method.returnDefinition.scope == Definition.Scope.Singletone {
                if method.numberOfRuntimeArguments() == 0 {
                    methodNames.append(method.returnDefinition.key)
                }
            }
        }
        
        output += "\n" + indentStep + "override func singletones() -> [()->(Any)]\n"
        output += indentStep + "{\n"
        output += indentStep + indentStep + "return [" + methodNames.joinWithSeparator(", ") + "]\n"
        output += indentStep + "}\n"
        
        
        return output
    }
    
    func assemblyImplClassName(assembly: AssemblyDefinition) ->String
    {
        return "\(assembly.name)Implementation"
    }
    
    func generateAssemblyExtension(assembly: AssemblyDefinition) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "extension \(assembly.name) {\n"
        outputBuffer += indentStep + "class var assembly :\(assemblyImplClassName(assembly)) {\n"
        outputBuffer += indentStep + indentStep + "get {\n"
        outputBuffer += indentStep + indentStep + indentStep + "struct Static {\n"
        outputBuffer += indentStep + indentStep + indentStep + "static var onceToken: dispatch_once_t = 0\n"
        outputBuffer += indentStep + indentStep + indentStep + "static var instance: \(assemblyImplClassName(assembly))? = nil\n"
        outputBuffer += indentStep + indentStep + "}\n"
        outputBuffer += indentStep + indentStep + "dispatch_once(&Static.onceToken) {\n"
        outputBuffer += indentStep + indentStep + indentStep + "Static.instance = \(assemblyImplClassName(assembly))()\n"
        outputBuffer += indentStep + indentStep + "}\n"
        outputBuffer += indentStep + indentStep + "return Static.instance!\n"
        outputBuffer += indentStep + indentStep + "}\n"
        outputBuffer += indentStep + "}\n"
        outputBuffer += "}\n"
        
        return outputBuffer
    }
    
    func generateMethod(method: MethodDefinition, indent: String) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "\n\(indent)func \(method.name) -> \(method.returnDefinition.className!) { "
        
        let insideIndent = indent + indentStep
        
        outputBuffer += "\n\(insideIndent)"
        
        outputBuffer += "return " + generateInstance(method.returnDefinition, indent: insideIndent)
        
        outputBuffer += "\n"
        
        outputBuffer += "\(indent)}\n"
        
        return outputBuffer
    }
    
    func trimEmptyLines(inout string: String)
    {
        var lines: [String] = []
        string.enumerateLines { line, _ in lines.append(line) }
        
        
        string = lines.filter{!$0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty}.joinWithSeparator("\n")
    }

    
    func generateInstance(definition: InstanceDefinition, indent: String) -> String
    {
        var outputBuffer = ""
        
        let scope = "Definition.Scope.\(definition.scope)"
        
        if definition.propertyInjections.count > 0 {
            let insideIndent = indent + indentStep
            outputBuffer += "component(\(definition.className!)(), key: \"\(definition.key)\", scope: \(scope), configure: { instance in \n"
            outputBuffer += generatePropertyInjections(definition.propertyInjections, ivar: "instance", indent: insideIndent)
            outputBuffer += "\(indent)})"
        } else {
            outputBuffer.appendContentsOf("component(\(definition.className!)(), key: \"\(definition.key)\", scope: \(scope))")
        }
        
        return outputBuffer
    }
    
    func generatePropertyInjections(injections: [PropertyInjection], ivar: String, indent: String) -> String
    {
        var outputBuffer = ""
        for injection in injections {
            outputBuffer += "\(indent)\(generatePropertyInjection(injection, ivar: ivar))\n"
        }
        return outputBuffer
    }
    
    func generatePropertyInjection(injection: PropertyInjection, ivar: String) -> String
    {
        return "\(ivar).\(injection.propertyName) = \(injection.injectedValue)"
    }
    
    private func replace(inout inside buffer: String, replacements: [Replacement]) {
        let replaceBuffer = replacements.sort { a, b in
            return a.range.startIndex > b.range.startIndex
        }
        for replacement in replaceBuffer {
            let startIndex = buffer.startIndex.advancedBy(replacement.range.startIndex)
            let endIndex = buffer.startIndex.advancedBy(replacement.range.endIndex)
            
            let indexRange = startIndex..<endIndex
            
            buffer.replaceRange(indexRange, with: replacement.string)
        }
        
    }
}