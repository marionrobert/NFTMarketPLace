import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "../../../declarations/nft";
import { Principal } from "@dfinity/principal";
import Button from "./Button";
import { opend } from "../../../declarations/opend/index";

function Item(props) {

  const [name, setName] = useState();
  const [owner, SetOwner] = useState();
  const [image, setImage] = useState();
  const [button, setButton] = useState();
  const [priceInput, setPriceInput] = useState();

  const id = props.id;

  const localHost = "http://localhost:8080/";
  const agent = new HttpAgent({host: localHost});

  async function loadNFT(){
    const NFTActor = await Actor.createActor(idlFactory, {
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
    setButton(<Button handleClick={handleSell} text={"Sell"}/>)
  }

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
    console.log("set price =" + price);
    const listingResult = await opend.listItem(props.id, Number(price));
    console.log("listing:" + listingResult);
  }

  return (
    <div className="disGrid-item">
      <div className="disPaper-root disCard-root makeStyles-root-17 disPaper-elevation1 disPaper-rounded">
        <img
          className="disCardMedia-root makeStyles-image-19 disCardMedia-media disCardMedia-img"
          src={image}
        />
        <div className="disCardContent-root">
          <h2 className="disTypography-root makeStyles-bodyText-24 disTypography-h5 disTypography-gutterBottom">
            {name}<span className="purple-text"></span>
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
