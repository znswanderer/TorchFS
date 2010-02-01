// ================================================================
// Copyright (C) 2009-2010 Tim Scheffler
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ================================================================
//
//  pathContainer.m
//  TorchFS
//


#include "pathContainer.h"

// Originally this has been a Haskell library. This is the reason
// why the pathContainer API is somewhat less object oriented.
// Just think of a pathContainer as an opaque data type, which
// just happens to be implemented as a NSMutableDictionary.
// For now I will keep this non-OOP API, because I might switch
// back to the Haskell implementation in the future. And this
// part of TorchFS is small enough, such that its non-OOP
// character does not has too much a weight.

#pragma mark API

NSMutableDictionary *getRoot()
{
    return makeDir([NSMutableArray arrayWithObject:@"/"]);
}

void addPathToDir(NSString *path, NSMutableDictionary *dir)
{
    NSMutableArray *paths = [[[path pathComponents] mutableCopy] autorelease];
    addPathsToDir_(paths, dir);
}

void removePathFromDir(NSString *path, NSMutableDictionary *dir)
{
    NSMutableArray *paths = [[[path pathComponents] mutableCopy] autorelease];
    removePathFromDir_(paths, dir);
}

NSArray *listPathInDir(NSString *path, NSMutableDictionary *dir)
{
    NSMutableArray *paths = [[[path pathComponents] mutableCopy] autorelease];
    return listPathsInDir_(paths, dir);
}

#pragma mark Implementation

void addPathsToDir_(NSMutableArray *pathArray, NSMutableDictionary *dir)
{
    if ([pathArray count] == 0) return;
    
    NSString *path = [pathArray objectAtIndex:0]; [pathArray removeObjectAtIndex:0];
    
    NSMutableDictionary *subDir = [dir objectForKey:path];
    if (subDir != nil) 
        addPathsToDir_(pathArray, subDir);
    else 
        [dir setObject:makeDir(pathArray) forKey:path];
}

void removePathFromDir_(NSMutableArray *pathArray, NSMutableDictionary *dir)
{
    if ([pathArray count] == 0) return;
    
    NSString *path = [pathArray objectAtIndex:0]; [pathArray removeObjectAtIndex:0];
    
    NSMutableDictionary *subDir = [dir objectForKey:path];
    if (subDir != nil) {
        removePathFromDir_(pathArray, subDir);
        if ([[subDir allKeys] count] == 0) {
            // if we deleted the subdir completely also delete it from this
            // directorys key list
            [dir removeObjectForKey:path];
        }
    } // else: do nothing. We do not have to delete a directory we cannot find!
}

NSMutableDictionary *makeDir(NSMutableArray *pathArray)
{
    if ([pathArray count] == 0) return [NSMutableDictionary dictionary];
    
    NSString *path = [pathArray objectAtIndex:0]; [pathArray removeObjectAtIndex:0];
    
    return [NSMutableDictionary dictionaryWithObject:makeDir(pathArray) forKey:path];
}

NSArray *listPathsInDir_(NSMutableArray *pathArray, NSDictionary *dir)
{
    if ([pathArray count] == 0) return [dir allKeys];
    
    NSString *path = [pathArray objectAtIndex:0]; [pathArray removeObjectAtIndex:0];
    
    NSDictionary *subDir = [dir objectForKey:path];
    if (subDir != nil) return listPathsInDir_(pathArray, subDir);
    
    return nil;
}
