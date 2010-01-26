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
//  pathContainer.h
//  TorchFS
//

#import <Cocoa/Cocoa.h>

NSMutableDictionary *getRoot();
void addPathToDir(NSString *path, NSMutableDictionary *dir);
NSArray *listPathInDir(NSString *path,NSMutableDictionary *dir);
void removePathFromDir(NSString *path, NSMutableDictionary *dir);

void addPathsToDir_(NSMutableArray *pathArray, NSMutableDictionary *dir);
void removePathFromDir_(NSMutableArray *pathArray, NSMutableDictionary *dir);
NSMutableDictionary *makeDir(NSMutableArray *pathArray);
NSArray *listPathsInDir_(NSMutableArray *pathArray, NSDictionary *dir);

