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
//  FileFilter.m
//  TorchFS
//
//  Based on SpotlightFS 
//  Copyright (C) 2007-2008 Google Inc.
//  Licensed under Apache License, Version 2.0
//

#import "FileFilter.h"
#import	"TorchFSDefines.h"

@implementation FileFilter

+(void)setupFiltersWithFilterManager:(FilterManager*)theManager;
{	
	// defined by concrete subclasses
}



-(void)dealloc
{
	[self stopSearch];
	
    droppedPathComponents_ = nil;
	[filterName_ release];
    filterName_ = nil;
	[savedSearch_ release];
	savedSearch_ = nil;
	
    [super dealloc];
}

- (NSMutableDictionary *)pathContainer {
    return [[pathContainer_ retain] autorelease];
}

- (void)setPathContainer:(NSMutableDictionary *)value {
	BOOL selectFirstItem = NO;
	
    if (pathContainer_ != value) {
		if (!pathContainer_) selectFirstItem = YES;
        [pathContainer_ release];
        pathContainer_ = [value copy];
		
		if (value != nil) {
			[droppedPathComponents_ release];
			droppedPathComponents_ = [[self calculatePathStart:value] retain];
		}
    }
	
	// if we do an initial "insert" of Spotlight results 
	// select them in the Finder
	if (selectFirstItem && (value != nil)) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:kTSFileFilterDidInitialInsert object:self];
	}
}

- (NSArray *)droppedPathComponents;
{
	if (droppedPathComponents_)
		return [[droppedPathComponents_ copy] autorelease];
	else
		return [NSArray array];
}

- (BOOL)didStartSearch;
{
    return didStartSearch_;
}

- (void)startSearch;
{
    if (didStartSearch_) return;
    didStartSearch_ = YES;
    
    if (query_) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        CFRelease(query_);
        query_ = NULL;
    }
	
	NSString *queryString = [savedSearch_ objectForKey:@"RawQuery"];
    query_ = MDQueryCreate(kCFAllocatorDefault, (CFStringRef)queryString, NULL, NULL);
    if (query_){
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(gatherData:) name:(NSString*)kMDQueryDidFinishNotification object:(id)query_];
		[nc addObserver:self selector:@selector(liveUpdateData:) name:(NSString*)kMDQueryDidUpdateNotification object:(id)query_];									
		
		MDQuerySetSearchScope(query_, (CFArrayRef)[NSArray arrayWithObject:(id)kMDQueryScopeHome], 0);
		MDQueryExecute(query_, kMDQueryWantsUpdates);
		NSLog(@"Started search for filter \"%@\"", [self filterName]);
    } else {
		NSLog(@"Could not create MDQuery for filter \"%@\"", [self filterName]);
	}
}

- (void)stopSearch;
{
	NSLog(@"stopping search for %@", [self filterName]);
    if (query_) {
		MDQueryDisableUpdates(query_);
        [[NSNotificationCenter defaultCenter] removeObserver:self];
		MDQueryStop(query_);
		
        CFRelease(query_);
        query_ = NULL;
    } 
	didStartSearch_ = NO;

	[self setPathContainer:nil];
	
	if ([queryStopTimer_ isValid]) [queryStopTimer_ invalidate];
	[queryStopTimer_ release];
	queryStopTimer_ = nil;
}

// A timeout will tell this FileFilter if the query is not needed any more
// as the user did not use this specific filter for some time.
#define QUERYSLEEPTIME 300.0		// after this time (in seconds) the query will stop 
- (void)resetTimer;
{
	if (queryStopTimer_) {
		if ([queryStopTimer_ isValid]) [queryStopTimer_ invalidate];
		[queryStopTimer_ release];
	}
	queryStopTimer_ = [NSTimer scheduledTimerWithTimeInterval:QUERYSLEEPTIME target:self selector:@selector(timerStopQuery:) userInfo:nil repeats:NO];
	// the documentation is not clear (?) if the runloop retains the time,
	// so for safety we retain it. (very likely this is unnecessary)
	[queryStopTimer_ retain];  
}

- (void)timerStopQuery:(NSTimer*)theTimer;
{
	[self performSelectorOnMainThread:@selector(stopSearch) withObject:nil waitUntilDone:NO];
}

- (void)liveUpdateData:(NSNotification *)aNotification;
{
	MDQueryDisableUpdates(query_);
	
	NSDictionary *argDict = [[aNotification userInfo] copy];
	[self performSelectorOnMainThread:@selector(adjustPathContainer:) withObject:argDict waitUntilDone:NO];
	[argDict release];
	
	MDQueryEnableUpdates(query_);
}

