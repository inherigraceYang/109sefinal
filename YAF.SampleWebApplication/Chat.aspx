﻿<%@ Page Title="Chat" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Chat.aspx.cs" Inherits="YAF.SampleWebApplication.Chat" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <!--Reference the autogenerated SignalR hub script. -->
    <script src="signalr/hubs"></script>

    <script type="text/javascript">

        var IntervalVal;
        $(function () {

            // Declare a proxy to reference the hub.

            var chatHub = $.connection.chatHub;
            registerClientMethods(chatHub);
            // Start Hub
            $.connection.hub.start().done(function () {

                registerEvents(chatHub);

            });

            // Reset Message Counter on Hover
            $("#divChatWindow").mouseover(function () {

                $("#MsgCountMain").html('0');
                $("#MsgCountMain").attr("title", '0 New Messages');
            });

            // Stop Title Alert
            window.onfocus = function (event) {
                if (event.explicitOriginalTarget === window) {

                    clearInterval(IntervalVal);
                    document.title = 'SignalR Chat App';
                }
            };


        });

        // Show Title Alert
        function ShowTitleAlert(newMessageTitle, pageTitle) {
            if (document.title == pageTitle) {
                document.title = newMessageTitle;
            }
            else {
                document.title = pageTitle;
            }
        }

        function registerEvents(chatHub) {

            var name = '<%= this.UserName %>';
            var userId = '<%= this.UserId %>';

            if (name.length > 0) {
                chatHub.server.connect(name, userId);
            }


            // Clear Chat
            $('#btnClearChat').click(function () {

                var msg = $("#divChatWindow").html();

                if (msg.length > 0) {
                    chatHub.server.clearTimeout();
                    $('#divChatWindow').html('');

                }
            });

            // Send Button Click Event
            $('#btnSendMsg').click(function () {

                var msg = $("#txtMessage").val();

                if (msg.length > 0) {

                    var userName = $('#hdUserName').val();
                    var userId = $('#hdUserId').val();

                    var date = GetCurrentDateTime(new Date());

                    chatHub.server.sendMessageToAll(userName, userId, msg, date);
                    $("#txtMessage").val('');
                }
            });

            // Send Message on Enter Button
            $("#txtMessage").keypress(function (e) {
                if (e.which == 13) {
                    $('#btnSendMsg').click();
                }
            });

        }

        function registerClientMethods(chatHub) {


            // Calls when user successfully logged in
            chatHub.client.onConnected = function (id, userName, userId, allUsers, messages, times) {

                $('#hdId').val(id);
                $('#hdUserName').val(userName);
                $('#hdUserId').val(userId);
                $('#spanUser').html(userName);

                // Add All Users
                for (i = 0; i < allUsers.length; i++) {

                    AddUser(chatHub, allUsers[i].ConnectionId, allUsers[i].UserName, allUsers[i].UserImage, allUsers[i].LoginTime);
                }

                // Add Existing Messages
                for (i = 0; i < messages.length; i++) {
                    AddMessage(messages[i].UserName, messages[i].Message, messages[i].Time, messages[i].UserImage);

                }
            };

            // On New User Connected
            chatHub.client.onNewUserConnected = function (id, name, UserImage, loginDate) {
                AddUser(chatHub, id, name, UserImage, loginDate);
            };

            // On User Disconnected
            chatHub.client.onUserDisconnected = function (id, userName) {

                $('#Div' + id).remove();

                var ctrId = 'private_' + id;
                $('#' + ctrId).remove();


                var disc = $('<div class="disconnect">"' + userName + '" logged off.</div>');

                $(disc).hide();
                $('#divusers').prepend(disc);
                $(disc).fadeIn(200).delay(2000).fadeOut(200);

            };

            chatHub.client.messageReceived = function (userName, message, time, userimg) {

                AddMessage(userName, message, time, userimg);

                // Display Message Count and Notification
                var CurrUser1 = $('#hdUserName').val();
                if (CurrUser1 != userName) {

                    var msgcount = $('#MsgCountMain').html();
                    msgcount++;
                    $("#MsgCountMain").html(msgcount);
                    $("#MsgCountMain").attr("title", msgcount + ' New Messages');
                    var Notification = 'New Message From ' + userName;
                    IntervalVal = setInterval("ShowTitleAlert('SignalR Chat App', '" + Notification + "')", 800);

                }
            };


            chatHub.client.sendPrivateMessage = function (windowId, fromUserName, message, userimg, CurrentDateTime) {

                var ctrId = 'private_' + windowId;
                if ($('#' + ctrId).length == 0) {

                    OpenPrivateChatcard(chatHub, windowId, ctrId, fromUserName, userimg);

                }

                var CurrUser = $('#hdUserName').val();
                var Side = 'right';
                var TimeSide = 'left';

                if (CurrUser == fromUserName) {
                    Side = 'left';
                    TimeSide = 'right';

                }
                else {
                    var Notification = 'New Message From ' + fromUserName;
                    IntervalVal = setInterval("ShowTitleAlert('SignalR Chat App', '" + Notification + "')", 800);

                    var msgcount = $('#' + ctrId).find('#MsgCountP').html();
                    msgcount++;
                    $('#' + ctrId).find('#MsgCountP').html(msgcount);
                    $('#' + ctrId).find('#MsgCountP').attr("title", msgcount + ' New Messages');
                }

                var divChatP = '<div class="direct-chat-msg ' + Side + '">' +
                    '<div class="direct-chat-info clearfix">' +
                    '<span class="direct-chat-name float-' + Side + '">' + fromUserName + '</span>' +
                    '<span class="direct-chat-timestamp float-' + TimeSide + '"">' + CurrentDateTime + '</span>' +
                    '</div>' +

                    ' <img class="direct-chat-img" src="' + userimg + '" alt="Message User Image">' +
                    ' <div class="direct-chat-text" >' + message + '</div> </div>';

                $('#' + ctrId).find('#divMessage').append(divChatP);

                // Apply Slim Scroll Bar in Private Chat card
                var ScrollHeight = $('#' + ctrId).find('#divMessage')[0].scrollHeight;
                $('#' + ctrId).find('#divMessage').slimScroll({
                    height: ScrollHeight
                });
            };

        }

        function GetCurrentDateTime(now) {

            var localdate = dateFormat(now, "dddd, mmmm dS, yyyy, h:MM:ss TT");

            return localdate;
        }

        function AddUser(chatHub, id, name, UserImage, date) {

            var userId = $('#hdId').val();

            var code, Clist;
            if (userId == id) {

                code = $('<div class="card-comment">' +
                    '<img class="img-sm" src="' + UserImage + '" alt="User Image" />' +
                    ' <div class="comment-text">' +
                    '<span class="username">' + name + '<span class="text-muted float-right">' + date + '</span>  </span></div></div>');


                Clist = $(
                    '<li style="background:#494949;">' +
                    '<a href="#">' +
                    '<img class="contacts-list-img" src="' + UserImage + '" alt="User Image" />' +

                    ' <div class="contacts-list-info">' +
                    ' <span class="contacts-list-name" id="' + id + '">' + name + ' <small class="contacts-list-date float-right">' + date + '</small> </span>' +
                    ' <span class="contacts-list-msg">How have you been? I was...</span></div></a > </li >');

            }
            else {

                code = $('<div class="card-comment" id="Div' + id + '">' +
                    '<img class="img-sm" src="' + UserImage + '" alt="User Image" />' +
                    ' <div class="comment-text">' +
                    '<span class="username">' + '<a id="' + id + '" class="user" >' + name + '<a>' + '<span class="text-muted float-right">' + date + '</span>  </span></div></div>');


                Clist = $(
                    '<li>' +
                    '<a href="#">' +
                    '<img class="contacts-list-img" src="' + UserImage + '" alt="User Image" />' +

                    ' <div class="contacts-list-info">' +
                    '<span class="contacts-list-name" id="' + id + '">' + name + ' <small class="contacts-list-date float-right">' + date + '</small> </span>' +
                    ' <span class="contacts-list-msg">How have you been? I was...</span></div></a > </li >');


                var UserLink = $('<a id="' + id + '" class="user" >' + name + '<a>');
                $(code).click(function () {

                    var id = $(UserLink).attr('id');

                    if (userId != id) {
                        var ctrId = 'private_' + id;
                        OpenPrivateChatcard(chatHub, id, ctrId, name);

                    }

                });

                var link = $('<span class="contacts-list-name" id="' + id + '">');
                $(Clist).click(function () {

                    var id = $(link).attr('id');

                    if (userId != id) {
                        var ctrId = 'private_' + id;
                        OpenPrivateChatcard(chatHub, id, ctrId, name);

                    }

                });

            }

            $("#divusers").append(code);

            $("#ContactList").append(Clist);

        }

        function AddMessage(userName, message, time, userimg) {

            var CurrUser = $('#hdUserName').val();
            var Side = 'right';
            var TimeSide = 'left';

            if (CurrUser == userName) {
                Side = 'left';
                TimeSide = 'right';

            }

            var divChat = '<div class="direct-chat-msg ' + Side + '">' +
                '<div class="direct-chat-info clearfix">' +
                '<span class="direct-chat-name float-' + Side + '">' + userName + '</span>' +
                '<span class="direct-chat-timestamp float-' + TimeSide + '"">' + time + '</span>' +
                '</div>' +

                ' <img class="direct-chat-img" src="' + userimg + '" alt="Message User Image">' +
                ' <div class="direct-chat-text" >' + message + '</div> </div>';

            $('#divChatWindow').append(divChat);

            var height = $('#divChatWindow')[0].scrollHeight;

            // Apply Slim Scroll Bar in Group Chat card
            $('#divChatWindow').slimScroll({
                height: height
            });

            ParseEmoji('#divChatWindow');

        }

        function OpenPrivateChatcard(chatHub, userId, ctrId, userName) {

            var PWClass = $('#PWCount').val();

            if ($('#PWCount').val() == 'info')
                PWClass = 'danger';
            else if ($('#PWCount').val() == 'danger')
                PWClass = 'warning';
            else
                PWClass = 'info';

            $('#PWCount').val(PWClass);
            var div1 = ' <div class="col-md-4"> <div  id="' + ctrId + '" class="card card-solid card-' + PWClass + ' direct-chat direct-chat-' + PWClass + '">' +
                '<div class="card-header with-border">' +
                ' <h3 class="card-title">' + userName + '</h3>' +

                ' <div class="card-tools float-right">' +
                ' <span data-toggle="tooltip" id="MsgCountP" title="0 New Messages" class="badge bg-' + PWClass + '">0</span>' +
                ' <button type="button" class="btn btn-card-tool" data-widget="collapse">' +
                '    <i class="fa fa-minus"></i>' +
                '  </button>' +
                '  <button id="imgDelete" type="button" class="btn btn-card-tool" data-widget="remove"><i class="fa fa-times"></i></button></div></div>' +

                ' <div class="card-body">' +
                ' <div id="divMessage" class="direct-chat-messages">' +

                ' </div>' +

                '  </div>' +
                '  <div class="card-footer">' +


                '    <input type="text" id="txtPrivateMessage" name="message" placeholder="Type Message ..." class="form-control"  />' +

                '  <div class="input-group">' +
                '    <input type="text" name="message" placeholder="Type Message ..." class="form-control" style="visibility:hidden;" />' +
                '   <span class="input-group-btn">' +
                '          <input type="button" id="btnSendMessage" class="btn btn-' + PWClass + ' btn-flat" value="send" />' +
                '   </span>' +


                '  </div>' +

                ' </div>' +
                ' </div></div>';



            var $div = $(div1);

            // Closing Private Chat card
            $div.find('#imgDelete').click(function () {
                $('#' + ctrId).remove();
            });

            // Send Button event in Private Chat
            $div.find("#btnSendMessage").click(function () {

                $textcard = $div.find("#txtPrivateMessage");

                var msg = $textcard.val();
                if (msg.length > 0) {
                    chatHub.server.sendPrivateMessage(userId, msg);
                    $textcard.val('');
                }
            });

            // Text card event on Enter Button
            $div.find("#txtPrivateMessage").keypress(function (e) {
                if (e.which == 13) {
                    $div.find("#btnSendMessage").click();
                }
            });

            // Clear Message Count on Mouse over           
            $div.find("#divMessage").mouseover(function () {

                $("#MsgCountP").html('0');
                $("#MsgCountP").attr("title", '0 New Messages');
            });

            // Append private chat div inside the main div
            $('#PriChatDiv').append($div);
            var msgTextcard = $div.find("#txtPrivateMessage");
            $(msgTextcard).emojioneArea();
        }

        function ParseEmoji(div) {
            var input = $(div).html();

            var output = emojione.unicodeToImage(input);

            $(div).html(output);
        }

    </script>


        
           <header>
            <nav class="navbar navbar-expand-lg navbar-light bg-light">
                <!-- Logo -->
                <a href="#" class="navbar-brand">
                    <!-- logo for regular state and mobile devices -->
                    <span class="font-weight-bold">SignalR</span> Chat App
                </a>
                <button class="navbar-toggler" type="button" 
                        data-toggle="collapse" 
                        data-target="#navbarSupportedContent" 
                        aria-controls="navbarSupportedContent" 
                        aria-expanded="false" 
                        aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
            </nav>
           </header>
    <main role="main" class="container mt-3">
            <div class="row">

                <div class="col-md-8">
                    <!-- DIRECT CHAT PRIMARY -->
                    <div class="card">
                        <div class="card-header">
                            Welcome to Discussion Room <span id='spanUser' class="font-weight-bold"></span>
                            <div class="float-right">
                                <button type="button" class="btn btn-secondary btn-sm" id="btnClearChat" data-toggle="tooltip" title="Clear Chat">
                                    <i class="fa fa-trash"></i>
                                </button>

                                <span id="MsgCountMain" title="0 New Messages" class="badge badge-secondary">0</span>
                            </div>
                        </div>
                        <!-- /.card-header -->
                        <div class="card-body">
                            <!-- Conversations are loaded here -->
                            <div class="card-body" id="chat-card">
                                <!-- Conversations are loaded here -->

                                <div id="divChatWindow" class="direct-chat-messages" style="height: 450px;">
                                </div>

                            </div>

                        </div>
                        <!-- /.card-body -->
                        <div class="card-footer">

                            <textarea id="txtMessage"></textarea>

                            <div class="float-right">
                                <input type="button" class="btn btn-primary" id="btnSendMsg" value="Send" />
                               
                            </div>
                        </div>
                        <!-- /.card-footer-->
                    </div>
                    <!--/.direct-chat -->
                </div>
                <!-- /.col -->
                <div class="col-md-4">

                    <div class="card">

                        <div class="card-header">
                            <h6 class="card-title">Online Users <span id='UserCount'></span></h6>
                        </div>

                        <div class="card-body" id="divusers">
                        </div>

                    </div>

                    
                    <div class="card mt-3">
                        <ul class="contacts-list" id="ContactList">

                            <!-- End Contact Item -->
                        </ul>
                        <!-- /.contatcts-list -->
                    </div>
                    <!-- /.direct-chat-pane -->
                </div>
                
                


                <div class="row">
                    <div class="col-md-12">
                        <div class="row" id="PriChatDiv">
                        </div>
                        <textarea class="form-control" style="visibility: hidden;"></textarea>




                        <!--/.private-chat -->
                    </div>
                </div>

                <!-- /.col -->


                <!-- /.col -->

                <!-- /.col -->
            </div>
            <!-- /.row -->
        </main>
        <span id="time"></span>
        <input id="hdId" type="hidden" />
        <input id="PWCount" type="hidden" value="info" />
        <input id="hdUserName" type="hidden" />
        <input id="hdUserId" type="hidden" />


        

        <style>
            
            .img-sm {
                width: 200px;
            }
            .direct-chat-text img {
                width: 20px;
            }
        </style>

        <script>
            $(function () {
                $("#txtMessage").emojioneArea();

            });
        </script>
    </asp:Content>
