import Debug "mo:base/Debug";

// use actor class to create actors programmatically
// [Nat8] : type de données pour un tableau de nombres naturels à huits bits
actor class NFT(name: Text, owner: Principal, content: [Nat8]) {
    let itemName = name;
    let nftOwner = owner;
    let imageBytes = content;

    public query func getName() : async Text {
        return itemName;
    };

    public query func getOwner() : async Principal {
        return nftOwner;
    };

    public query func getAsset() : async [Nat8] {
        return imageBytes;
    };
}