/*
This class serves as a singleton to hold the instance of SmartFox
with static functions to access it from any class
*/
package {
    import com.smartfoxserver.v2.SmartFox;
    
    public class SFSConnector {
        private static var _sfs:SmartFox;
        
        public static function get connection():SmartFox {
            if (_sfs == null) _sfs = new SmartFox();
            return _sfs;
        }

        public static function set connection(anSFS:SmartFox):void {
            if (_sfs == null) _sfs = anSFS;
        }
        
        public static function get isInitialized():Boolean {
            return _sfs != null; 
        }
        
        
    }
}
