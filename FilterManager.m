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
//  FilterManager.m
//  TorchFS

#import "FilterManager.h"
#import "FileFilter.h"
#import "CannedSavedSearchFilter.h"
#import "UserSavedSearchFilter.h"

@implementation FilterManager

- (id) init
{
    self = [super init];
    if (self != nil) {
        fileFilters_ = [[NSMutableDictionary alloc] init];
		[self setupFilters];
		
		// subscribe to NSWorkspace for wake up events
		NSNotificationCenter *wsnc = [[NSWorkspace sharedWorkspace] notificationCenter];
		[wsnc addObserver:self selector:@selector(workspaceDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
    }
    return self;
}

- (void) dealloc
{
	[fileFilters_ release];
	fileFilters_ = nil;
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	
	[super dealloc];
}

- (void)workspaceDidWakeUp:(NSNotification *)notification;
{
	NSLog(@"voiding all queries");
	
	NSArray *allFilters = [fileFilters_ allValues];
	
	NSUInteger i, count = [allFilters count];
	for (i = 0; i < count; i++) {
		FileFilter *aFilter = (FileFilter*)[allFilters objectAtIndex:i];
		[aFilter stopSearch];
	}
}



-(NSArray*)topLevelDirectories;
{
    return [fileFilters_ allKeys];
}

-(FileFilter*)fileFilterForPath:(NSString*)path shouldStartSearch:(BOOL)startSearch;
{
    NSArray *components = [path pathComponents];    
    if ([components count] < 2) return nil;
    
    FileFilter *theFilter = [fileFilters_ objectForKey:[components objectAtIndex:1]];
	// path has suffix @"\r" if MacFUSE asks for the Icon -> we do not want to start 
	// the search in this case.
	if (theFilter && ![path hasSuffix:@"\r"] && startSearch) {
		[theFilter performSelectorOnMainThread:@selector(resetTimer) withObject:nil waitUntilDone:NO];
		if (![theFilter didStartSearch]) {
			// somehow the search has to be started on the main thread
			// This might be due to the NSNotificationCenter or the MDQuery.
			[theFilter performSelectorOnMainThread:@selector(startSearch) withObject:nil waitUntilDone:NO];
		}
	}
    return theFilter;
}

-(void)addFilter:(FileFilter*)aFilter;
{
    [fileFilters_ setObject:aFilter forKey:[aFilter filterName]];
}

-(void)setupFilters;
{
	[CannedSavedSearchFilter setupFiltersWithFilterManager:self];
	[UserSavedSearchFilter setupFiltersWithFilterManager:self];
}


@end
