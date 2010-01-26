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
//  TorchFS_Filesystem.m
//  TorchFS
//
//  Based on SpotlightFS 
//  Copyright (C) 2007-2008 Google Inc.
//  Licensed under Apache License, Version 2.0
//

#import <sys/xattr.h>
#import <sys/stat.h>
#import "TorchFS_Filesystem.h"
#import <MacFUSE/MacFUSE.h>
#import "FileFilter.h"
#import "FilterManager.h"


// Category on NSError to  simplify creating an NSError based on posix errno.
@interface NSError (POSIX)
+(NSError *)errorWithPOSIXCode:(int)code;
@end
@implementation NSError (POSIX)
+(NSError *)errorWithPOSIXCode:(int)code 
{
  return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
}
@end

// The core set of file system operations. This class will serve as the delegate
// for GMUserFileSystemFilesystem. For more details, see the section on 
// GMUserFileSystemOperations found in the documentation at:
// http://macfuse.googlecode.com/svn/trunk/core/sdk-objc/Documentation/index.html
@implementation TorchFS_Filesystem

-(id)init;
{
    self = [super init];
    if (self != nil) {
        filterManager_ = [[FilterManager alloc] init];
    }
    return self;
}


-(void)dealloc;
{
    [filterManager_ release];
    filterManager_ = nil;
    
    [super dealloc];
}


-(NSString *)volumeName;
{
    return @"TorchFS";
}

#pragma mark -

// This class/object does not communicate directly with the file system.
// It only asks the FilterManager and the given FileFilter for contents,
// file attributes and so on.
// (only in resourceAttributesAtPath we are asking for an icon resource,
//  but this hardly counts...)

-(NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
{
    NSArray *components = [path pathComponents];    
    
    // the keys of the fileFilters_ dictionary are the top-level search folders...
    if ([components count] == 1) {
		NSArray *topLevelDirs = [filterManager_ topLevelDirectories];
		return topLevelDirs;
	}

    FileFilter *subFilter = [filterManager_ fileFilterForPath:path shouldStartSearch:YES];
	if (subFilter == nil) {
		// happens if asked for e.g. ".DS_Store" -> just ignore it
        *error = [NSError errorWithPOSIXCode:ENOENT];
        return nil;
    }

	// default case: path points to an item in the "smart folder"
    return [subFilter contentsOfDirectoryAtPath:path error:error];
}

-(NSDictionary *)attributesOfItemAtPath:(NSString *)path userData:(id)userData error:(NSError **)error 
{
    NSArray *components = [path pathComponents];    
	BOOL isTopLevelDir = ([components count] == 2);
	
	if ([components count] == 1) return nil;		// this is root

    FileFilter *subFilter = [filterManager_ fileFilterForPath:path shouldStartSearch:!isTopLevelDir];
    if (subFilter == nil) {
		// happens if asked for e.g. ".DS_Store" -> just ignore it
        *error = [NSError errorWithPOSIXCode:ENOENT];
        return nil;
    }

    if (isTopLevelDir) {
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:500], NSFilePosixPermissions,
                [NSNumber numberWithInt:geteuid()], NSFileOwnerAccountID,
                [NSNumber numberWithInt:getegid()], NSFileGroupOwnerAccountID,
                [NSDate date], NSFileCreationDate,
                [NSDate date], NSFileModificationDate,
                NSFileTypeDirectory, NSFileType,
                nil];
	}

	// default case: path points to an item in the "smart folder"
    return [subFilter attributesOfItemAtPath:path userData:userData error:error];
}


#pragma mark (Optional)

-(NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error;
{
    FileFilter *subFilter = [filterManager_ fileFilterForPath:path shouldStartSearch:YES];
    if (subFilter == nil) {
        *error = [NSError errorWithPOSIXCode:ENOENT];
        return nil;
    }

    return [subFilter destinationOfSymbolicLinkAtPath:path error:error];
}


-(NSDictionary *)finderAttributesAtPath:(NSString *)path error:(NSError **)error;
{
    NSArray *components = [path pathComponents];    
	BOOL isTopLevelDir = ([components count] == 2);

    if (isTopLevelDir && ([filterManager_ fileFilterForPath:path shouldStartSearch:NO] != nil)) {
		NSNumber* finderFlags = [NSNumber numberWithLong:kHasCustomIcon];
		return [NSDictionary dictionaryWithObject:finderFlags forKey:kGMUserFileSystemFinderFlagsKey];
	}
	
	return nil;
}

-(NSDictionary *)resourceAttributesAtPath:(NSString *)path error:(NSError **)error;
{
    NSArray *components = [path pathComponents];    
	BOOL isTopLevelDir = ([components count] == 2);

    if (isTopLevelDir && ([filterManager_ fileFilterForPath:path shouldStartSearch:NO] != nil)) {
		NSString *file = [[NSBundle mainBundle] pathForResource:@"SmartFolder" ofType:@"icns"];
		return [NSDictionary dictionaryWithObject:[NSData dataWithContentsOfFile:file] forKey:kGMUserFileSystemCustomIconDataKey];
	}
	
	return nil;
}

@end
