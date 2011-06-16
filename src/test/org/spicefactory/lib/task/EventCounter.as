package org.spicefactory.lib.task {
	
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.utils.Dictionary;

import org.spicefactory.lib.task.events.TaskEvent;
	
	
public class EventCounter {
	
	
	private var counter:Dictionary = new Dictionary();
	

	function EventCounter (t:Task) {
		t.addEventListener(ErrorEvent.ERROR, handleEvent, false, 1);
		t.addEventListener(TaskEvent.COMPLETE, handleEvent, false, 1);
		t.addEventListener(TaskEvent.START, handleEvent, false, 1);
		t.addEventListener(TaskEvent.SUSPEND, handleEvent, false, 1);
		t.addEventListener(TaskEvent.RESUME, handleEvent, false, 1);
		t.addEventListener(TaskEvent.CANCEL, handleEvent, false, 1);
	}
	
	private function handleEvent (event:Event) : void {
		if (counter[event.type] == undefined) {
			counter[event.type] = 1;
		} else {
			counter[event.type]++;
		}
	}
	
	
	public function getCount (type:String) : uint {
		return (counter[type] == undefined) ? 0 : counter[type];
	}
	
	
}

}