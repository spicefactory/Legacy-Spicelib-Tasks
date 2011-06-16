package org.spicefactory.lib.task {
import org.hamcrest.object.sameInstance;
import org.hamcrest.object.equalTo;
import org.flexunit.assertThat;
import org.flexunit.async.Async;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.utils.Dictionary;

import org.spicefactory.lib.task.enum.TaskState;
import org.spicefactory.lib.task.events.TaskEvent;
import org.spicefactory.lib.task.ResultTask;


public class TaskTest {


	private var eventCounter:EventCounter;
	private var expectedState:TaskState;
	private var expectedEvents:Result;



	private function startTask (eventType:String, expectedState:TaskState,
			listener:Function = null,
			cancelable:Boolean = false, restartable:Boolean = false,
			suspendable:Boolean = false, skippable:Boolean = false, 
			timeout:uint = 0) : TimerTask {
		this.expectedState = expectedState;
		if (listener == null) listener = onTestComplete;
		var tt:TimerTask = new TimerTask(150, cancelable, restartable, suspendable, skippable, timeout);
		tt.addEventListener(eventType, Async.asyncHandler(this, listener, 500));
		eventCounter = new EventCounter(tt);
		tt.start();
		return tt;
	}
	
	private function startSequential (tasks:Array, eventType:String, expectedState:TaskState,
			listener:Function = null, timeout:uint = 0, async:Boolean = true) : TaskGroup {
		return startGroup(new SequentialTaskGroup(), tasks, eventType, expectedState, listener, timeout, async);
	}
	
	private function startConcurrent (tasks:Array, eventType:String, expectedState:TaskState,
			listener:Function = null, timeout:uint = 0, async:Boolean = true) : TaskGroup {
		return startGroup(new ConcurrentTaskGroup(), tasks, eventType, expectedState, listener, timeout, async);
	}
	
	private function startGroup (tg:TaskGroup, tasks:Array, eventType:String, expectedState:TaskState,
			listener:Function = null, timeout:uint = 0, async:Boolean = true) : TaskGroup {
		for each (var t:Task in tasks) {
			tg.addTask(t);
		}
		this.expectedState = expectedState;
		if (async) {
			if (listener == null) listener = onTestComplete;
			tg.addEventListener(eventType, Async.asyncHandler(this, listener, 500));
		}
		eventCounter = new EventCounter(tg);
		tg.timeout = timeout;
		tg.start();
		return tg;
	}

	[Test(async)]
	public function completeRestartable () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		startTask(TaskEvent.COMPLETE, TaskState.INACTIVE, null, true, true);
	}
	
	[Test(async)]
	public function completeNonRestartable () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		startTask(TaskEvent.COMPLETE, TaskState.FINISHED, null, true, false);
	}
	
	[Test(async)]
	public function illegalRestart () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		startTask(TaskEvent.COMPLETE, TaskState.FINISHED, onTestIllegalRestart, true, false);
	}
	
	[Test(async)]
	public function cancel () : void {
		expectedEvents = new Result(1, 0, 1, 0, 0, 0);
		var t:Task = startTask(TaskEvent.CANCEL, TaskState.INACTIVE, null, true, true);
		t.cancel();
	}
	
	[Test(async)]
	public function illegalCancel () : void {
		expectedEvents = new Result(1, 0, 0, 0, 0, 0);
		startTask(TaskEvent.START, TaskState.ACTIVE, onTestIllegalCancel, false, true);
	}
	
	[Test(async)]
	public function suspendResume () : void {
		expectedEvents = new Result(1, 0, 0, 0, 1, 1);
		var t:Task = startTask(TaskEvent.RESUME, TaskState.ACTIVE, null, true, true, true);
		assertThat(t.suspendable, equalTo(true));	
		assertThat(t.suspend(), equalTo(true));	
		assertThat(t.resume(), equalTo(true));	
	}
	
	[Test(async)]
	public function error () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var t:TimerTask = startTask(ErrorEvent.ERROR, TaskState.FINISHED, null);
		t.dispatchError("Expected Error");		
	}
	
	[Test(async)]
	public function skip () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var t:Task = startTask(TaskEvent.COMPLETE, TaskState.INACTIVE, null, true, true);
		t.skip();
	}
	
	[Test(async)]
	public function illegalSkip () : void {
		expectedEvents = new Result(1, 0, 0, 0, 0, 0);
		startTask(TaskEvent.START, TaskState.ACTIVE, onTestIllegalSkip);
	}
	
	[Test(async)]
	public function timeout () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		startTask(ErrorEvent.ERROR, TaskState.FINISHED, null, false, false, false, false, 80);	
	}
	
	[Test]
	public function emptySequentialComplete () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tg:TaskGroup = startSequential([], TaskEvent.COMPLETE, TaskState.INACTIVE, null, 0, false);
		validate(tg);
	}
	
	[Test]
	public function emptyConcurrentComplete () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tg:TaskGroup = startConcurrent([], TaskEvent.COMPLETE, TaskState.INACTIVE, null, 0, false);
		validate(tg);
	}
	
	[Test(async)]
	public function sequentialComplete () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		// child tasks are not restartable so we expect FINISHED state
		startSequential([tt1, tt2], TaskEvent.COMPLETE, TaskState.FINISHED);
	}
	
	[Test(async)]
	public function concurrentComplete () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		// child tasks are not restartable so we expect FINISHED state
		startConcurrent([tt1, tt2], TaskEvent.COMPLETE, TaskState.FINISHED);
	}
	
	[Test(async)]
	public function restartableSequentialComplete () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, true);
		var tt2:TimerTask = new TimerTask(150, false, true);
		startSequential([tt1, tt2], TaskEvent.COMPLETE, TaskState.INACTIVE);
	}
	
	[Test(async)]
	public function cancelSequential () : void {
		expectedEvents = new Result(1, 0, 1, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, true);
		var tt2:TimerTask = new TimerTask(150, true);
		var tg:TaskGroup = startSequential([tt1, tt2], TaskEvent.CANCEL, TaskState.FINISHED);
		tg.cancel();
		assertThat(tt1.state, equalTo(TaskState.FINISHED));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));	
	}
	
	[Test(async)]
	public function cancelConcurrent () : void {
		expectedEvents = new Result(1, 0, 1, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, true);
		var tt2:TimerTask = new TimerTask(150, true);
		var tg:TaskGroup = startConcurrent([tt1, tt2], TaskEvent.CANCEL, TaskState.FINISHED);
		tg.cancel();
		assertThat(tt1.state, equalTo(TaskState.FINISHED));
		assertThat(tt2.state, equalTo(TaskState.FINISHED));	
	}
	
	[Test(async)]
	public function illegalCancelSequential () : void {
		expectedEvents = new Result(1, 0, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		startSequential([tt1, tt2], TaskEvent.START, TaskState.ACTIVE, onTestIllegalCancel);
	}
	
	[Test(async)]
	public function illegalCancelConcurrent () : void {
		expectedEvents = new Result(1, 0, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		startConcurrent([tt1, tt2], TaskEvent.START, TaskState.ACTIVE, onTestIllegalCancel);
	}
	
	[Test(async)]
	public function suspendResumeSequential () : void {
		expectedEvents = new Result(1, 0, 0, 0, 1, 1);
		var tt1:TimerTask = new TimerTask(150, false, false, true);
		var tt2:TimerTask = new TimerTask(150, false, false, true);
		var tg:TaskGroup = startSequential([tt1, tt2], TaskEvent.RESUME, 
				TaskState.ACTIVE);
		assertThat(tg.suspendable, equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));	
		assertThat(tg.suspend(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.SUSPENDED));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));			
		assertThat(tg.resume(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));			
	}
	
	[Test(async)]
	public function suspendResumeConcurrent () : void {
		expectedEvents = new Result(1, 0, 0, 0, 1, 1);
		var tt1:TimerTask = new TimerTask(150, false, false, true);
		var tt2:TimerTask = new TimerTask(150, false, false, true);
		var tg:TaskGroup = startConcurrent([tt1, tt2], TaskEvent.RESUME, 
				TaskState.ACTIVE);
		assertThat(tg.suspendable, equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
		assertThat(tg.suspend(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.SUSPENDED));
		assertThat(tt2.state, equalTo(TaskState.SUSPENDED));			
		assertThat(tg.resume(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
	}
	
	[Test(async)]
	public function errorSequential () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		startSequential([tt1, tt2], ErrorEvent.ERROR, TaskState.FINISHED);
		tt1.dispatchError("Expected Error");
	}
	
	[Test(async)]
	public function errorConcurrent () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		startConcurrent([tt1, tt2], ErrorEvent.ERROR, TaskState.FINISHED);
		tt1.dispatchError("Expected Error");
	}
	
	[Test(async)]
	public function skipSequential () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, false, false, true);
		var tt2:TimerTask = new TimerTask(150, false, false, false, true);
		var tg:TaskGroup = startSequential([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.FINISHED);
		assertThat(tg.skippable, equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));	
		assertThat(tg.skip(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.FINISHED));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));			
	}
	
	[Test(async)]
	public function skipConcurrent () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, false, false, true);
		var tt2:TimerTask = new TimerTask(150, false, false, false, true);
		var tg:TaskGroup = startConcurrent([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.FINISHED);
		assertThat(tg.skippable, equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
		assertThat(tg.skip(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.FINISHED));
		assertThat(tt2.state, equalTo(TaskState.FINISHED));		
	}
	
	[Test(async)]
	public function illegalSkipSequential () : void {
		expectedEvents = new Result(1, 0, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		startSequential([tt1, tt2], TaskEvent.START, TaskState.ACTIVE, onTestIllegalSkip);
	}
	
	[Test(async)]
	public function illegalSkipConcurrent () : void {
		expectedEvents = new Result(1, 0, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		startConcurrent([tt1, tt2], TaskEvent.START, TaskState.ACTIVE, onTestIllegalSkip);
	}
	
	[Test(async)]
	public function timeoutSequential () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, false, false, false, 80);
		var tt2:TimerTask = new TimerTask(150);
		startSequential([tt1, tt2], ErrorEvent.ERROR, TaskState.FINISHED);
	}
	
	[Test(async)]
	public function timeoutConcurrent () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, false, false, false, 80);
		var tt2:TimerTask = new TimerTask(150);
		startConcurrent([tt1, tt2], ErrorEvent.ERROR, TaskState.FINISHED);
	}
	
	[Test(async)]
	public function parentTimeoutSequential () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var tt1:TimerTask = new TimerTask(1000, true);
		var tt2:TimerTask = new TimerTask(150, true);
		startSequential([tt1, tt2], ErrorEvent.ERROR, TaskState.FINISHED, null, 200);
	}
	
	[Test(async)]
	public function parentTimeoutConcurrent () : void {
		expectedEvents = new Result(1, 0, 0, 1, 0, 0);
		var tt1:TimerTask = new TimerTask(1000, true);
		var tt2:TimerTask = new TimerTask(150, true);
		startConcurrent([tt1, tt2], ErrorEvent.ERROR, TaskState.FINISHED, null, 200);
	}
		
	[Test(async)]
	public function ignoreTimeoutSequential () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, false, false, false, 80);
		var tt2:TimerTask = new TimerTask(150);
		var tg:TaskGroup = startSequential([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.FINISHED);
		tg.ignoreChildErrors = true;
	}
	
	[Test(async)]
	public function ignoreTimeoutConcurrent () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, false, false, false, false, 80);
		var tt2:TimerTask = new TimerTask(150);
		var tg:TaskGroup = startConcurrent([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.FINISHED);
		tg.ignoreChildErrors = true;
	}
	
	[Test(async)]
	public function taskGroupData () : void {
		var outerGroup:TaskGroup = new SequentialTaskGroup();
		var innerGroup:TaskGroup = new ConcurrentTaskGroup();
		var task:Task = new TimerTask(100);
		innerGroup.addTask(task);
		outerGroup.addTask(innerGroup);
		outerGroup.data = 7;
		assertThat(outerGroup.data, equalTo(7));
		assertThat(innerGroup.data, equalTo(7));
		assertThat(task.data, equalTo(7));
		innerGroup.data = "foo";
		assertThat(outerGroup.data, equalTo(7));
		assertThat(innerGroup.data, equalTo("foo"));
		assertThat(task.data, equalTo("foo"));
		task.data = true;	
		assertThat(outerGroup.data, equalTo(7));
		assertThat(innerGroup.data, equalTo("foo"));
		assertThat(task.data, equalTo(true));
	}
	
	[Test(async)]
	public function addTaskToRunningConcurrent () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		var tg:TaskGroup = startConcurrent([tt1], TaskEvent.COMPLETE, 
				TaskState.FINISHED);
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));			
		assertThat(tg.addTask(tt2), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
	}
	
	[Test]
	public function addTaskWhileDoStartExecutes () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tg:TaskGroup = new ConcurrentTaskGroup();
		var tAdded:Task = new NonRestartableCommandTask(new Delegate(childTask2));
		var t:Task = new NonRestartableCommandTask(new Delegate(childTask1, [tg, tAdded]));
		var t2:Task = new NonRestartableCommandTask(new Delegate(childTask2));
		startGroup(tg, [t, t2], TaskEvent.COMPLETE, TaskState.FINISHED, null, 0, false);
		validate(tg);
		assertThat(t.state, equalTo(TaskState.FINISHED));
		assertThat(t2.state, equalTo(TaskState.FINISHED));
		assertThat(tAdded.state, equalTo(TaskState.FINISHED));
	}
	
	private function childTask1 (group:TaskGroup, t:Task) : void {
		group.addTask(t);
	}

	private function childTask2 () : void {  } 
	
	[Test(async)]
	public function removeTaskFromRunningConcurrent () : void {
		expectedEvents = new Result(1, 0, 1, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, true);
		var tt2:TimerTask = new TimerTask(150, true);
		var tg:TaskGroup = startConcurrent([tt1, tt2], TaskEvent.CANCEL, 
				TaskState.FINISHED);
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));			
		assertThat(tg.removeTask(tt2), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
		assertThat(tg.cancel(), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.FINISHED));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));		
	}
	
	[Test(async)]
	public function removeTaskFromRunningSequential () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150);
		var tt2:TimerTask = new TimerTask(150);
		var tg:TaskGroup = startSequential([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.FINISHED);	
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));
		assertThat(tg.removeTask(tt1), equalTo(true));
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
	}
	
	[Test(async)]
	public function removeAllTasksFromRunningConcurrent () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, true);
		var tt2:TimerTask = new TimerTask(150, true);
		var tg:TaskGroup = startConcurrent([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.INACTIVE);
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));	
		tg.removeAllTasks();	
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.ACTIVE));
	}
	
	[Test(async)]
	public function removeAllTasksFromRunningSequential () : void {
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		var tt1:TimerTask = new TimerTask(150, true);
		var tt2:TimerTask = new TimerTask(150, true);
		var tg:TaskGroup = startSequential([tt1, tt2], TaskEvent.COMPLETE, 
				TaskState.INACTIVE);
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));	
		tg.removeAllTasks();	
		assertThat(tt1.state, equalTo(TaskState.ACTIVE));
		assertThat(tt2.state, equalTo(TaskState.INACTIVE));
	}
	
	[Test]
	public function resultTask () : void {
		var t:ResultTask = new SimpleResultTask();
		eventCounter = new EventCounter(t);
		expectedState = TaskState.INACTIVE;
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		t.start();
		validate(Task(t));
		assertThat(t.result, equalTo("foo"));
	}
	
	[Test]
	public function resultTaskWithContextProperty () : void {
		var t:ResultTask = new SimpleResultTask("test");
		var tg:TaskGroup = new SequentialTaskGroup();
		tg.data = new Dictionary();
		tg.addTask(t);
		eventCounter = new EventCounter(tg);
		expectedState = TaskState.INACTIVE;
		expectedEvents = new Result(1, 1, 0, 0, 0, 0);
		tg.start();
		validate(Task(tg));
		assertThat(tg.data.test, equalTo("foo"));
	}
	
	[Test]
	public function rootProperty () : void {
		var t:ResultTask = new SimpleResultTask("test");
		assertThat(t.root, sameInstance(t));
		var tg1:TaskGroup = new SequentialTaskGroup();
		tg1.addTask(t);
		assertThat(t.root, sameInstance(tg1));
		var tg2:TaskGroup = new SequentialTaskGroup();
		tg2.addTask(tg1);
		assertThat(t.root, sameInstance(tg2));
	}
	
	private function onTestIllegalRestart (event:Event, data:Object = null) : void {
		validate(Task(event.target));
		assertThat(Task(event.target).start(), equalTo(false));
	}
	
	private function onTestIllegalCancel (event:Event, data:Object = null) : void {
		validate(Task(event.target));
		assertThat(Task(event.target).cancel(), equalTo(false));
	}
	
	private function onTestIllegalSkip (event:Event, data:Object = null) : void {
		validate(Task(event.target));
		assertThat(Task(event.target).skip(), equalTo(false));
	}
			
	
	private function onTestComplete (event:Event, data:Object = null) : void {
		validate(Task(event.target));
	}
	
	
	private function validate (t:Task) : void {
		assertThat(t.state, equalTo(expectedState)); 		
		var r:Result = expectedEvents;
		assertThat("Unexpected count of START events", eventCounter.getCount(TaskEvent.START), equalTo(r.start)); 		
		assertThat("Unexpected count of COMPLETE events", eventCounter.getCount(TaskEvent.COMPLETE), equalTo(r.complete)); 		
		assertThat("Unexpected count of CANCEL events", eventCounter.getCount(TaskEvent.CANCEL), equalTo(r.cancel)); 		
		assertThat("Unexpected count of ERROR events", eventCounter.getCount(ErrorEvent.ERROR), equalTo(r.error)); 		
		assertThat("Unexpected count of SUSPEND events", eventCounter.getCount(TaskEvent.SUSPEND), equalTo(r.suspend)); 		
		assertThat("Unexpected count of RESUME events", eventCounter.getCount(TaskEvent.RESUME), equalTo(r.resume)); 		
	}


}
}

