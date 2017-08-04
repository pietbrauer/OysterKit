//
//  stateTestBranch.swift
//  OysterKit Mac
//
//  Created by Nigel Hughes on 03/07/2014.
//  Copyright (c) 2014 RED When Excited Limited. All rights reserved.
//

import XCTest
import OysterKit

class stateTestBranch: XCTestCase {
    let tokenizer = Tokenizer()

    func testBranch(){
        let branch = char("x").branch(char("y").token("xy"), char("z").token("xz"))
        _ = tokenizer.branch(branch, OKStandard.eot)
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }

    func testRepeatLoopEquivalence(){
        let seperator = Characters(from: ",").token("sep")

        let lettersWithLoop = LoopingCharacters(from:"abcdef").token("easy")
        let state = Characters(from:"abcdef").token("ignore")
        let lettersWithRepeat = Repeated(state: state).token("easy")

        let space = Characters(from: " ")
        let bracketedWithRepeat = Delimited(open: "(", close: ")", states: lettersWithRepeat).token("bracket")
        let bracketedWithLoop = Delimited(open: "(", close: ")", states: lettersWithLoop).token("bracket")

        _ = tokenizer.branch([
            bracketedWithLoop,
            seperator,
            space
        ])

        let underTest = Tokenizer()
        underTest.branch([
            bracketedWithRepeat,
            seperator,
            space])

        let testString = "(a),(b) (c)(e),(abc),(def) (fed)(aef)"
        
        let testTokens = underTest.tokenize(testString)
        let referenceTokens = tokenizer.tokenize(testString)
        
        assertTokenListsEqual(testTokens, reference: referenceTokens)
    }

    func testNestedBranch(){
        let branch = Branch(states: [char("x").branch(char("y").token("xy"), char("z").token("xz"))])
        _ = tokenizer.branch(branch)
        XCTAssert(tokenizer.tokenize("xyxz") == [token("xy"),token("xz")])
    }

    func testXY(){
        _ = tokenizer.sequence(char("x"),char("y").token("xy"))
        _ = tokenizer.branch(OKStandard.eot)
        
        XCTAssert(tokenizer.tokenize("xy") == [token("xy")], "Chained results do not match")
    }

    
    func testSequence1(){
        let expectedResults = [token("done",chars:"xyz")]
        
        _ = tokenizer.branch(
            sequence(char("x"),char("y"),char("z").token("done")),
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyz") == expectedResults)
    }

    func testSequence2(){
        let expectedResults = [token("done",chars:"xyz")]
        
        _ = tokenizer.branch(
            char("x").sequence(char("y"),char("z").token("done")),
            OKStandard.eot
        )
        
        XCTAssert(tokenizer.tokenize("xyz") == expectedResults)
    }
}
