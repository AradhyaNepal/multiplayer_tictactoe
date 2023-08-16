## Credit:
First I want to thank [OriginalRepo](https://github.com/qubeena07/MyWidgets/commits/main/lib/screens/tic_tac_toe_screen.dart)'s repo, from which I got the TicTacToe game code. The original game was single-user TicTacToe, from which I was inspired to make multi-user TicTacToe. The above repo contains many other exciting codings, so make sure to watch the repo, follow [qubeena07](https://github.com/qubeena07/), and give the repo a star.

# Multiplayer TicTacToe
Flutter + Local Websocket + ❤️ = Multiplayer TicTacToe Game for Android and Windows

Unlike HTTP, Websocket allows developers to set up 2-way real-time data communication tunnel.
Real-time means, whenever user 1 performs some action, user 2 gets notified, which is not possible in HTTP, except if you keep hitting the Get API every 1 second to refresh the latest data, which is very inefficient since it wastes lots of resources.

In this application, the host device runs ServerSocket on its IP address and on a specific port, and shares that with a QR.
The client device needs to be connected to the same internet and needs to scan the QR to connect to the provided Server. And then you can start playing the game😊.


Not only that, while playing the game, to ensure that the data don't get lost in the middle, my application uses the Handshake mechanism (Handshake might not be its actual technical term), where one device sends the request to another and another device sends back a confirmation that it received the request.

So make sure to run the APK and review the code, and give me some feedback 😊.

APK: [Touch Me!](https://drive.google.com/drive/u/0/folders/1j2jfecUFIdPj8l5yBlbCEIjkxHZEPqk6)

Video Demonstration: [Touch Me!](https://drive.google.com/file/d/1IdI5o11L8W3Rb6SLQdM9W5Sk0YXyMWGz/view?usp=drive_link)
