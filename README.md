# Video Merge

---------

This is a sample implementation for merging multiple video files using AVFoundation, fixed orientatiuon issues. The project is written in Swift 5.

It's a sample that can merge several video clips into one screen. Please take a look at the Example projet to see how to use this it.

----------

```
	videoMerger.merge { [weak self] session in
            
        guard session.status == .completed, let outputURL = session.outputURL else { return }

	    if PHPhotoLibrary.authorizationStatus() != .authorized {
    	    PHPhotoLibrary.requestAuthorization({ status in
        	    if status == .authorized {
            	    self.saveToPhotoLibrary(url: outputURL)
            	}
        	})
    	}
    }
```