// // Import the page's CSS. Webpack will know what to do with it.
// import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract';

import bank_artifacts from '../../build/contracts/Bank.json';

var Bank = contract(bank_artifacts);

var account;
var wtoE;
var GAS_AMOUNT = 90000000;
function getBalance (address) {
  return web3.eth.getBalance(address, function (error, result) {
    if (!error) {
      console.log(result.toNumber());
    } else {
      console.error(error);
    }
  })
}

function refreshPage() {
  location.reload();
}
function deposit(amount) {
  Bank.deployed().then(function(contractInstance) {
    // contractInstance.defaultAccount = account;
    contractInstance.deposit({value: web3.toWei(amount,'ether'), from: account, gas: 200}).then(function() {
      refreshPage();
    });
  });
}

function showPastLoans() {
  Bank.deployed().then(function(contractInstance) {
    console.log("CONTRACT : ",contractInstance);
    console.log(account);
    contractInstance.totalLoansBy.call(account).then(function(loanCount) {
      console.log("GOT NUMBER OF LOANS : ",loanCount.valueOf());
      if(loanCount.valueOf() !== 0)
      {
        for(let i=0;i< loanCount.valueOf();i++)
        {
          contractInstance.getLoanDetailsByAddressPosition.call(account, i).then(function(el) {
            console.log(el[5].valueOf());
            console.log(el[5]);
            var newRowContent = '<tr class="'+LOANSTATECLASS[el[0].valueOf()]+'">\
              <td>'+el[4].valueOf()+'</td>\
              <td>'+new Date(el[1].valueOf()*1000).toDateString()+'</td>\
              <td>'+el[2].valueOf()/wtoE+' eth</td>\
              <td>'+el[3].valueOf()/wtoE+' eth</td>\
              </tr>';
            $("#loan-rows tbody").prepend(newRowContent);
          });
        }
      }
   });
  });  
}

$( document ).ready(function() {
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }

  web3.eth.getAccounts(function(err, accs) {
    wtoE = web3.toWei(1,'ether');
    account = accs[0];
    $('#account-number').html(account);
    web3.eth.getBalance(account, function (error, result) {
      if (!error) {
        $('#account-balance').html(result.toNumber()/wtoE);
      } else {
        console.error(error);
      }
    });
  });


  document.getElementById("newloan-form").addEventListener('submit', function(evt){
    evt.preventDefault();
    var amount = $('#newloan-amount').val();
    var date = new Date($('#newloan-date').val()).getTime()/1000;
    deposit(amount);
  });

  Bank.setProvider(web3.currentProvider);
  showPastLoans();
});
