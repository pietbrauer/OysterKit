//
//  Exit.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 14/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

open class Exit : TokenizationState {
    
    public override init(){
        super.init()
    }
    
    override func serialize(_ indentation: String) -> String {
        return "^"+pseudoTokenNameSuffix()
    }
    
    open override func scan(_ operation: TokenizeOperation) {
        emitToken(operation)
    }
}
