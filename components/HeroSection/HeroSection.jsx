import React, { useState, useEffect, useContext } from "react";
import Image from "next/image";
import { useRouter } from "next/router";

//INTERNAL IMPORT
import Style from "./HeroSection.module.css";
import StylePrice from "../LivePrice/LivePrice.module.css"
import { Button } from "../componentsindex";
import {Price} from "../componentsindex";
import images from "../../img";

//SMART CONTRACT IMPORT
import { NFTMarketplaceContext } from "../../Context/NFTMarketplaceContext";

const HeroSection = () => {
  const { titleData } = useContext(NFTMarketplaceContext);
  const router = useRouter();
  return (
    <div className={Style.heroSection}>
      <div className={Style.heroSection_box}>
        <div className={Style.heroSection_box_left}>
          <h1>{titleData}</h1>
          <div className={StylePrice.PriceContainer}>
            <Price coin="BITCOIN"/>
            <Price coin="ROSE"/>
            <Price coin="ETHEREUM"/>
          </div>
          <Button
            btnName="Start your search"
            handleClick={() => router.push("/searchPage")}
          />
        </div>
        <div className={Style.heroSection_box_right}>
          <Image
            src={images.hero3}
            alt="Hero section"
            width={600}
            height={300}
            layout="responsive"
            objectFit="none"
            className={Style.coolImage}
          />
        </div>
      </div>
    </div>
  );
};

export default HeroSection;
