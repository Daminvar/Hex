package {
    import flash.events.Event;

    public class TurnEvent extends Event {
        public static const CHANGE_TURN:String = "onChangeTurn";
        public static const GAME_OVER:String = "onGameOver";
        public static const PIECE_SET:String = "onPieceSet";
        public var player:Player;

        public function TurnEvent(type:String, p:Player) {
            this.player = p;
            super(type, true, false);
        }
    }
}
