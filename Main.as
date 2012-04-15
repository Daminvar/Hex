package {
    import com.junkbyte.console.Cc;

    import flash.text.*;

    import com.smartfoxserver.v2.SmartFox;
    import com.smartfoxserver.v2.core.SFSEvent;
    import com.smartfoxserver.v2.entities.*;
    import com.smartfoxserver.v2.entities.data.*;
    import com.smartfoxserver.v2.requests.*;

    public class Main extends Entity {
        private var _board:Board;
        private var _message:TextField;
        private var _player:Player;
        private var sfs:SmartFox;

        public function Main(player:Player) {
            Cc.log("Player (from main):", player);
            try {
                sfs = SFSConnector.connection;
                _player = player;
                initBoard();
                initMessageDisplay();
                initNetworking();
            } catch(e:Error) {
                Cc.error(e);
            }
        }

        private function initBoard():void {
            _board = new Board(20, 9, _player);
            _board.y = 100;
            addChild(_board);
        }

        private function initMessageDisplay():void {
            _message = new TextField();
            _message.scaleX = _message.scaleY = 2;
            _message.text = "Waiting for white to start";
            _message.selectable = false;
            _message.autoSize = TextFieldAutoSize.LEFT;
            _message.x = 10;
            _message.y = 10;
            addChild(_message);
            setChildIndex(_message, 0); //Don't overlap the board.
            addEventListener(TurnEvent.CHANGE_TURN, onTurn);
            addEventListener(TurnEvent.GAME_OVER, function(e:TurnEvent):void {
                if(e.player == _player) {
                    _message.text = "You won!";
                } else {
                    if(_player != Player.NEITHER)
                        _message.text = "You lost...";
                    else
                        _message.text = e.player == Player.WHITE ?
                            "White won!" : "Black won!";
                }
                disableBoard();
            });
        }

        private function disableBoard():void {
            _board.mouseEnabled = false;
            _board.mouseChildren = false;
            removeEventListener(TurnEvent.CHANGE_TURN, onTurn);
        }

        private function initNetworking():void {
            sfs.addEventListener(SFSEvent.OBJECT_MESSAGE, function(e:SFSEvent):void {
                Cc.log("Received message");
                var obj:ISFSObject = e.params.message as SFSObject;
                var index:int = obj.getInt("index");
                var player:Player = obj.getBool("white") ?
                    Player.WHITE : Player.BLACK;
                _board.takeTile(index, player);
                //Only spectators need to check this
                if(_player == Player.NEITHER)
                    _board.checkForVictory();
                _board.checkForOpponentVictory();
            });
            sfs.addEventListener(SFSEvent.USER_EXIT_ROOM, function(e:SFSEvent):void {
                Cc.log(e.params.user.name, "left from", e.params.room.name);
                if(e.params.room.name == "The Lobby")
                    return;
                if(_board.mouseEnabled == false)
                    return; //Hacky way to prevent spectators from seeing the wrong thing
                var name:String = e.params.user.name;
                var whiteName:String = sfs.lastJoinedRoom.getVariable("white").getStringValue();
                var blackName:String = sfs.lastJoinedRoom.getVariable("black").getStringValue();
                var winnerName:String = _player != Player.NEITHER ?
                    "You" : (name == whiteName ? whiteName : blackName);
                if(name == whiteName || name == blackName) {
                    _message.text = winnerName + " won by default";
                    disableBoard();
                }
            });
        }

        private function onTurn(e:TurnEvent):void {
            if(sfs.lastJoinedRoom == "The Lobby")
                return; //The black player just entered.
            var turnString:String = e.player == Player.WHITE ? "white" : "black";
            var parenName:String = e.player == _player ?
                "You" : sfs.lastJoinedRoom.getVariable(turnString).getStringValue();
            if(e.player == Player.WHITE)
                _message.text = "White's turn (" + parenName + ")";
            else
                _message.text = "Black's turn (" + parenName + ")";
        }
    }
}
