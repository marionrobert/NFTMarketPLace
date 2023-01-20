import Cycles "mo:base/ExperimentalCycles";
import NFTActorClass "../NFT/nft";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Iter "mo:base/Iter";

actor OpenD {

    // create a new data-type
    private type Listing = {
        itemOwner: Principal;
        itemPrice: Nat;
    };

    var mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);
    // listings = disponiblités à la vente
    // key = NFTid (principal); value = Listing{itemOwner: Principal, itemPrice:Nat}
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

    public query func getListedNFTs() : async [Principal]{
       let ids = Iter.toArray(mapOfListings.keys());
       return ids;
    } ;

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

    // check if the NFT (with id) is regeistered in the list of transfer (mapOflistings)
    public query func isListed(id: Principal) : async Bool {
        if (mapOfListings.get(id) == null) {
            return false;
        } else {
            return true;
        }
    };

    public query func getOriginalOwner(nftId: Principal) : async Principal {
        var listing : Listing = switch (mapOfListings.get(nftId)) {
            case null return Principal.fromText("");
            case (?result) result;
        }; 

        return listing.itemOwner;
    };

    public query func getListedNFTPrice(nftId: Principal) : async Nat {
        var listing : Listing = switch (mapOfListings.get(nftId)) {
            case null return 0;
            case (?result) result;
        }; 

        return listing.itemPrice;
    };

    public shared(msg) func completePurchase(nftId: Principal, currentOwnerId: Principal, newOwnerId: Principal) : async Text {
        // pull up/identify the puchased NFT 
        var purchasedNFT : NFTActorClass.NFT = switch (mapOfNFTs.get(nftId)){
            case null return "NFT does not exist";
            case (?result) result
        };

        // transfert the NFT over to the newOwner
        // the NFT has a new owner registered
        let transferResult = await purchasedNFT.transferOwnership(newOwnerId);


        if (transferResult == "Success") {

            // delete the NFT from our maOfListings
            mapOfListings.delete(nftId);

        // delete the NFT from the previous owner's registered list of owned NFTs
            // first get the NFTs owned by the previous owner
            var ownedNFTs : List.List<Principal> = switch (mapOfOwners.get(currentOwnerId)) {
                case null List.nil<Principal>();
                case (?result) result
            };
            // update the list of owned nfts by the previous owner
            // by returning a new list without the NFT purchased bcs it doesn't enter the condition listItemId != id
            ownedNFTs := List.filter(ownedNFTs, func(listItemId: Principal) : Bool {
                return listItemId != nftId;
            });

            // update the mapOfOwners with the updated list of NFT's owned by the previous owner
            //mapOfOwners.put(currentOwnerId, ownedNFTs)

            //add the purchased NFT to the new owner's list of owned NFTs, in the mapOfOwners
            addToOwnershipMap(newOwnerId, nftId);
            return "Success"

        } else {

            return transferResult;
            
        };
    };
};