- (void)adjustPathContainer:(NSDictionary*)argDict;
{
    if (!query_) {
        NSLog(@"%@ adjustPathContainer:%@, trying to update without query",
			  [self filterName], argDict);
        return;
    }
	
	MDQueryDisableUpdates(query_);
	NSMutableDictionary *dir0 = [self pathContainer];
	
	// Add new items from addedItems and changedItems.
	// We have to start with an empty array and not the result of 
	// [argDict objectForKey:(NSString*)kMDQueryUpdateAddedItems] because this 
	// might be nil and then in the following step we would not be able to add 
	// [argDict objectForKey:(NSString*)kMDQueryUpdateChangedItems] to nil.
	NSArray *addedItems = [NSArray array];
	addedItems = [addedItems arrayByAddingObjectsFromArray:[argDict objectForKey:(NSString*)kMDQueryUpdateAddedItems]];
	addedItems = [addedItems arrayByAddingObjectsFromArray:[argDict objectForKey:(NSString*)kMDQueryUpdateChangedItems]];

	NSUInteger i, count = [addedItems count];
	for (i = 0; i < count; i++) {
		MDItemRef addedItem = (MDItemRef)[addedItems objectAtIndex:i];
		NSString *path = (NSString*)MDItemCopyAttribute(addedItem, kMDItemPath);
		if (path) {
			addPathToDir(path, dir0);
			[path release];
		} 
	}
	
	// remove items...
	NSArray *removedItems = [argDict objectForKey:(NSString*)kMDQueryUpdateRemovedItems];
	count = [removedItems count];
	for (i = 0; i < count; i++) {
		MDItemRef removedItem = (MDItemRef)[removedItems objectAtIndex:i];
		NSString *path = (NSString*)MDItemCopyAttribute(removedItem, kMDItemPath);
		if (path) {
			removePathFromDir(path, dir0);
			[path release];
		} 
	}
	
	MDQueryEnableUpdates(query_);
	[self setPathContainer:dir0];
}

- (void)removeFromPathContainer:(NSString*)path;
{
    if (path) {
        NSMutableDictionary *dir0 = [self pathContainer];
        removePathFromDir(path, dir0);
       	[self setPathContainer:dir0];
    }
}

- (NSString*)filterName;
{
    return [[filterName_ retain] autorelease];
}


#define GRANUM 5000
- (void)gatherData:(NSNotification *)notification
{
	MDQueryDisableUpdates(query_);
	
    NSLog(@"Search finished for filter \"%@\"", [self filterName]);
    
    NSMutableDictionary *dir0 = getRoot();
    
    MDItemRef item;
    NSString *path;
	long i;
	long itemCount = MDQueryGetResultCount(query_);
    NSLog(@"found: %d", itemCount);
	
    for (i=0; i<itemCount; i++) {
        if ((i+1)%GRANUM == 0) {
            NSLog(@"commit: %d", i);
			[self setPathContainer:dir0];
        }
		item = (MDItemRef)MDQueryGetResultAtIndex(query_, i);
        path = (NSString*)MDItemCopyAttribute(item, kMDItemPath);
        if (path != NULL) {
			// it can happen that MDQuery retrieves NULL paths
			// if it happens, just ignore it
            addPathToDir(path, dir0);
            [path release];
        }
	}
    
    [self setPathContainer:dir0];
    
	MDQueryEnableUpdates(query_);
	[self performSelectorOnMainThread:@selector(resetTimer) withObject:nil waitUntilDone:NO];
}

// get the beginning of the "interesting" directories.
// This means if we only have files in /User/user1/ and its
// subdirectories, this method will calculate the common
// root of all files. In this case /User/user1/
// The common root is at max the user's home directory

-(NSMutableArray*)calculatePathStart:(NSMutableDictionary*)dir;
{
    NSMutableArray *droppedComponents = [[NSMutableArray alloc] init];
    [droppedComponents addObject:@"/"];
	
    NSArray *contents = listPathInDir(@"/", dir);
    while ([contents count] == 1) {
        [droppedComponents addObject:[contents objectAtIndex:0]];
		NSString *droppedpath = [NSString pathWithComponents:droppedComponents];
		if ([droppedpath isEqualToString:NSHomeDirectory()]) break;
        contents = listPathInDir(droppedpath, dir);
    }
	
	return [droppedComponents autorelease];
}

