//
//  ThePoster.swift
//  LDIO
//
//  Created by Eric Betts on 1/14/16.
//  Copyright © 2016 Eric Betts. All rights reserved.
//

import Foundation

enum FuncCirkleBrick : UInt16 {
    case Minifig = 0
    case VG = 1
}

class ThePoster {
    //There are two types of LD pieces: minifigs with 2x1 base, and unwritten bases for vehicles/gadgets that are 2x2.
    //I found that the vehicle/gadget ones are "6104392: Func. Cirkle Brick 4X4X2/3 No.1" http://brickset.com/parts/6104392
    //and the minifigs are "Func. Cirkle Brick 4X4X2/3 No.2" followed by a "No. XX" for each different minifig.

    static let Minifigs = [
    "<Placeholder>",
    "Batman",
    "Gandalf",
    "Wyldstyle",
    "Aquaman",
    "Bad Cop",
    "Bane",
    "Bart",
    "Benny",
    "Chell",
    "Cole",
    "Cragger",
    "Cyborg",
    "Cyberman",
    "Doc Brown",
    "The Doctor",
    "Emmet",
    "Eris",
    "Gimli",
    "Gollum",
    "Harley Quinn",
    "Homer",
    "Jay",
    "Joker",
    "Kai",
    "ACU",
    "Gamer Kid",
    "Krusty",
    "Laval",
    "Legolas",
    "Lloyd",
    "Marty Mcfly",
    "Nya",
    "Owen",
    "Peter Venkman",
    "Slimer",
    "Scooby Doo",
    "SenseiWu",
    "Shaggy",
    "Stay Puft",
    "Superman",
    "Unikitty",
    "Wicked Witch",
    "Wonder Woman",
    "Zane",
    "Green Arrow",
    "Super Girl"
    ]
}
