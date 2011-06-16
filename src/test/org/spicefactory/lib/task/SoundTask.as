package org.spicefactory.lib.task {
	
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.net.URLRequest;
	
	
public class SoundTask extends Task {
	

	private var filename:String;


	function SoundTask (file:String) {
		super();
		filename = file;
		setCancelable(false);
		setSuspendable(false);
		setSkippable(false);	
	}
	
	
	protected override function doStart () : void {
		var sound:Sound = new Sound();
        sound.addEventListener(IOErrorEvent.IO_ERROR, onError);
        sound.load(new URLRequest(filename));
        var channel:SoundChannel = sound.play();	
        channel.addEventListener(Event.SOUND_COMPLETE, onComplete);	
	}
	
	
	private function onComplete (event:Event) : void {
		complete();
	}
	
	private function onError (event:ErrorEvent) : void {
		error("Error playing sound file " + filename + ": " + event.text);
	}
	
	
}

}