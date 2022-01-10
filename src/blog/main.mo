import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {

    public type Message = {
        content: Text;
        time: Time.Time;
    };

    public type Microblog = actor {
        follow: shared(Principal) -> async ();
        follows: shared query () -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Time.Time) -> async [Message];
        timeline: shared (Time.Time) -> async [Message];
    };

    stable var followed : List.List<Principal> = List.nil();

    public shared func follow(id: Principal): async () {
        followed := List.push(id, followed);
    };

    public shared query func follows() : async [Principal] {
        List.toArray(followed);
    };

    var messages : List.List<Message> = List.nil();

    public shared func post(text: Text) : async () {
        let msg = {
            content = text;
            time = Time.now();
        };
        messages := List.push(msg, messages);
    }; 

    public shared query func posts(since: Time.Time) : async [Message] {
        let after : Message -> Bool = func(a) { a.time > since };
        List.toArray(List.filter(messages, after));
    };

    public shared func timeline(since: Time.Time) : async [Message] {
        var all : List.List<Message> = List.nil();

        for (id in Iter.fromList(followed)) {
            let canister: Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for (msg in Iter.fromArray(msgs)) {
                all := List.push(msg, all);
            };
        };

        List.toArray(all);
    };

};

