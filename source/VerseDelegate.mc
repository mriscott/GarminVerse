//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

class VerseDelegate extends Ui.BehaviorDelegate {
    var notify;
    var index=0;
    var url= "https://beta.ourmanna.com/api/v1/get/?format=json";
    var gotverse=0;
    var linelen=20;
    var maxlines=4;
    var MAX=10;
    var verses=new[MAX];

    // Handle menu button press
    function onMenu() {
        nextStory();
        return true;
    }

    function onSelect() {
        nextStory();
        return true;
    }
    

    function nextStory() {
        if(gotverse==0) {
	   getVerse();
	}
	notify.invoke(verses[index]);
	index++;
	if(index==MAX||verses[index]==null || verses[index].length==0) {
	  index=0;
	}
	
    }

    function getVerse(){
        if(System.getDeviceSettings().phoneConnected){
        notify.invoke("Getting\nVerse");
        Comm.makeWebRequest(
             url,
            {
            },
            {
                "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON
            },
            method(:onReceive)
        );

	}  else {
	   notify.invoke("Phone\ndisconnected");
	}

    }

    // Set up the callback to the view
    function initialize(handler) {
        Ui.BehaviorDelegate.initialize();
        notify = handler;
	getVerse();
    }

    function splitLines(str){
       gotverse=1;
       if (str == null ) {
         verses[0]="No data";
	 return;
 	}
    	if(str.length()<linelen) {
	   verses[0]=str;
	   return;
	}
	

        var tokens = [];
	var x=0;
        var found = str.find(" ");
        while (found != null) {
            var token = str.substring(0, found);
            tokens.add(token);
            str = str.substring(found + 1, str.length());
            found = str.find(" ");
        }

        tokens.add(str);

        var newstr="";
	var lines=1;
	var line=0;
	for(var i=0;i<tokens.size();i++){
           line+=tokens[i].length();
	   if (line>linelen){
	        if(lines>=maxlines) {
		   newstr+="$";
		   verses[x]=newstr;
		   x++;
		   line=0;
		   lines=0;
                   if(x==MAX) {
		      break;
		   }
	   	   newstr="";

	        }
	   	newstr+="\n";
		line=tokens[i].length();
		lines++;
	   } 
	   newstr+=tokens[i];
	   newstr+=" ";
	   line++;	   
	}
	
	verses[x]=newstr;
    }

   // Receive the data from the web request
    function onReceive(responseCode, data) {
        if (responseCode == 200) {
		if(data instanceof Dictionary) {
		    notify.invoke("Processing");
		    var verse=data.get("verse");
		    var details=verse.get("details");
		    var text = details.get("text");
		    var ref = details.get("reference");
		    if(text instanceof String && text != null ) {
		    	    notify.invoke("Reading");
		    	    splitLines(text+" ~ "+ref);
	            }else{
		       notify.invoke("Bad text:"+text);
		    }
		     Attention.vibrate([new Attention.VibeProfile(100,200)]);
	  
		    nextStory();
		} else {
			notify.invoke("Bad response");
			}
        } else {
            notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }


}
