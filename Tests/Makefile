

clean:
	rm -rf TestPodApp
	rm -rf TestApp

setup:
	cp TestAppCode/AppDelegate.m TestApp/TestApp/
	cp TestAppCode/ViewController.m TestApp/TestApp/
	cp TestAppCode/Main*.* TestApp/TestApp/en.lproj/

	open TestApp/TestApp.xcodeproj

setuppod:
	cp TestAppCode/AppDelegate.m TestPodApp/TestPodApp/
	cp TestAppCode/ViewController.m TestPodApp/TestPodApp/
	cp TestAppCode/Main*.* TestPodApp/TestPodApp/en.lproj/
	cp TestAppCode/Podfile TestPodApp/
	
	cd TestPodApp; pod install

	open TestPodApp/TestPodApp.xcworkspace