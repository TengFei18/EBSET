pragma solidity ^0.4.18;

// Event tickets TOKEN STARTS HERE

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a % b;
    //uint256 z = a / b;
    assert(a == (a / b) * b + c); // There is no case in which this doesn't hold
    return c;
  }

}

contract Ownable {

  address public owner;
  address public superOwner ;  

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == superOwner ) ;
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

function transferSuperOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(superOwner, newOwner);
    superOwner = newOwner;
  }


}

contract Restrictable is Ownable {
    
    address public restrictedAddress;
    event RestrictedAddressChanged(address indexed restrictedAddress);
    
    function Restrictable() {
        restrictedAddress = address(0);
    }

    function setRestrictedAddress(address _restrictedAddress) onlyOwner public {
      restrictedAddress = _restrictedAddress;
      emit RestrictedAddressChanged(_restrictedAddress);
      transferOwnership(_restrictedAddress);
    }
    
    modifier notRestricted(address tryTo) {
        if(tryTo == restrictedAddress) {
            revert();
        }
        _;
    }
}

contract BasicToken is ERC20Basic, Restrictable {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) notRestricted(_to) public returns (bool) {
    require(_to != address(0));

    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

function burn(uint256 _value, address _from) onlyOwner public returns (bool) {

    require(_value <= balances[_from]);
    balances[_from] = balances[_from].sub(_value);
    balances[address(0)] = balances[address(0)].add(_value);
    return true;
  }


}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  function transferFrom(address _from, address _to, uint256 _value) notRestricted(_to) public returns (bool) {
    require(_to != address(0));
    
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {

   

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

 
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

 
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Mintable token
 * @dev ERC20 Token, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {

  uint32 public constant decimals = 0;
  uint256 public constant MAX_SUPPLY = 700000000 * (10 ** uint256(decimals)); // 700MM tokens hard cap

  event Mint(address indexed to, uint256 amount);

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */

  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    uint256 newTotalSupply = totalSupply.add(_amount);
    require(newTotalSupply <= MAX_SUPPLY); // never ever allows to create more than the hard cap limit
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

}

// EVENT Token deployed in KOVAN at: 
// https://kovan.etherscan.io/address/0xf3ce15586a132855b2a13f37ad1c226f1525a744

contract EVENTToken is MintableToken 

{
  string public constant name = "Event Token";
  string public constant symbol = "EVENT";

 function EVENTToken() { totalSupply = 0 ; } // initializes to 0 the total token supply 
 
}


// Contract deployed in KOVAN at
// https://kovan.etherscan.io/address/0xa52c8371d379d7036a862673b08bd73faf4660fd



contract EVENTMarketplace is Ownable
{
  event log(string) ; 
  
// CHANGE BELOW ADDRESS to the real one deployed token address 
  EVENTToken public token = EVENTToken(0xd45968f99ce42c63b2ee728bf4ccf63c19166bc0) ;
  
  uint public constant tokensReward = 10 ; 
  uint public constant tokensPenalty = 20 ; 

struct buyer
      {
        uint qtyBought ; 
        uint priceBought ; 
      }

buyer public thisBuyer ; 


  struct Ticket 
      {
         
        string Description ;
        uint maxBuyPerWallet ;
        uint originalPrice ; 
        uint askPrice ; // current market spot price 
        uint tokensRewardOverride ; 
        uint tokensPenaltyOverride ; 
        address seller ; 
        uint qtyAvailable ; 
       mapping (address => buyer) buyers ; 
      }
    
    Ticket[] public tickets ; 
    Ticket public oneTicket ; 



  struct user 
      {
        uint joinedOn ; // when user joined the platform, unix timestamp
        uint qtyTicketsPurchased ;
        uint qtyTicketsSold ; 
        uint sellerRating ; 
        uint buyerRating ; 
      }
  
    mapping (address => user) public wallets ; 

 function EVENTMarketplace() 
  {


  } 
 

function buy(uint _ticketID, uint _price, address _buyer, uint _qty) public returns (bool)
// 0, 300, 0x692a70d2e424a56d2c6c27aa97d1a86395877b3a, 3

{
  // make sure there are enough tickets available to sell 
require( tickets[_ticketID].qtyAvailable > 0 ) ;
require ( _qty > 0 ) ; 
require ( (tickets[_ticketID].qtyAvailable - _qty) >= 0 ) ; 
require( _price >= tickets[_ticketID].askPrice ) ;
require ( (tickets[_ticketID].buyers[_buyer].qtyBought + _qty) <= tickets[_ticketID].maxBuyPerWallet ) ; 
emit log("1"); 

// selling price higher than original price --> penalize seller burning tokens  
if (_price > tickets[_ticketID].originalPrice ) 

{
  uint penalty ; 
  emit log("2") ; 
  if (tokensPenalty > tickets[_ticketID].tokensPenaltyOverride )
      penalty = tokensPenalty ; 
        else penalty = tickets[_ticketID].tokensPenaltyOverride ; 

  require (token.balanceOf(tickets[_ticketID].seller) > penalty )  ;
  emit log("3");   
  // tokens from seller are burnt
  require (token.burn(penalty,tickets[_ticketID].seller)) ; 
  emit log("4"); 
}

// selling price lower than original price --> reward seller w/ tokens 
if (_price < tickets[_ticketID].originalPrice ) 
{
  emit log("5"); 
  
  uint reward ; 
  if (tokensReward > tickets[_ticketID].tokensRewardOverride )  
      reward = tokensReward ; 
        else reward = tickets[_ticketID].tokensRewardOverride ; 

  require (token.mint(tickets[_ticketID].seller,reward)); 
}

// selling price same as original price --> nothing happens 
if (_price == tickets[_ticketID].originalPrice ) { emit log("6"); }

// records the sell 
tickets[_ticketID].qtyAvailable = tickets[_ticketID].qtyAvailable - _qty ; 
tickets[_ticketID].buyers[_buyer].qtyBought = tickets[_ticketID].buyers[_buyer].qtyBought + _qty ; 
tickets[_ticketID].buyers[_buyer].priceBought = _price ; 

// reward buyer with tokens for the current transaction 
require( rewardBuyer(_buyer,_qty) ) ; 
emit log ("7") ; 

// updates user's wallets stats 
wallets[_buyer].qtyTicketsPurchased = wallets[_buyer].qtyTicketsPurchased + _qty ; 

wallets[tickets[_ticketID].seller].qtyTicketsSold = 
wallets[tickets[_ticketID].seller].qtyTicketsSold + _qty ; 

return true  ; 

} // END OF buy() 



function rateBuyer(address _buyer, uint _rating) onlyOwner public returns (bool)

{
require(_rating >= 1 && _rating <=5);
require (wallets[_buyer].qtyTicketsPurchased > 0) ; 

// ( currentScore * (TotalQty -1) + _rating ) / TotalQty 
uint score ; 

if (wallets[_buyer].buyerRating == 0 ) score = _rating ; 
  else 
    score = ( ( wallets[_buyer].buyerRating * (wallets[_buyer].qtyTicketsPurchased - 1) ) 
            + _rating ) / wallets[_buyer].qtyTicketsPurchased ; 

wallets[_buyer].buyerRating = score ; 

return true ; 

}


function rateSeller(address _seller, uint _rating) onlyOwner public returns (bool)

{
require(_rating >= 1 && _rating <=5);
require ( wallets[_seller].qtyTicketsSold >= 1) ; 


// ( currentScore * (TotalQty -1) + _rating ) / TotalQty 
uint score ; 

if (wallets[_seller].sellerRating == 0 ) score = _rating ; 
  else 
    score = ( ( wallets[_seller].sellerRating * (wallets[_seller].qtyTicketsSold - 1) ) 
            + _rating ) / wallets[_seller].qtyTicketsSold ; 


wallets[_seller].sellerRating = score ; 

return true ; 

}


function rewardBuyer(address _buyer, uint _qty ) internal returns (bool)
{
  
  uint reward = wallets[_buyer].qtyTicketsPurchased + (2 * _qty) ; 
  reward = reward + (token.balanceOf(_buyer) * 2) ; 
  require(token.mint(_buyer,reward));

  return true ; 

}


function uploadTicket(string _Description, uint _maxBuyPerWallet,
                      uint _originalPrice, uint _askPrice, uint _tokensRewardOverride, 
                      uint _tokensPenaltyOverride,  
                      address _seller, uint _qtyAvailable) public returns (uint)

{

require( _qtyAvailable > 0 );
require( _maxBuyPerWallet > 0 ) ; 
require( _seller != address(0) ) ;  

// "test",1,1,1,1,1, 0xca35b7d915458ef540ade6068dfe2f44e8fa733c,1
// "Metallica",2,250,300,30,30, 0xca35b7d915458ef540ade6068dfe2f44e8fa733c,100

oneTicket = Ticket(_Description, _maxBuyPerWallet, _originalPrice, 
                    _askPrice, _tokensRewardOverride, _tokensPenaltyOverride, 
                    _seller, _qtyAvailable) ;
                    
tickets.push(oneTicket)  ; 

// thisBuyer = buyer(100,50) ;

// tickets[ticketsLength()-1].
// buyers[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = thisBuyer ; 


return (tickets.length -1) ; 

}

function ticketsLength() public constant returns (uint) { return tickets.length ; }

function  priceOfATicket(uint _ticketID, address _address) public constant returns (uint)
{ return  tickets[_ticketID].buyers[_address].priceBought ; }


function userJoins(address _user) onlyOwner public returns (bool) { wallets[_user].joinedOn = now ; } 


} // END OF EVENTMarketplace

