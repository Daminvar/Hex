package {
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;

    public class Entity extends Sprite {
        private var handlers:Dictionary;

        public function Entity() {
            handlers = new Dictionary();
            addEvent(Event.REMOVED_FROM_STAGE, function(e:Event):void {
                removeListeners();
            });
        }

        public function onAdded(f:Function):void {
            addEvent(Event.ADDED_TO_STAGE, function(e:Event):void {
                f.call();
                removeEventListener(Event.ADDED_TO_STAGE, arguments.callee);
            });
        }

        public function onRemoved(f:Function):void {
            addEvent(Event.REMOVED_FROM_STAGE, function(e:Event):void {
                f.call();
            });
        }

        protected function addEvent(evt:String, f:Function):void {
            handlers[f] = evt;
            addEventListener(evt, f);
        }

        private function removeListeners():void {
            for (var key:Object in handlers) {
                var funcKey:Function = key as Function;
                removeEventListener(handlers[funcKey], funcKey);
            }
        }
    }
}
