
package evsm;

import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

/**

The FState class takes two type parameters, the first is the type of the object
that contains the state, and the second is the type of the object that will be
used as event objects. Each modifying function in FState returns the state that
it was called upon, allowing them to be chained together.

**/

class FState<T: (StateObject),U: (EventObject)>{



    /**
    *
    * The name is used for debugging/identification purposes, and is not
    * utilized internally.
    *
    **/

    public var name:String;



    /**
    *
    * Creates a new State object.
    *
    * @param name The name to assign to this state. Defaults to "unnamed" 
    *
    **/

    public function new(n:String = "unnamed") 
    { 
        name = n;
    } 



    /**
    *
    * Sets the state to transition to on the given event.
    *
    * @param toState The state to transition to.
    *
    * @param eventID The eventID that triggers this transition.
    *
    * @returns Returns this state.
    *
    **/

    public function setTransition(eventID:String,toState:FState<T,U>):FState<T,U>
    {
        transitions.set(eventID,toState);
        return this;
    }



    /**
    *
    * Sets the callback to invoke on the given event. 
    *
    * @param eventID The eventID that triggers this transition.
    *
    * @param func The function to call. Must be type `T->Void` or `T->U->Void`.
    *
    * @returns Returns this state.
    *
    **/

    public function onEvent(eventID:String,?funcA:T->Void,?funcB:T->U->Void)
    {
        if(funcA == null && funcB == null)
        {
            trace("No argument given to set onEvent on state " + name);
            return this;
        }
        if(funcA != null && funcB != null)
        {
            trace("Too many arguments given to set onEvent on state " + name);
            return this;
        }

        if(funcA != null)
        {
            eventActions.set(eventID,function(t:T,u:U){funcA(t);});
        }
        if(funcB != null)
        {
            eventActions.set(eventID,funcB);
        }
        return this;
    }



    /**
    *
    * Sets the callback to invoke when this state is updated. 
    *
    * @param func The function to call. Must be type `T->Void`.
    *
    * @returns Returns this state.
    *
    **/

    public function setUpdate(func:T->Void):FState<T,U>
    {
        setCallback(CB_UPDATE,func);
        return this;
    }



    /**
    *
    * Sets the callback to invoke when an object transitions to this state.
    *
    * To invoke the start function when an object first takes a class, create
    * a blank dummy state and use `transitionTo`.
    *
    * @param func The function to call. Must be type `T->Void` or `T->U->Void`.
    *
    * @returns Returns this state.
    *
    **/

    public function setStart(?funcA:T->Void,?funcB:T->U->Void):FState<T,U>
    {
        setCallback(CB_START,funcA,funcB);
        return this;
    }



    /**
    *
    * Sets the callback to invoke when an object transitions out of this state.
    *
    * @param func The function to call. Must be type `T->Void` or `T->U->Void`.
    *
    * @returns Returns this state.
    *
    **/

    public function setEnd(?funcA:T->Void,?funcB:T->U->Void):FState<T,U>
    {
        setCallback(CB_END,funcA,funcB);
        return this;
    }



    /**
    *
    * Adds a parent to this state, and uses the given parameters. For more
    * information, [look here.](https://github.com/sepharoth213/evsm-hx/wiki/State-Parents-and-Hierarchy)
    *
    * @param parent The state to add as a parent.
    *
    * @param params An optional array of parameters to pass to the parent state.
    *
    * @returns Returns this state.
    *
    **/

    public function addParent(parent:FState<T,U>,?params:Array<Dynamic>):FState<T,U>
    {
        parents.push(parent);

        if(params != null)
        {
            parameters.set(parent,params);
        }
        return this;
    }



    /**
    *
    * Gets the `i`th parameter passed into this parent state. For more 
    * information, [look here.](https://github.com/sepharoth213/evsm-hx/wiki/State-Parents-and-Hierarchy)
    *
    * @param i The index of the parameter to get.
    *
    * @returns Returns the parameter.
    *
    **/

    public function getParameter(i:Int):Dynamic
    {
        return currentParameters.get(this)[i];
    }



    /**
    *
    * Switches an object to the given state, invoking _this_ state's end
    * callback. The object's state is not used.
    *
    * @param obj The object to operate on. Must be type `T`.
    *
    **/

    public function switchTo(obj:T,toState:FState<T,U>,event:U):Void
    {
        end(obj,event);
        obj.state = toState;
        toState.start(obj,event);
    }



    /**
    *
    * Processes an event with this state, invoking transitions if there are any.
    * The transitions will operate on the given object.
    *
    * @param obj The object to operate on. Must be type `T`.
    *
    * @param event The event to send to process.
    *
    * @returns Returns true if a transition occurred, false otherwise.
    *
    **/

    public function processEvent(obj:T,event:U):Bool
    {
        if(eventActions.exists(event.id))
        {
            eventActions.get(event.id)(obj,event);
        }
        if(transitions.exists(event.id))
        {
            switchTo(obj,transitions.get(event.id),event);
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



    /**
    *
    * Invokes the update callback for this state if there is one.
    *
    * @param obj The object to operate on. Must be type `T`.
    *
    **/

    public function update(obj:T):Bool
    {
        if(processCallback(obj,CB_UPDATE,this))
        {
            return true;
        }

        return false;
    }


    private function setCallback(i:Int,?funcA:T->Void,?funcB:T->U->Void)
    {
        if(funcA == null && funcB == null)
        {
            trace("No argument given to set callback on state " + name);
            return this;
        }
        if(funcA != null && funcB != null)
        {
            trace("Too many arguments given to set callback on state " + name);
            return this;
        }
        if(funcA != null)
        {
            callbacks[i] = function(t:T,u:U){funcA(t);};
        }
        if(funcB != null)
        {
            callbacks[i] = funcB;
        }
        return this;
    }

    private function processCallback(obj:T, i:Int, parameterRef:FState<T,U>, ?event:U):Bool
    {

        currentParameters = parameterRef.parameters;

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
    var currentParameters:ObjectMap<FState<T,U>,Array<Dynamic>>;

    var eventActions:StringMap<T->U->Void> = new StringMap<T->U->Void>();
    var transitions:StringMap<FState<T,U>> = new StringMap<FState<T,U>>();
}