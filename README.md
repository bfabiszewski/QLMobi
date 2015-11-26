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

[libmobi]: https://github.com/bfabiszewski/libmobi
[binary]: https://github.com/bfabiszewski/QLMobi/releases/latest
[qlmobi]: https://github.com/bfabiszewski/QLMobi
 
### Changelog
**0.2**  
Faster thumbnail generation  
Thumbnails for encrypted documents  
**0.1**  
Initial version

### License

Licensed under the [GNU Public License (GPL)](http://www.gnu.org/licenses/) version 3 or later.



