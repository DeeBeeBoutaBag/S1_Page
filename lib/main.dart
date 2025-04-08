import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "/Users/demetriousbrown/Sewara_v1/sewara_v1/.env");
  runApp(const SEVAApp());
}

class SEVAApp extends StatelessWidget {
  const SEVAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SEVAHome(),
    );
  }
}

class SEVAHome extends StatefulWidget {
  const SEVAHome({super.key});
  @override
  _SEVAHomeState createState() => _SEVAHomeState();
}

class _SEVAHomeState extends State<SEVAHome> {
  final List<Chat> chats = [];
  final ai = OpenAIService();

  void newChat() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => ChatScreen(openAIService: ai),
  )).then((chat) => chat != null ? setState(() => chats.add(chat)) : null);

  void openChat(Chat c) => Navigator.push(context, MaterialPageRoute(
    builder: (_) => ChatScreen(chat: c, openAIService: ai),
  )).then((_) { setState(() {}); });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('S.E.V.A Chats', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(icon: const Icon(Icons.add,color:Colors.white), onPressed: newChat),
      ],
    ),
    extendBodyBehindAppBar: true,
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.black, Colors.grey, Color(0xFFFFFF00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(top:100),
        itemCount: chats.length,
        itemBuilder: (_, i) => ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.chat, color: Colors.black),
            backgroundColor: Colors.amber,
          ),
          title: Text(
            chats[i].title,
            maxLines:1,
            overflow:TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white), // explicitly white
          ),
          subtitle: Text(
            chats[i].messages.last.text,
            maxLines:1,
            overflow:TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70), // soft white readability
          ),
          trailing: Text(
            TimeOfDay.fromDateTime(chats[i].time).format(context),
            style: const TextStyle(color:Colors.white70),
          ),
          onTap: () => openChat(chats[i]),
        ),
      ),
    ),
  );
}

class ChatScreen extends StatefulWidget {
  final Chat? chat; final OpenAIService openAIService;
  const ChatScreen({super.key,this.chat,required this.openAIService});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> messages = [];
  final input = TextEditingController();
  bool loading = false;

  @override
  void initState(){
    super.initState();
    messages = widget.chat?.messages ?? [Message(text:'Hey fam! What you need today?',isUser:false)];
  }

  void send() async{
    final text = input.text.trim();
    if(text.isEmpty) return;
    
    setState(()=>messages.add(Message(text: input.text,isUser:true)));
    input.clear();
    setState(() => loading = true);
    
    final response = await widget.openAIService.generateResponse(
      messages.map((m)=>{'role':m.isUser?'user':'assistant','content':m.text}).toList()
    );

    if (!mounted) return; // prevents setState error
    setState((){
      messages.add(Message(text:response,isUser:false));
      loading = false;
    });
  }

  Future<void> saveExit() async {
    final summary=await widget.openAIService.generateResponse([
      {'role':'system','content':'Provide a summarized chat title(2-4 words).'},
      ...messages.map((m)=>{'role':m.isUser?'user':'assistant','content':m.text}),
      {'role':'user','content':'Summarize briefly.'}], tokens:10);
    
    if(!mounted)return; // prevents setState after dispose error
    
    final title = summary.length > 25 ? summary.substring(0,25) : summary;
    final chat = widget.chat??Chat(title:title,messages:messages,time:DateTime.now());
    if(widget.chat!=null){
      widget.chat!.title=title;
      widget.chat!.time=DateTime.now();
      widget.chat!.messages=messages;
    }
    Navigator.pop(context,chat);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.chat?.title??'New Chat'),
      leading: IconButton(icon:const Icon(Icons.arrow_back),onPressed:saveExit),
    ),
    extendBodyBehindAppBar:true,
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image:AssetImage('assets/HGPAssets_Emblem_Yellow.png'),
          fit:BoxFit.cover,
        ),
      ),
      child:Column(children:[
        Expanded(child:ListView.builder(
          padding: const EdgeInsets.only(top:120,bottom:10),
          itemCount: messages.length + (loading ? 1 : 0),
          itemBuilder:(_,i){
            if(i==messages.length)return TypingIndicator();
            final m=messages[i];
            return Align(
              alignment:m.isUser?Alignment.centerRight:Alignment.centerLeft,
              child: Container(
                margin:const EdgeInsets.all(5),padding:const EdgeInsets.all(12),
                constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*0.75),
                decoration:BoxDecoration(
                  color:m.isUser?Colors.blue.shade700:Colors.grey.shade800,
                  borderRadius:BorderRadius.circular(16)),
                child:Text(m.text,style:const TextStyle(color:Colors.white)),
              ),
            );
          },
        )),
        SafeArea(child:Padding(padding:const EdgeInsets.all(10),
          child:Container(
            decoration:BoxDecoration(
              color:Colors.grey.shade900,
              borderRadius:BorderRadius.circular(30)
            ),
            child:Row(children:[
              Expanded(child:Padding(
                padding:const EdgeInsets.symmetric(horizontal:15),
                child:TextField(
                  controller:input,
                  style:const TextStyle(color:Color(0xFFFFD700)),
                  decoration:const InputDecoration(
                    hintText:'Message',
                    hintStyle:TextStyle(color:Colors.white54),
                    border:InputBorder.none
                  )),
              )),
              IconButton(icon:const Icon(Icons.send,color:Colors.amber),onPressed:send),
            ]),
          ),
        )),
      ]),
    ),
  );
}

class TypingIndicator extends StatelessWidget{
  @override Widget build(BuildContext context)=>Align(alignment:Alignment.centerLeft,
    child:Container(width:60,height:35,padding:const EdgeInsets.all(10),
      decoration:BoxDecoration(color:Colors.grey.shade800,borderRadius:BorderRadius.circular(20)),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,
        children:List.generate(3,(i)=>AnimatedBubble(delay:i*200)))));
}

class AnimatedBubble extends StatefulWidget{
  final int delay;const AnimatedBubble({required this.delay,super.key});
  @override State createState()=>_AnimatedBubble();}
class _AnimatedBubble extends State<AnimatedBubble>with SingleTickerProviderStateMixin{
  late AnimationController c;@override void initState(){super.initState();
  c=AnimationController(vsync:this,duration:const Duration(milliseconds:600))..repeat(reverse:true);}
  @override Widget build(context)=>FadeTransition(opacity:c,child:CircleAvatar(radius:4,backgroundColor:Colors.white));
  @override void dispose(){c.dispose();super.dispose();}}

class Chat{String title;List<Message>messages;DateTime time;Chat({required this.title,required this.messages,required this.time});}
class Message{String text;bool isUser;Message({required this.text,required this.isUser});}