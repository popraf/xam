// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./First.sol";

contract Second is First {
    string public nametwo;

    constructor() {
        nametwo = "Xamsec";
    }

}