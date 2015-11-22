//
//  CharSequences.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 09/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public class Keywords : TokenizationState {
    override func stateClassName()->String {
        return "Keywords"
    }
    
    let validStrings : [String]
    
    public init(validStrings:Array<String>){
        self.validStrings = validStrings
        super.init()
    }
    
    public override func scan(operation: TokenizeOperation) {
        let completionsText = operation.context.consumedCharacters + String(operation.current)
        guard let _ = completions(completionsText) else { return }

        var didAdvance = false
        while let allCompletions = completions(operation.context.consumedCharacters + String(operation.current)) {
            if allCompletions.first == operation.context.consumedCharacters {
                emitToken(operation)
                scanBranches(operation)
            } else {
                operation.advance()
                didAdvance = true
            }
        }
        
        if (didAdvance){
            scanBranches(operation)
        }
    }
        
    func completions(string: String) -> [String]? {
        let allMatches = validStrings.filter({ $0.hasPrefix(string) })

        if allMatches.count == 0 {
            return nil
        } else {
            return allMatches
        }
    }
    
    
    override func serialize(indentation: String) -> String {
        
        var output = ""
        
        output+="["
        
        var first = true
        for keyword in validStrings {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\"\(keyword)\""
        }
        
        output+="]"
        
        return output+serializeBranches(indentation+"\t")
    }
    
    override public func clone() -> TokenizationState {
        let newState = Keywords(validStrings: validStrings)
        
        newState.__copyProperities(self)
        
        return newState
    }
}