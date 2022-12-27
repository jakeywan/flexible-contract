const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('Contract', () => {

  let tokenContract
  let deployerAddress

  before(async () => {
    const [deployer] = await ethers.getSigners()
    deployerAddress = deployer.address

    const Token = await ethers.getContractFactory('Contract')
    tokenContract = await Token.deploy()

    const Descriptor = await ethers.getContractFactory('DescriptorMock')
    const descriptor = await Descriptor.deploy()
  })

  // TESTS GO HERE ====
  it('Should mint', async () => {
    const mint = await tokenContract.mint(
      {
        descriptor: ethers.constants.AddressZero,
        tokenURI: "https://test.com",
        isOnChain: false
      }, {
        image: "",
        imageUriType: 0,
        animationUrl: "",
        animationUrlUriType: 0,
        jsonKeyValues: ""
      })
    await mint.wait()

    expect(await tokenContract.balanceOf(deployerAddress)).to.equal(1)

    let tokenUri = await tokenContract.tokenURI(0)
    console.log(tokenUri)
    // expect(await tokenContract.tokenURI(0)).to.equal(1)
  })

  it('Should mint on chain', async () => {
    const mint = await tokenContract.mint(
      {
        descriptor: ethers.constants.AddressZero,
        tokenURI: "",
        isOnChain: true
      }, {
        image: `<svg height="100" width="100">
        <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" />
        Sorry, your browser does not support inline SVG.  
      </svg>`,
        imageUriType: 0,
        animationUrl: "",
        animationUrlUriType: 0,
        jsonKeyValues: '"exampleMetadata": "test", "anotherExample": "testTwo"'
      })
    await mint.wait()

    let tokenUri = await tokenContract.tokenURI(1)
    console.log('tokenUri', tokenUri)
    expect(await tokenContract.balanceOf(deployerAddress)).to.equal(2)
  })

  it('Should mint on chain w/o jsonKeyValuePairs', async () => {
    const mint = await tokenContract.mint(
      {
        descriptor: ethers.constants.AddressZero,
        tokenURI: "",
        isOnChain: true
      }, {
        image: `<svg>bla</svg>`,
        imageUriType: 0, // 0 == 1st option in UriType, "SVG"
        animationUrl: "https://www.leegte.org/nft/bla.html",
        animationUrlUriType: 2, // 2 == 3rd option in UriType enum, "URL"
        jsonKeyValues: '"name": "bla", "description: "bla", "external_url": "project website"'
      })
    await mint.wait()

    let tokenUri = await tokenContract.tokenURI(2)
    console.log('tokenUri', tokenUri)
    expect(await tokenContract.balanceOf(deployerAddress)).to.equal(3)
  })

  it('Should run to print latest results', async () => {
    expect(await tokenContract.balanceOf(deployerAddress)).to.equal(3)
  })

})
