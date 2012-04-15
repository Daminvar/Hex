package {
    import mx.core.UIComponent;

    public class GameContainer extends UIComponent {
        private var _game:Entity;

        public function GameContainer() {
            _game = new Main(Player.NEITHER);
            addChild(_game);
            percentHeight = 100;
        }

        override protected function measure():void {
            measuredWidth = measuredMinWidth = _game.width;
            measuredHeight = measuredMinHeight = _game.height;
        }

        public function reset(p:Player):void {
            if(_game != null)
                removeChild(_game);
            _game = new Main(p);
            addChild(_game);
        }
    }
}
