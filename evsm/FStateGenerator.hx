
package evsm;

class FStateGenerator<T: (StateObject),U: (EventObject)> {

    // public var id:FighterEventID;

    public function new()
    {
    }

    public function newState(?name:String)
    {
        return new FState<T,U>(name);
    }
}