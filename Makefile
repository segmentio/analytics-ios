

clean:
	rm -rf AnalyticsPodApp

setup:
	cp AnalyticsPodAppCode/AppDelegate.m AnalyticsPodApp/AnalyticsPodApp/
	cp AnalyticsPodAppCode/ViewController.m AnalyticsPodApp/AnalyticsPodApp/
	cp AnalyticsPodAppCode/Main*.* AnalyticsPodApp/AnalyticsPodApp/en.lproj/
	cp AnalyticsPodAppCode/Podfile AnalyticsPodApp/
	
	cd AnalyticsPodApp; pod install

	open AnalyticsPodApp/AnalyticsPodApp.xcworkspace