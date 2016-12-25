[![Travis status](https://travis-ci.org/bfabiszewski/QLMobi.svg?branch=master)](https://travis-ci.org/bfabiszewski/QLMobi)

## Quick Look plugin for Kindle ebook formats

QLMobi plugin supports various ebook formats used on kindle readers. It is based on [libmobi] and works with all the formats supported by the library: `prc`, `mobi`, `azw`, `azw3`, `azw4` and some `pdb` files. The plugin will generate a thumbnail, based on document embedded cover, and a preview for its content.

### Installation

Place the plugin file: [QLMobi.qlgenerator][binary] into `~/Library/QuickLook/` folder to install it for your account, or into `(Macintosh HD)/Library/QuickLook/` folder to install it for all users. If the folder does not exist, create it manually. 

### Building

Source code is available on [github][qlmobi]. It is bundled as an Xcode project and depends on the [libmobi] library. 

### Screenshots
![Finder preview](http://www.mobileread.com/forums/attachment.php?attachmentid=143433&d=1446545022)
![Finder thubmnails](http://www.mobileread.com/forums/attachment.php?attachmentid=143432&d=1446545022)


### Troubleshooting
 
If the plugin doesn't work:
- reload plugins running `qlmanage -r` from the console;  
- try reinstalling the plugin;
- try in the top level `Library` folder instead of the user's one;
- go to github [issues] tab, start new issue describing your problem, you may also provide output of the command: `qlmanage -d 4 -p -o /tmp /path/to/your/test.mobi`.

### Changelog
**0.5**  
Minor workaround for plugin failing to register handled file types  
Include minor fixes from current libmobi  
**0.4**  
Hide broken image links in corrupt documents   
**0.3**  
Minor changes to use improved libmobi metadata interface   
Rebuilt with libmobi 0.3   
**0.2**  
Faster thumbnail generation  
Thumbnails for encrypted documents  
**0.1**  
Initial version

### License

Licensed under the [GNU Public License (GPL)](http://www.gnu.org/licenses/) version 3 or later.


[libmobi]: https://github.com/bfabiszewski/libmobi
[binary]: https://github.com/bfabiszewski/QLMobi/releases/latest
[qlmobi]: https://github.com/bfabiszewski/QLMobi
[issues]: https://github.com/bfabiszewski/QLMobi/issues
