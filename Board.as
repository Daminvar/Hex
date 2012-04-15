package {
    import com.junkbyte.console.Cc;
    import flash.events.MouseEvent;

    import com.smartfoxserver.v2.SmartFox;
    import com.smartfoxserver.v2.core.SFSEvent;
    import com.smartfoxserver.v2.entities.*;
    import com.smartfoxserver.v2.entities.variables.*;
    import com.smartfoxserver.v2.entities.data.*;
    import com.smartfoxserver.v2.requests.*;

    public class Board extends Entity {
        private var _boardSize:int;
        private var _lastMove:int;
        private var _player:Player;
        private var _tileSize:int;
        private var _tiles:Vector.<Tile>;
        private var _turn:Player;
        private var sfs:SmartFox;

        public function get lastMove():int { return _lastMove; }

        public function Board(tileSize:int, boardSize:int, player:Player) {
            sfs = SFSConnector.connection;
            _player = player;
            _tileSize = tileSize;
            _boardSize = boardSize;
            initTiles();
            rotation -= 30;
            initConnections();
            addEventListener(MouseEvent.CLICK, onClicked);
            onAdded(function():void {
                //White starts
                _turn = Player.WHITE;
                dispatchEvent(new TurnEvent("onChangeTurn", Player.WHITE));
            });
        }

        private function initTiles():void {
            _tiles = new Vector.<Tile>();
            for(var i:int = 0; i < _boardSize * _boardSize; i++) {
                var color:int = 0x999999;
                if(i % _boardSize == 0 || i % _boardSize == _boardSize - 1)
                    color = 0x444444;
                if(i < _boardSize || i > _boardSize * _boardSize - _boardSize)
                    color = 0xdddddd;
                if(i == 0
                    || i == _boardSize - 1
                    || i == _boardSize * _boardSize - 1
                    || i == _boardSize * _boardSize - _boardSize)
                    color = 0x777777;
                var tile:Tile = new Tile(_tileSize, color);
                _tiles.push(tile);
                tile.x = tile.width / 2 + (i % _boardSize) * tile.height * (Math.sqrt(3) / 2);
                tile.y = tile.height / 2 * int(i % _boardSize) + int(i / _boardSize) * tile.height;
                addChild(tile);
            }
        }

        private function initConnections():void {
            for(var i:int = 0; i < _tiles.length; i++) {
                var neighbors:Vector.<Tile> = new Vector.<Tile>();
                //If you're not in the first row
                if(i - _boardSize >= 0) {
                    neighbors.push(_tiles[i - _boardSize]);
                    if(i % _boardSize != _boardSize - 1)
                        neighbors.push(_tiles[i - _boardSize + 1]);
                }
                //If you're not in the last row
                if(i + _boardSize < _tiles.length) {
                    neighbors.push(_tiles[i + _boardSize]);
                    if(i % _boardSize != 0)
                        neighbors.push(_tiles[i + _boardSize - 1]);
                }
                //If you're not on the left edge
                if(i % _boardSize != 0)
                    neighbors.push(_tiles[i - 1]);
                //If you're not on the right edge
                if(i % _boardSize != _boardSize - 1)
                    neighbors.push(_tiles[i + 1]);
                _tiles[i].neighbors = neighbors;
            }
        }

        private function onClicked(e:MouseEvent):void {
            Cc.log("Turn:", _turn, "Player:", _player);
            if(_turn != _player)
                return;
            var clickedTile:Tile = e.target as Tile;
            if(clickedTile.occupier != Player.NEITHER)
                return;
            _lastMove = _tiles.indexOf(clickedTile);
            clickedTile.take(_turn);
            checkForVictory();
            updateNetwork();
            changeTurn();
            e.updateAfterEvent();
        }

        private function updateNetwork():void {
            var data:ISFSObject = new SFSObject();
            data.putInt("index", _lastMove);
            data.putBool("white", _turn == Player.WHITE);
            sfs.send(new ObjectMessageRequest(data));
            Cc.log("Sent object message.");
        }

        public function takeTile(i:int, p:Player):void {
            if(p == Player.NEITHER) {
                Cc.error("Cannot set a tile to be NEITHER");
                return;
            }
            _tiles[i].take(p);
            changeTurn();
        }

        public function checkForVictory():void {
            //Actionscript's terrible Vector implementation makes this harder
            //than it needs to be.
            var tiles:Array = new Array();
            for(var a:int; a < _tiles.length; a++)
                tiles.push(_tiles[a]);
            var isOver:Boolean = tiles.filter(function(t:Tile, i:*, arr:*):Boolean {
                if(_turn == Player.WHITE)
                    return i < _boardSize && t.occupier == Player.WHITE;
                else
                    return i % _boardSize == 0 && t.occupier == Player.BLACK;
            }).map(function(t:Tile, i:*, arr:*):Boolean {
                var explored:Vector.<Tile> = new Vector.<Tile>();
                return (function connects(tile:Tile):Boolean {
                    explored.push(tile);
                    var index:int = _tiles.indexOf(tile);
                    if(_turn == Player.WHITE && index >= _boardSize * _boardSize - _boardSize)
                        return true;
                    if(_turn == Player.BLACK && index % _boardSize == _boardSize - 1)
                        return true;
                    var validNeighbors:Vector.<Tile>
                            = tile.neighbors.filter(function(neighbor:Tile, j:*, vec:*):Boolean {
                        return explored.indexOf(neighbor) == -1 && neighbor.occupier == _turn;
                    });
                    if(validNeighbors.length == 0)
                        return false;
                    return validNeighbors.some(function(neighbor:Tile, j:*, vec:*):Boolean {
                        return connects(neighbor);
                    });
                })(t);
            }).some(function(b:Boolean, i:*, v:*):Boolean {
                return b;
            });
            if(isOver)
                dispatchEvent(new TurnEvent("onGameOver", _turn));
        }

        //FIXME
        public function checkForOpponentVictory():void {
            _turn = _turn == Player.WHITE ? Player.BLACK : Player.WHITE;
            checkForVictory();
            _turn = _turn == Player.WHITE ? Player.BLACK : Player.WHITE;
        }

        private function changeTurn():void {
            _turn = _turn == Player.WHITE ? Player.BLACK : Player.WHITE;
            dispatchEvent(new TurnEvent("onChangeTurn", _turn));
        }
    }
}
