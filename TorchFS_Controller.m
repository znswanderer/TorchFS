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
//  TorchFS_Controller.m
//  TorchFS
//
//  Based on SpotlightFS 
//  Copyright (C) 2007-2008 Google Inc.
//  Licensed under Apache License, Version 2.0
//


#import "TorchFS_Controller.h"
#import "TorchFS_Filesystem.h"
#import <MacFUSE/MacFUSE.h>
#import "TorchFSDefines.h"
#import "FileFilter.h"

@implementation TorchFS_Controller

- (void)mountFailed:(NSNotification *)notification 
{
    NSDictionary* userInfo = [notification userInfo];
    NSError* error = [userInfo objectForKey:kGMUserFileSystemErrorKey];
    NSLog(@"kGMUserFileSystem Error: %@, userInfo=%@", error, [error userInfo]);  
    NSRunAlertPanel(@"Mount Failed", [error localizedDescription], nil, nil, nil);
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)didMount:(NSNotification *)notification 
{
    NSDictionary* userInfo = [notification userInfo];
    NSString* mountPath = [userInfo objectForKey:kGMUserFileSystemMountPathKey];
    NSString* parentPath = [mountPath stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] selectFile:mountPath inFileViewerRootedAtPath:parentPath];
}

- (void)didUnmount:(NSNotification*)notification 
{
    NSLog(@"didUnmount!");
    //[[NSApplication sharedApplication] terminate:nil];
    // exit is better as it kills the spotlight search thread
    exit(0);
}


- (void)fileFilterUpdate:(NSNotification*)notification;
{
	FileFilter *theFilter = (FileFilter*)[notification object];
	NSString *filterPath = [NSString pathWithComponents:[NSArray arrayWithObjects:@"/", 
														 [theFilter filterName], 
														 nil]];

	NSError *anError = nil;
	NSArray *contents = [theFilter contentsOfDirectoryAtPath:filterPath error:&anError];
	if ([contents count] > 0) {
		contents = [contents sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		NSArray *paths = [NSArray arrayWithObjects:@"/", 
						  @"Volumes", 
						  [fs_delegate_ volumeName], 
						  [theFilter filterName],
						  [contents objectAtIndex:0],
						  nil];
					  
		[[NSWorkspace sharedWorkspace] selectFile:[NSString pathWithComponents:paths] inFileViewerRootedAtPath:@""];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(mountFailed:) name:kGMUserFileSystemMountFailed object:nil];
    [center addObserver:self selector:@selector(didMount:) name:kGMUserFileSystemDidMount object:nil];
    [center addObserver:self selector:@selector(didUnmount:) name:kGMUserFileSystemDidUnmount object:nil];
	
	[center addObserver:self selector:@selector(fileFilterUpdate:) name:kTSFileFilterDidInitialInsert object:nil];

    fs_delegate_ = [[TorchFS_Filesystem alloc] init];
    fs_ = [[GMUserFileSystem alloc] initWithDelegate:fs_delegate_ isThreadSafe:YES];
    
    NSMutableArray* options = [NSMutableArray array];
    NSString* volArg = [NSString stringWithFormat:@"volicon=%@", [[NSBundle mainBundle] pathForResource:[fs_delegate_ volumeName] ofType:@"icns"]];
    [options addObject:volArg];
    [options addObject:[NSString stringWithFormat:@"volname=%@", [fs_delegate_ volumeName]]];
    [options addObject:@"rdonly"];
    [fs_ mountAtPath:[NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"Volumes", [fs_delegate_ volumeName], nil]] withOptions:options];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fs_ unmount];
    [fs_ release];
    [fs_delegate_ release];
    return NSTerminateNow;
}




@end
