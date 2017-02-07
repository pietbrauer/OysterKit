//
//  TokenizeOperation.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 15/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import Foundation

public protocol EmancipatedTokenizer {
    func scan(_ operation:TokenizeOperation)
}

open class TokenizeOperation : CustomStringConvertible {
    open class Context : CustomStringConvertible {
        var tokens = [Token]()
        var consumedCharacters : String {
            let substring = __sourceString[__startIndex..<__currentIndex]

            return substring
        }

        let states : [TokenizationState]
        fileprivate let __sourceString : String

        fileprivate var __startIndex : String.Index
        fileprivate var __currentIndex : String.Index

        var startPosition : Int
        var currentPosition : Int

        fileprivate init(atPosition:Int, withMarker:String.Index, withStates:[TokenizationState], forString:String){
            __startIndex = withMarker
            __currentIndex = __startIndex
            __sourceString = forString

            startPosition = atPosition
            currentPosition = atPosition
            states = withStates
        }

        internal func flushConsumedCharacters(){
            __startIndex = __currentIndex
            startPosition = currentPosition
        }

        open var description : String {
            return "Started at: \(startPosition), now at: \(currentPosition), having consumed \(consumedCharacters) and holding \(tokens)"
        }
    }


    var  current : Character
    var  next : Character?

    var  scanAdvanced = false

    fileprivate var  __tokenHandler : (Token)->Bool
    fileprivate let  __startingStates : [TokenizationState]
    let  eot : Character = "\u{04}"
    fileprivate var  __marker : IndexingIterator<String.CharacterView> {
        didSet{
            scanAdvanced = true
        }
    }
    fileprivate var  __contextStack = [Context]()
    fileprivate var  __sourceString : String

    var  context : Context
    var  complete : Bool {
        return current == eot
    }

    open var description : String {
        var output = "Tokenization Operation State\n\tCurrent=\(current) Next=\(next) scanAdvanced=\(scanAdvanced) Complete=\(complete)\n"

        //Print the context stack
        for index in __contextStack.endIndex-1...0 {
            output+="\t"+__contextStack[index].description+"\n"
        }

        return output
    }

    //For now, to help with compatibility
    init(legacyTokenizer:Tokenizer){
        __sourceString = "\u{0004}"
        __marker = __sourceString.characters.makeIterator()
        current = __marker.next()!
        next = __marker.next()

        __startingStates = legacyTokenizer.branches
        __tokenHandler = {(token:Token)->Bool in
            print("No token handler specified")
            return false
        }

        context = Context(atPosition: 0, withMarker: "".startIndex, withStates: [], forString: "")
    }

    //
    // The primary entry point for the class, the token receiver will be called
    // whenever a token is published
    //
    open func tokenize(_ string:String, tokenReceiver : @escaping (Token)->(Bool)){
        __tokenHandler = tokenReceiver

        //Prepare string
        __sourceString = string
        __marker = __sourceString.characters.makeIterator()

        //Prepare stack and context
        __contextStack.removeAll(keepingCapacity: true)
        __contextStack.append(Context(atPosition: 0, withMarker:__sourceString.startIndex, withStates: __startingStates, forString:__sourceString))
        context = __contextStack[0]

        if let first = __marker.next() {
            current = first
            next = __marker.next()
        } else {
            return
        }

        scan(self)
    }

    //
    // Moves forward in the supplied string
    //
    open func advance(){
        if next != nil {
            current = next!
            next = __marker.next()
        } else {
            current = eot
        }

        context.__currentIndex = context.__currentIndex.successor(in: context.__sourceString)
        context.currentPosition += 1
    }

    open func token(_ token:Token){
        if !(token is Token.EndOfTransmissionToken) {
            context.tokens.append(token)
        }

        context.startPosition = context.currentPosition
        context.__startIndex = context.__currentIndex
    }


    fileprivate func __publishTokens(_ inContext:Context)->Bool{
        //Do we need to do this at all?
        if inContext.tokens.count == 0 {
            return true
        }

        for token in inContext.tokens {
            if !__tokenHandler(token){
                inContext.tokens.removeAll(keepingCapacity: true)
                return false
            }
        }

        inContext.tokens.removeAll(keepingCapacity: true)
        return true
    }

    open func pushContext(_ states:[TokenizationState]){
        //Publish any tokens before moving into the new state
        _ = __publishTokens(context)

        let newContext = Context(atPosition: context.currentPosition, withMarker:context.__currentIndex, withStates: states, forString:__sourceString)
        __contextStack.append(newContext)
        context = newContext
    }


    open func popContext(_ publishTokens:Bool=true){
        let publishedTokens = publishTokens && context.tokens.count > 0

        if publishTokens {
            _ = __publishTokens(context)
        }

        if __contextStack.count == 1 {
            return
        }

        let poppedState = __contextStack.removeLast()
        context = __contextStack[__contextStack.count-1]

        //If we didn't publish tokens merge in the new characters parsed so far
        if !publishedTokens {
            _ = __sourceString[context.__currentIndex..<poppedState.__currentIndex]
            _ = poppedState.consumedCharacters
        }

        //Update the now current context with the progress achieved by the popped state
        context.currentPosition = poppedState.currentPosition
        context.__currentIndex = poppedState.__currentIndex
    }
}

extension TokenizeOperation : EmancipatedTokenizer {
    public func scan(_ operation:TokenizeOperation) {

        scanAdvanced = true

        while scanAdvanced && !complete {
            scanAdvanced = false

            //Scan through our branches
            for tokenizer in context.states {
                tokenizer.scan(operation)
                if scanAdvanced {
                    break
                }
            }

            //TODO: I would like this to be tidier. Feels wierd in the main loop, I don't like that not
            //issuing a token doesn't get you failure, don't like
            //If I am my own state
            if __contextStack.count == 1 {
                context.startPosition = context.currentPosition
                context.__startIndex = context.__currentIndex
                _ = __publishTokens(context)
            }
        }
    }
}

extension String.Index{
    func successor(in string:String)->String.Index{
        return string.index(after: self)
    }

    func predecessor(in string:String)->String.Index{
        return string.index(before: self)
    }

    func advance(_ offset:Int, `for` string:String)->String.Index{
        return string.index(self, offsetBy: offset)
    }
}
