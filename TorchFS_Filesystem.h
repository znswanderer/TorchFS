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
//  TorchFS_Filesystem.h
//  TorchFS
//
//  Based on SpotlightFS 
//  Copyright (C) 2007-2008 Google Inc.
//  Licensed under Apache License, Version 2.0
//

#import <Foundation/Foundation.h>
#import "TorchFS_Filesystem.h"

@class FilterManager;

// The core set of file system operations. This class will serve as the delegate
// for GMUserFileSystemFilesystem. For more details, see the section on 
// GMUserFileSystemOperations found in the documentation at:
// http://macfuse.googlecode.com/svn/trunk/core/sdk-objc/Documentation/index.html
@interface TorchFS_Filesystem : NSObject  {
    NSMutableDictionary *fileFilters_;

    FilterManager *filterManager_;

}

-(NSString *)volumeName;



@end
