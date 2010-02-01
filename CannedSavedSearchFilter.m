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
//  CannedSavedSearchFilter.m
//  TorchFS


#import "CannedSavedSearchFilter.h"


@implementation CannedSavedSearchFilter

+(void)setupFiltersWithFilterManager:(FilterManager*)theManager;
{
    NSString *file;
    NSString *docsDir = @"/System/Library/CoreServices/Finder.app/Contents/Resources/CannedSearches";
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:docsDir];
    FileFilter *aFilter;
    
    while (file = [dirEnum nextObject]) {
        if ([file isEqualToString:@"All Downloads.cannedSearch"])
            continue;   // this CannedSearch is broken under OS X 10.6.2
        if ([[file pathExtension] isEqualToString: @"cannedSearch"]) {
            NSLog(@"Adding %@", file);
            
            aFilter = [[self alloc] initWithPath:[NSString stringWithFormat:@"%@/%@", docsDir, file]];
            [theManager addFilter:aFilter];
            [aFilter release];
        }
    }
}

-(id)initWithPath:(NSString*)pathForCannedSearch;
{
    self = [super init];
    if (self != nil) {
        filterName_ = [[[[NSFileManager defaultManager] displayNameAtPath:pathForCannedSearch] stringByDeletingPathExtension] retain];
        
        savedSearch_ = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/search.savedSearch", pathForCannedSearch]];
        [savedSearch_ retain];
    }
    return self;
}

@end