import org.spicefactory.lib.task.util.SynchronousDelegateTask;
import org.spicefactory.lib.task.ResultTask;

class Result {
	
	
	public var start:uint;
	public var complete:uint;
	public var cancel:uint;
	public var error:uint;
	public var suspend:uint;
	public var resume:uint;
	
	function Result (start:uint, complete:uint, cancel:uint, error:uint,
			suspend:uint, resume:uint) {
		this.start = start;
		this.complete = complete;
		this.cancel = cancel;
		this.error = error;
		this.suspend = suspend;
		this.resume = resume;
	}
	
	
}

class NonRestartableCommandTask extends SynchronousDelegateTask {
	
	public function NonRestartableCommandTask (delegate:Object, name:String = "[CommandTask]") {
		super(delegate, name);
		setRestartable(false);
	}
	
}

class SimpleResultTask extends ResultTask {
	
	
	function SimpleResultTask (propName:String = null) {
		super(propName);
	}
	
	protected override function doStart () : void {
		setResult("foo");
	}
	
	
}

class Delegate {
	
	private var method:Function;
	private var params:Array;

	public function Delegate (method:Function, params:Array = null) {
		this.method = method;
		this.params = (params == null) ? [] : params;
	}
	
	public function invoke () : * {
		return method.apply(null, params);
	}
	
}


