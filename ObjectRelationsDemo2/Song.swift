//
//  Song.swift
//  ObjectRelationsDemo
//
//  Created by Jeremy Petter on 2016-04-07.
//  Copyright © 2016 JeremyPetter. All rights reserved.
//

import Parse

class Song: PFObject {
    @NSManaged var name:String      // this is a value because it's just data
    @NSManaged var artist:Artist    // this is a reference becasue it's a pointer to an object

    convenience init(name:String) {
        self.init()
        self.name = name
    }
}

extension Song: PFSubclassing {
    static func parseClassName() -> String {
        return "Song"
    }
}