// get the real location on the filesystem where the path 
// in TorchFS points to
-(NSString*)realPath:(NSString*)path;
{
    NSMutableArray *components = [[path pathComponents] mutableCopy];
    [components removeObjectsInRange:NSMakeRange(0, 2)];
    path = [NSString pathWithComponents:[droppedPathComponents_ arrayByAddingObjectsFromArray:components]];
    [components release];
    
    return path;
}

#pragma mark MacFUSE methods for this specific filter

- (BOOL)isResourcePath:(NSString*)path;
{
    if ([[path lastPathComponent] hasPrefix:@"._"])
        return YES;
    else 
        return NO;
}



// Unfortunately Spotlight will only tell us *that* a file is moved
// and *where* its new location is, but it will not tell us *wherefrom*
// the file has been moved.
//
// (To see: Try moving a file with 'mv' after it has been found in a given
// directory A to a new directory B. Spotlight will only tell in the
// kMDQueryUpdateChangedItems notification its new location B)
//
// Therefore in order to removed moved files from old directories in
// the TorchFS file tree we have to scan the physical representation
// of a TorchFS directory and adjust it if any file is missing.

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error 
{
    if ([self pathContainer] == nil) return [NSArray arrayWithObject:NSLocalizedString(@"Please wait!",)];
    
	NSString *realPath = [self realPath:path];
	NSArray *dir = listPathInDir(realPath, [self pathContainer]);
	
	// get the content of the physical representation
	// and compare it to the stored files in the pathContainer
	// (the contents of the path in the path container must be a subset
	//  of the contents of the real path)
	NSError *someError = nil;
	NSArray *realContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:realPath error:&someError];
	if (realContents) {
		NSSet *realSet = [NSSet setWithArray:realContents];
		NSMutableSet *torchSet = [NSMutableSet setWithArray:dir];
		
		[torchSet minusSet:realSet];
		// get rid of the surplus files in the path container...
		if ([torchSet count] != 0) {			
			NSArray *missingPaths = [torchSet allObjects];
			NSUInteger i, count = [missingPaths count];
			for (i = 0; i < count; i++) {
				NSString *fileName = (NSString*)[missingPaths objectAtIndex:i];
				[self performSelectorOnMainThread:@selector(removeFromPathContainer:) withObject:[realPath stringByAppendingPathComponent:fileName] waitUntilDone:NO];
			}
		}
	} else {
		NSLog(@"FileFilter \"%@\": error at contentsOfDirectoryAtPath: %@\nerror: %@",
			  [self filterName], path, someError);
		return nil;
	}
	
	return dir;
}

// helper method:
// Return the real location of path on the hard drive
// Return nil if (for various reasons) there is no real path
// for the TorchFS path.
// The boolean isDir will be NO for file packages.
//
// In Snow Leopard maybe a better way to code this would
// be code blocks?
// (http://www.mikeash.com/?page=pyblog/friday-qa-2008-12-26.html )
- (NSString*)checkedRealPath:(NSString*)path isDir:(BOOL*)isDir;
{
    if ([self pathContainer] == nil) return nil;
    
    NSString *realPath = [self realPath:path];
    if ([self isResourcePath:realPath]) {
        return nil;
    }
	
	if (listPathInDir(realPath, [self pathContainer]) == nil) {
		// this happens if it's been asked for icons, resources etc...
		// just ignore it
		return nil;
	}
	if (![[NSFileManager defaultManager] fileExistsAtPath:realPath isDirectory:isDir]) return nil;
	
	return realPath;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path userData:(id)userData error:(NSError **)error 
{
	BOOL isDir;
	NSString *realPath = [self checkedRealPath:path isDir:&isDir];
	if (realPath == nil) return nil;
    
	NSMutableDictionary *res = [[[[NSFileManager defaultManager] attributesOfItemAtPath:realPath error:error] mutableCopy] autorelease];
    if (!res) res = [[[NSMutableDictionary dictionary] retain] autorelease];
	if (!isDir || [[NSWorkspace sharedWorkspace] isFilePackageAtPath:realPath]) 
			[res setObject:NSFileTypeSymbolicLink forKey:NSFileType];
	
	return res;
}

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error;
{
	BOOL isDir;
	NSString *realPath = [self checkedRealPath:path isDir:&isDir];
	if (realPath == nil) return nil;

	if (isDir && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:realPath]) return nil;
    
	return realPath;
}

@end
