package org.spicefactory.lib.task {
	
import flash.events.TimerEvent;
import flash.utils.Timer;
	
	
public class TimerTask extends Task {
	
	
	private var _duration:uint;
	private var _timer:Timer;
	
	
	function TimerTask (duration:uint, cancelable:Boolean = false, restartable:Boolean = false,
			suspendable:Boolean = false, skippable:Boolean = false, 
			timeout:uint = 0) {
		super();
		_duration = duration;
		setCancelable(cancelable);
		setSuspendable(suspendable);
		setSkippable(skippable);
		setRestartable(restartable);
		setTimeout(timeout);
	}
	
	
	
	protected override function doStart () : void {
		_timer = new Timer(_duration, 1);
		_timer.addEventListener(TimerEvent.TIMER, onTimer);
		_timer.start();
	}
	
	private function onTimer (event:TimerEvent) : void {
		_timer = null;
		complete();
	}
	
	protected override function doCancel () : void {
		_timer.stop();
		_timer = null;
	}

	protected override function doSuspend () : void {
		_timer.stop();
	}
	
	protected override function doResume () : void {
		// to keep the test simple, runs the full duration again, not only the remaining time
		_timer.start();
	}
	
	
	public function dispatchError (message:String) : void {
		error(message);
	}
	
	
	
	
}

}