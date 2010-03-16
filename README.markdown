# TorchFS -- A filter for your files and folders

TorchFS displays your folder *structure* filtered by your search criteria. This helps 
to manage large amounts of files on the Mac.

*For example:* You want to focus on stuff that happened in 2010 on your computer. 
TorchFS filters the given folder structure ("Documents", "Pictures", "Music", ...)
and only displays entries, that have seen some action in 2010, dropping older stuff 
from the focus. 

!["A normal finder view of an user's home folder"](http://timscheffler.com/images/Blog/2010-01-21/finder_without_torchFS.png)  
This is a picture of an example user home folder. You see a lot of folders that might 
be a bit older and that take up the user's attention without need.

!["A finder view of an user's home folder, but filtered for files of 2010"](http://timscheffler.com/images/Blog/2010-01-21/finder_with_torchFS.png)  
Here you see the same home folder, but this time TorchFS has filtered out all
unnecessary folders, which helps to focus on the folders that are relevant in 2010.


## Raison d'être

Computers get more powerful by the year and the amount of files we store on them gets
bigger and bigger. You probably have files as old as 10 years (or even older) stored
somewhere in the hierarchy of your home folder. All this stuff wont go away, hopefully. 
But we need an efficient way to deal with this abundance of information.

My personal story is, that sometime in 2009 I noticed that my "Documents" folder had grown 
to a size that was unmanageable for me: it contained documents from several years and -- as I
am a lazy person -- it had no deeper folder structure inside the "Documents" folder. 
So I decided to try the next best thing and started to create subfolders called 2009, 2008,
2007 and so on and moved the stuff to these subfolders. 

But after some weeks I got tired of this chore and remembered that I had a computer,
that is more than able to do this boring work for me. And my computer could not
only categorize my stuff by years, but by using Spotlight it was able to apply any
criteria to a collection of files that I needed. This was basically the idea behind TorchFS: to 
move away from *manual* work of categorizing my files and to leave this work to the computer.


## Behind the scenes: Spotlight and MacFUSE

TorchFS works by using Apple's Spotlight search engine and Google's [MacFUSE][macfuse] 
user-space filesystem framework. TorchFS creates a Spotlight query and displays the 
found files in their original folder hierarchy in a virtual filesytem provided by MacFUSE.
This way no new folders or files are created on your hard-drive. In fact the files 
are not touched at all, but TorchFS will display a virtual file alias that will take
you to the original file.

TorchFS builds on the SpotlightFS file system, which is part of the standard MacFUSE distribution
by Google, but extends its functionality to preserve the original folder structure of the 
found results.


## Differences to the standard Spotlight result window

The Finder can display the results of a Spotlight query, called "smart folder", in 
any of its view options, but not in the hierarchical view, that can be used for "normal"
folders. If you want to know the location of a smart folder item you have to click on it
and its location will be displayed at the bottom of the Finder window.

This way you lose much of the original meta-structure that could help you to tell the
relevance of the found item in the context of other files. 

Additionally the normal Finder view of a smart folder usually gives you too many
results for a broad query like "2009": too much files to get a good overview of what
happened last year.

These two points are solved with TorchFS.

## How to get TorchFS

First of all: Please remember, that this is a **beta** release. So this version
might contain bugs and if you decide to use TorchFS you will do so *at your own risk!* 

In order to use TorchFS you first have to install MacFUSE: Please go to the [MacFUSE][macfuse] 
website and follow the instructions for installing.

After you have installed MacFUSE, just download and unpack the zip-file containing the TorchFS app.
This file can be found [here][torchFS_download]. 

To start TorchFS just double-click it. It will present some basic system smart folders like "All Documents" along with your own smart folders as TorchFS folder (Please consult you Mac's help system 
on how to construct smart folders). If you like you can drag these TorchFS folders to your 
Finder's "Places" shortcuts menu for easy access. (In order to see new smart folders in TorchFS you 
have to restart the TorchFS.app)

TorchFS is Open Source and its source can be accessed via the [github][github] page.

## Why "Torch"?

Why this name? I wanted to keep a reference to Spotlight in the name. And
a torch only illuminates a very small area and it can be used to follow a path. Just
like the path through the folder structure. But on the other hand, it's just a name.

## Updates

Please follow the TorchFS twitter [feed][twitter] for updates!



[macfuse]: http://code.google.com/p/macfuse/
[torchFS_download]: http://www.timscheffler.com/downloads/TorchFS.zip
[twitter]: http://twitter.com/TorchFS
[github]: http://github.com/tscheff/TorchFS