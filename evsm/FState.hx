
package evsm;

import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

// The FState class takes two type parameters, the first is the type of the object that contains the state,
// and the second is the type of the object that will be used as event objects.
// Each modifying function in FState returns the state that it was called upon, allowing them to be chained together.
 
class FState<T: (StateObject),U: (EventObject)>{

    //The name is used for debugging purposes, and is not utilized within the class.
    public var name:String;

    public function new(n:String = "Unnamed") 
    { 
        name = n;
    } 

    //addTransition adds a basic link between two states: if an event with the given ID is recieved by this state, it
    //will transition to the one specified.
    public function addTransition(toState:FState<T,U>,eventID:String):FState<T,U>
    {
        eventActions.set(eventID,toState);
        return this;
    }

    //FStates have 3 separate callback functions that are called at distinct times during the 
    public function setUpdate(func1:T->Void):FState<T,U>
    {
        setCallback(CB_UPDATE,func1);
        return this;
    }

    public function setStart(?func1:T->Void,?func2:T->U->Void):FState<T,U>
    {
        setCallback(CB_START,func1,func2);
        return this;
    }

    public function setEnd(?func1:T->Void,?func2:T->U->Void):FState<T,U>
    {
        setCallback(CB_END,func1,func2);
        return this;
    }

    public function addParent(parent:FState<T,U>,?params:Array<Dynamic>):FState<T,U>
    {
        parents.push(parent);

        if(params != null)
        {
            parameters.set(parent,params);
        }
        return this;
    }

    public function getParameter(i:Int):Dynamic
    {
        return currentParameterRef.get(this)[i];
    }

    public function switchTo(obj:T,toState:FState<T,U>,event:U):Void
    {
        end(obj,event);
        obj.state = toState;
        toState.start(obj,event);
    }

    public function processEvent(obj:T,event:U):Bool
    {
        if(eventActions.exists(event.id))
        {
            switchTo(obj,eventActions.get(event.id),event);
            return true;
        }
        for(parent in parents)
        {
            if(parent.processEvent(obj,event))
            {
                return true;
            }
        }
        return false;
    }

    public function update(obj:T):Bool
    {
        if(processCallback(obj,CB_UPDATE,this))
        {
            return true;
        }

        return false;
    }


    private function setCallback(i:Int,?func1:T->Void,?func2:T->U->Void)
    {
        if(func1 == null && func2 == null)
        {
            trace("No argument given to set callback on state " + name);
            return this;
        }
        if(func1 != null && func2 != null)
        {
            trace("Too many arguments given to set callback on state " + name);
            return this;
        }
        if(func1 != null)
        {
            callbacks[i] = function(t:T,u:U){func1(t);};
        }
        if(func2 != null)
        {
            callbacks[i] = func2;
        }
        return this;
    }

    private function processCallback(obj:T, i:Int, parameterRef:FState<T,U>, ?event:U):Bool
    {

        currentParameterRef = parameterRef.parameters;

        var currentState = obj.state;

        if(callbacks[i] != null)
        {
            callbacks[i](obj,event);
            if(obj.state != currentState)
            {
                return true;
            }
        }

        for(parent in parents)
        {
            if(parent.processCallback(obj, i, this,event))
            {
                return true;
            }
        }
        return false;
    }

    private function start(obj:T,?event:U):Bool
    {
        return processCallback(obj,CB_START, this, event);
    }

    private function end(obj:T,?event:U):Bool
    {
        return processCallback(obj,CB_END, this, event);
    }

    var CB_UPDATE:Int = 0;
    var CB_START:Int = 1;
    var CB_END:Int = 2;

    var callbacks:Array<T->U->Void> = [function(f,u){},function(f,u){},function(f,u){}];
    var parents:Array<FState<T,U>> = [];
    
    var parameters:ObjectMap<FState<T,U>,Array<Dynamic>> = new ObjectMap<FState<T,U>,Array<Dynamic>>();
    var currentParameterRef:ObjectMap<FState<T,U>,Array<Dynamic>>;

    var eventActions:StringMap<FState<T,U>> = new StringMap<FState<T,U>>();
}