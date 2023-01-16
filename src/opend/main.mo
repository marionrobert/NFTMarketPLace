import Cycles "mo:base/ExperimentalCycles";
import NFTActorClass "../NFT/nft";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";



actor OpenD {

    public shared(msg) func mint(imgData: [Nat8], name: Text) : async Principal{
        let owner : Principal = msg.caller;

        Debug.print(debug_show(Cycles.balance()));
        // 1 milliard to create a new canister, + 500millions pour le garder up and running
        Cycles.add(100_500_000_000);
        // those cycles will com from this principal canister (OpenD) and be allocated to the next canister created
        let newNFT = await NFTActorClass.NFT(name, owner, imgData);
        Debug.print(debug_show(Cycles.balance()));

        let newNFTPrincipal = await newNFT.getCanisterId();

        return newNFTPrincipal;
    };
 
};
