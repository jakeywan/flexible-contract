const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('Token', () => {

  let tokenContract
  let deployerAddress

  before(async () => {
    const [deployer] = await ethers.getSigners()
    deployerAddress = deployer.address

    const Token = await ethers.getContractFactory('FlexibleContract')
    tokenContract = await Token.deploy(constructorArguments[0], constructorArguments[1])

    const Descriptor = await ethers.getContractFactory('DescriptorMock')
    const descriptor = await Descriptor.deploy()
  })

  // TESTS GO HERE ====

})
