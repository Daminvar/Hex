import com.junkbyte.console.Cc;
import mx.collections.ArrayList;
import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.CloseEvent;

import com.smartfoxserver.v2.SmartFox;
import com.smartfoxserver.v2.core.SFSEvent;
import com.smartfoxserver.v2.entities.*;
import com.smartfoxserver.v2.entities.variables.*;
import com.smartfoxserver.v2.entities.data.*;
import com.smartfoxserver.v2.requests.*;
import com.smartfoxserver.v2.requests.game.*;
import com.smartfoxserver.v2.entities.invitation.*;

[Bindable]
private var userProvider:ArrayList;
[Bindable]
private var roomProvider:ArrayList;

private var sfs:SmartFox;
private var player:Player = Player.NEITHER;

private function init():void {
    Cc.startOnStage(this, "`");
    Cc.config.commandLineAllowed = true;
    sfs = SFSConnector.connection;
    addListeners();
    sfs.loadConfig();
    //TODO: Add catch-all-errors code.
    Cc.log("SFS Version:", sfs.version);
    Cc.log("Finished init.");
}

private function addListeners():void {
    sfs.addEventListener(SFSEvent.CONFIG_LOAD_SUCCESS, onConfig);
    sfs.addEventListener(SFSEvent.CONFIG_LOAD_FAILURE, onConfigFailure);
    sfs.addEventListener(SFSEvent.CONNECTION, onConnect);
    sfs.addEventListener(SFSEvent.CONNECTION_LOST, onConnectionLost);
    sfs.addEventListener(SFSEvent.LOGIN, onLogin);
    sfs.addEventListener(SFSEvent.LOGIN_ERROR, onLoginError);
    sfs.addEventListener(SFSEvent.ROOM_JOIN, onRoomJoined);
    sfs.addEventListener(SFSEvent.ROOM_JOIN_ERROR, onRoomJoinError);
    sfs.addEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
    sfs.addEventListener(SFSEvent.USER_EXIT_ROOM, onUserLeaveRoom);
    sfs.addEventListener(SFSEvent.USER_COUNT_CHANGE, onUserCountChange);
    //sfs.addEventListener(SFSEvent.LOGOUT, onLogout);
    sfs.addEventListener(SFSEvent.PUBLIC_MESSAGE, onPublicMessage);
    sfs.addEventListener(SFSEvent.ROOM_ADD, onRoomAdd);
    sfs.addEventListener(SFSEvent.ROOM_CREATION_ERROR, function(e:*):void { Cc.error("Couldn't create room."); });
    //sfs.addEventListener(SFSEvent.OBJECT_MESSAGE, onMessage);
    sfs.addEventListener(SFSEvent.INVITATION_REPLY, onInvitationReply);
    sfs.addEventListener(SFSEvent.INVITATION, onInvitationReceived);
    sfs.addEventListener(SFSEvent.INVITATION_REPLY_ERROR, onInvitationReplyError);
}

private function onConfig(e:SFSEvent):void {
    Cc.log("Server settings:", sfs.config.host, ":", sfs.config.port);
}

private function onConfigFailure(e:SFSEvent):void {
    Cc.error("Configuration load failed.");
}

private function onConnect(e:SFSEvent):void {
    if(e.params.success)
        Cc.log("Connection successful.");
    else
        Cc.error(e.params.errorMessage);
    loginScreen.enabled = true;
}

private function onConnectionLost(e:SFSEvent):void {
    Cc.error("Connection was lost.");
}

private function onLogin(e:SFSEvent):void {
    Cc.log("Login successful.");
    sfs.send(new JoinRoomRequest("The Lobby"));
}

private function onLoginError(e:SFSEvent):void {
    Cc.error(e.params.errorMessage);
    //TODO: prompt user to change name
    Alert.show(e.params.errorMessage, "Error");
    userName.text = "";
}

private function onRoomJoined(e:SFSEvent):void {
    try {
        if(e.params.room.name == "The Lobby") {
            currentState = "ChatState";
            refreshUserList();
            refreshRoomList();
        }
        Cc.log("Joined room:", e.params.room.name);
    } catch(e:Error) {
        Cc.error(e);
    }
}

private function refreshUserList():void {
    userProvider = new ArrayList();
    for each(var u:Object in sfs.lastJoinedRoom.userList) {
        if(u.isItMe)
            userProvider.addItem(u.name + " (me)");
        else
            userProvider.addItem(u.name);
    }
}

