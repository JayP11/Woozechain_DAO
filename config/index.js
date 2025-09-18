/* eslint-disable no-undef */
"use strict";
require("dotenv").config();
const {
    
  } = require("./initializer.json")
const {
   
  } = require('./contract.json')

const {
    POLYGON_RPC,
    ETHEREUM_RPC,
    SEPOLIA_RPC,
    AMOY_RPC,
    ACCOUNT_PRIVATE_KEY,
    POLYGONSCAN_API_KEY,
    ETHERSCAN_API_KEY,
    TEST_ACCOUNT_PRIVATE_KEY
  } = process.env

module.exports = {
    POLYGON_RPC,
    ETHEREUM_RPC,
    SEPOLIA_RPC,
    AMOY_RPC,
    ACCOUNT_PRIVATE_KEY,
    POLYGONSCAN_API_KEY,
    ETHERSCAN_API_KEY,
    TEST_ACCOUNT_PRIVATE_KEY
  };