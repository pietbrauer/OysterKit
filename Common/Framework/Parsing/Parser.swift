/*
Copyright (c) 2014, RED When Excited
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/



import Foundation

protocol Parser{
    func parse(_ token:Token)->Bool
    func parseString(_ string:String, withTokenizer:Tokenizer)
}

open class StackParser:Parser{
    var symbolStack = Array<Token>()
    
    public init(){
        
    }
    
    open func pushToken(_ symbol: Token) {
        symbolStack.append(symbol)
    }
    
    open func topToken() -> Token? {
        if !hasTokens(){
            return nil
        }
        
        return symbolStack[symbolStack.endIndex-1]
    }
    
    open func popToken() -> Token? {
        if !hasTokens(){
            return nil
        }
        
        return symbolStack.removeLast()
    }
    
    open func hasTokens() -> Bool {
        return symbolStack.count != 0
    }
    
    open func tokens() -> Array<Token> {
        return symbolStack
    }
    
    open func parse(_ token: Token) -> Bool {
        pushToken(token)
        return true
    }
    
    open func parseString(_ string: String, withTokenizer: Tokenizer) {
        withTokenizer.tokenize(string,newToken:parse)
    }
}



