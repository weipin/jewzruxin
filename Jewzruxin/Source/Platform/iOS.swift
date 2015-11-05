import Foundation

public class NetworkActivityIndicator {
    var count = 0

    static let sharedInstance = NetworkActivityIndicator()

    func increase() {
        ++self.count;
        if 1 == self.count {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
        }
    }

    func decrease() {
        --self.count;
        if 0 == self.count {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false;
        }
    }
}