private function refreshRoomList():void {
    roomProvider = new ArrayList();
    for each(var r:Object in sfs.roomManager.getRoomList()) {
        if(r.name == "The Lobby")
            continue;
        roomProvider.addItem(r.name);
    }
}

private function onRoomJoinError(e:SFSEvent):void {
    Cc.error(e.params.errorMessage);
}

private function onUserEnterRoom(e:SFSEvent):void {
    refreshUserList();
}

private function onUserLeaveRoom(e:SFSEvent):void {
    refreshUserList();
}

private function onUserCountChange(e:SFSEvent):void {
    refreshUserList();
}

private function onPublicMessage(e:SFSEvent):void {
    Cc.log(e.params.sender.name, ":", e.params.message);
    chatbox.chatbox.appendText(e.params.sender.name + ": " + e.params.message + "\n");
}

private function onRoomAdd(e:SFSEvent):void {
    Cc.log("Room was added:", e.params.room.name);
    refreshRoomList();
}

private function onInvitationReply(e:SFSEvent):void {
    if(e.params.reply == InvitationReply.ACCEPT) {
        Cc.log(e.params.invitee.name, "accepted the invitation");
    } else {
        Alert.show(e.params.invitee.name + " declined the invitation", "Sorry...");
        sfs.send(new JoinRoomRequest("The Lobby"));
        currentState = "ChatState";
    }
}

private function onInvitationReceived(e:SFSEvent):void {
    var invite:Invitation = e.params.invitation;
    var gameRoom:String = invite.params.getUtfString("roomName");
    Alert.show(invite.inviter.name + " invited you to play. Will you join?",
        "Invitation received",
        Alert.YES | Alert.NO,
        null,
        function(e:CloseEvent):void {
            if(e.detail == Alert.YES) {
                Cc.log("Accepted invitation");
                sfs.send(new InvitationReplyRequest(invite,
                    InvitationReply.ACCEPT));
                player = Player.WHITE;
                sfs.send(new JoinRoomRequest(gameRoom));
                currentState = "PlayState";
                Cc.log("Joining game...");
            } else {
                Cc.log("Declined invitation");
                sfs.send(new InvitationReplyRequest(invite,
                    InvitationReply.REFUSE));
            }
        });
}

private function onInvitationReplyError(e:SFSEvent):void {
    Cc.error(e.params.errorMessage);
}

//
// Other
//

private function login():void {
    Cc.log("Sending login request for user name:", userName.text);
    Cc.log("Zone:", sfs.currentZone);
    sfs.send(new LoginRequest(userName.text, "", "m113dmh"));
}

private function returnToLobby():void {
    currentState = "ChatState";
    sfs.send(new JoinRoomRequest("The Lobby"));
}

private function spectate(e:MouseEvent):void {
    Cc.log(e.currentTarget.selectedItem);
    sfs.send(new JoinRoomRequest(e.currentTarget.selectedItem));
    currentState = "PlayState";
}

private function invite(e:MouseEvent):void {
    Cc.log(e.currentTarget.selectedItem);
    var selectedName:String = e.currentTarget.selectedItem;
    //todo: prevent parens in user name selection to keep this from breaking.
    if(selectedName.search("(me)") != -1) {
        Alert.show("You can't play with yourself!", "Eww");
        return;
    }
    var roomName:String = sfs.mySelf.name + " VS " + selectedName;
    makeGameRoom(roomName, selectedName, sfs.mySelf.name);
    var params:ISFSObject = new SFSObject();
    params.putUtfString("roomName", roomName);
    sfs.send(new InviteUsersRequest([sfs.userManager.getUserByName(selectedName)], 60, params));
    Cc.log("Sent invitation to:", selectedName);
    player = Player.BLACK;
    sfs.send(new JoinRoomRequest(roomName));
    currentState = "PlayState";
}

private function makeGameRoom(name:String, white:String, black:String):void {
    var settings:RoomSettings = new RoomSettings(name);
    settings.isGame = true;
    settings.maxUsers = 20;
    settings.variables = [new SFSRoomVariable("white", white), new SFSRoomVariable("black", black)];
    // CreateRoomRequest(settings:RoomSettings, autoJoin:Boolean = false, roomToLeave:Room = null)
    sfs.send(new CreateRoomRequest(settings, false, sfs.lastJoinedRoom));
}
