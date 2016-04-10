//
//  AppDelegate.swift
//  ObjectRelationsDemo2
//
//  Created by Jeremy Petter on 2016-04-07.
//  Copyright © 2016 JeremyPetter. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        setupParse()

        // Start of demo code

        // Assigning objects to the properties of other objects is a bit more complicated than just assigning data to those properties.
        // In casese like this, we say that one object references another object. Check out `Artist.swift` and `Song.swift` to see the
        // the objects I'm using. They are PFObject subclasses

        let taylor = Artist(name: "Taylor Swift")                               // When we crete relationships between objects,
                                                                                // we need to save them both separately

        let never = Song(name: "We Are Never Ever Getting Back Together")   // `name` is a value. It is automatically saved with our song.
        never.artist = taylor                                               // `artist` is a reference because it points to another object.
                                                                            // It can only point to an object that's ALSO saved to Parse
        let mean = Song(name: "Mean")
        mean.artist = taylor

        taylor.saveInBackgroundWithBlock { (success, error) in                  // The closure is not fired until after taylor is saved,
            if success {                                                        // so we know we can safely save `taylor` to the properties
                print("`taylor` saved")                                         // of the songs that follow, then save them
                never.saveInBackgroundWithBlock({ (success, error) in
                    if success {
                        print("`never` saved")
                        mean.saveInBackgroundWithBlock({ (success, error) in    // Because the rest of our code requires these objects to be
                            if success {                                        // saved, we're using sequential blocks to ensure things happen
                                print("`mean` saved")                           // in order.

                                self.printNameOfArtistForSong(never)            // See line 62
                                self.printNamesOfSongsForArtist(taylor)         // See line 91

                                self.printNameOfArtistForSongName("Mean")               // See line 117
                                self.printNamesOfSongsForArtistName("Taylor Swift")     // See line 130

                                self.demoPFRelations()                          // See line 146
                            }
                        })
                    }
                })
            }
        }
        return true
    }

    // This is a ONE-TO-MANY relationship: many songs can reference one (and only one) artist:

    // 1. We can find the artist for a song by looking at the song's `artist` property

    func printNameOfArtistForSong(song:Song) {

        // When we download an object from Parse, its values are downloaded automatically, but the objects that it references are not.
        // Just like we had to save objects separately, we have to download them separately, too.

        // This means that sometimes, we can have a reference to an object that has not been actually been downloaded. You'll see this happen
        // shortly. For now, the important thing is `fetchIfNeededInBackgroundWithBlock(PFObject?, NSError?)` checks if our reference is a real
        // object and downloads it if it isn't.

        song.fetchIfNeededInBackgroundWithBlock{ (fetchedObject, error) in
            if let fetchedSong = fetchedObject as? Song {                   // Again, because Parse objects are always downloaded as PFObjects
                                                                            // we need to convert them to Songs before we can use them.
                print("Artist for \(fetchedSong.name) is:")                 // This will work: `name` is a value so it's downloaded with our song.

                /* print(fetchedSong.artist.name) */                        // This will not work if artist was just fetched, because artist is
                                                                            // a refernce and hasn't been downloaded. We need to fetch it first.
                fetchedSong.artist.fetchIfNeededInBackgroundWithBlock{ (fetchedArtistObject, error) in
                    if let fetchedArtist = fetchedArtistObject as? Artist {
                        print(fetchedArtist.name)                           // This, finally, will work.
                    }
                }
            }
        }
    }

    // 2. We can find the songs for a particular artist by making query for songs, and filtering by artist

    func printNamesOfSongsForArtist(artist:Artist) {
        let songClassName = Song.parseClassName()                           // For our PFObject subclasses, like Song, we can use the
        let query = PFQuery(className:songClassName)                        // `parseClassName()` method to get the correct class name.
                                                                            // This prevents typos.

        query.whereKey("artist", equalTo: artist)                           // Parse checks this on its servers, so we can pass an object OR a
                                                                            // reference. We don't need to download `artist` first.

        query.findObjectsInBackgroundWithBlock { (results, error) in
            if let songs = results as? [Song] {
                /* print("songs for \(artist.name):") */                    // This, though, will NOT work if `artist` is a reference: to use its
                                                                            // data, we do need to fetch it.
                artist.fetchIfNeededInBackgroundWithBlock({ (artistObject, error) in
                    if let artist = artistObject as? Artist {
                        print("songs for \(artist.name):")                  // Now, this will work!
                    }
                })
                for song in songs {
                    print(song.name)
                }
            }
        }
    }

    // Of course, the above methods only work if we already have references to the objects we want to look for.
    // If we don't, we need to query for them first:

    func printNameOfArtistForSongName(name:String) {
        let songQuery = PFQuery(className: Song.parseClassName())               // get the song we want the artist for with a query...
        songQuery.whereKey("name", equalTo: name)
        songQuery.getFirstObjectInBackgroundWithBlock { (songObject , error) in // we can use `getFirstObject...` if we know we know there is only one
            if let song = songObject as? Song {
                self.printNameOfArtistForSong(song)                             // we can call our other method, now that we have a song
            }
        }
    }

    // (Artists work the same way)

    func printNamesOfSongsForArtistName(name:String) {
        let artistQuery = PFQuery(className: Artist.parseClassName())
        artistQuery.whereKey("name", equalTo: name)
        artistQuery.getFirstObjectInBackgroundWithBlock { (artistObject , error) in
            if let artist = artistObject as? Artist {
                self.printNamesOfSongsForArtist(artist)
            }
        }
    }

    // If we want to be able to create a MANY TO MANY relationship between artists and songs (becasue some songs will have multiple artists)
    // then we need to be able to attach multiple songs to each artist, and multiple artists to each song. I've done half of this, buy adding
    // a `PFRelation` property called `songs` to my Artist class. To see how to implement it, go to `Artist.swift`. PFRelations act a bit like arrays

    func demoPFRelations() {

        let kendrick = Artist(name: "Kendrick Lamar")
        kendrick.saveInBackgroundWithBlock { (success, error) in
            let i = Song(name: "i")
            let badBlood = Song(name: "Bad Blood")

            kendrick.songs.addObject(i)         // unlike the `artist` property, for `Song`, we can add multiple songs to `songs` with
            kendrick.songs.addObject(badBlood)  // PFRelation's `addObject(PFObject)`

            i.saveInBackgroundWithBlock({ (success, error) in
                if success {
                    print("saved 'i'")
                    badBlood.saveInBackgroundWithBlock({ (success, error) in
                        if success {
                            print("saved 'badBlood'")
                            kendrick.saveInBackgroundWithBlock({ (success, error) in
                                if success {
                                    print("saved kendrick")

                                    self.printNamesOfSongsForArtistUsingPFRelation(kendrick) // Sew line 178
                                }
                            })
                        }
                    })
                }
            })
        }
    }

    // Getting information from a PFRelation is pretty similar to what we've already done:

    func printNamesOfSongsForArtistUsingPFRelation(artist:Artist) {
        artist.fetchIfNeededInBackgroundWithBlock { (artistObject, error) in    // first, `fetchIfNeeded` to make sure we have a real object...
            if let artist = artistObject as? Artist {                           // ... then, make sure the object we got back is the type it should be
                print("songs by \(artist.name):")

                let query = artist.songs.query()                                // PFRelations have a method called `query` that creates a PFQuery
                query.findObjectsInBackgroundWithBlock({ (results, error) in    // for all the objects they point to, so we don't need to create it
                    if let songs = results as? [Song] {                         // ourselves.
                        for song in songs {
                            print(song.name)
                        }
                    }
                })
            }
        }
    }

// End of demo code
        

    
    func setupParse() {
        
        // We covered this last class

    Parse.setApplicationId("PZzGTD8UFGZlKQLmHyeMxxGI2FYvFp7XlQAnNisZ", clientKey: "8RRx1K4yII8EEf01u1008PqwKcRZLttM7CPFNxP9")

    Artist.registerSubclass()
    Song.registerSubclass()
}


}

