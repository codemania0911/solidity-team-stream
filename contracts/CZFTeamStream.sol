//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICZFToken {
    function mint(address to, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;
}

contract CZFTeamStream is Ownable {
    struct Member {
        address account;
        uint256 lastUpdatedBlock;
        uint256 allocPoint;
        uint256 debt;
    }

    Member[] public members;
    uint256 public totalAllocPoints;
    uint256 public czfPerBlock;
    uint256 public lastMintBlock;

    address public token = 'put your token';

    function getPending(uint256 _memberId)
        public
        view
        returns (uint256 amount_)
    {
        Member storage member = members[_memberId];
        return
            ((czfPerBlock *
                (block.number - member.lastUpdatedBlock) *
                member.allocPoint) / totalAllocPoints) + member.debt;
    }

    function claim(uint256 _memberId) external {
        mintCZFToStream();
        Member storage member = members[_memberId];
        uint256 amount;

        amount = getPending(_memberId);
        member.debt = 0;
        member.lastUpdatedBlock = block.number;

        ICZFToken(token).transfer(member.account, amount);
    }

    function massUpdateMembers() public {
        mintCZFToStream();
        for (uint256 i = 0; i < members.length; i++) {
            updateMember(i);
        }
    }

    function updateMember(uint256 _memberId) public {
        Member storage member = members[_memberId];
        if (member.allocPoint == 0) return;
        member.debt = getPending(_memberId);
        member.lastUpdatedBlock = block.number;
    }

    function mintCZFToStream() public {
        if (lastMintBlock == 0) lastMintBlock = block.number;
        ICZFToken(token).mint(
            address(this),
            czfPerBlock * (block.number - lastMintBlock)
        );
        lastMintBlock = block.number;
    }

    function setCZFPerBlock(uint256 amount, bool _withUpdate)
        external
        onlyOwner
    {
        if (_withUpdate) massUpdateMembers();
        czfPerBlock = amount;
    }

    function changeAddress(uint256 _memberId, address _account)
        external
        onlyOwner
    {
        members[_memberId].account = _account;
    }

    function update(
        uint256 _memberId,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) massUpdateMembers();
        totalAllocPoints =
            totalAllocPoints -
            members[_memberId].allocPoint +
            _allocPoint;
        members[_memberId].allocPoint = _allocPoint;
    }

    function add(
        address _account,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) massUpdateMembers();
        Member memory member;

        member.account = _account;
        member.allocPoint = _allocPoint;
        member.lastUpdatedBlock = block.number;

        totalAllocPoints += _allocPoint;

        members.push(member);
    }
}
