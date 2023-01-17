import Cycles "mo:base/ExperimentalCycles";
import NFTActorClass "../NFT/nft";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import List "mo:base/List";

actor OpenD {

    var mapOfNFTS = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);

    public shared(msg) func mint(imgData: [Nat8], name: Text) : async Principal{
        let owner : Principal = msg.caller;

        Debug.print(debug_show(Cycles.balance()));
        // 1 milliard to create a new canister, + 500millions pour le garder up and running
        Cycles.add(100_500_000_000);
        // those cycles will com from this principal canister (OpenD) and be allocated to the next canister created
        let newNFT = await NFTActorClass.NFT(name, owner, imgData);
        Debug.print(debug_show(Cycles.balance()));

        let newNFTPrincipal = await newNFT.getCanisterId();
        mapOfNFTS.put(newNFTPrincipal, newNFT);
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
 
};
