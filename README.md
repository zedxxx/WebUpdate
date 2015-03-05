WebUpdate
=========

WebUpdate is a bunch of code that can be included into any application to add some simple JSON based WebUpdate. The contained authoring tool allows to create snapshots with a single click. These snapshots can be copied to a dedicated location or uploaded to an FTP server. This can also be done automatically when taking a snapshot. Once uploaded the WebUpdate only needs a simple HTTP connection in order to perform a web update.

The tool was created after thinking about how a modern, lightweight web update tool could work without the need of an extra server (only file serving is required). It is not yet used and thus mostly untested beyond the used in the tool itself.

In order to use this tool in your project there are a few prerequisites. First the source code is licensed under a dual license of MPL or LGPL, which means you can use this either under the conditions of MPL or under the conditions of LGPL. Both have advantages and disadvantages, however the essence of these libraries is that you mention the use of this library and to allow integration of changes to the original project. If you need to license this under a different license, feel free to contact me.

Beyond the license, there are at least 3 dependencies to other libraries namely:
* [Virtual Treeview](http://www.jam-software.com/virtual-treeview/)
* [mORMot](http://synopse.info/)
* [Indy](http://www.indyproject.org/)

Please make sure you have these libraries accessible from your Delphi environment.

Command-line switches (Snapshot tool)
--------------------------------------

In case you want to automate the authoring tool, you can use the following command-line switches. In fact the tool will still be a GUI-tool, but with a hidden user interface, so don't expect any output of the tool. Following, all commands and options are listed: 

    Usage:                                                                     
        SnapshotTool.exe <Project.wup> Commands [Options]                       

    Arguments:                                                                 
        <Project.wup>           Your project file name                         
    
    Commands:                                                                  
        -h, --help              Print this help message and exit               
        -s, --snapshot          Take snapshot                                  
        -c, --copy              Copy to path                                   
        -u, --upload            Upload snapshot to server                      
    
    Options:                                                                   
        --channel=<name>        default: "Nightly"                             
        --ftp-host=<host>       FTP host name, overrides project's default    
        --ftp-user=<username>   FTP user name, overrides project's default    
        --ftp-pass=<password>   FTP password, overrides project's default     
        --copy-path=<path>      Path of snapshot copies                        
        --collect-files         Scan and add all new files                     
    
    Example:                                                                   
        SnapshotTool.exe MyProj.wup -scu --channel=Stable


Command-line switches (Updater)
-------------------------------

While the 'Updater' tool can be started as stand-alone tool, it is supposed to work as a helper for a main application. It is required because a running application can't replace itself.

    Usage:                                                                     
        Updater.exe --url=<url> --channels-file=<file> [Commands] [Options]

    Commands:                                                                  
        -h, --help              Print this help message and exit               

    Options:                                                                   
        --url=<url>             Base URL for JSON files                        
        --channel=<name>        Update Channel, default is "Stable"            
        --channels-file=<file>  Filename of channels definition file           
        --delay=<time>          Time in milliseconds before updating starts    
        --setup-file=<file>     Local filename of current setup                
        --app-exe-name=<name>   Name of main application executable            
        --app-caption=<caption> Caption of main application window             
    
    Example:                                                                   
        Updater.exe --url=http://test.com --channels-file=Channels.json
