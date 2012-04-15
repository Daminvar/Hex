package {
    import com.junkbyte.console.Cc;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class Tile extends Entity {
        private var _color:int;
        private var _initColor:int;
        private var _sizeFactor:int;

        public var neighbors:Vector.<Tile>;
        public var occupier:Player = Player.NEITHER;

        public function Tile(sizeFactor:int, color:int) {
            _sizeFactor = sizeFactor;
            _color = color;
            _initColor = color;
            initListeners();
            draw();
        }

        private function initListeners():void {
            addEventListener(MouseEvent.MOUSE_OVER, onOver);
            addEventListener(MouseEvent.MOUSE_OUT, onOut);
        }

        public function take(p:Player):void {
            occupier = p;
            draw();
            var prevColor:int = _initColor;
            var firstTime:Boolean = true;
            stage.addEventListener(TurnEvent.CHANGE_TURN, function onChange(e:*):void {
                if(firstTime) {
                    _initColor = _color = Util.interpolateColor(_color, 0xaabbff, 0.7);
                    draw();
                    firstTime = false;
                    return;
                }
                _initColor = _color = prevColor;
                draw();
                removeEventListener(TurnEvent.CHANGE_TURN, onChange);
            });
        }

        private function onOver(e:MouseEvent):void {
            if(occupier != Player.NEITHER)
                _color = Util.interpolateColor(_color, 0xff0000, 0.4);
            else
                _color = Util.interpolateColor(_color, 0xffffff, 0.5);
            draw();
            e.updateAfterEvent();
        }

        private function onOut(e:MouseEvent):void {
            _color = _initColor;
            draw();
            e.updateAfterEvent();
        }

        private function draw():void {
            graphics.clear();
            var points:Array = [1,2,3,4,5,6].map(function(num:Number, index:int, v:*):Point {
                return new Point(
                    _sizeFactor * Math.cos(num * 2 * Math.PI / 6),
                    _sizeFactor * Math.sin(num * 2 * Math.PI / 6));
            });

            graphics.lineStyle(2, Util.interpolateColor(_color, 0x000000, 0.2));
            graphics.beginFill(_color);
            graphics.moveTo(points[0].x, points[0].y);
            for(var i:int = 1; i < points.length; i++) {
                graphics.lineTo(points[i].x, points[i].y);
            }
            graphics.endFill();

            if(occupier != Player.NEITHER) {
                graphics.lineStyle(1, 0x888888);
                graphics.beginFill(occupier == Player.WHITE ? 0xffffff : 0x000000);
                graphics.drawCircle(0, 0, _sizeFactor * 0.7);
                graphics.endFill();
            }
        }
    }
}
