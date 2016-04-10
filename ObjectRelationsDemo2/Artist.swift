//
//  Artist.swift
//  ObjectRelationsDemo
//
//  Created by Jeremy Petter on 2016-04-07.
//  Copyright © 2016 JeremyPetter. All rights reserved.
//

import Parse

class Artist: PFObject {
    @NSManaged var name:String  // this is a value; it's a kind of data

    var songs:PFRelation {                              // this is a PFRelation, a collection of references to MULTIPLE objects
        return relationForKey(Song.parseClassName())    // we could also write this as `relationForKey("Song")`
    }

    convenience init(name:String) {
        self.init()
        self.name = name
    }
}

extension Artist: PFSubclassing {
    static func parseClassName() -> String {
        return "Artist"
    }
}