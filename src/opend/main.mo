import Cycles "mo:base/ExperimentalCycles";
import NFTActorClass "../NFT/nft";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import List "mo:base/List";

actor OpenD {

    // create a new data-type
    private type Listing = {
        itemOwner: Principal;
        itemPrice: Nat;
    };

    var mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);
    var mapOfListings = HashMap.HashMap<Principal, Listing>(1, Principal.equal, Principal.hash);

    public shared(msg) func mint(imgData: [Nat8], name: Text) : async Principal{
        let owner : Principal = msg.caller;

        Debug.print(debug_show(Cycles.balance()));
        // 1 milliard to create a new canister, + 500millions pour le garder up and running
        Cycles.add(100_500_000_000);
        // those cycles will com from this principal canister (OpenD) and be allocated to the next canister created
        let newNFT = await NFTActorClass.NFT(name, owner, imgData);
        Debug.print(debug_show(Cycles.balance()));

        let newNFTPrincipal = await newNFT.getCanisterId();
        mapOfNFTs.put(newNFTPrincipal, newNFT);
        addToOwnershipMap(owner, newNFTPrincipal);
        
        return newNFTPrincipal;
    };


    private func addToOwnershipMap(owner: Principal, nftId: Principal) {

        // get hold of the list of canisters IDs for a particular owner
        var ownedNFTs : List.List<Principal>  = switch (mapOfOwners.get(owner)) {
            // in case where mapOfOwners.get(owner) returns null, ownedNFTs = empty list
            case null List.nil<Principal>();
            case (?result) result;
        };

        // add new nftID to this list
        ownedNFTs := List.push(nftId, ownedNFTs);

        // update the mapOfOwners with the new list of ownedNFTs>
        mapOfOwners.put(owner, ownedNFTs)
    };


    public query func getOwnedNFTs(user: Principal) : async [Principal]{
        var userNFTs : List.List<Principal> = switch (mapOfOwners.get(user)) {
            case null List.nil<Principal>();
            case (?result) result;
        };

        return List.toArray(userNFTs);
    };

    public shared(msg) func listItem(nftId: Principal, price: Nat) : async Text {
        var item : NFTActorClass.NFT = switch (mapOfNFTs.get(nftId)) {
            case null return "NFT does not exist.";
            case (?result) result;
        };

        let owner = await item.getOwner();
        // l'utilisateur appelant la méthode est-il le propriétaire de la NFT ?
        if (Principal.equal(owner, msg.caller)) {
            let newListing : Listing = {
                itemOwner = owner;
                itemPrice = price;
            };
            mapOfListings.put(nftId, newListing);
            return "Success"
        } else {
            return "You don't own the NFT."
        };
    };

    public query func getOpenDCanisterID() : async Principal {
        return Principal.fromActor(OpenD);
    };
  
};
