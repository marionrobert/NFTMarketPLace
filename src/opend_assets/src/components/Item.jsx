import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "../../../declarations/nft";
import { idlFactory } from "../../../declarations/token";
import { Principal } from "@dfinity/principal";
import Button from "./Button";
import { opend } from "../../../declarations/opend/index";
import CURRENT_USER_ID from "../index";
import PriceLabel from "./PriceLabel";

function Item(props) {

  const [name, setName] = useState();
  const [owner, SetOwner] = useState();
  const [image, setImage] = useState();
  const [button, setButton] = useState();
  const [priceInput, setPriceInput] = useState();
  const [loaderHidden, setLoaderHidden] = useState(true);
  const [blur, setBlur] = useState();
  const [sellStatus, setSellStatus] = useState("");
  const [priceLabel, setPriceLabel] = useState();

  const id = props.id;

  const localHost = "http://localhost:8080/";
  const agent = new HttpAgent({host: localHost});
  // add this line for error : "Fail to Verify certificate"
  // --> "By default, the agent is configured to talk to the main Internet Computer,
  // and verifies responses using a hard-coded public key."
  // https://erxue-5aaaa-aaaab-qaagq-cai.raw.ic0.app/agent/interfaces/Agent.html#rootKey 
  // This following function will instruct the agent to ask the endpoint for its public key,
  // and use that instead. This is required when talking to a local test instance, for example
  agent.fetchRootKey();
  // --> TODO: when deploying live, remove the line above
  let NFTActor;

  async function loadNFT(){
    NFTActor = await Actor.createActor(idlFactory, {
      agent,
      canisterId: id,
    });

    const NFTname = await NFTActor.getName();
    const userID = await NFTActor.getOwner();
    const imageData = await NFTActor.getAsset();

    // make imageData (Nat8) recognised by JS in 2 steps (array of Nat8  & URL object)
    // https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Global_Objects/Uint8Array
    // https://developer.mozilla.org/en-US/docs/Web/API/URL/createObjectURL
    // https://developer.mozilla.org/en-US/docs/Web/API/Blob/Blob
    const imageContent = new Uint8Array(imageData);
    const image = URL.createObjectURL(
      new Blob([imageContent.buffer], {type: "image/png"})
    );
    
    setName(NFTname);
    SetOwner(userID.toText());
    setImage(image);
    
      if (props.role == "collection") {
        // check if the NFT is in the mapsOfListings (using isListed opend method)
        // e.d. NFT is in the transfers' list
        // if so, update the owner and blur it
        const nftIsListed = await opend.isListed(props.id);
        if (nftIsListed) {
          SetOwner("OpenD");
          setBlur({filter: "blur(4px"});
          setSellStatus("Listed");
        } else {
          setButton(<Button handleClick={handleSell} text={"Sell"}/>);
        };
      } else if (props.role == "discover") {
          const originalOwner = await opend.getOriginalOwner(props.id);
          if (originalOwner.toText() != CURRENT_USER_ID.toText()) {
            setButton(<Button handleClick={handleBuy} text={"Buy"}/>);
          };
          const price = await opend.getListedNFTPrice(props.id);
          setPriceLabel(<PriceLabel sellPrice={price.toString()} />) 
      };

    
  };

  // leave second argment "[]" empty --> the function will be called once, the first time the website is load
  useEffect(() => {
    loadNFT();
  }, []);

  let price;

  function handleSell(){
    // console.log("sell clicked");
    setPriceInput(<input
      placeholder="Price in DANG"
      type="number"
      className="price-input"
      value={price}
      onChange={(e) => price = e.target.value}
    />);
    setButton(<Button handleClick={sellItem} text={"Confirm"}/>);
    
  };

  async function sellItem(){
    setBlur({filter: "blur(4px"});
    setLoaderHidden(false);
    console.log("set price =" + price);
    const listingResult = await opend.listItem(props.id, Number(price));
    console.log("listing:" + listingResult);
    if (listingResult == "Success") {
      const openDId = await opend.getOpenDCanisterID();
      const transferResult = await NFTActor.transferOwnership(openDId);
      console.log("transfer:" + transferResult);
      if (transferResult == "Success") {
        setLoaderHidden(true);
        setButton();
        setPriceInput();
        SetOwner("OpenD");
      };
    };
  };

  async function handleBuy() {
    console.log("Buy was triggered");

  };

  return (
    <div className="disGrid-item">
      <div className="disPaper-root disCard-root makeStyles-root-17 disPaper-elevation1 disPaper-rounded">
        <img
          className="disCardMedia-root makeStyles-image-19 disCardMedia-media disCardMedia-img"
          src={image}
          style={blur}
        />
        
        <div className="lds-ellipsis"
              hidden={loaderHidden}>
                <div></div>
                <div></div>
                <div></div>
                <div></div>
        </div>
        <div className="disCardContent-root">
          {priceLabel}
          <h2 className="disTypography-root makeStyles-bodyText-24 disTypography-h5 disTypography-gutterBottom">
            {name}<span className="purple-text"> {sellStatus}</span>
          </h2>
          <p className="disTypography-root makeStyles-bodyText-24 disTypography-body2 disTypography-colorTextSecondary">
            Owner: {owner}
          </p>
          {priceInput}
          {button}
        </div>
      </div>
    </div>
  );
}

export default Item;
