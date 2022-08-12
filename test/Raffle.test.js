const { assert } = require("chai")
const { getNamedAccounts, deployments, ethers } = require("hardhat")
const {developmentChains, networkConfig} = require("../helper-hardhat-config")

!developmentChains.includes(network.name) 
    ? describe.skip 
    : describe("Raffle Unit Tests", async function () {
        let raffle, vrfCoordinatorV2Mock
        const chainId = network.config.chainId

        beforeEach(async function() {
            const { deployer } = await getNamedAccounts()
            await deployments.fixture(["mocks", "raffle"])
            // await deployments.fixture(["all"])
            raffle = await ethers.getContract("Raffle", deployer)
            vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
        })

        describe("constructor", async function() {
            it("initializes the raffle correctly", async function() {
                const raffleState = await raffle.getRaffleState()
                const interval = await raffle.getInterval()
                assert.equal(raffleState.toString(), "0")
                assert.equal(interval.toString(), networkConfig[chainId]["interval"])
            })
        })

        console.log(".1.1.1.1.1..11..1.1.1.1.222222222")
        
    })
