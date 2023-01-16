import Debug "mo:base/Debug";

// actor class to create actors programmatically
// [Nat8] : type de données pour un tableau de nombres naturels à huits bits
actor class NFT(name: Text, owner: Principal, content: [Nat8]) {
    let itemName = name;
    let nftOwner = owner;
    let imageBytes = content;

}