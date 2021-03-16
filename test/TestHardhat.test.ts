const assert = require('assert');
import { ethers } from "hardhat";

describe("Greeter", function() {
  it("Should return the new greeting once it's changed", async function() {

    const Greeter = await ethers.getContractFactory("TestHardhat");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    await greeter.setMessage("Hola, mundo!");
    assert(await greeter.greet() === 'Hola, mundo!', 'eps!');
  });
});

