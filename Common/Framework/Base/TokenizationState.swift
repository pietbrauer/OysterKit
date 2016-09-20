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

internal var __anonymousStateCount:Int = 0

//
// XCode 6 Beta 3 Crashes if two protocols refer to each other, so turning this into a class for now
//
open class TokenizationState : CustomStringConvertible, Equatable /*StringLiteralConvertible*/ {
    var tokenGenerator : TokenCreationBlock?
    var id : String = ""
    var reference : String?
    var branches = Array<TokenizationState>() //All states that can be transitioned to
    
    
    func stateClassName()-> String {
        return "TokenizationState"
    }
    
    init(){
        __anonymousStateCount += 1
        id = "\(stateClassName())\(__anonymousStateCount)"
    }
    
    //
    // String Literal
    //
    open class func convertFromStringLiteral(_ value: String) -> TokenizationState {
        if let parsedState = OKStandard.parseState(value) {
            return parsedState
        }
        
        return TokenizationState()
    }
    
    open class func convertFromExtendedGraphemeClusterLiteral(_ value: String) -> TokenizationState {
        return TokenizationState.convertFromStringLiteral(value)
    }
    
    //If I have a branch that goes to a branch that goes nowhere....
    func flattenBranches(){
        if branches.count == 1 {
            if let _ = branches[0] as? Branch {
                branches = branches[0].branches
                //Keep trying
                flattenBranches()
            }
        }
        
        for branch in branches {
            _ = branch.flatten()
        }
    }
    
    func flatten()->TokenizationState{
        flattenBranches()
        return self
    }
    
    //
    // Manage storage of branches
    //
    open func branch(_ toStates: [TokenizationState]) -> TokenizationState {
        for state in toStates{
            branches.append(state)
        }
        
        return self
    }

    open func branch(_ toStates: TokenizationState...) -> TokenizationState {
        return branch(toStates)
    }


    
    //
    // As this method only calls branch, we can provide a concrete implementation here
    //
    open func sequence(_ ofStates: TokenizationState...) -> TokenizationState {
        sequence(ofStates)
        
        return self        
    }
    
    open func sequence(_ ofStates:[TokenizationState]){
        _ = branch(ofStates[0])
        for index in 1..<ofStates.count{
            _ = ofStates[index-1].branch(ofStates[index])
        }
    }

    func loopingStates()->[TokenizationState]{
        return [self]
    }
    
    //
    // Token creation
    //
    open func token(_ emitToken: String) -> TokenizationState {
        _ = token(){(state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
            let token = Token(name: emitToken, withCharacters: capturedCharacters)
            token.originalStringIndex = startIndex
            return token
        }
        
        return self
    }
    
    open func token(_ emitToken: Token) -> TokenizationState {
        _ = token(){(state:TokenizationState, capturedCharacters:String, startIndex:Int)->Token in
            let token = Token(name: emitToken.name, withCharacters: capturedCharacters)
            token.originalStringIndex = startIndex
            return token
        }
        
        return self
    }
    
    open func token(_ with: @escaping TokenCreationBlock) -> TokenizationState {
        tokenGenerator = with
        
        return self
    }
    
    open func clearToken()-> TokenizationState{
        tokenGenerator = nil
        return self
    }
    
    //
    // Output
    //
    func pseudoTokenNameSuffix()->String{
        if let token = tokenGenerator?(self,"",0){
            return "->"+token.name
        }
        return ""
    }
    
    func serializeStateArray(_ indentation:String, states:Array<TokenizationState>)->String{
        if states.count == 1 {
            return states[0].serialize(indentation)
        }
        var output = ""
        var first = true
        for state in states {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\n"
            output+=indentation+state.serialize(indentation)
        }
        
        return output
    }
    
    func serializeBranches(_ indentation:String)->String{
        if branches.count == 1  {
            return "."+branches[0].serialize(indentation)
        } else if (tokenGenerator != nil) {
            return pseudoTokenNameSuffix()
        } else if branches.count == 0 {
            return ""
        }
        
        
        var output = ".{"
        var first = true
        for branch in branches {
            if !first {
                output+=","
            } else {
                first = false
            }
            output+="\n"
            output+=indentation+branch.serialize(indentation)
        }
        return output+"}\n"
    }
    
    func serialize(_ indentation:String)->String{
        if (reference != nil) {
           return reference!+pseudoTokenNameSuffix()
        }
        return ""
    }

    open var description:String{
        return serialize("")
    }
    
    //
    // Object Life Cycle
    //
    internal func __copyProperities(_ from:TokenizationState){
        if (from.tokenGenerator != nil){
            _ = token(from.tokenGenerator!)
        }

        for branch in from.branches {
            _ = self.branch(branch.clone())
        }
        
        reference = from.reference
    }
    
    open func clone()->TokenizationState {
        let newState = TokenizationState()
        newState.__copyProperities(self)
        return newState
    }
    
    final func isEqualTo(_ otherState:TokenizationState)->Bool{
        return id == otherState.id
    }
    
    func scanBranches(_ operation:TokenizeOperation){
        let startPosition = operation.context.currentPosition
        
        for branch in branches {
            branch.scan(operation)
            
            //Potential bug: For exit states we may remain in this fixed position, but providing exit
            //states are at the end that could be OK
            //Did we move forward? If so we can leave
            if operation.context.currentPosition > startPosition{
                return
            }
        }
        
    }
    
    open func scan(_ operation : TokenizeOperation){
        scanBranches(operation)
    }
    
}

public func ==(lhs: TokenizationState, rhs: TokenizationState) -> Bool{
    return lhs.isEqualTo(rhs)
}

public func ==(lhs:[TokenizationState], rhs:[TokenizationState])->Bool{
    if lhs.count != rhs.count {
        return false
    }
    
    for i in 0..<rhs.count {
        if lhs[i] != rhs[i] {
            return false
        }
    }
    
    return true
}

public typealias   TokenCreationBlock = ((_ state:TokenizationState,_ capturedCharacteres:String,_ charactersStartIndex:Int)->Token)

/*

 TO-DO: Once you can over-ride extention provided definitions, pull scan() out of Tokenization STate and put it back here

*/
extension TokenizationState : EmancipatedTokenizer {
    
    func createToken(_ operation:TokenizeOperation,useCharacters:String?)->Token?{
        let useCharacters = (useCharacters != nil) ? useCharacters : operation.context.consumedCharacters
        if let token = tokenGenerator?(self, useCharacters!,operation.context.startPosition){
            return token
        }
        
        return nil
    }
    
    func emitToken(_ operation:TokenizeOperation,useCharacters:String?=nil){
        if let token = createToken(operation,useCharacters: useCharacters) {
            operation.token(token)
        }
    }
}


