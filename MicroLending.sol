// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// SafeMath library to perform safe arithmetic operations
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract MicroLending {
    using SafeMath for uint256;

    struct Loan {
        uint amount;
        uint collateral;
        address payable borrower;
        address payable lender;
        uint dueDate;
        uint lowestInterestRate;
        bool isPaid;
    }

    struct LoanProposal {
        uint loanId;
        address payable lender;
        uint interestRate;
    }

    Loan[] public loans;
    LoanProposal[] public loanProposals;

    function requestLoan(uint amount, uint collateral, uint dueDate) public payable {
        require(msg.value == collateral, "Send the collateral amount");
        loans.push(Loan(amount, collateral, payable(msg.sender), payable(address(0)), dueDate, 100, false));
    }

    function proposeLoan(uint loanId, uint interestRate) public {
        Loan storage loan = loans[loanId];
        require(loan.lender == payable(address(0)), "Loan already approved");
        require(interestRate < loan.lowestInterestRate, "Propose a lower interest rate");
        loan.lowestInterestRate = interestRate;
        loanProposals.push(LoanProposal(loanId, payable(msg.sender), interestRate));
    }

    function approveLoan(uint loanProposalId) public payable {
        LoanProposal storage loanProposal = loanProposals[loanProposalId];
        Loan storage loan = loans[loanProposal.loanId];
        require(loan.lender == payable(address(0)), "Loan already approved");
        require(msg.sender == loan.borrower, "Only borrower can approve loan");
        require(msg.value == loan.amount, "Send the loan amount");
        loan.lender = loanProposal.lender;
    }

    function repay(uint loanId) public payable {
        Loan storage loan = loans[loanId];
        require(msg.sender == loan.borrower, "Only borrower can repay");

        uint repaymentAmount = loan.amount.add(loan.amount.mul(loan.lowestInterestRate).div(100));
        if (block.timestamp > loan.dueDate) {
            repaymentAmount = repaymentAmount.add(repaymentAmount.mul(10).div(100)); // add 10% late penalty
        }
        require(msg.value == repaymentAmount, "Send the full repayment amount");
        require(loan.isPaid == false, "Loan is already repaid");
        loan.isPaid = true;
        loan.lender.transfer(msg.value);
        loan.borrower.transfer(loan.collateral);
    }

    function seizeCollateral(uint loanId) public {
        Loan storage loan = loans[loanId];
        require(msg.sender == loan.lender, "Only lender can seize collateral");
        require(block.timestamp > loan.dueDate, "Can only seize collateral after due date");
        require(loan.isPaid == false, "Loan is already repaid");
        loan.lender.transfer(loan.collateral);
        loan.isPaid = true; // set to true to prevent multiple seizures
    }

    function getLoansCount() public view returns (uint) {
        return loans.length;
    }

    function getLoanProposalsCount() public view returns (uint) {
        return loanProposals.length;
    }
}
