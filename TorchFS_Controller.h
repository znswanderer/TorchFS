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
//  TorchFS_Controller.h
//  TorchFS
//
//  Based on SpotlightFS 
//  Copyright (C) 2007-2008 Google Inc.
//  Licensed under Apache License, Version 2.0
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@class GMUserFileSystem;
@class TorchFS_Filesystem;

@interface TorchFS_Controller : NSObject {
    GMUserFileSystem* fs_;
    TorchFS_Filesystem* fs_delegate_;
}




@end
