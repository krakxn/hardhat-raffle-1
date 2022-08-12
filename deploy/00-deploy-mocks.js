const { network } = require("hardhat")
const {deelopmentChains, developmentChains} = require("../helper-hardhat-config")
const BASE_FEE = ethers.utils.parseEther("0.25") //0.25 is the premium to request a random number.
const GAS_PRICE_LINK = 1e9// 1e9 == 1000000000 // calculated value based on gas price of the chain. //link per gas

module.exports = async function({getNamedAccounts, deployments}) {
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const args = [BASE_FEE, GAS_PRICE_LINK]
   
    if(developmentChains.includes(network.name)){
        log("Local network deteced! Deploying Mocks...")
        //deploy a mock VRFCoordinator
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: args,
        })
        log("Mocks Deployed")
        log("-------------------------------------")
    }
}

module.exports.tags = ["all", "mocks"]