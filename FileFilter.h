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
//  FileFilter.h
//  TorchFS
//
//  Based on SpotlightFS 
//  Copyright (C) 2007-2008 Google Inc.
//  Licensed under Apache License, Version 2.0
//


#import <Cocoa/Cocoa.h>
#import "pathContainer.h"
#import "FilterManager.h"


@interface FileFilter : NSObject {
    NSMutableDictionary *pathContainer_;
	MDQueryRef query_;    
    NSMutableArray *droppedPathComponents_;
    
	NSString *filterName_;
	NSDictionary *savedSearch_;

    BOOL didStartSearch_;
	
	NSTimer *queryStopTimer_;
}

+ (void)setupFiltersWithFilterManager:(FilterManager*)theManager;


- (NSMutableDictionary *)pathContainer;
- (void)setPathContainer:(NSMutableDictionary *)value;
- (void)adjustPathContainer:(NSDictionary*)argDict;
- (void)removeFromPathContainer:(NSString*)path;

- (void)gatherData:(NSNotification *)notification;
- (void)liveUpdateData:(NSNotification *)aNotification;
-(NSMutableArray*)calculatePathStart:(NSMutableDictionary*)dir;


- (void)startSearch;
- (void)stopSearch;
- (void)resetTimer;
- (void)timerStopQuery:(NSTimer*)theTimer;
- (BOOL)queryDidNotRunBefore;


- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path userData:(id)userData error:(NSError **)error;
- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)isResourcePath:(NSString*)path;

- (NSString*)realPath:(NSString*)path;

- (BOOL)didStartSearch;

- (NSString*)filterName;
- (NSString*)checkedRealPath:(NSString*)path isDir:(BOOL*)isDir;
- (NSArray *)droppedPathComponents;


@end
