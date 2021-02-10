import "./ownable.sol";
import "./safemath.sol";
import "./erc721.sol";
contract MonsterFactory is Ownable, ERC721 {
  using SafeMath for uint256;

  event NewMonster(uint monsterId, uint dna, bool sellable);

  struct Monster {
    uint dna;
    bool sellable;
  }

  uint dnaHexDigits = 4;
  uint dnaModulus = 16 ** dnaHexDigits;
  Monster[] public monsters;
  mapping (uint => address) public monsterToOwner;
  mapping (address => uint) ownerMonsterCount;
  mapping (uint => address) monsterApprovals;
  uint monsterCreationFee = 0.01 ether;

  modifier onlyOwnerOf(uint _monsterId) {
    require(msg.sender == monsterToOwner[_monsterId]);
    _;
  }

  function getMonsterCreationFee() external view returns (uint _fee){
    return monsterCreationFee;
  }

  function setMonsterCreationFee(uint _fee) external onlyOwner {
    monsterCreationFee = _fee;
  }

  function createNewMonster() external payable {
    require(msg.value == monsterCreationFee);
    require(ownerMonsterCount[msg.sender] == 0);
    uint randDna = _generateMonsterDna(msg.sender);
    _createMonster(randDna);
  }

  function buyMonster(uint _monsterId) external payable {
    Monster storage monster = monsters[_monsterId];
    require(monster.sellable);
    uint monsterPrice = (monster.dna * 0.0001 ether + 0.001 ether);
    require(msg.value == monsterPrice);
    address owner = ownerOf(_monsterId);
    _transfer(owner, msg.sender, _monsterId);
    monster.sellable = false;
  }

  function changeSellable(uint256 _monsterId, bool _sellable) public onlyOwnerOf(_monsterId) {
    monsters[_monsterId].sellable = _sellable;
  }

  function transfer(address _to, uint256 _tokenId) public override(ERC721) onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public override(ERC721) onlyOwnerOf(_tokenId) {
    monsterApprovals[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public override(ERC721) {
    require(monsterApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }

  function _createMonster(uint _dna) internal {
    monsters.push(Monster(_dna, false));
    uint id = monsters.length - 1;
    monsterToOwner[id] = msg.sender;
    ownerMonsterCount[msg.sender]++;
    NewMonster(id, _dna, false);
  }

  function _generateMonsterDna(address _add) private view returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(_add)));
    return rand % dnaModulus;
  }

  function getMonstersByOwner(address _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](ownerMonsterCount[_owner] + 1);
    result[0] = monsters.length;
    uint counter = 1;
    for (uint i = 0; i < monsters.length; i++) {
      if (monsterToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  function balanceOf(address _owner) public view override(ERC721) returns (uint256 _balance) {
    return ownerMonsterCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view override(ERC721) returns (address _owner) {
    return monsterToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {
    ownerMonsterCount[_to] = ownerMonsterCount[_to].add(1);
    ownerMonsterCount[msg.sender] = ownerMonsterCount[msg.sender].sub(1);
    monsterToOwner[_tokenId] = _to;
    Transfer(_from, _to, _tokenId);
  }
}
