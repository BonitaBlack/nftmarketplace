# NFT marketplace Project

This project includes a complete NFT marketplace build on the Oasis Emerald Paratime block chain. 

*Contents*

* A complete development environment in Hardhat which comes with a NFT smart contract, 
* A test for that contract (in future), 
* And a script that deploys that contract.
* Frontend (in future)
* Backend (in future)

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

# Preconditions (One Time Operations Only):

Install all requirements listed under https://docs.oasis.io/dapp/emerald/writing-dapps-on-emerald#create-dapp-on-emerald-with-hardhat

Run the npm update command in both folders -> (nftsmartcontract, nftfrontend)
```shell
npm update
```

# Steps to run the Frontend

```shell
cd nftfrontend
npm run dev
```

Then open http://localhost:3000 in a webbrowser

# Steps to compile and deploy the smart contract

```shell
cd nftsmartcontracts
npx hardhat compile
npx hardhat run scripts/deploy.js
```
